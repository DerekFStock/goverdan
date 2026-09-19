"""Task 021A.8 research-only evidence and production-isolation contract."""

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

EVIDENCE_PATH = ROOT / "content/research/radhakunda-wave-b-cohort-1-evidence.yaml"
GEOMETRY_PATH = ROOT / "content/research/radhakunda-wave-b-cohort-1-evidence.geojson"
MANIFEST_PATH = ROOT / "content/manifests/radhakunda-mvp-development-manifest.yaml"
DATABASE_PATH = ROOT / "build/radhakunda-content.sqlite"
IDS = {"RK-03", "RK-15", "RK-22", "RK-GH-09"}
DECISIONS = {
    "CONTROLLED_FEATURE_READY", "CONTROLLED_ENTRANCE_READY", "CONTROLLED_DISPLAY_ONLY",
    "HOLD_ACCESS_VERIFICATION", "HOLD_IDENTITY_RECONCILIATION",
    "HOLD_PARENT_CHILD_RECONCILIATION", "FIELD_VERIFICATION_REQUIRED",
    "INSUFFICIENT_EVIDENCE",
}
SEMANTICS = {
    "PHYSICAL_FEATURE_POINT", "PUBLIC_ENTRANCE_CANDIDATE", "COMPOUND_BOUNDARY",
    "CROSSING_LINE", "GHAT_EDGE", "RESEARCH_LEAD_ONLY",
}
BASELINE_HASHES = {
    "content/pilgrimage/places.yaml": "055440f6a6e8770e93b6d7e0a2c7753ee1a7b18c9e6e77cb5ddee72ef3c8a392",
    "content/pilgrimage/place-content.yaml": "a943d6807d918b938fe02243403e4efe0102edae58fe81fcebf3e158148a0afb",
    "content/pilgrimage/place-geometries.geojson": "d60e8b169c41ff029ac4191f65e378ecf2b9573acc1599921482500c49088814",
    "content/manifests/radhakunda-mvp-development-manifest.yaml": "0502618343fb5ef93df59c7ee7193c8a1673ccaad9eb1dd1a512b0039b5c62d5",
    "content/manifests/SHA256SUMS.json": "cb8add1e461302ab5e9f5a1a43dd07ef14701412c2af3d1aee2c47d8b8843cf9",
    "build/radhakunda-content.sqlite": "bc75449e44cf33037180c316b5b7722e10b9c8372bd899da54a91e0e753bc4f3",
    "build/build-report.json": "c802b1c0303508c85072657cc3d76e4ec08f9bb49116838781f7d145d5b21ff4",
}


class WaveBCohortEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.evidence = yaml.safe_load(EVIDENCE_PATH.read_text(encoding="utf-8"))
        cls.geometry = json.loads(GEOMETRY_PATH.read_text(encoding="utf-8"))

    def test_exact_cohort_independent_decisions_and_separated_claims(self):
        records = self.evidence["records"]
        ids = [item["research_id"] for item in records]
        self.assertEqual(4, len(ids))
        self.assertEqual(IDS, set(ids))
        self.assertEqual(4, len(set(ids)))
        self.assertEqual(IDS, set(self.evidence["selected_research_ids"]))
        self.assertEqual("RESEARCH_ONLY_NOT_RUNTIME_INPUT", self.evidence["scope"])
        self.assertFalse(self.evidence["production_ingestion_authorized"])
        for item in records:
            with self.subTest(item=item["research_id"]):
                self.assertIn(item["decision"], DECISIONS)
                self.assertTrue(item["recommended_representation"])
                self.assertEqual("NOT_ELIGIBLE", item["navigation_recommendation"])
                self.assertTrue(item["relationships"])
                self.assertTrue(item["required_field_observations"])
                self.assertTrue(item["production_acceptance_conditions"])
                self.assertTrue(item["geometry_negative_finding"])
                self.assertEqual({
                    "present_physical_identity", "present_access", "historical_identification",
                    "textual_or_lila_significance", "devotional_practice",
                }, set(item["claims"]))
                self.assertTrue(all(item["claims"].values()))

    def test_every_source_has_auditable_claim_and_limitations(self):
        sources = self.evidence["source_catalog"]
        by_id = {item["id"]: item for item in sources}
        self.assertEqual(len(sources), len(by_id))
        for source in sources:
            with self.subTest(source=source["id"]):
                for key in ("title", "provider", "reference", "retrieved_on", "claim",
                            "feature_id_or_revision", "license_attribution", "limitations"):
                    self.assertTrue(source[key])
                self.assertIn("published_or_revised_on", source)
        for item in self.evidence["records"]:
            self.assertTrue(item["source_ids"])
            self.assertTrue(set(item["source_ids"]) <= set(by_id))

    def test_geometry_semantics_and_missing_geometry_are_explicit(self):
        geometry = self.geometry
        self.assertEqual("FeatureCollection", geometry["type"])
        self.assertEqual("RESEARCH_ONLY_NOT_RUNTIME_INPUT", geometry["scope"])
        self.assertFalse(geometry["navigation_eligible"])
        self.assertEqual(IDS, set(geometry["negative_findings"]))
        self.assertTrue(all(geometry["negative_findings"].values()))
        self.assertEqual([], geometry["features"])
        for feature in geometry["features"]:
            props = feature["properties"]
            self.assertIn(props["research_id"], IDS)
            self.assertIn(props["coordinate_semantics"], SEMANTICS)
            for key in ("source", "source_feature_id", "revision", "retrieved_on", "confidence", "represents"):
                self.assertTrue(props[key])
            self.assertFalse(props["navigation_eligible"])
            self.assertNotEqual("polygon centroid", props["coordinate_semantics"])
            self.assertNotEqual("plus code", props["source"])
        # No silent promotion of approximate codes, lake edges, or inferred points.
        self.assertNotIn("plus_code:", EVIDENCE_PATH.read_text(encoding="utf-8"))
        self.assertNotIn('"coordinates"', GEOMETRY_PATH.read_text(encoding="utf-8"))

    def test_production_files_manifest_and_database_remain_unchanged(self):
        for relative_path, expected_digest in BASELINE_HASHES.items():
            with self.subTest(path=relative_path):
                self.assertEqual(expected_digest, hashlib.sha256((ROOT / relative_path).read_bytes()).hexdigest())
        manifest = yaml.safe_load(MANIFEST_PATH.read_text(encoding="utf-8"))
        runtime_paths = {entry["target_path"] for entry in manifest["compile_sequence"]}
        self.assertNotIn(str(EVIDENCE_PATH.relative_to(ROOT)), runtime_paths)
        self.assertNotIn(str(GEOMETRY_PATH.relative_to(ROOT)), runtime_paths)
        compiled = compile_manifest(ROOT, "radhakunda-mvp-development-manifest")
        self.assertEqual(72, len(compiled.content["pilgrimage_places"]))
        self.assertEqual(4, len(compiled.content["pilgrimage_place_geometries"]))
        with sqlite3.connect(DATABASE_PATH) as db:
            self.assertEqual(72, db.execute("SELECT count(*) FROM pilgrimage_places").fetchone()[0])
            self.assertEqual(71, db.execute("SELECT count(*) FROM pilgrimage_places WHERE map_number IS NOT NULL").fetchone()[0])
            self.assertEqual(4, db.execute("SELECT count(*) FROM pilgrimage_place_geometries").fetchone()[0])
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())


if __name__ == "__main__":
    unittest.main()
