#!/usr/bin/env python3
"""Import the supplied Windows-1252 Word-HTML Kṛṣṇa-bhāvanāmṛta witness."""

from __future__ import annotations

import argparse
from html.parser import HTMLParser
from pathlib import Path
import re
import unicodedata

import yaml


WORK_ID = "work.krishna-bhavanamrita"
EDITION_ID = "edition.krishna-bhavanamrita.english-supplied-witness-v1"
CHAPTERS = [
    (1, "Pastimes at Dawn", "3:36 a.m.–6:00 a.m.", 13),
    (2, "Pastimes at Dawn, Cont'd.", "3:36 a.m.–6:00 a.m.", 35),
    (3, "Morning Pastimes", "6:00 a.m.–8:24 a.m.", 34),
    (4, "Śrī Rādhikā's Bath, Dressing and Ornamentation", "6:00 a.m.–8:24 a.m.", 37),
    (5, "Śrī Rādhikā Goes to Nandīśvara to Cook for Kṛṣṇa", "6:00 a.m.–8:24 a.m.", 30),
    (6, "Breakfast and Other Pastimes", "8:24 a.m.–10:48 a.m.", 59),
    (7, "Pastimes in the Pastures", "8:24 a.m.–10:48 a.m.", 28),
    (8, "Pastimes in the Forest", "8:24 a.m.–10:48 a.m.", 29),
    (9, "Flowerplays and Loveplays", "10:48 a.m.–3:36 p.m.", 64),
    (10, "Relishing the Nectar of Playing in the Kuñja", "10:48 a.m.–3:36 p.m.", 39),
    (11, "Playing on Swings in the Rainy Season", "10:48 a.m.–3:36 p.m.", 19),
    (12, "Wanderings in the Forest", "10:48 a.m.–3:36 p.m.", 38),
    (13, "Rādhā and Kṛṣṇa Drink Honey", "10:48 a.m.–3:36 p.m.", 22),
    (14, "Rādhā and Kṛṣṇa's Water Play Pastimes", "10:48 a.m.–3:36 p.m.", 32),
    (15, "Rādhā and Kṛṣṇa Play Dice and Worship the Sun God", "10:48 a.m.–3:36 p.m.", 80),
    (16, "Afternoon Pastimes", "3:36 p.m.–6:00 p.m.", 33),
    (17, "Evening Pastimes", "6:00 p.m.–8:24 p.m.", 23),
    (18, "Pastimes at Nightfall", "8:24 p.m.–10:48 p.m.", 34),
    (19, "Rādhā and Kṛṣṇa Engage in Nocturnal Pastimes", "10:48 p.m.–3:36 a.m.", 43),
    (20, "End of the Day", "10:48 p.m.–3:36 a.m.", 20),
]


class ParagraphParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.in_paragraph = False
        self.parts: list[str] = []
        self.paragraphs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() == "p":
            self.in_paragraph = True
            self.parts = []
        elif tag.lower() == "br" and self.in_paragraph:
            self.parts.append(" ")

    def handle_data(self, data: str) -> None:
        if self.in_paragraph:
            self.parts.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() == "p" and self.in_paragraph:
            text = unicodedata.normalize("NFC", re.sub(r"\s+", " ", "".join(self.parts)).strip())
            if text:
                self.paragraphs.append(text)
            self.in_paragraph = False
            self.parts = []


def parse_paragraphs(path: Path) -> list[str]:
    raw = path.read_bytes()
    # The meta tag incorrectly declares Windows-1251. Byte usage and the supplied audit
    # identify this witness as Windows-1252; strict decoding catches accidental changes.
    text = raw.decode("cp1252", errors="strict")
    parser = ParagraphParser()
    parser.feed(text)
    return parser.paragraphs


def passage(identifier: str, locus: str, display: str, order: int, text: str, **notes: object) -> dict:
    return {
        "id": f"passage.krishna-bhavanamrita.{identifier}",
        "locus": locus,
        "display_locus": display,
        "order": order,
        "verification_status": "SUPPLIED_WITNESS_TRANSCRIPTION",
        "translation": text,
        "translation_status": "SUPPLIED_TRANSLATION_TRANSLATOR_UNKNOWN",
        **notes,
    }


