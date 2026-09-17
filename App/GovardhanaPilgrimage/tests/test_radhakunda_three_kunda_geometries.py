"""Focused, offline checks for the research-only three-kuṇḍa source snapshot."""

import hashlib
import json
from pathlib import Path
import sqlite3
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "content/research/radhakunda-three-kunda-controlled-geometries.yaml"
GEOJSON = ROOT / "content/research/radhakunda-three-kunda-controlled-geometries.geojson"
PLACES = ROOT / "content/pilgrimage/places.yaml"
PRODUCTION_GEOMETRY = ROOT / "content/pilgrimage/place-geometries.geojson"
MANIFEST = ROOT / "content/manifests/radhakunda-mvp-development-manifest.yaml"
DATABASE = ROOT / "build/radhakunda-content.sqlite"
EXPECTED = {
    "place.radhakunda": (335571302, 16, 17, "8fec3c7308def4fa3944b5bbd8b0301f80fd77be58b9369014e9116fd2c08c8d"),
    "place.syamakunda": (335571305, 16, 17, "e8e3c5fb597ff72c65dbdcb6e257bc46459cf4f28477c4b7bc8f4ab395ceeb76"),
    "place.lalitakunda": (335571300, 12, 13, "67e74912ef110baf9a2b0bc6f943c7c714353a5193ddc0d956af9f7034ada3a5"),
}


