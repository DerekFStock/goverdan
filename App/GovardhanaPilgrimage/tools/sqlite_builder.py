"""Generate and inspect the Task 002 read-only runtime content database."""

from __future__ import annotations

import hashlib
import json
import sqlite3
from pathlib import Path
from typing import Any

from content_tooling import BuildResult, ContentValidationError


SCHEMA_VERSION = 4
DATABASE_FILENAME = "radhakunda-content.sqlite"

SCHEMA_SQL = """
PRAGMA foreign_keys = ON;
PRAGMA user_version = 4;

CREATE TABLE package_metadata (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE stories (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    status TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE story_parts (
    id TEXT PRIMARY KEY NOT NULL,
    story_id TEXT NOT NULL REFERENCES stories(id),
    title TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    UNIQUE (story_id, sort_order)
) WITHOUT ROWID;

CREATE TABLE story_sections (
    id TEXT PRIMARY KEY NOT NULL,
    story_id TEXT NOT NULL REFERENCES stories(id),
    part_id TEXT REFERENCES story_parts(id),
    title TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    UNIQUE (story_id, sort_order)
) WITHOUT ROWID;

CREATE TABLE story_blocks (
    id TEXT PRIMARY KEY NOT NULL,
    section_id TEXT NOT NULL REFERENCES story_sections(id),
    sort_order INTEGER NOT NULL,
    block_type TEXT NOT NULL,
    text TEXT NOT NULL,
    UNIQUE (section_id, sort_order)
) WITHOUT ROWID;

CREATE TABLE source_works (
    id TEXT PRIMARY KEY NOT NULL,
    parent_work_id TEXT REFERENCES source_works(id),
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    author TEXT,
    source_layer TEXT
) WITHOUT ROWID;

CREATE TABLE source_editions (
    id TEXT PRIMARY KEY NOT NULL,
    work_id TEXT NOT NULL REFERENCES source_works(id),
    title TEXT NOT NULL,
    status TEXT NOT NULL,
    translator TEXT,
    translation_provenance TEXT,
    normalization_provenance TEXT,
    preferred INTEGER NOT NULL DEFAULT 0 CHECK (preferred IN (0, 1))
) WITHOUT ROWID;

CREATE UNIQUE INDEX source_editions_one_preferred_per_work
ON source_editions(work_id) WHERE preferred = 1;

CREATE TABLE source_sections (
    id TEXT PRIMARY KEY NOT NULL,
    work_id TEXT NOT NULL REFERENCES source_works(id),
    parent_section_id TEXT REFERENCES source_sections(id),
    title TEXT NOT NULL,
    sort_order INTEGER NOT NULL
) WITHOUT ROWID;

CREATE TABLE source_passages (
    id TEXT PRIMARY KEY NOT NULL,
    work_id TEXT NOT NULL REFERENCES source_works(id),
    parent_passage_id TEXT REFERENCES source_passages(id),
    canonical_locus TEXT NOT NULL,
    display_locus TEXT,
    sort_order INTEGER NOT NULL,
    verification_status TEXT,
    UNIQUE (work_id, canonical_locus)
) WITHOUT ROWID;

CREATE TABLE passage_representations (
    id TEXT PRIMARY KEY NOT NULL,
    passage_id TEXT NOT NULL REFERENCES source_passages(id),
    edition_id TEXT NOT NULL REFERENCES source_editions(id),
    original_text TEXT,
    transliteration TEXT,
    translation TEXT,
    commentary TEXT,
    source_notes TEXT,
    search_text TEXT NOT NULL,
    UNIQUE (passage_id, edition_id)
) WITHOUT ROWID;

CREATE TABLE citations (
    id TEXT PRIMARY KEY NOT NULL,
    content_block_id TEXT NOT NULL REFERENCES story_blocks(id),
    source_passage_id TEXT REFERENCES source_passages(id),
    start_passage_id TEXT REFERENCES source_passages(id),
    end_passage_id TEXT REFERENCES source_passages(id),
    role TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 1,
    CHECK (
        (source_passage_id IS NOT NULL AND start_passage_id IS NULL AND end_passage_id IS NULL)
        OR
        (source_passage_id IS NULL AND start_passage_id IS NOT NULL AND end_passage_id IS NOT NULL)
    )
) WITHOUT ROWID;

CREATE INDEX citations_by_block ON citations(content_block_id, sort_order);
CREATE INDEX citations_by_source_passage ON citations(source_passage_id);
CREATE INDEX citations_by_start_passage ON citations(start_passage_id);
CREATE INDEX citations_by_end_passage ON citations(end_passage_id);

CREATE TABLE witnesses (
    id TEXT PRIMARY KEY NOT NULL,
    work_id TEXT NOT NULL REFERENCES source_works(id),
    edition_id TEXT REFERENCES source_editions(id),
    title TEXT NOT NULL,
    file_path TEXT NOT NULL,
    media_type TEXT NOT NULL,
    page_count INTEGER
) WITHOUT ROWID;

CREATE TABLE witness_mappings (
    id TEXT PRIMARY KEY NOT NULL,
    witness_id TEXT NOT NULL REFERENCES witnesses(id),
    passage_id TEXT NOT NULL REFERENCES source_passages(id),
    representation_id TEXT REFERENCES passage_representations(id),
    pdf_page_index INTEGER NOT NULL CHECK (pdf_page_index >= 0),
    printed_page_label TEXT
) WITHOUT ROWID;

CREATE TABLE images (
    id TEXT PRIMARY KEY NOT NULL,
    file_path TEXT NOT NULL,
    title TEXT,
    alt_text TEXT
) WITHOUT ROWID;

CREATE TABLE search_documents (
    rowid INTEGER PRIMARY KEY,
    id TEXT NOT NULL UNIQUE,
    content_type TEXT NOT NULL CHECK (content_type IN ('story_block', 'source_passage')),
    target_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL
);

CREATE VIRTUAL TABLE search_documents_fts USING fts5(
    title,
    body,
    content_type UNINDEXED,
    target_id UNINDEXED,
    content='search_documents',
    content_rowid='rowid',
    tokenize='unicode61 remove_diacritics 2'
);
"""


