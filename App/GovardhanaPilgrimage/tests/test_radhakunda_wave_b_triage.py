"""Task 021A.7 research-only Wave B triage contract."""

from collections import Counter
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from content_tooling import compile_manifest  # noqa: E402

INVENTORY = ROOT / "content/research/radhakunda-location-inventory.yaml"
TRIAGE = ROOT / "content/research/radhakunda-wave-b-triage.yaml"
MANIFEST = ROOT / "content/manifests/radhakunda-mvp-development-manifest.yaml"
DATABASE = ROOT / "build/radhakunda-content.sqlite"
STATUSES = {
    "NEXT_COHORT_CANDIDATE", "CONTROLLED_SOURCE_DISCOVERY_NEEDED", "FIELD_VERIFICATION_REQUIRED",
    "IDENTITY_RECONCILIATION_REQUIRED", "PARENT_CHILD_RECONCILIATION_REQUIRED",
    "TEXTUAL_ONLY_NO_PHYSICAL_PIN", "DUPLICATE_OR_EXISTING_PLACE_CANDIDATE", "DEFER_LOW_CONFIDENCE",
}
REPRESENTATIONS = {
    "POINT", "WATER_BODY_POLYGON", "COMPOUND_POLYGON", "GHAT_EDGE_OR_SEGMENT",
    "APPROXIMATE_AREA", "RELATIONSHIP_ONLY", "NO_MAP_FEATURE",
}
NAVIGATION = {"POTENTIALLY_NAVIGABLE", "DISPLAY_ONLY", "FIELD_VERIFICATION_REQUIRED", "NON_PHYSICAL"}
BASELINE_HASHES = {
    "content/pilgrimage/places.yaml": "055440f6a6e8770e93b6d7e0a2c7753ee1a7b18c9e6e77cb5ddee72ef3c8a392",
    "content/pilgrimage/place-content.yaml": "a943d6807d918b938fe02243403e4efe0102edae58fe81fcebf3e158148a0afb",
    "content/pilgrimage/place-geometries.geojson": "d60e8b169c41ff029ac4191f65e378ecf2b9573acc1599921482500c49088814",
    "content/manifests/radhakunda-mvp-development-manifest.yaml": "0502618343fb5ef93df59c7ee7193c8a1673ccaad9eb1dd1a512b0039b5c62d5",
    "content/manifests/SHA256SUMS.json": "cb8add1e461302ab5e9f5a1a43dd07ef14701412c2af3d1aee2c47d8b8843cf9",
    "build/radhakunda-content.sqlite": "bc75449e44cf33037180c316b5b7722e10b9c8372bd899da54a91e0e753bc4f3",
    "build/build-report.json": "c802b1c0303508c85072657cc3d76e4ec08f9bb49116838781f7d145d5b21ff4",
}


class WaveBTriageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = yaml.safe_load(INVENTORY.read_text(encoding="utf-8"))
        cls.triage = yaml.safe_load(TRIAGE.read_text(encoding="utf-8"))
        cls.records = cls.triage["records"]
        cls.inventory_records = cls.inventory["locations"] + cls.inventory["ghats"]

    def test_every_wave_b_record_appears_once_and_no_other_wave_is_reclassified(self):
        wave_b = {item["research_id"] for item in self.inventory_records if item["implementation_wave"] == "B"}
        wave_a = {item["research_id"] for item in self.inventory_records if item["implementation_wave"] == "A"}
        wave_c = {item["research_id"] for item in self.inventory_records if item["implementation_wave"] == "C"}
        ids = [item["research_id"] for item in self.records]
        self.assertEqual(53, len(wave_b))
        self.assertEqual(53, len(ids))
        self.assertEqual(53, len(set(ids)))
        self.assertEqual(wave_b, set(ids))
        self.assertFalse(set(ids) & wave_a)
        self.assertFalse(set(ids) & wave_c)
        self.assertFalse({"RK-17", "RK-27", "RK-29", "RK-SAM-01"} & set(ids))
        self.assertEqual("RESEARCH_ONLY_NOT_RUNTIME_INPUT", self.triage["scope"])
        self.assertFalse(self.triage["production_ingestion_authorized"])

    def test_classifications_are_complete_and_cohort_is_small_and_explicit(self):
        inventory_by_id = {item["research_id"]: item for item in self.inventory_records}
        selected = self.triage["selected_next_cohort"]
        self.assertEqual(4, len(selected))
        self.assertLessEqual(len(selected), 8)
        self.assertEqual(len(selected), len(set(selected)))
        self.assertEqual(set(selected), {item["research_id"] for item in self.records if item["status"] == "NEXT_COHORT_CANDIDATE"})
        for item in self.records:
            with self.subTest(research_id=item["research_id"]):
                self.assertEqual("B", inventory_by_id[item["research_id"]]["implementation_wave"])
                self.assertIn(item["status"], STATUSES)
                self.assertIn(item["representation"], REPRESENTATIONS)
                self.assertIn(item["navigation"], NAVIGATION)
                self.assertIn(item["confidence"], {"HIGH", "MEDIUM", "LOW"})
                self.assertIn(item["pilgrim_value"], {"HIGH", "MEDIUM", "LOW"})
                self.assertIn(item["physical_identifiability"], {"PRESENT_FEATURE_LEAD", "UNRESOLVED", "RELATIONSHIP_ONLY"})
                self.assertIn(item["location_evidence"], {"TEXT_AND_TRADITION_ONLY", "PILGRIMAGE_TRADITION_ONLY", "APPROXIMATE_LISTING_ONLY"})
                self.assertTrue(item["note"])
                if item["research_id"] in selected:
                    self.assertTrue(item["inclusion_reason"])
                    self.assertTrue(item["evidence_available"])
                    self.assertTrue(item["missing_evidence"])
                    self.assertTrue(item["acceptance_conditions"])
                    self.assertTrue(item["fieldwork_expected"])
                    self.assertEqual("FIELD_VERIFICATION_REQUIRED", item["navigation"])
                else:
                    self.assertNotIn("inclusion_reason", item)
                if item["location_evidence"] == "APPROXIMATE_LISTING_ONLY":
                    self.assertNotEqual("POTENTIALLY_NAVIGABLE", item["navigation"])
                    self.assertNotEqual("NEXT_COHORT_CANDIDATE", item["status"])
                if item["representation"] in {"RELATIONSHIP_ONLY", "NO_MAP_FEATURE"}:
                    self.assertNotEqual("POTENTIALLY_NAVIGABLE", item["navigation"])
        self.assertEqual(Counter({
            "CONTROLLED_SOURCE_DISCOVERY_NEEDED": 16,
            "PARENT_CHILD_RECONCILIATION_REQUIRED": 14,
            "DEFER_LOW_CONFIDENCE": 8,
            "IDENTITY_RECONCILIATION_REQUIRED": 5,
            "NEXT_COHORT_CANDIDATE": 4,
            "FIELD_VERIFICATION_REQUIRED": 3,
            "DUPLICATE_OR_EXISTING_PLACE_CANDIDATE": 2,
            "TEXTUAL_ONLY_NO_PHYSICAL_PIN": 1,
        }), Counter(item["status"] for item in self.records))

    def test_no_invented_coordinates_or_approximate_arrival(self):
        forbidden_keys = {"latitude", "longitude", "coordinates", "coordinate", "arrival_point", "navigation_point", "plus_code", "map_number"}

        def walk(value):
            if isinstance(value, dict):
                for key, child in value.items():
                    self.assertNotIn(key, forbidden_keys)
                    walk(child)
            elif isinstance(value, list):
                for child in value:
                    walk(child)

        walk(self.triage)
        by_id = {item["research_id"]: item for item in self.records}
        for research_id in ("RK-18", "RK-KUT-01"):
            self.assertEqual("APPROXIMATE_LISTING_ONLY", by_id[research_id]["location_evidence"])
            self.assertEqual("FIELD_VERIFICATION_REQUIRED", by_id[research_id]["navigation"])
        self.assertEqual("DUPLICATE_OR_EXISTING_PLACE_CANDIDATE", by_id["RK-09"]["status"])
        self.assertEqual("RELATIONSHIP_ONLY", by_id["RK-GH-07"]["representation"])

    def test_production_files_manifest_compilation_and_database_are_unchanged(self):
        for relative_path, expected_digest in BASELINE_HASHES.items():
            with self.subTest(path=relative_path):
                self.assertEqual(expected_digest, hashlib.sha256((ROOT / relative_path).read_bytes()).hexdigest())
        manifest = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))
        runtime_paths = {entry["target_path"] for entry in manifest["compile_sequence"]}
        self.assertNotIn(str(TRIAGE.relative_to(ROOT)), runtime_paths)
        compiled = compile_manifest(ROOT, "radhakunda-mvp-development-manifest")
        self.assertEqual(72, len(compiled.content["pilgrimage_places"]))
        self.assertEqual(4, len(compiled.content["pilgrimage_place_geometries"]))
        with sqlite3.connect(DATABASE) as db:
            self.assertEqual(72, db.execute("SELECT count(*) FROM pilgrimage_places").fetchone()[0])
            self.assertEqual(71, db.execute("SELECT count(*) FROM pilgrimage_places WHERE map_number IS NOT NULL").fetchone()[0])
            self.assertEqual(4, db.execute("SELECT count(*) FROM pilgrimage_place_geometries").fetchone()[0])
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())


if __name__ == "__main__":
    unittest.main()
