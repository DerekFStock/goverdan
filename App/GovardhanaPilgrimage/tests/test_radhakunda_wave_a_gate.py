"""Focused Task 021A.2 release-gate checks; the gate is never runtime input."""

from collections import Counter
from pathlib import Path
import re
import sqlite3
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "content/research/radhakunda-location-inventory.yaml"
GATE = ROOT / "content/research/radhakunda-wave-a-release-gate.yaml"
SPEC = ROOT / "docs/RADHAKUNDA_SHARED_MAP_SPEC.md"
REVIEW = ROOT / "docs/RADHAKUNDA_WAVE_A_RELEASE_GATE.md"
REGISTRY = ROOT / "content/pilgrimage/places.yaml"
SQLITE = ROOT / "build/radhakunda-content.sqlite"

EXPECTED_REUSE = {
    "RK-01": "place.radhakunda",
    "RK-02": "place.syamakunda",
    "RK-04": "place.lalitakunda",
    "RK-INST-01": "place.radha-kunjabihari-gaudiya-matha",
}
POTENTIAL_FIRST_COHORT = {"RK-17", "RK-27", "RK-29", "RK-SAM-01"}
ALLOWED_STATUSES = {
    "REUSE_EXISTING_NO_NEW_ID", "ELIGIBLE_AFTER_COORDINATE_CONTROL",
    "ELIGIBLE_AS_AREA_NOT_ARRIVAL", "HOLD_IDENTITY_RECONCILIATION",
    "HOLD_COMPOUND_RECONCILIATION", "HOLD_ACCESS_VERIFICATION", "NOT_ELIGIBLE",
}
REQUIRED_FIELDS = {
    "research_id", "place_id", "canonical_name", "current_physical_mapping_status",
    "decision_status", "approved_marker_semantics", "identity_disposition",
    "coordinate_geometry_disposition", "arrival_anchor_disposition", "evidence_summary",
    "source_layers", "confidence", "relationships", "blockers", "required_verification",
    "recommended_next_action", "later_production_ingestion_authorized", "editorial_rationale",
}


def table_ids(path: Path) -> list[str]:
    """Read the explicit cohort/review tables, not incidental RK mentions in prose."""
    return re.findall(r"^\| (RK-(?:\d\d|SAM-01|INST-01)) \|", path.read_text(encoding="utf-8"), re.M)


class RadhakundaWaveAGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = yaml.safe_load(INVENTORY.read_text(encoding="utf-8"))
        cls.gate = yaml.safe_load(GATE.read_text(encoding="utf-8"))
        cls.registry = yaml.safe_load(REGISTRY.read_text(encoding="utf-8"))
        cls.records = cls.inventory["locations"] + cls.inventory["ghats"]
        cls.wave_a = [item for item in cls.records if item["implementation_wave"] == "A"]
        cls.decisions = cls.gate["decisions"]
        cls.by_id = {item["research_id"]: item for item in cls.decisions}

    def test_inventory_spec_review_and_gate_have_same_twelve(self):
        inventory_ids = [item["research_id"] for item in self.wave_a]
        decision_ids = [item["research_id"] for item in self.decisions]
        self.assertEqual(12, len(inventory_ids))
        self.assertEqual(12, len(table_ids(SPEC)))
        self.assertEqual(12, len(table_ids(REVIEW)))
        self.assertEqual(Counter(inventory_ids), Counter(decision_ids))
        self.assertEqual(Counter(inventory_ids), Counter(table_ids(SPEC)))
        self.assertEqual(Counter(inventory_ids), Counter(table_ids(REVIEW)))
        self.assertIn("RK-05", inventory_ids)

    def test_every_identity_has_one_complete_controlled_decision(self):
        self.assertEqual(12, len(self.by_id))
        self.assertEqual(set(ALLOWED_STATUSES), set(self.gate["gate"]["decision_statuses"]))
        for item in self.decisions:
            with self.subTest(research_id=item["research_id"]):
                self.assertFalse(REQUIRED_FIELDS - item.keys())
                self.assertIn(item["decision_status"], ALLOWED_STATUSES)
                self.assertEqual(item["canonical_name"], next(
                    record["canonical_name"] for record in self.wave_a
                    if record["research_id"] == item["research_id"]
                ))
                self.assertEqual(item["current_physical_mapping_status"], next(
                    record["physical_mapping_status"] for record in self.wave_a
                    if record["research_id"] == item["research_id"]
                ))
                self.assertTrue(item["source_layers"])
                self.assertTrue(item["evidence_summary"])
                self.assertTrue(item["editorial_rationale"])
                self.assertTrue(item["required_verification"])
                location = item["coordinate_geometry_disposition"]
                self.assertTrue({"feature", "source", "source_reference", "source_retrieved_on", "control", "navigation_use"} <= location.keys())
                self.assertTrue(location["source"])
                self.assertFalse(item["later_production_ingestion_authorized"])

    def test_existing_ids_reused_and_proposed_ids_stay_distinct(self):
        registry_ids = {place["id"] for place in self.registry["places"]}
        proposed = []
        for item in self.decisions:
            research_id, place_id = item["research_id"], item["place_id"]
            if research_id in EXPECTED_REUSE:
                self.assertEqual(EXPECTED_REUSE[research_id], place_id)
                self.assertIn(place_id, registry_ids)
                self.assertEqual("REUSE_EXISTING_NO_NEW_ID", item["decision_status"])
            else:
                proposed.append(place_id)
                self.assertNotIn(place_id, registry_ids)
            inventory_record = next(record for record in self.wave_a if record["research_id"] == research_id)
            self.assertEqual(place_id, inventory_record.get("existing_place_id") or inventory_record["proposed_place_id"])
        self.assertEqual(len(proposed), len(set(proposed)))

    def test_mohana_is_area_not_arrival(self):
        item = self.by_id["RK-05"]
        self.assertEqual("ELIGIBLE_AS_AREA_NOT_ARRIVAL", item["decision_status"])
        self.assertEqual("WATER_BODY_AREA_ONLY_NO_ARRIVAL", item["approved_marker_semantics"])
        self.assertIn("NOT_AUTHORIZED", item["arrival_anchor_disposition"])
        self.assertIn("430061166", item["coordinate_geometry_disposition"]["source_reference"])
        self.assertNotIn("ARRIVAL", item["coordinate_geometry_disposition"]["navigation_use"])

    def test_memorial_and_compound_reconciliation_stay_open(self):
        self.assertNotEqual(self.by_id["RK-17"]["place_id"], self.by_id["RK-SAM-01"]["place_id"])
        self.assertIn("RK-SAM-01", [relation.get("research_id") for relation in self.by_id["RK-17"]["relationships"]])
        self.assertIn("RK-17", [relation.get("research_id") for relation in self.by_id["RK-SAM-01"]["relationships"]])
        self.assertEqual("HOLD_IDENTITY_RECONCILIATION", self.by_id["RK-16"]["decision_status"])
        self.assertIn("GFGR+6QP", " ".join(self.by_id["RK-16"]["blockers"]))
        self.assertIn("RK-KUT-01", [relation.get("research_id") for relation in self.by_id["RK-16"]["relationships"]])
        self.assertEqual("HOLD_COMPOUND_RECONCILIATION", self.by_id["RK-21"]["decision_status"])
        self.assertIn("RK-GH-14", [relation.get("research_id") for relation in self.by_id["RK-21"]["relationships"]])
        ghat = next(record for record in self.inventory["ghats"] if record["research_id"] == "RK-GH-14")
        self.assertEqual("RK-21", ghat["parent_research_id"])
        self.assertEqual("CHILD_FEATURE_DO_NOT_DUPLICATE", ghat["physical_mapping_status"])

    def test_potential_first_cohort_is_conditional_and_not_released(self):
        for research_id in POTENTIAL_FIRST_COHORT:
            item = self.by_id[research_id]
            with self.subTest(research_id=research_id):
                expected = "HOLD_IDENTITY_RECONCILIATION" if research_id in {"RK-17", "RK-SAM-01"} else "HOLD_ACCESS_VERIFICATION"
                self.assertEqual(expected, item["decision_status"])
                self.assertEqual("NO_PUBLIC_MARKER", item["approved_marker_semantics"])
                self.assertTrue(item["blockers"])
                self.assertIn("FIELD_UNVERIFIED", item["coordinate_geometry_disposition"]["control"])
                self.assertFalse(item["later_production_ingestion_authorized"])
        self.assertEqual("HOLD_ACCESS_VERIFICATION", self.by_id["RK-20"]["decision_status"])
        self.assertTrue(self.by_id["RK-20"]["blockers"])
        self.assertFalse(any(item["decision_status"] == "ELIGIBLE_AFTER_COORDINATE_CONTROL" for item in self.decisions))

    def test_no_other_inventory_wave_or_production_ingestion_authorized(self):
        self.assertFalse(self.gate["gate"]["new_production_ingestion_authorized"])
        self.assertFalse(self.gate["gate"]["runtime_compilation"])
        self.assertEqual("none", self.gate["gate"]["public_numbering"])
        self.assertTrue(all(item["research_id"] in {record["research_id"] for record in self.wave_a}
                            for item in self.decisions))
        for item in self.decisions:
            if item["decision_status"].startswith("ELIGIBLE"):
                self.assertFalse(item["blockers"])
                self.assertNotEqual("NO_PUBLIC_MARKER", item["approved_marker_semantics"])
                self.assertTrue(item["evidence_summary"] and item["source_layers"])

    def test_runtime_registry_and_sqlite_remain_unchanged_seventy_one(self):
        registry_places = self.registry["places"]
        self.assertEqual(71, len(registry_places))
        self.assertEqual(list(range(1, 72)), sorted(place["map_number"] for place in registry_places))
        registry_ids = {place["id"] for place in registry_places}
        connection = sqlite3.connect(SQLITE)
        try:
            runtime = connection.execute("SELECT id, map_number FROM pilgrimage_places").fetchall()
            self.assertEqual(71, len(runtime))
            self.assertEqual(registry_ids, {place_id for place_id, _ in runtime})
            self.assertEqual(list(range(1, 72)), sorted(number for _, number in runtime))
            self.assertFalse(any(place_id.startswith("place.rk.") for place_id, _ in runtime))
            self.assertEqual("ok", connection.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], connection.execute("PRAGMA foreign_key_check").fetchall())
        finally:
            connection.close()

    def test_research_gate_is_not_a_manifest_or_public_map_input(self):
        manifests = list((ROOT / "content/manifests").glob("*"))
        for path in manifests:
            if path.is_file():
                self.assertNotIn(GATE.name, path.read_text(encoding="utf-8"), str(path))
        self.assertNotIn("map_number:", GATE.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