def build_package(paragraphs: list[str]) -> dict:
    by_text = {text: index for index, text in enumerate(paragraphs)}
    required = [f"Chapter {number}" for number, *_ in CHAPTERS]
    if any(paragraphs.count(label) != 1 for label in required):
        raise ValueError("Chapters 1 through 20 must each appear exactly once")

    output: list[dict] = []
    order = 1
    preface_indices = [6, 7, 12, 13]
    for sequence, index in enumerate(preface_indices, 1):
        output.append(passage(
            f"kba.front.preface.p{sequence:03d}", f"front.preface.p{sequence:03d}",
            f"Preface {sequence}", order, paragraphs[index], section_kind="FRONT_MATTER",
            passage_kind="preface", witness_locator=f"translator's preface, paragraph {sequence}",
        ))
        order += 1

    for sequence, index in enumerate((19, 24), 1):
        output.append(passage(
            f"kba.invocation.p{sequence:03d}", f"invocation.p{sequence:03d}",
            f"Invocation {sequence}", order, paragraphs[index], section_kind="INVOCATION",
            passage_kind="invocation_translation", witness_locator=f"invocation translation {sequence}",
        ))
        order += 1

    for chapter_number, chapter_title, time_range, expected_count in CHAPTERS:
        heading = by_text[f"Chapter {chapter_number}"]
        if heading + 3 >= len(paragraphs):
            raise ValueError(f"Chapter {chapter_number} header is incomplete")
        source_title = paragraphs[heading + 1]
        source_time = paragraphs[heading + 2]
        if not source_title or not re.fullmatch(r"\(.+\)", source_time):
            raise ValueError(f"Chapter {chapter_number} title or time range is missing")
        end = next((i for i in range(heading + 3, len(paragraphs)) if paragraphs[i].lower().startswith("thus ends chapter")), None)
        if end is None:
            raise ValueError(f"Chapter {chapter_number} completion statement is missing")
        body = paragraphs[heading + 3:end]
        # The supplied witness places its "End of Pratah Lila" cycle marker immediately
        # after the chapter-six colophon. The approved 712-paragraph migration snapshot
        # treats that reader-visible marker as chapter 6, passage 59.
        if chapter_number == 6 and end + 1 < len(paragraphs) and paragraphs[end + 1].startswith("End of Pratah Lila"):
            body.append(paragraphs[end + 1])
        if len(body) != expected_count:
            raise ValueError(f"Chapter {chapter_number}: expected {expected_count} body passages, found {len(body)}")
        for sequence, text in enumerate(body, 1):
            anchor = f"kba.ch{chapter_number:02d}.p{sequence:03d}"
            output.append(passage(
                anchor, f"ch{chapter_number:02d}.p{sequence:03d}",
                f"Chapter {chapter_number}, passage {sequence}", order, text,
                section_kind="CHAPTER", chapter_number=chapter_number, chapter_title=chapter_title,
                source_chapter_title=source_title, time_range=time_range, passage_kind="prose",
                witness_locator=f"chapter {chapter_number}, paragraph {sequence}", canonical_verse=None,
            ))
            order += 1

    completion = 'Thus ends Srila Visvanatha Cakravrti\'s "Krishna Bhavanamrita Mahakavya," which describes the transcendental eight fold daily pastimes of Sri Radha and Sri Krishna.'
    if completion not in by_text:
        raise ValueError("Final completion statement is absent")
    output.append(passage(
        "kba.colophon.p001", "colophon.p001", "Final colophon", order, completion,
        section_kind="COLOPHON", passage_kind="colophon", witness_locator="final completion statement",
    ))
    order += 1

    cast_heading = by_text.get("Cast of Characters")
    if cast_heading is None or paragraphs[cast_heading + 1] != "In Order of Appearance":
        raise ValueError("Cast of Characters appendix is missing")
    for sequence, text in enumerate(paragraphs[cast_heading + 2:], 1):
        output.append(passage(
            f"kba.appendix.cast.p{sequence:03d}", f"appendix.cast.p{sequence:03d}",
            f"Cast {sequence}", order, text, section_kind="APPENDIX", passage_kind="cast",
            witness_locator=f"cast of characters, paragraph {sequence}",
        ))
        order += 1

    ids = [item["id"] for item in output]
    if len(ids) != len(set(ids)):
        raise ValueError("Generated passage ID is duplicated")
    if sum(item.get("section_kind") == "CHAPTER" for item in output) != 712:
        raise ValueError("Expected 712 chapter-body passages")
    if "passage.krishna-bhavanamrita.kba.ch01.p001" not in ids or "passage.krishna-bhavanamrita.kba.ch20.p020" not in ids:
        raise ValueError("First or final body anchor is missing")

    return {
        "schema_version": 1,
        "work": {
            "id": WORK_ID, "title": "Kṛṣṇa-bhāvanāmṛta-mahākāvya",
            "short_title": "Kṛṣṇa-bhāvanāmṛta", "abbreviation": "KBA",
            "author": "Śrī Viśvanātha Cakravartī Ṭhākura", "parent_work_id": None,
            "source_layer": "A_PRIMARY_GOSVAMI", "language": "en", "status": "PRIVATE_RESEARCH",
        },
        "edition": {
            "id": EDITION_ID, "work_id": WORK_ID, "title": "English Supplied-Witness Reading Edition",
            "representation": "translation", "version": "1.0.0-private", "status": "PRIVATE_RIGHTS_UNCONFIRMED",
            "preferred": True, "source_document": "Krishna Bhavanamrta.doc",
            "text_provenance": {
                "encoding": "Windows-1252", "format": "HTML saved with a .doc extension",
                "normalization": "Unicode NFC and whitespace cleanup only; English wording preserved",
                "verse_numbering_available": False,
            },
            "translation_provenance": {
                "type": "SUPPLIED_TRANSLATION", "translator": "Translator not identified in supplied file",
                "status": "PUBLICATION_RIGHTS_UNCONFIRMED",
            },
        },
        "provenance": {
            "reader_scope": "FULL_WORK", "text_scope": "COMPLETE_TRANSLATION",
            "chapter_count": 20, "chapter_body_passage_count": 712,
            "orientation": "A twenty-chapter meditation on the full eightfold daily pastimes of Śrī Śrī Rādhā-Kṛṣṇa.",
            "public_distribution_authorized": False,
        },
        "passages": output,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    package = build_package(parse_paragraphs(args.input))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(yaml.safe_dump(package, allow_unicode=True, sort_keys=False, width=120), encoding="utf-8")
    print(f"Wrote {len(package['passages'])} passages ({package['provenance']['chapter_body_passage_count']} chapter body passages)")


if __name__ == "__main__":
    main()
