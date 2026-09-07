# Govardhana Pilgrimage — Rādhā-kuṇḍa Story MVP

This directory is the implementation repository area for the private, offline iPhone MVP. Tasks 001–009 established the app architecture against a neutral fixture. Task 010 installs the authorized Rādhā-kuṇḍa development vertical slice while preserving those readers, navigation, search, bookmarks, and reading positions.

## Authoritative specifications and content handoff

The approved specifications remain unchanged at:

```text
../CODEX_DEVELOPMENT_HANDOFF/docs/app-specs/
```

The curator-controlled source handoff remains at:

```text
../CODEX_DEVELOPMENT_HANDOFF/content-handoff/
```

The neutral fixture remains under `content/fixtures/` for compiler regression tests. The runtime database contains the development-manifest-authorized Rādhā-kuṇḍa slice plus the Task 013 Śrīmad-Bhāgavatam 10.36.1–16 expansion.

## Requirements

- Python 3.11 or newer
- PyYAML (development-time YAML parsing)

## Commands

Run these commands from this directory:

```bash
python3 tools/validate_content.py --manifest radhakunda-mvp-development-manifest
python3 tools/build_content.py --manifest radhakunda-mvp-development-manifest
python3 -m unittest discover tests
```

Generate the real development database before building the app, then resolve GRDB and build/test against an installed iPhone simulator:

```bash
xcodebuild -resolvePackageDependencies -project app/GovardhanaPilgrimage.xcodeproj -scheme GovardhanaPilgrimage
xcodebuild -project app/GovardhanaPilgrimage.xcodeproj -scheme GovardhanaPilgrimage -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project app/GovardhanaPilgrimage.xcodeproj -scheme GovardhanaPilgrimage -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO test
```

The generated project targets iOS 18+, uses GRDB.swift as its only external Swift dependency, and bundles `build/radhakunda-content.sqlite` as a read-only resource. The real Story opens through the database-driven TOC. Citations resolve canonical Passage IDs into preferred Edition representations, and the Source Reader supports surrounding reading and exact Return to Story. Optional compiled witness mappings can expose a PDFKit Original Witness viewer at an exact zero-based PDF page index while retaining a separate printed page label. Task 012 proves this only with a neutral fixture; the real development manifest currently compiles zero witnesses and mappings. Library presents the four packaged Works (excluding the metadata-only parent Work). Global and Work-scoped FTS5 search, bookmarks, and semantic reading positions retain the Task 008–009 behavior. User state persists only in `Application Support/user-state.sqlite`; Python remains a development-time compiler and does not ship in the app.

Validation reads the manifest and authoring files without writing build output. Building writes:

- `build/radhakunda-mvp-development-content.json` — deterministic canonical/representation intermediate content;
- `build/radhakunda-content.sqlite` — inspectable runtime SQLite/FTS package;
- `build/build-report.json` — content, schema, integrity, and FTS results.

The SQLite database is generated and must not be hand-edited. The shipped iPhone app will read this database; it will not run Python.

## SQLite inspection

With the `sqlite3` command-line tool installed, inspect the generated database from this directory:

```bash
sqlite3 -readonly build/radhakunda-content.sqlite "PRAGMA integrity_check;"
sqlite3 -readonly build/radhakunda-content.sqlite "PRAGMA foreign_key_check;"
sqlite3 -readonly build/radhakunda-content.sqlite "SELECT c.id, p.id, w.id FROM citations c JOIN source_passages p ON p.id = c.passage_id JOIN source_works w ON w.id = p.work_id;"
sqlite3 -readonly build/radhakunda-content.sqlite "SELECT content_type, target_id, title FROM search_documents_fts WHERE search_documents_fts MATCH '\"narma-dharmokti\"' ORDER BY content_type, target_id;"
```

The first query returns `ok`; the second returns no rows; all 12 citation rows resolve; and the FTS query returns the Story block and `passage.radha-kundastaka.1`.

## Repository layout

- `app/` — iOS 18+ SwiftUI application, unit tests, and UI tests
- `content/` — human-readable authoring content, manifests, and fixtures
- `docs/` — implementation-facing conventions; approved specs remain in the handoff above
- `tools/` — deterministic YAML/Markdown validator/compiler and SQLite builder
- `tests/` — automated content-tooling tests
- `witnesses/` — reserved for later approved witness integration
- `build/` — generated artifacts, ignored except for `.gitkeep`