def orientation(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def proper_segment_crossing(a, b, c, d):
    return orientation(a, b, c) * orientation(a, b, d) < 0 and orientation(c, d, a) * orientation(c, d, b) < 0


def segments_intersect(a, b, c, d):
    if proper_segment_crossing(a, b, c, d):
        return True
    return any(
        abs(orientation(start, end, point)) < 1e-12
        and min(start[0], end[0]) <= point[0] <= max(start[0], end[0])
        and min(start[1], end[1]) <= point[1] <= max(start[1], end[1])
        for start, end, point in ((a, b, c), (a, b, d), (c, d, a), (c, d, b))
    )


def on_boundary(point, ring):
    for a, b in zip(ring, ring[1:]):
        if abs(orientation(a, b, point)) < 1e-12 and min(a[0], b[0]) <= point[0] <= max(a[0], b[0]) and min(a[1], b[1]) <= point[1] <= max(a[1], b[1]):
            return True
    return False


def point_in_ring(point, ring):
    if on_boundary(point, ring):
        return False
    inside = False
    for a, b in zip(ring, ring[1:]):
        if (a[1] > point[1]) != (b[1] > point[1]):
            crossing = a[0] + (point[1] - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
            if point[0] < crossing:
                inside = not inside
    return inside


def polygons_conflict(first, second):
    if any(point_in_ring(point, second) for point in first[:-1]):
        return True
    if any(point_in_ring(point, first) for point in second[:-1]):
        return True
    return any(segments_intersect(a, b, c, d) for a, b in zip(first, first[1:]) for c, d in zip(second, second[1:]))


class ThreeKundaGeometryEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.evidence = yaml.safe_load(EVIDENCE.read_text(encoding="utf-8"))
        cls.geojson = json.loads(GEOJSON.read_text(encoding="utf-8"))
        cls.places = {place["id"]: place for place in yaml.safe_load(PLACES.read_text(encoding="utf-8"))["places"]}
        cls.features = {feature["id"]: feature for feature in cls.geojson["features"]}

    def test_exact_scope_and_research_only_manifest_exclusion(self):
        self.assertEqual(3, len(self.evidence["records"]))
        self.assertEqual(3, len(self.geojson["features"]))
        self.assertEqual(set(EXPECTED), {record["place_id"] for record in self.evidence["records"]})
        self.assertEqual(set(EXPECTED), set(self.features))
        self.assertEqual("RESEARCH_ONLY_NOT_RUNTIME_INPUT", self.evidence["scope"])
        self.assertEqual("RESEARCH_ONLY_NOT_RUNTIME_INPUT", self.geojson["scope"])
        self.assertFalse(self.evidence["production_ingestion_authorized"])
        manifest = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))
        runtime_paths = {entry["target_path"] for entry in manifest["compile_sequence"]}
        self.assertNotIn(str(EVIDENCE.relative_to(ROOT)), runtime_paths)
        self.assertNotIn(str(GEOJSON.relative_to(ROOT)), runtime_paths)

    def test_source_provenance_and_exact_ordered_rings(self):
        decisions = {
            "CONTROLLED_GEOMETRY_READY", "HOLD_SOURCE_CONFLICT", "HOLD_IDENTITY_RECONCILIATION",
            "HOLD_INVALID_GEOMETRY", "HOLD_INSUFFICIENT_EVIDENCE", "FIELD_VERIFICATION_REQUIRED",
        }
        for record in self.evidence["records"]:
            place_id = record["place_id"]
            way_id, unique_count, stored_count, ring_digest = EXPECTED[place_id]
            with self.subTest(place_id=place_id):
                source = record["source"]
                geometry = record["geometry"]
                feature = self.features[place_id]
                props = feature["properties"]
                ring = feature["geometry"]["coordinates"][0]
                self.assertIn(record["decision"], decisions)
                self.assertEqual("OpenStreetMap contributors", source["provider"])
                self.assertEqual(f"way/{way_id}", source["feature_id"])
                self.assertEqual(f"https://api.openstreetmap.org/api/0.6/way/{way_id}/full.json", source["full_feature_endpoint"])
                self.assertEqual("2026-09-17", source["retrieved_on"])
                self.assertEqual((1, 29850243, "2015-03-30T13:22:53Z"),
                                 (source["version"], source["changeset"], source["timestamp"]))
                self.assertEqual({"natural": "water", "water": "lake"},
                                 {key: source["tags"][key] for key in ("natural", "water")})
                self.assertEqual("ODbL 1.0", source["license"])
                self.assertIn("OpenStreetMap contributors", source["attribution"])
                self.assertEqual(source["tags"], props["source_tags"])
                self.assertEqual(source["feature_id"], props["source_feature_id"])
                self.assertEqual(stored_count, len(source["ordered_node_ids"]))
                self.assertEqual(source["ordered_node_ids"][0], source["ordered_node_ids"][-1])
                self.assertEqual(unique_count, len(set(source["ordered_node_ids"])))
                self.assertEqual("WATER_BODY_POLYGON", geometry["semantics"])
                self.assertEqual("POLYGON_VERTEX", geometry["coordinate_semantics"])
                self.assertEqual(("WATER_BODY_POLYGON", "POLYGON_VERTEX"),
                                 (props["geometry_semantics"], props["coordinate_semantics"]))
                self.assertEqual(feature["geometry"]["type"], "Polygon")
                self.assertEqual(stored_count, len(ring))
                self.assertEqual(unique_count, len({tuple(point) for point in ring}))
                self.assertEqual(ring[0], ring[-1])
                self.assertEqual([min(p[0] for p in ring), min(p[1] for p in ring),
                                  max(p[0] for p in ring), max(p[1] for p in ring)], geometry["bbox_lon_lat"])
                self.assertTrue(all(77 < lon < 78 and 27 < lat < 28 for lon, lat in ring))
                self.assertEqual(ring_digest, hashlib.sha256(json.dumps(ring, separators=(",", ":")).encode()).hexdigest())
                self.assertTrue(geometry["valid_simple_ring"])
                self.assertTrue(geometry["closed"])
                self.assertNotEqual(0, sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(ring, ring[1:])))
                for i in range(len(ring) - 1):
                    for j in range(i + 2, len(ring) - 1):
                        if i == 0 and j == len(ring) - 2:
                            continue
                        self.assertFalse(segments_intersect(ring[i], ring[i + 1], ring[j], ring[j + 1]))
                self.assertFalse(props["navigation_authorized"])
                self.assertFalse(props["arrival_authorized"])
                point = record["existing_point"]
                production = self.places[place_id]
                self.assertEqual((production["longitude"], production["latitude"]),
                                 (point["longitude"], point["latitude"]))
                self.assertEqual("PROVISIONAL", point["coordinate_status"])
                self.assertEqual("INSIDE_POLYGON", point["relationship"])
                self.assertTrue(point_in_ring([point["longitude"], point["latitude"]], ring))
                self.assertFalse(point["independently_documented_arrival_meaning"])
                self.assertIn("field verification", record["limitations"].lower())

    def test_distinct_water_bodies_and_mohana_separation(self):
        rings = {place_id: feature["geometry"]["coordinates"][0] for place_id, feature in self.features.items()}
        mohana = json.loads(PRODUCTION_GEOMETRY.read_text(encoding="utf-8"))["features"][0]
        self.assertEqual("place.rk.mohana-kunda", mohana["properties"]["place_id"])
        rings["place.rk.mohana-kunda"] = mohana["geometry"]["coordinates"][0]
        ids = list(rings)
        for index, first in enumerate(ids):
            for second in ids[index + 1:]:
                with self.subTest(first=first, second=second):
                    self.assertFalse(polygons_conflict(rings[first], rings[second]))

    def test_runtime_database_has_only_the_four_authorized_water_polygons(self):
        with sqlite3.connect(DATABASE) as db:
            self.assertEqual(72, db.execute("SELECT count(*) FROM pilgrimage_places").fetchone()[0])
            self.assertEqual(71, db.execute("SELECT count(*) FROM pilgrimage_places WHERE map_number IS NOT NULL").fetchone()[0])
            self.assertEqual(4, db.execute("SELECT count(*) FROM pilgrimage_place_geometries").fetchone()[0])
            self.assertEqual(
                {"place.rk.mohana-kunda", *EXPECTED},
                {row[0] for row in db.execute("SELECT place_id FROM pilgrimage_place_geometries")},
            )
            self.assertEqual("ok", db.execute("PRAGMA integrity_check").fetchone()[0])
            self.assertEqual([], db.execute("PRAGMA foreign_key_check").fetchall())


if __name__ == "__main__":
    unittest.main()
