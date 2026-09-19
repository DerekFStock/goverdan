#!/usr/bin/env python3
"""Import the complete English-only Vraja-rīti-cintāmaṇi DOCX witness."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import unicodedata
from xml.etree import ElementTree as ET
from zipfile import ZipFile

import yaml


WORK_ID = "work.vraja-riti-cintamani"
EDITION_ID = "edition.vraja-riti-cintamani.english-supplied-witness-v1"
W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
CHAPTER_TITLES = {
    1: "Nandīśvara and the People of Vraja",
    2: "The Forests and Sacred Environment of Vṛndāvana",
    3: "Govardhana and Its Sacred Landscape",
}
SEARCH_ALIASES = "Braj Vrndavana Vṛndāvana Radha-kunda Rādhā-kuṇḍa Syama-kunda Śyāma-kuṇḍa Govardhan Govardhana Nandisvara Nandīśvara kunja kuñja"
REQUIRED_RECOVERED = {(1, number, number) for number in (40, 46, 53, 59, 66, 71, 73)}


def normalize(text: str) -> str:
    return unicodedata.normalize("NFC", re.sub(r"[ \u00a0]+", " ", text).strip())


def docx_paragraphs(path: Path) -> list[str]:
    with ZipFile(path) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))
    paragraphs: list[str] = []
    for paragraph in root.findall(f".//{W}body/{W}p"):
        parts: list[str] = []
        for element in paragraph.iter():
            if element.tag == f"{W}t":
                parts.append(element.text or "")
            elif element.tag == f"{W}tab":
                parts.append("\t")
            elif element.tag in {f"{W}br", f"{W}cr"}:
                parts.append("\n")
        value = normalize("".join(parts))
        if value:
            paragraphs.append(value)
    return paragraphs


def build_package(paragraphs: list[str]) -> dict:
    chapter_positions = [i for i, text in enumerate(paragraphs) if re.fullmatch(r"Chapter [123]", text)]
    if [paragraphs[i] for i in chapter_positions] != ["Chapter 1", "Chapter 2", "Chapter 3"]:
        raise ValueError("Chapters 1 through 3 must each appear exactly once and in order")

    passages: list[dict] = []
    order = 1
    pending_note: tuple[int, int] | None = None
    for chapter, start in enumerate(chapter_positions, 1):
        end = chapter_positions[chapter] if chapter < 3 else len(paragraphs)
        chapter_passages: list[dict] = []
        for text in paragraphs[start + 1:end]:
            match = re.match(r"^(\d+)(?:-(\d+))?\s+(.+)$", text, re.S)
            if match:
                verse_start = int(match.group(1))
                verse_end = int(match.group(2) or match.group(1))
                locus = f"{chapter}.{verse_start}" + (f"-{verse_end}" if verse_end != verse_start else "")
                item = {
                    "id": f"passage.vraja-riti-cintamani.vrc.{locus}",
                    "locus": locus,
                    "display_locus": locus,
                    "order": order,
                    "verification_status": "SUPPLIED_WITNESS_TRANSCRIPTION",
                    "translation": normalize(match.group(3)),
                    "translation_status": "SUPPLIED_TRANSLATION_TRANSLATOR_UNKNOWN",
                    "section_kind": "CHAPTER",
                    "chapter_number": chapter,
                    "chapter_title": CHAPTER_TITLES[chapter],
                    "source_chapter_title": f"Chapter {chapter}",
                    "chapter_passage_number": len(chapter_passages) + 1,
                    "passage_kind": "verse_range_translation" if verse_end != verse_start else "verse_translation",
                    "witness_locator": f"chapter {chapter}, verse {verse_start}" + (f"–{verse_end}" if verse_end != verse_start else ""),
                    "canonical_verse": locus,
                    "verse_start": verse_start,
                    "verse_end": verse_end,
                    "search_aliases": SEARCH_ALIASES,
                }
                chapter_passages.append(item)
                passages.append(item)
                order += 1
                pending_note = None
            elif text.startswith("Note:"):
                if not chapter_passages:
                    raise ValueError("Witness note appears before a verse")
                note = normalize(text.removeprefix("Note:").strip())
                chapter_passages[-1]["translation_note"] = note
                pending_note = (chapter, chapter_passages[-1]["verse_start"])
            elif pending_note == (3, 8):
                current = chapter_passages[-1].get("translation_note", "")
                chapter_passages[-1]["translation_note"] = normalize(f"{current}\n\n{text}")
                chapter_passages[-1]["note_presentation"] = "alternative"
                pending_note = None
            elif chapter_passages:
                # The witness uses separate paragraphs for two continued verse translations
                # and for the embedded Bhāgavatam quotation under 1.54.
                chapter_passages[-1]["translation"] = normalize(f"{chapter_passages[-1]['translation']}\n\n{text}")
            else:
                raise ValueError(f"Unexpected chapter content: {text[:60]}")

        expected = 87 if chapter == 1 else 84 if chapter == 2 else 60
        if len(chapter_passages) != expected:
            raise ValueError(f"Chapter {chapter}: expected {expected} English blocks, found {len(chapter_passages)}")

    coverage = {(item["chapter_number"], item["verse_start"], item["verse_end"]) for item in passages}
    expanded = {(chapter, verse) for chapter, start, end in coverage for verse in range(start, end + 1)}
    expected_expanded = ({(1, n) for n in range(1, 88)} | {(2, n) for n in range(1, 88)} | {(3, n) for n in range(1, 61)})
    if expanded != expected_expanded or (2, 7, 10) not in coverage:
        raise ValueError("Canonical verse coverage or the combined 2.7–10 passage is invalid")
    if not REQUIRED_RECOVERED.issubset(coverage):
        raise ValueError("One or more recovered Chapter 1 passages is absent")
    notes = [item for item in passages if item.get("translation_note")]
    if [(item["chapter_number"], item["verse_start"]) for item in notes] != [(1, 2), (1, 87), (3, 8)]:
        raise ValueError("Expected exactly the three supplied notes attached to 1.2, 1.87, and 3.8")
    next(item for item in notes if item["chapter_number"] == 1 and item["verse_start"] == 87)["note_presentation"] = "collapsed"
    if len(passages) != 231 or len({item["id"] for item in passages}) != 231:
        raise ValueError("Expected 231 unique English passage blocks")
    if "completed in this, the last verse" not in passages[-1]["translation"]:
        raise ValueError("Final completion statement is absent")

    return {
        "schema_version": 1,
        "work": {
            "id": WORK_ID, "title": "Vraja-rīti-cintāmaṇi", "short_title": "Vraja-rīti-cintāmaṇi",
            "abbreviation": "VRC", "author": "Śrī Viśvanātha Cakravartī Ṭhākura",
            "parent_work_id": None, "source_layer": "A_PRIMARY_GOSVAMI", "language": "en",
            "status": "PRIVATE_RESEARCH",
        },
        "edition": {
            "id": EDITION_ID, "work_id": WORK_ID, "title": "Complete English Supplied-Witness Reading Edition",
            "representation": "translation", "version": "1.0.0-private", "status": "PRIVATE_RIGHTS_UNCONFIRMED",
            "preferred": True, "source_document": "Vraja_Riti_Cintamani_English_Complete.docx",
            "text_provenance": {
                "format": "Modern DOCX converted losslessly from the legacy English Word witness",
                "normalization": "Unicode NFC and mechanical whitespace cleanup only; English wording preserved",
                "legacy_english_witness": "Vraja riti cintamani.doc",
                "verification_witness": "vraja-riti-cintamani_-_visvanatha_cakravartin.docx",
                "canonical_verse_numbering": True,
            },
            "translation_provenance": {
                "type": "SUPPLIED_TRANSLATION", "translator": "Translator not identified in supplied file",
                "status": "PUBLICATION_RIGHTS_UNCONFIRMED",
            },
        },
        "provenance": {
            "reader_scope": "FULL_WORK", "text_scope": "COMPLETE_TRANSLATION",
            "english_subtitle": "The Cintāmaṇi Jewel of Vraja", "chapter_count": 3,
            "canonical_verse_count": 234, "english_passage_count": 231, "attached_note_count": 3,
            "orientation": "A three-chapter meditation on the people, natural environment, and sacred geography of Vraja, culminating in Govardhana and Rādhā-kuṇḍa.",
            "public_distribution_authorized": False,
        },
        "passages": passages,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    package = build_package(docx_paragraphs(args.input))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(yaml.safe_dump(package, allow_unicode=True, sort_keys=False, width=120), encoding="utf-8")
    print("Wrote 231 English passages covering 234 canonical verses with 3 attached notes")


if __name__ == "__main__":
    main()
