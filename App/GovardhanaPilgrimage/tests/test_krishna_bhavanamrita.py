"""Focused import, compilation, and offline-reader tests for Kṛṣṇa-bhāvanāmṛta."""

from pathlib import Path
import json
import sqlite3
import subprocess
import tempfile
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path("/Users/derekstock/Documents/Goverdhan/books/Krishna Bhavanamrta.doc")
PACKAGE = ROOT / "content/sources/krishna-bhavanamrita/package.yaml"
DATABASE = ROOT / "build/radhakunda-content.sqlite"
WORK_ID = "work.krishna-bhavanamrita"


class KrishnaBhavanamritaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.package = yaml.safe_load(PACKAGE.read_text(encoding="utf-8"))
        cls.passages = cls.package["passages"]

    def test_importer_reproduces_committed_package_from_windows_1252_witness(self):
        self.assertTrue(SOURCE.exists())
        self.assertIn(b"\x92", SOURCE.read_bytes())
        with tempfile.TemporaryDirectory() as directory:
            generated = Path(directory) / "package.yaml"
            subprocess.run([
                "python3", str(ROOT / "tools/import_krishna_bhavanamrita.py"),
                "--input", str(SOURCE), "--output", str(generated),
            ], check=True, capture_output=True, text=True)
            self.assertEqual(PACKAGE.read_text(encoding="utf-8"), generated.read_text(encoding="utf-8"))
        self.assertTrue(any("each other’s" in item["translation"] for item in self.passages))

    def test_complete_chapter_manifest_and_stable_reader_anchors(self):
        chapter_passages = [item for item in self.passages if item.get("section_kind") == "CHAPTER"]
        self.assertEqual(712, len(chapter_passages))
        self.assertEqual(list(range(1, 21)), sorted({item["chapter_number"] for item in chapter_passages}))
        for chapter in range(1, 21):
            items = [item for item in chapter_passages if item["chapter_number"] == chapter]
            self.assertTrue(all(item["chapter_title"] and item["time_range"] for item in items))
            self.assertEqual(list(range(1, len(items) + 1)), [int(item["id"].rsplit("p", 1)[1]) for item in items])
        self.assertEqual("passage.krishna-bhavanamrita.kba.ch01.p001", chapter_passages[0]["id"])
        self.assertEqual("passage.krishna-bhavanamrita.kba.ch20.p020", chapter_passages[-1]["id"])

    def test_english_only_front_matter_colophon_and_cast_are_separate(self):
        ids = [item["id"] for item in self.passages]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(4, sum(item.get("section_kind") == "FRONT_MATTER" for item in self.passages))
        self.assertEqual(2, sum(item.get("section_kind") == "INVOCATION" for item in self.passages))
        self.assertEqual(1, sum(item.get("section_kind") == "COLOPHON" for item in self.passages))
        self.assertEqual(65, sum(item.get("section_kind") == "APPENDIX" for item in self.passages))
        all_text = "\n".join(item["translation"] for item in self.passages)
        self.assertNotIn("sri krishna caitanya ghanam prapadye", all_text)
        self.assertNotIn("vikriditam vraja vadhubhir", all_text)
        self.assertIn("I take shelter of the Sri Krishna Caitanya cloud", all_text)
        chapter_twenty = [item for item in self.passages if item.get("chapter_number") == 20]
        self.assertFalse(any(item.get("section_kind") == "APPENDIX" for item in chapter_twenty))

    def test_metadata_is_honest_and_source_is_private(self):
        self.assertEqual(WORK_ID, self.package["work"]["id"])
        self.assertEqual("Kṛṣṇa-bhāvanāmṛta-mahākāvya", self.package["work"]["title"])
        self.assertEqual("Śrī Viśvanātha Cakravartī Ṭhākura", self.package["work"]["author"])
        provenance = self.package["edition"]["translation_provenance"]
        self.assertEqual("Translator not identified in supplied file", provenance["translator"])
        self.assertEqual("PUBLICATION_RIGHTS_UNCONFIRMED", provenance["status"])
        self.assertFalse(self.package["provenance"]["public_distribution_authorized"])
        self.assertFalse((ROOT / "content/sources/krishna-bhavanamrita/Krishna Bhavanamrta.doc").exists())

    def test_compiled_database_is_offline_searchable_and_exactly_addressable(self):
        with sqlite3.connect(DATABASE) as db:
            count = db.execute("SELECT count(*) FROM source_passages WHERE work_id = ?", (WORK_ID,)).fetchone()[0]
            self.assertEqual(784, count)
            for query in ("Radha", "Rādhā", "Krishna", "Kṛṣṇa", "kunja", "kuñja", "sakhi", "sakhī", "Visvanatha", "Viśvanātha"):
                result = db.execute(
                    "SELECT target_id FROM search_documents_fts WHERE search_documents_fts MATCH ? AND content_type='source_passage' LIMIT 1",
                    (f'"{query}"',),
                ).fetchone()
                self.assertIsNotNone(result, query)
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())
            target = db.execute(
                "SELECT display_locus FROM source_passages WHERE id = ?",
                ("passage.krishna-bhavanamrita.kba.ch09.p001",),
            ).fetchone()
            self.assertEqual(("Chapter 9, passage 1",), target)

    def test_manifest_contains_one_generic_package_entry(self):
        manifest = yaml.safe_load((ROOT / "content/manifests/radhakunda-mvp-development-manifest.yaml").read_text(encoding="utf-8"))
        entries = [item for item in manifest["compile_sequence"] if item.get("work_id") == WORK_ID]
        self.assertEqual(1, len(entries))
        self.assertEqual("SOURCE_PACKAGE", entries[0]["role"])
        self.assertEqual("content/sources/krishna-bhavanamrita/package.yaml", entries[0]["target_path"])
        compiled = json.loads((ROOT / "build/radhakunda-mvp-development-content.json").read_text(encoding="utf-8"))
        self.assertIn(WORK_ID, {item["id"] for item in compiled["works"]})


if __name__ == "__main__":
    unittest.main()