def _json_text(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False, sort_keys=True)


def _logical_digest(connection: sqlite3.Connection) -> str:
    tables = [
        row[0]
        for row in connection.execute(
            "SELECT name FROM sqlite_schema WHERE type = 'table' AND name NOT LIKE 'search_documents_fts_%' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name"
        )
    ]
    logical: dict[str, list[list[Any]]] = {}
    for table in tables:
        columns = [row[1] for row in connection.execute(f'PRAGMA table_info("{table}")')]
        if not columns:
            continue
        order = ", ".join(f'"{column}"' for column in columns)
        logical[table] = [list(row) for row in connection.execute(f'SELECT {order} FROM "{table}" ORDER BY {order}')]
    encoded = json.dumps(logical, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _insert_content(connection: sqlite3.Connection, result: BuildResult) -> None:
    content = result.content
    connection.executemany(
        "INSERT INTO package_metadata(key, value) VALUES (?, ?)",
        [("manifest_id", content["manifest_id"]), ("schema_version", str(SCHEMA_VERSION))],
    )
    connection.executemany(
        "INSERT INTO stories(id, title, status) VALUES (:id, :title, :status)", content["stories"]
    )
    connection.executemany(
        "INSERT INTO story_sections(id, story_id, part_id, title, sort_order) VALUES (?, ?, ?, ?, ?)",
        [(item["id"], item["story_id"], item.get("part_id"), item["title"], item["order"]) for item in content["story_sections"]],
    )
    connection.executemany(
        "INSERT INTO story_blocks(id, section_id, sort_order, block_type, text) VALUES (?, ?, ?, ?, ?)",
        [(item["id"], item["section_id"], item["order"], item.get("block_type", "paragraph"), item["text"]) for item in content["content_blocks"]],
    )
    connection.executemany(
        "INSERT INTO source_works(id, parent_work_id, title, status, author, source_layer) VALUES (?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item.get("parent_work_id"), item["title"], item.get("status", "fixture"),
                item.get("author"), item.get("source_layer")
            )
            for item in content["works"]
        ],
    )
    connection.executemany(
        "INSERT INTO source_editions(id, work_id, title, status, translator, translation_provenance, normalization_provenance, preferred) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item["work_id"], item["title"], item.get("status", "fixture"),
                item.get("translator"), item.get("translation_provenance"), item.get("normalization_provenance"),
                int(item.get("preferred", False))
            )
            for item in content["editions"]
        ],
    )
    connection.executemany(
        "INSERT INTO source_passages(id, work_id, parent_passage_id, canonical_locus, display_locus, sort_order, verification_status) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item["work_id"], item.get("parent_passage_id"), item["locus"],
                item.get("display_locus"), item["order"], item.get("verification_status")
            )
            for item in content["passages"]
        ],
    )
    connection.executemany(
        "INSERT INTO passage_representations(id, passage_id, edition_id, original_text, transliteration, translation, commentary, source_notes, search_text) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item["passage_id"], item["edition_id"], item.get("original_text"),
                item.get("transliteration"), item.get("translation"), _json_text(item.get("commentary")),
                _json_text(item.get("source_notes")), item.get("search_text", item["text"])
            )
            for item in content["passage_representations"]
        ],
    )
    connection.executemany(
        "INSERT INTO citations(id, content_block_id, source_passage_id, start_passage_id, end_passage_id, role, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item["content_block_id"], item.get("source_passage_id"),
                item.get("start_passage_id"), item.get("end_passage_id"), item["role"], item.get("order", 1)
            )
            for item in content["citations"]
        ],
    )
    connection.executemany(
        "INSERT INTO witnesses(id, work_id, edition_id, title, file_path, media_type, page_count) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item["work_id"], item.get("edition_id"), item["title"], item["file_path"],
                item["media_type"], item.get("page_count")
            )
            for item in content.get("witnesses", [])
        ],
    )
    connection.executemany(
        "INSERT INTO witness_mappings(id, witness_id, passage_id, representation_id, pdf_page_index, printed_page_label) VALUES (?, ?, ?, ?, ?, ?)",
        [
            (
                item["id"], item["witness_id"], item["passage_id"], item.get("representation_id"),
                item["pdf_page_index"], item.get("printed_page_label")
            )
            for item in content.get("witness_mappings", [])
        ],
    )

    story_by_section = {item["id"]: item["story_id"] for item in content["story_sections"]}
    story_by_id = {item["id"]: item for item in content["stories"]}
    search_rows: list[tuple[str, str, str, str, str]] = []
    for block in content["content_blocks"]:
        story = story_by_id[story_by_section[block["section_id"]]]
        search_rows.append((f"search.story.{block['id']}", "story_block", block["id"], story["title"], block["text"]))

    preferred_editions = {item["id"] for item in content["editions"] if item.get("preferred")}
    passage_by_id = {item["id"]: item for item in content["passages"]}
    work_by_id = {item["id"]: item for item in content["works"]}
    for representation in content["passage_representations"]:
        if representation["edition_id"] not in preferred_editions:
            continue
        passage = passage_by_id[representation["passage_id"]]
        work = work_by_id[passage["work_id"]]
        search_rows.append(
            (
                f"search.source.{representation['id']}", "source_passage", passage["id"],
                f"{work['title']} {passage['locus']}", representation.get("search_text", representation["text"])
            )
        )
    search_rows.sort(key=lambda row: row[0])
    connection.executemany(
        "INSERT INTO search_documents(id, content_type, target_id, title, body) VALUES (?, ?, ?, ?, ?)", search_rows
    )
    connection.execute("INSERT INTO search_documents_fts(search_documents_fts) VALUES ('rebuild')")


