"""Task 021A.6: existing numbered points plus separate, non-navigable water geometry."""

import copy
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import unittest

import yaml

from tests.test_radhakunda_three_kunda_geometries import polygons_conflict, segments_intersect


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from content_tooling import ContentValidationError, validate_pilgrimage_geometry  # noqa: E402

REGISTRY = ROOT / "content/pilgrimage/places.yaml"
PRODUCTION = ROOT / "content/pilgrimage/place-geometries.geojson"
RESEARCH = ROOT / "content/research/radhakunda-three-kunda-controlled-geometries.geojson"
MOHANA_RESEARCH = ROOT / "content/research/radhakunda-wave-a-controlled-evidence.geojson"
DATABASE = ROOT / "build/radhakunda-content.sqlite"
EXPECTED_POINTS = {
    "place.radhakunda": (1, 27.525256, 77.491353),
    "place.syamakunda": (2, 27.525200, 77.492500),
    "place.lalitakunda": (3, 27.526200, 77.493100),
}
EXPECTED_WAYS = {
    "place.radhakunda": (335571302, 16, 17, [77.4908475, 27.5246231, 77.4918439, 27.5256634]),
    "place.syamakunda": (335571305, 16, 17, [77.4917621, 27.5246623, 77.4932980, 27.5257390]),
    "place.lalitakunda": (335571300, 12, 13, [77.4929360, 27.5261084, 77.4932541, 27.5263572]),
}
ORIGINAL_ID_NUMBER_DIGEST = "5fdffa7e6503f1adf8ae9ddb69ef3f25e3c4c9d2737feb94c7a973de25ea30c5"


class ThreeKundaProductionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.places = yaml.safe_load(REGISTRY.read_text(encoding="utf-8"))["places"]
        cls.by_id = {place["id"]: place for place in cls.places}
        cls.production = json.loads(PRODUCTION.read_text(encoding="utf-8"))
        cls.features = {item["properties"]["place_id"]: item for item in cls.production["features"]}
        cls.research = {item["id"]: item for item in json.loads(RESEARCH.read_text(encoding="utf-8"))["features"]}

    def test_identity_numbering_and_original_point_contract(self):
        self.assertEqual(72, len(self.places))
        self.assertEqual(71, sum(place["map_number"] is not None for place in self.places))
        pairs = sorted((place["id"], place["map_number"]) for place in self.places)
        digest = hashlib.sha256(json.dumps(pairs, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
        self.assertEqual(ORIGINAL_ID_NUMBER_DIGEST, digest)
        micro = [place for place in self.places if place.get("collection") == "RADHA_KUNDA_MICRO"]
        self.assertEqual(["place.rk.mohana-kunda"], [place["id"] for place in micro])
        self.assertIsNone(micro[0]["map_number"])
        for place_id, (number, latitude, longitude) in EXPECTED_POINTS.items():
            with self.subTest(place_id=place_id):
                place = self.by_id[place_id]
                self.assertEqual((number, latitude, longitude),
                                 (place["map_number"], place["latitude"], place["longitude"]))
                self.assertEqual("GOVARDHANA_NUMBERED", place.get("collection", "GOVARDHANA_NUMBERED"))
                self.assertEqual("POINT", place.get("geometry_type", "POINT"))
                self.assertEqual("EXISTING_WORKING_POINT", place.get("coordinate_semantics", "EXISTING_WORKING_POINT"))
                self.assertEqual("ALL_ZOOMS", place.get("map_visibility", "ALL_ZOOMS"))
                self.assertTrue(place.get("navigation_eligible", True))
                self.assertEqual(("PROVISIONAL", "LOW"),
                                 (place["coordinate_status"], place["coordinate_confidence"]))
                self.assertIsNone(place.get("navigation_anchor_place_id"))
                self.assertEqual("PROJECT_FIXTURE", place["provenance"][0]["source_type"])

    def test_four_exact_distinct_water_rings_and_provenance(self):
        self.assertEqual({*EXPECTED_WAYS, "place.rk.mohana-kunda"}, set(self.features))
        mohana = self.features["place.rk.mohana-kunda"]
        self.assertEqual(
            json.loads(MOHANA_RESEARCH.read_text(encoding="utf-8"))["features"][0]["geometry"]["coordinates"][0],
            mohana["geometry"]["coordinates"][0],
        )
        self.assertEqual(("OSM-WAY-430061166-V2", 2, 67612276, 15, 15),
                         tuple(mohana["properties"][key] for key in
                               ("source_id", "source_version", "source_changeset", "min_zoom", "label_min_zoom")))
        rings = {}
        for place_id, feature in self.features.items():
            props = feature["properties"]
            ring = feature["geometry"]["coordinates"][0]
            rings[place_id] = ring
            self.assertEqual("WATER_BODY_POLYGON", props["geometry_type"])
            self.assertEqual("POLYGON_VERTEX", props["coordinate_semantics"])
            self.assertEqual("PRECINCT_ONLY", props["visibility"])
            self.assertEqual((15, 15), (props["min_zoom"], props["label_min_zoom"]))
            self.assertFalse(props["navigation_authorized"])
            self.assertFalse(props["arrival_authorized"])
            self.assertEqual(ring[0], ring[-1])
            self.assertEqual(len(ring) - 1, len({tuple(pair) for pair in ring}))
            for i in range(len(ring) - 1):
                for j in range(i + 2, len(ring) - 1):
                    if i == 0 and j == len(ring) - 2:
                        continue
                    self.assertFalse(segments_intersect(ring[i], ring[i + 1], ring[j], ring[j + 1]))
            if place_id in EXPECTED_WAYS:
                way, unique_count, stored_count, bbox = EXPECTED_WAYS[place_id]
                self.assertEqual(self.research[place_id]["geometry"]["coordinates"][0], ring)
                self.assertEqual((unique_count, stored_count), (len({tuple(p) for p in ring}), len(ring)))
                self.assertEqual(bbox, [min(p[0] for p in ring), min(p[1] for p in ring),
                                        max(p[0] for p in ring), max(p[1] for p in ring)])
                self.assertEqual((f"OSM-WAY-{way}-V1", 1, 29850243),
                                 (props["source_id"], props["source_version"], props["source_changeset"]))
                self.assertEqual("2015-03-30T13:22:53Z", props["source_object_timestamp"])
                self.assertEqual("2026-09-17", props["source_retrieved_on"])
                self.assertEqual(f"https://www.openstreetmap.org/way/{way}", props["source_url"])
                self.assertEqual("GOVARDHANA_NUMBERED", props["collection"])
                self.assertEqual(EXPECTED_POINTS[place_id][0], props["map_number"])
            self.assertIn("OpenStreetMap contributors", props["attribution"])
            self.assertIn("ODbL", props["attribution"])
        ids = list(rings)
        for index, first in enumerate(ids):
            for second in ids[index + 1:]:
                with self.subTest(first=first, second=second):
                    self.assertFalse(polygons_conflict(rings[first], rings[second]))

    def test_compiled_points_and_polygons_remain_separate(self):
        with sqlite3.connect(DATABASE) as db:
            self.assertEqual(72, db.execute("SELECT count(*) FROM pilgrimage_places").fetchone()[0])
            self.assertEqual(71, db.execute("SELECT count(*) FROM pilgrimage_places WHERE map_number IS NOT NULL").fetchone()[0])
            self.assertEqual(4, db.execute("SELECT count(*) FROM pilgrimage_place_geometries").fetchone()[0])
            self.assertEqual(0, db.execute("SELECT count(*) FROM pilgrimage_places WHERE map_number = 72").fetchone()[0])
            compiled_pairs = [list(row) for row in db.execute("SELECT id, map_number FROM pilgrimage_places ORDER BY id")]
            compiled_digest = hashlib.sha256(json.dumps(compiled_pairs, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()
            self.assertEqual(ORIGINAL_ID_NUMBER_DIGEST, compiled_digest)
            for place_id, (number, latitude, longitude) in EXPECTED_POINTS.items():
                with self.subTest(place_id=place_id):
                    point = db.execute(
                        "SELECT map_number, latitude, longitude, navigation_eligible, geometry_type, coordinate_semantics, map_visibility "
                        "FROM pilgrimage_places WHERE id = ?", (place_id,),
                    ).fetchone()
                    self.assertEqual((number, latitude, longitude, 1, "POINT", "EXISTING_WORKING_POINT", "ALL_ZOOMS"), point)
                    geometry = db.execute(
                        "SELECT geometry_type, coordinate_semantics, visibility, min_zoom, source_id, source_version, "
                        "source_changeset, source_retrieved_on, attribution, navigation_authorized, arrival_authorized "
                        "FROM pilgrimage_place_geometries WHERE place_id = ?", (place_id,),
                    ).fetchone()
                    self.assertEqual(("WATER_BODY_POLYGON", "POLYGON_VERTEX", "PRECINCT_ONLY", 15.0), geometry[:4])
                    way = EXPECTED_WAYS[place_id][0]
                    self.assertEqual((f"OSM-WAY-{way}-V1", 1, 29850243, "2026-09-17"), geometry[4:8])
                    self.assertEqual((0, 0), geometry[-2:])
                    self.assertIn("ODbL", geometry[-3])
                    compiled_ring = db.execute(
                        "SELECT longitude, latitude FROM pilgrimage_place_geometry_vertices WHERE place_id = ? ORDER BY vertex_index",
                        (place_id,),
                    ).fetchall()
                    self.assertEqual(self.research[place_id]["geometry"]["coordinates"][0],
                                     [list(pair) for pair in compiled_ring])
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())

    def test_validator_rejects_misattached_numbered_polygon(self):
        for mutation in ("place_id", "map_number", "collection", "navigation"):
            document = copy.deepcopy(self.production)
            feature = next(item for item in document["features"] if item["properties"]["place_id"] == "place.radhakunda")
            props = feature["properties"]
            if mutation == "place_id":
                props["place_id"] = "place.unknown"
            elif mutation == "map_number":
                props["map_number"] = 2
            elif mutation == "collection":
                props["collection"] = "RADHA_KUNDA_MICRO"
            else:
                props["navigation_authorized"] = True
            with self.subTest(mutation=mutation), self.assertRaises(ContentValidationError):
                validate_pilgrimage_geometry(document, self.places)


if __name__ == "__main__":
    unittest.main()
