"""Focused import, compilation, and offline-reader tests for Vraja-rīti-cintāmaṇi."""

from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("/Users/derekstock/Downloads/Vraja_Riti_Cintamani_English_Complete.docx")
PACKAGE = ROOT / "content/sources/vraja-riti-cintamani/package.yaml"
DATABASE = ROOT / "build/radhakunda-content.sqlite"
WORK_ID = "work.vraja-riti-cintamani"


class VrajaRitiCintamaniTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.package = yaml.safe_load(PACKAGE.read_text(encoding="utf-8"))
        cls.passages = cls.package["passages"]

    def test_importer_reproduces_committed_package(self):
        self.assertTrue(SOURCE.exists())
        with tempfile.TemporaryDirectory() as directory:
            generated = Path(directory) / "package.yaml"
            subprocess.run([
                "python3", str(ROOT / "tools/import_vraja_riti_cintamani.py"),
                "--input", str(SOURCE), "--output", str(generated),
            ], check=True, capture_output=True, text=True)
            self.assertEqual(PACKAGE.read_text(encoding="utf-8"), generated.read_text(encoding="utf-8"))

    def test_complete_coverage_range_recovered_verses_and_stable_ids(self):
        self.assertEqual(231, len(self.passages))
        self.assertEqual(234, sum(item["verse_end"] - item["verse_start"] + 1 for item in self.passages))
        self.assertEqual("passage.vraja-riti-cintamani.vrc.1.1", self.passages[0]["id"])
        self.assertEqual("passage.vraja-riti-cintamani.vrc.3.60", self.passages[-1]["id"])
        self.assertEqual(1, sum(item["id"].endswith("vrc.2.7-10") for item in self.passages))
        ids = {item["id"] for item in self.passages}
        for verse in (40, 46, 53, 59, 66, 71, 73):
            self.assertIn(f"passage.vraja-riti-cintamani.vrc.1.{verse}", ids)

    def test_three_notes_are_attached_and_reader_is_english_only(self):
        notes = {item["locus"]: item for item in self.passages if item.get("translation_note")}
        self.assertEqual({"1.2", "1.87", "3.8"}, set(notes))
        self.assertEqual("collapsed", notes["1.87"]["note_presentation"])
        self.assertEqual("alternative", notes["3.8"]["note_presentation"])
        self.assertTrue(all(item.get("translation") for item in self.passages))
        self.assertTrue(all("original_text" not in item and "transliteration" not in item for item in self.passages))
        self.assertIn("completed in this, the last verse", self.passages[-1]["translation"])

    def test_metadata_and_rights_warning_are_honest(self):
        self.assertEqual("Vraja-rīti-cintāmaṇi", self.package["work"]["title"])
        self.assertEqual("The Cintāmaṇi Jewel of Vraja", self.package["provenance"]["english_subtitle"])
        self.assertEqual("Translator not identified in supplied file", self.package["edition"]["translation_provenance"]["translator"])
        self.assertFalse(self.package["provenance"]["public_distribution_authorized"])
        self.assertFalse((PACKAGE.parent / SOURCE.name).exists())

    def test_compiled_database_search_and_integrity(self):
        with sqlite3.connect(DATABASE) as db:
            self.assertEqual(231, db.execute(
                "SELECT count(*) FROM source_passages WHERE work_id = ?", (WORK_ID,)
            ).fetchone()[0])
            self.assertEqual(0, db.execute(
                "SELECT count(*) FROM passage_representations r JOIN source_passages p ON p.id=r.passage_id "
                "WHERE p.work_id=? AND (r.original_text IS NOT NULL OR r.transliteration IS NOT NULL)", (WORK_ID,)
            ).fetchone()[0])
            for query in ("Radha-kunda", "Rādhā-kuṇḍa", "Vrndavana", "Vṛndāvana", "Braj", "Nandīśvara", "kaleidoscope"):
                self.assertIsNotNone(db.execute(
                    "SELECT target_id FROM search_documents_fts WHERE search_documents_fts MATCH ? "
                    "AND target_id LIKE 'passage.vraja-riti-cintamani.%' LIMIT 1", (f'"{query}"',)
                ).fetchone(), query)
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())


if __name__ == "__main__":
    unittest.main()
