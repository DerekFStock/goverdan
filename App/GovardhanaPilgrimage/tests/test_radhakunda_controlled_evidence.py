"""Task 021A.3 research-only evidence and runtime-separation checks."""

from pathlib import Path
import json
import sqlite3
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "content/research/radhakunda-wave-a-controlled-evidence.yaml"
GEOJSON = ROOT / "content/research/radhakunda-wave-a-controlled-evidence.geojson"
GATE = ROOT / "content/research/radhakunda-wave-a-release-gate.yaml"
REGISTRY = ROOT / "content/pilgrimage/places.yaml"
SQLITE = ROOT / "build/radhakunda-content.sqlite"
IDS = {"RK-05", "RK-17", "RK-27", "RK-29", "RK-SAM-01"}
ELIGIBILITY = {
    "CONTROLLED_AREA_ONLY", "CONTROLLED_FEATURE_AND_APPROACH",
    "CONTROLLED_FEATURE_NO_APPROACH", "IDENTITY_CONFIRMED_LOCATION_UNCONTROLLED",
    "INSUFFICIENT_REMOTE_EVIDENCE", "FIELD_VERIFICATION_REQUIRED",
}
MEANINGS = {
    "FEATURE_POINT", "PUBLIC_ENTRANCE", "PRACTICAL_APPROACH",
    "AREA_CENTROID_NON_NAVIGABLE", "POLYGON_VERTEX", "UNCONTROLLED_LISTING_CENTER",
}


class ControlledEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.package = yaml.safe_load(EVIDENCE.read_text(encoding="utf-8"))
        cls.records = cls.package["records"]
        cls.by_id = {record["research_id"]: record for record in cls.records}
        cls.geojson = json.loads(GEOJSON.read_text(encoding="utf-8"))
        cls.gate = yaml.safe_load(GATE.read_text(encoding="utf-8"))

    def test_exact_scope_and_required_fields(self):
        self.assertEqual(5, len(self.records))
        self.assertEqual(IDS, set(self.by_id))
        self.assertFalse(self.package["production_ingestion_authorized"])
        required = {
            "research_id", "place_id", "canonical_name", "evidence_review_date",
            "acquisition_method", "physical_feature_type", "identity_evidence",
            "feature_location_evidence", "public_approach_evidence", "access_status",
            "sources", "coordinate_meaning", "precision_uncertainty",
            "relationship_checks", "conflicting_evidence", "negative_findings",
            "remaining_blockers", "eligibility_decision", "recommended_later_marker_semantics",
        }
        for record in self.records:
            with self.subTest(record=record["research_id"]):
                self.assertFalse(required - record.keys())
                self.assertIn(record["eligibility_decision"], ELIGIBILITY)
                self.assertTrue(record["remaining_blockers"])

    def test_every_source_has_stable_reference_and_retrieval_date(self):
        for record in self.records:
            self.assertTrue(record["sources"])
            for source in record["sources"]:
                with self.subTest(record=record["research_id"], source=source["source_id"]):
                    self.assertTrue(source["retrieved_on"])
                    self.assertTrue(source["stable_reference"])
                    self.assertTrue(source["version"])
                    self.assertTrue(source["supports"])
                    self.assertTrue(source["limitations"])
                    self.assertTrue(source["license"])
                    self.assertTrue(source["attribution"])

    def test_coordinates_and_geometry_are_typed_sourced_and_research_only(self):
        self.assertEqual("FeatureCollection", self.geojson["type"])
        self.assertEqual(["RK-05"], [feature["properties"]["research_id"] for feature in self.geojson["features"]])
        for record in self.records:
            for point in record.get("coordinates", []):
                self.assertIn(point["coordinate_meaning"], MEANINGS)
                self.assertTrue(point["source_id"])
            if record.get("coordinates") or record.get("geometry"):
                self.assertIn(record["coordinate_meaning"], MEANINGS)
            else:
                self.assertIsNone(record["coordinate_meaning"])
        for feature in self.geojson["features"]:
            props = feature["properties"]
            self.assertIn(props["geometry_meaning"], MEANINGS)
            self.assertTrue(props["source_id"])
            self.assertTrue(props["source_retrieved_on"])
            self.assertTrue(props["control_status"])
            self.assertFalse(props["navigation_authorized"])
            self.assertFalse(props["arrival_authorized"])
            self.assertIn(props["research_id"], IDS)

    def test_mohana_polygon_is_complete_and_never_arrival(self):
        record = self.by_id["RK-05"]
        feature = self.geojson["features"][0]
        ring = feature["geometry"]["coordinates"][0]
        self.assertEqual("CONTROLLED_AREA_ONLY", record["eligibility_decision"])
        self.assertEqual("POLYGON_VERTEX", record["geometry"]["coordinate_meaning"])
        self.assertEqual(81, len(ring))
        self.assertEqual(80, len(set(tuple(point) for point in ring)))
        self.assertEqual(ring[0], ring[-1])
        self.assertEqual(
            [77.4929354, 27.5234252, 77.4951433, 27.5271270],
            [min(p[0] for p in ring), min(p[1] for p in ring),
             max(p[0] for p in ring), max(p[1] for p in ring)],
        )
        self.assertFalse(record["geometry"]["navigation_authorized"])
        self.assertFalse(record["geometry"]["arrival_authorized"])
        self.assertEqual("OSM-WAY-430061166-V2", feature["properties"]["source_id"])

    def test_memorials_remain_separate_research_ids_and_hold(self):
        a, b = self.by_id["RK-17"], self.by_id["RK-SAM-01"]
        self.assertNotEqual(a["place_id"], b["place_id"])
        self.assertEqual("FIELD_VERIFICATION_REQUIRED", a["eligibility_decision"])
        self.assertEqual("FIELD_VERIFICATION_REQUIRED", b["eligibility_decision"])
        self.assertIn("RK-SAM-01", " ".join(a["relationship_checks"]))
        self.assertIn("RK-17", " ".join(b["relationship_checks"]))
        decisions = {item["research_id"]: item for item in self.gate["decisions"]}
        for research_id in ("RK-17", "RK-SAM-01"):
            item = decisions[research_id]
            self.assertEqual("HOLD_IDENTITY_RECONCILIATION", item["decision_status"])
            self.assertEqual("HOLD_ACCESS_VERIFICATION", item["decision_change"]["from"])
            self.assertTrue(item["decision_change"]["supporting_source_ids"])
            self.assertFalse(item["later_production_ingestion_authorized"])

    def test_temple_namesakes_and_plus_codes_do_not_release(self):
        rk27 = " ".join(self.by_id["RK-27"]["relationship_checks"])
        for term in ("RK-23", "RK-32", "Vṛndāvana", "ghāṭ"):
            self.assertIn(term, rk27)
        rk29 = " ".join(self.by_id["RK-29"]["relationship_checks"])
        for term in ("place.nipa-kunda-radha-govinda", "Vṛndāvana", "Govinda-kuṇḍa"):
            self.assertIn(term, rk29)
        for record in self.records:
            if "GFGR+" in str(record):
                self.assertNotEqual("CONTROLLED_FEATURE_AND_APPROACH", record["eligibility_decision"])
            if record["public_approach_evidence"] == "NONE_CONTROLLED" or "UNVERIFIED" in record["access_status"]:
                self.assertNotEqual("CONTROLLED_FEATURE_AND_APPROACH", record["eligibility_decision"])

    def test_runtime_has_only_the_separately_authorized_area(self):
        places = yaml.safe_load(REGISTRY.read_text(encoding="utf-8"))["places"]
        self.assertEqual(72, len(places))
        self.assertEqual(list(range(1, 72)), sorted(place["map_number"] for place in places if place["map_number"] is not None))
        self.assertEqual(["place.rk.mohana-kunda"], [place["id"] for place in places if place["id"].startswith("place.rk.")])
        for path in (ROOT / "content/manifests").glob("*"):
            if path.is_file():
                contents = path.read_text(encoding="utf-8")
                self.assertNotIn(EVIDENCE.name, contents)
                self.assertNotIn(GEOJSON.name, contents)
        with sqlite3.connect(SQLITE) as db:
            rows = db.execute("SELECT id, map_number FROM pilgrimage_places").fetchall()
            self.assertEqual(72, len(rows))
            self.assertEqual(list(range(1, 72)), sorted(number for _, number in rows if number is not None))
            self.assertEqual([("place.rk.mohana-kunda", None)], [(place_id, number) for place_id, number in rows if place_id.startswith("place.rk.")])
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())

    def test_no_wave_b_c_or_new_public_numbering(self):
        inventory = yaml.safe_load((ROOT / "content/research/radhakunda-location-inventory.yaml").read_text(encoding="utf-8"))
        by_id = {r["research_id"]: r for r in inventory["locations"] + inventory["ghats"]}
        self.assertTrue(all(by_id[research_id]["implementation_wave"] == "A" for research_id in IDS))
        self.assertEqual("none", self.package["public_numbering"])
        self.assertFalse(any(item["later_production_ingestion_authorized"] for item in self.gate["decisions"]))


if __name__ == "__main__":
    unittest.main()
