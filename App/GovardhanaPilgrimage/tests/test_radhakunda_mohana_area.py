"""Task 021A.4 area-only production contract, without simulator UI."""

import copy
import json
from pathlib import Path
import sqlite3
import sys
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "content/pilgrimage/places.yaml"
PRODUCTION_GEOMETRY = ROOT / "content/pilgrimage/place-geometries.geojson"
RESEARCH_GEOMETRY = ROOT / "content/research/radhakunda-wave-a-controlled-evidence.geojson"
DATABASE = ROOT / "build/radhakunda-content.sqlite"
sys.path.insert(0, str(ROOT / "tools"))
from content_tooling import ContentValidationError, validate_pilgrimage_geometry, validate_pilgrimage_places  # noqa: E402


class MohanaAreaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.places = yaml.safe_load(REGISTRY.read_text(encoding="utf-8"))["places"]
        cls.production = json.loads(PRODUCTION_GEOMETRY.read_text(encoding="utf-8"))
        cls.research = json.loads(RESEARCH_GEOMETRY.read_text(encoding="utf-8"))

    def test_exactly_one_micro_place_and_original_numbers(self):
        numbered = [place for place in self.places if place["map_number"] is not None]
        micro = [place for place in self.places if place.get("collection") == "RADHA_KUNDA_MICRO"]
        self.assertEqual(72, len(self.places))
        self.assertEqual(71, len(numbered))
        self.assertEqual(list(range(1, 72)), [place["map_number"] for place in numbered])
        self.assertEqual(["place.rk.mohana-kunda"], [place["id"] for place in micro])
        area = micro[0]
        self.assertIsNone(area["map_number"])
        self.assertEqual("WATER_BODY_POLYGON", area["geometry_type"])
        self.assertEqual("POLYGON_VERTEX", area["coordinate_semantics"])
        self.assertFalse(area["navigation_eligible"])
        self.assertNotIn("latitude", area)
        self.assertNotIn("longitude", area)
        self.assertNotIn("navigation_anchor_place_id", area)
        self.assertFalse(any(place["id"].startswith("place.rk.") for place in numbered))

    def test_polygon_is_exact_controlled_source_not_research_runtime_file(self):
        self.assertNotEqual(PRODUCTION_GEOMETRY, RESEARCH_GEOMETRY)
        self.assertEqual(1, len(self.production["features"]))
        feature = self.production["features"][0]
        research = self.research["features"][0]
        ring = feature["geometry"]["coordinates"][0]
        self.assertEqual(research["geometry"]["coordinates"][0], ring)
        self.assertEqual(81, len(ring))
        self.assertEqual(80, len({tuple(pair) for pair in ring}))
        self.assertEqual(ring[0], ring[-1])
        self.assertEqual([77.4929354, 27.5234252, 77.4951433, 27.5271270], [
            min(pair[0] for pair in ring), min(pair[1] for pair in ring),
            max(pair[0] for pair in ring), max(pair[1] for pair in ring),
        ])
        props = feature["properties"]
        self.assertEqual("place.rk.mohana-kunda", props["place_id"])
        self.assertEqual("POLYGON_VERTEX", props["coordinate_semantics"])
        self.assertEqual("WATER_BODY_POLYGON", props["geometry_type"])
        self.assertEqual("PRECINCT_ONLY", props["visibility"])
        self.assertGreaterEqual(props["min_zoom"], 15)
        self.assertEqual(props["label_min_zoom"], props["min_zoom"])
        self.assertFalse(props["navigation_authorized"])
        self.assertFalse(props["arrival_authorized"])
        self.assertEqual("OSM-WAY-430061166-V2", props["source_id"])
        self.assertEqual(2, props["source_version"])
        self.assertEqual(67612276, props["source_changeset"])
        self.assertIn("OpenStreetMap", props["attribution"])
        self.assertIn("ODbL", props["attribution"])

    def test_compiled_sqlite_has_no_destination_or_centroid(self):
        with sqlite3.connect(DATABASE) as db:
            self.assertEqual(72, db.execute("SELECT count(*) FROM pilgrimage_places").fetchone()[0])
            self.assertEqual(71, db.execute("SELECT count(*) FROM pilgrimage_places WHERE map_number IS NOT NULL").fetchone()[0])
            self.assertEqual(1, db.execute("SELECT count(*) FROM pilgrimage_places WHERE collection = 'RADHA_KUNDA_MICRO'").fetchone()[0])
            row = db.execute(
                "SELECT map_number, latitude, longitude, navigation_anchor_place_id, navigation_eligible, geometry_type, coordinate_semantics "
                "FROM pilgrimage_places WHERE id = 'place.rk.mohana-kunda'"
            ).fetchone()
            self.assertEqual((None, None, None, None, 0, "WATER_BODY_POLYGON", "POLYGON_VERTEX"), row)
            self.assertEqual(
                [("place.rk.mohana-kunda",)],
                db.execute("SELECT id FROM pilgrimage_places WHERE id LIKE 'place.rk.%'").fetchall(),
            )
            geometry = db.execute(
                "SELECT source_id, source_version, source_changeset, min_zoom, label_min_zoom, navigation_authorized, arrival_authorized "
                "FROM pilgrimage_place_geometries WHERE place_id = 'place.rk.mohana-kunda'"
            ).fetchone()
            self.assertEqual(("OSM-WAY-430061166-V2", 2, 67612276, 15.0, 15.0, 0, 0), geometry)
            vertices = db.execute(
                "SELECT longitude, latitude, coordinate_semantics FROM pilgrimage_place_geometry_vertices "
                "WHERE place_id = 'place.rk.mohana-kunda' ORDER BY vertex_index"
            ).fetchall()
            self.assertEqual(
                [(pair[0], pair[1], "POLYGON_VERTEX") for pair in self.production["features"][0]["geometry"]["coordinates"][0]],
                vertices,
            )
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())

    def test_manifest_compiles_production_geometry_not_research_file(self):
        manifest = yaml.safe_load((ROOT / "content/manifests/radhakunda-mvp-development-manifest.yaml").read_text(encoding="utf-8"))
        paths = [item["target_path"] for item in manifest["compile_sequence"]]
        self.assertIn("content/pilgrimage/place-geometries.geojson", paths)
        self.assertNotIn("content/research/radhakunda-wave-a-controlled-evidence.geojson", paths)
        self.assertNotIn("content/research/radhakunda-wave-a-controlled-evidence.yaml", paths)

    def test_generic_validator_rejects_open_ring_or_arrival_promotion(self):
        for mutation in ("open_ring", "navigation", "source"):
            candidate = copy.deepcopy(self.production)
            feature = candidate["features"][0]
            if mutation == "open_ring":
                feature["geometry"]["coordinates"][0].pop()
            elif mutation == "navigation":
                feature["properties"]["navigation_authorized"] = True
            else:
                feature["properties"]["source_id"] = None
            with self.subTest(mutation=mutation), self.assertRaises(ContentValidationError):
                validate_pilgrimage_geometry(candidate, self.places)

    def test_generic_validator_rejects_micro_place_with_number_or_arrival(self):
        for mutation in ("map_number", "latitude", "navigation_eligible"):
            candidate = {"schema_version": 1, "registry": {}, "places": copy.deepcopy(self.places)}
            area = candidate["places"][-1]
            if mutation == "map_number":
                area["map_number"] = 72
            elif mutation == "latitude":
                area["latitude"] = 27.525
                area["longitude"] = 77.494
            else:
                area["navigation_eligible"] = True
            with self.subTest(mutation=mutation), self.assertRaises(ContentValidationError):
                validate_pilgrimage_places(candidate, "test")


if __name__ == "__main__":
    unittest.main()