def inspect_database(path: Path) -> dict[str, Any]:
    connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        tables = [
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_schema WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%' ORDER BY name"
            )
        ]
        indexes = [row[0] for row in connection.execute("SELECT name FROM sqlite_schema WHERE type='index' ORDER BY name")]
        story_fts = connection.execute(
            "SELECT count(*) FROM search_documents_fts WHERE content_type='story_block'"
        ).fetchone()[0]
        source_fts = connection.execute(
            "SELECT count(*) FROM search_documents_fts WHERE content_type='source_passage'"
        ).fetchone()[0]
        citation_resolution = connection.execute(
            "SELECT count(*) FROM citations c JOIN source_passages p ON p.id=COALESCE(c.source_passage_id, c.start_passage_id) JOIN source_works w ON w.id=p.work_id"
        ).fetchone()[0]
        return {
            "filename": path.name,
            "schema_version": connection.execute("PRAGMA user_version").fetchone()[0],
            "integrity_check": integrity,
            "foreign_key_violation_count": len(foreign_keys),
            "citation_resolution_count": citation_resolution,
            "story_fts_result_count": story_fts,
            "source_fts_result_count": source_fts,
            "search_document_count": connection.execute("SELECT count(*) FROM search_documents").fetchone()[0],
            "tables": tables,
            "indexes": indexes,
            "logical_content_sha256": _logical_digest(connection),
        }
    finally:
        connection.close()


def build_sqlite(path: Path, result: BuildResult) -> dict[str, Any]:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.unlink(missing_ok=True)
    try:
        connection = sqlite3.connect(temporary)
        try:
            connection.execute("PRAGMA foreign_keys = ON")
            connection.executescript(SCHEMA_SQL)
            with connection:
                _insert_content(connection, result)
            violations = connection.execute("PRAGMA foreign_key_check").fetchall()
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
            if violations or integrity != "ok":
                raise ContentValidationError(
                    f"SQLite validation failed: integrity={integrity}, foreign_key_violations={len(violations)}"
                )
            connection.execute("VACUUM")
        finally:
            connection.close()
        temporary.replace(path)
        report = inspect_database(path)
        if report["story_fts_result_count"] < 1 or report["source_fts_result_count"] < 1:
            raise ContentValidationError("SQLite FTS index is missing Story or Source documents")
        return report
    except sqlite3.Error as error:
        temporary.unlink(missing_ok=True)
        raise ContentValidationError(f"SQLite build failed: {error}") from error
