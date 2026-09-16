"""Focused Task 021A.1 research-inventory checks; no runtime compilation."""

from pathlib import Path
import re
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "content/research/radhakunda-location-inventory.yaml"
REGISTRY = ROOT / "content/pilgrimage/places.yaml"

STATUSES = {
    "EXISTING_RUNTIME_PLACE", "MAP_NOW_EXACT", "MAP_NOW_PRACTICAL_ARRIVAL",
    "MAP_NOW_AREA", "VERIFY_BEFORE_MAPPING", "TEXTUAL_ONLY_NO_PHYSICAL_PIN",
    "CHILD_FEATURE_DO_NOT_DUPLICATE", "DUPLICATE_CANDIDATE_RECONCILE",
}
CONTINUITIES = {
    "STRONG_CONTINUITY", "PROBABLE_CONTINUITY", "LIVING_TRADITION_ONLY",
    "TEXTUAL_GEOGRAPHY_ONLY", "PRESENT_SITE_ONLY", "DISPUTED_OR_MULTIPLE",
    "UNRESOLVED",
}


class RadhakundaInventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = yaml.safe_load(INVENTORY.read_text(encoding="utf-8"))
        cls.registry = yaml.safe_load(REGISTRY.read_text(encoding="utf-8"))
        cls.records = cls.inventory["locations"] + cls.inventory["ghats"]
        cls.by_id = {record["research_id"]: record for record in cls.records}

    def test_complete_original_dossier_and_separate_ghats(self):
        original = [item["research_id"] for item in self.inventory["locations"] if re.fullmatch(r"RK-\d\d", item["research_id"])]
        self.assertEqual([f"RK-{number:02d}" for number in range(1, 46)], original)
        self.assertEqual(21, len(self.inventory["ghats"]))
        self.assertEqual([f"RK-GH-{number:02d}" for number in range(1, 22)], [g["research_id"] for g in self.inventory["ghats"]])
        self.assertEqual("BOTH_RADHA_AND_SYAMA_KUNDA", self.by_id["RK-GH-07"]["bank_side"])

    def test_research_ids_statuses_and_map_numbers(self):
        self.assertEqual(len(self.records), len(self.by_id))
        registry_ids = {place["id"] for place in self.registry["places"]}
        required = {"research_id", "canonical_name", "ascii_name", "alternate_names", "place_type",
                    "map_collection", "physical_mapping_status", "local_display_code", "marker_semantics",
                    "evidence_layers", "source_notes", "continuity_status", "confidence", "map_priority",
                    "content_priority", "unresolved_questions"}
        for item in self.records:
            self.assertFalse(required - item.keys(), item["research_id"])
            self.assertTrue(item.get("existing_place_id") or item.get("proposed_place_id"), item["research_id"])
            self.assertIn(item["physical_mapping_status"], STATUSES, item["research_id"])
            self.assertIn(item["continuity_status"], CONTINUITIES, item["research_id"])
            self.assertIn(item["implementation_wave"], {"A", "B", "C"}, item["research_id"])
            self.assertNotIn("public_map_number", item, item["research_id"])
            self.assertTrue(item.get("source_notes"), item["research_id"])
            self.assertTrue(item.get("evidence_layers"), item["research_id"])
            if existing := item.get("existing_place_id"):
                self.assertIn(existing, registry_ids, item["research_id"])
            if item["physical_mapping_status"] == "TEXTUAL_ONLY_NO_PHYSICAL_PIN":
                self.assertIsNone(item.get("latitude"), item["research_id"])
                self.assertIsNone(item.get("longitude"), item["research_id"])
        self.assertEqual(71, len(self.registry["places"]))
        self.assertEqual(list(range(1, 72)), sorted(place["map_number"] for place in self.registry["places"]))

    def test_reconciliation_and_textual_geography(self):
        expected_existing = {
            "RK-01": "place.radhakunda",
            "RK-02": "place.syamakunda",
            "RK-04": "place.lalitakunda",
            "RK-09": "place.siva-khari",
            "RK-INST-01": "place.radha-kunjabihari-gaudiya-matha",
        }
        for research_id, place_id in expected_existing.items():
            self.assertEqual(place_id, self.by_id[research_id]["existing_place_id"])
        self.assertEqual("DUPLICATE_CANDIDATE_RECONCILE", self.by_id["RK-09"]["physical_mapping_status"])
        for research_id in ("RK-10", "RK-11"):
            self.assertEqual("TEXTUAL_ONLY_NO_PHYSICAL_PIN", self.by_id[research_id]["physical_mapping_status"])

    def test_early_pilgrimage_evidence_upgrades(self):
        for research_id, locus in {
            "RK-06": "5.585", "RK-08": "5.587", "RK-09": "5.587",
            "RK-13": "5.600", "RK-20": "5.602", "RK-GH-09": "5.599",
        }.items():
            self.assertTrue(any(locus in str(note["locus"]) for note in self.by_id[research_id]["source_notes"]), research_id)
        self.assertTrue(any("5.600" in str(note["locus"]) for note in self.by_id["RK-GH-10"]["source_notes"]))


if __name__ == "__main__":
    unittest.main()
