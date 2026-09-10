from __future__ import annotations

import copy
import hashlib
import json
import shutil
import sqlite3
import sys
import tempfile
import unicodedata
import unittest
from unittest import mock
from pathlib import Path
import yaml


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from content_tooling import (  # noqa: E402
    ContentValidationError,
    compile_manifest,
    deterministic_json,
)
import content_tooling  # noqa: E402
from sqlite_builder import build_sqlite, inspect_database  # noqa: E402


class ContentToolingTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        shutil.copytree(ROOT / "content", self.root / "content")
        shutil.copytree(ROOT / "docs", self.root / "docs")

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def source(self) -> dict:
        path = self.root / "content" / "fixtures" / "source.json"
        return json.loads(path.read_text(encoding="utf-8"))

    def write_source(self, source: dict) -> None:
        path = self.root / "content" / "fixtures" / "source.json"
        path.write_text(json.dumps(source, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def refresh_real_checksum(self, filename: str, path: Path) -> None:
        checksum_path = self.root / "content/manifests/SHA256SUMS.json"
        checksums = json.loads(checksum_path.read_text(encoding="utf-8"))
        checksums[filename] = hashlib.sha256(path.read_bytes()).hexdigest()
        checksum_path.write_text(json.dumps(checksums, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    def pilgrimage_registry(self) -> tuple[Path, dict]:
        path = self.root / "content/pilgrimage/places.yaml"
        return path, yaml.safe_load(path.read_text(encoding="utf-8"))

    def write_pilgrimage_registry(self, path: Path, registry: dict) -> None:
        path.write_text(yaml.safe_dump(registry, allow_unicode=True, sort_keys=False), encoding="utf-8")
        self.refresh_real_checksum("govardhana-pilgrimage-places.yaml", path)

    def test_valid_fixture_builds_successfully(self) -> None:
        result = compile_manifest(self.root, "fixture")
        self.assertEqual("success", result.report["status"])
        self.assertEqual(1, result.report["counts"]["stories"])
        self.assertEqual(3, result.report["counts"]["passages"])
        self.assertEqual(3, result.report["counts"]["passage_representations"])
        self.assertEqual(5, result.report["counts"]["content_blocks"])
        self.assertEqual(
            ["heading", "paragraph", "quotation", "verse", "paragraph"],
            [block["block_type"] for block in sorted(result.content["content_blocks"], key=lambda block: block["order"])],
        )
        self.assertEqual(
            "passage.fixture.2",
            result.content["citations"][0]["source_passage_id"],
        )

    def test_duplicate_id_fails(self) -> None:
        source = self.source()
        duplicate = copy.deepcopy(source["passages"][0])
        source["passages"].append(duplicate)
        self.write_source(source)
        with self.assertRaisesRegex(ContentValidationError, "Duplicate ID 'passage.fixture.1'"):
            compile_manifest(self.root, "fixture")

    def test_missing_citation_target_fails(self) -> None:
        story_path = self.root / "content" / "fixtures" / "story.md"
        story = story_path.read_text(encoding="utf-8").replace(
            "passage=passage.fixture.2", "passage=passage.fixture.missing"
        )
        story_path.write_text(story, encoding="utf-8")
        with self.assertRaisesRegex(ContentValidationError, "missing canonical Passage 'passage.fixture.missing'"):
            compile_manifest(self.root, "fixture")

    def test_missing_work_edition_relationship_fails(self) -> None:
        source = self.source()
        source["edition"]["work_id"] = "work.missing"
        self.write_source(source)
        with self.assertRaisesRegex(ContentValidationError, "references missing Work 'work.missing'"):
            compile_manifest(self.root, "fixture")

    def test_canonical_passage_is_not_edition_owned(self) -> None:
        result = compile_manifest(self.root, "fixture")
        passage = next(item for item in result.content["passages"] if item["id"] == "passage.fixture.2")
        representation = next(
            item
            for item in result.content["passage_representations"]
            if item["passage_id"] == passage["id"]
        )
        self.assertNotIn("edition_id", passage)
        self.assertNotIn("text", passage)
        self.assertEqual("edition.fixture.reading-v1", representation["edition_id"])
        self.assertIn("Rādhā-kuṇḍa", representation["text"])

    def test_edition_owned_text_on_canonical_passage_fails(self) -> None:
        source = self.source()
        source["passages"][0]["translation"] = "This must belong to a representation."
        self.write_source(source)
        with self.assertRaisesRegex(ContentValidationError, "edition-owned fields: translation"):
            compile_manifest(self.root, "fixture")

    def test_unicode_input_is_normalized_to_nfc(self) -> None:
        source = self.source()
        decomposed = unicodedata.normalize("NFD", "Rādhā-kuṇḍa")
        source["representations"][1]["text"] = decomposed
        self.write_source(source)
        result = compile_manifest(self.root, "fixture")
        text = result.content["passage_representations"][1]["text"]
        self.assertEqual("Rādhā-kuṇḍa", text)
        self.assertTrue(unicodedata.is_normalized("NFC", deterministic_json(result.content)))

    def test_story_fixture_preserves_multiscript_unicode(self) -> None:
        result = compile_manifest(self.root, "fixture")
        text = "\n".join(block["text"] for block in result.content["content_blocks"])
        self.assertIn("Rādhā-kuṇḍa", text)
        self.assertIn("राधा-कुण्ड", text)
        self.assertIn("রাধা-কুণ্ড", text)

    def test_deterministic_output(self) -> None:
        first = deterministic_json(compile_manifest(self.root, "fixture").content)
        second = deterministic_json(compile_manifest(self.root, "fixture").content)
        self.assertEqual(first, second)

    def build_database(self) -> tuple[Path, dict]:
        result = compile_manifest(self.root, "fixture")
        path = self.root / "build" / "radhakunda-content.sqlite"
        report = build_sqlite(path, result)
        return path, report

    def test_database_creation_and_integrity(self) -> None:
        path, report = self.build_database()
        self.assertTrue(path.is_file())
        self.assertEqual("ok", report["integrity_check"])
        self.assertEqual(0, report["foreign_key_violation_count"])
        connection = sqlite3.connect(path)
        try:
            self.assertEqual(7, connection.execute("PRAGMA user_version").fetchone()[0])
            self.assertEqual(3, connection.execute("SELECT count(*) FROM source_passages").fetchone()[0])
            self.assertEqual(5, connection.execute("SELECT count(*) FROM story_blocks").fetchone()[0])
        finally:
            connection.close()

    def test_task_015_original_registry_records_remain_unchanged(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        places = [place for place in result.content["pilgrimage_places"] if place["map_number"] in {1, 2, 3, 20}]
        self.assertEqual([1, 2, 3, 20], [place["map_number"] for place in places])
        self.assertEqual(
            ["place.radhakunda", "place.syamakunda", "place.lalitakunda", "place.manasiganga"],
            [place["id"] for place in places],
        )
        self.assertTrue(all(place["coordinate_status"] == "PROVISIONAL" for place in places))

    def test_task_015_registry_rejects_invalid_coordinate(self) -> None:
        path, registry = self.pilgrimage_registry()
        registry["places"][0]["latitude"] = 91
        self.write_pilgrimage_registry(path, registry)
        with self.assertRaisesRegex(ContentValidationError, "invalid latitude"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_015_registry_rejects_duplicate_id(self) -> None:
        path, registry = self.pilgrimage_registry()
        registry["places"][1]["id"] = registry["places"][0]["id"]
        self.write_pilgrimage_registry(path, registry)
        with self.assertRaisesRegex(ContentValidationError, "Duplicate Pilgrimage Place ID"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_015_registry_rejects_duplicate_map_number(self) -> None:
        path, registry = self.pilgrimage_registry()
        registry["places"][1]["map_number"] = registry["places"][0]["map_number"]
        self.write_pilgrimage_registry(path, registry)
        with self.assertRaisesRegex(ContentValidationError, "Duplicate Pilgrimage Place map_number"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_015_registry_rejects_invalid_verification_state(self) -> None:
        path, registry = self.pilgrimage_registry()
        registry["places"][0]["coordinate_status"] = "CERTAINISH"
        self.write_pilgrimage_registry(path, registry)
        with self.assertRaisesRegex(ContentValidationError, "invalid coordinate_status"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_015_sqlite_preserves_registry_aliases_and_provenance(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        path = self.root / "build/task015.sqlite"
        report = build_sqlite(path, result)
        self.assertEqual("ok", report["integrity_check"])
        self.assertEqual(0, report["foreign_key_violation_count"])
        connection = sqlite3.connect(path)
        try:
            self.assertEqual(20, connection.execute("SELECT count(*) FROM pilgrimage_places").fetchone()[0])
            self.assertEqual(64, connection.execute("SELECT count(*) FROM pilgrimage_place_aliases").fetchone()[0])
            self.assertEqual(53, connection.execute("SELECT count(*) FROM pilgrimage_place_provenance").fetchone()[0])
        finally:
            connection.close()

    def test_task_016_approved_place_batch_compiles_exactly(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        places = result.content["pilgrimage_places"]
        task_016_places = [place for place in places if place["map_number"] in {1, 2, 3, 4, 5, 6, 7, 8, 20}]
        self.assertEqual([1, 2, 3, 4, 5, 6, 7, 8, 20], [place["map_number"] for place in task_016_places])
        expected = {
            4: ("place.mukharai", 27.51031, 77.49956, "PROBABLE", "MEDIUM"),
            5: ("place.kusumasarovara", 27.51209, 77.47834, "VERIFIED", "HIGH"),
            6: ("place.uddhava-temple", 27.51141, 77.47705, "PROBABLE", "HIGH"),
            7: ("place.asoka-vana", 27.5111752, 77.4785779, "PROBABLE", "HIGH"),
            8: ("place.narada-kunda", 27.50819, 77.47980, "PROBABLE", "HIGH"),
        }
        for place in places:
            if place["map_number"] not in expected:
                continue
            self.assertEqual(expected[place["map_number"]], (
                place["id"], place["latitude"], place["longitude"],
                place["coordinate_status"], place["coordinate_confidence"],
            ))
            self.assertIsNone(place["coordinate_accuracy_meters"])
            self.assertIsNone(place["content_destination"])
            self.assertGreaterEqual(len(place["provenance"]), 3)

        by_number = {place["map_number"]: place for place in places}
        self.assertIn("Mukhara", by_number[4]["alternate_names"])
        self.assertIn("Kusum Sarovar", by_number[5]["alternate_names"])
        self.assertIn("Uddhav Temple", by_number[6]["alternate_names"])
        self.assertIn("Radha Bana Bihari Mandir", by_number[7]["alternate_names"])
        self.assertIn("Narada Muni's Temple", by_number[8]["alternate_names"])

    def test_task_017_coordinate_less_places_and_approved_batch_compile_exactly(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        places = [
            place for place in result.content["pilgrimage_places"]
            if place["map_number"] in set(range(1, 14)) | {20}
        ]
        self.assertEqual(list(range(1, 14)) + [20], [place["map_number"] for place in places])
        by_number = {place["map_number"]: place for place in places}
        expected = {
            9: ("place.ratna-kunda", 27.5101778, 77.4755889, "VERIFIED", "HIGH"),
            11: ("place.ratna-simhasana", 27.5098368, 77.4756396, "PROBABLE", "HIGH"),
            13: ("place.gvala-pokhara", 27.5078333, 77.4737194, "VERIFIED", "HIGH"),
        }
        for number, values in expected.items():
            place = by_number[number]
            self.assertEqual(values, (
                place["id"], place["latitude"], place["longitude"],
                place["coordinate_status"], place["coordinate_confidence"],
            ))
        for number in (10, 12):
            place = by_number[number]
            self.assertIsNone(place.get("latitude"))
            self.assertIsNone(place.get("longitude"))
            self.assertEqual("UNVERIFIED", place["coordinate_status"])
            self.assertEqual("UNKNOWN", place["coordinate_confidence"])
            self.assertEqual("place.ratna-simhasana", place["navigation_anchor_place_id"])
            self.assertTrue(place["location_guidance"])

    def test_task_017_rejects_half_coordinate(self) -> None:
        path, registry = self.pilgrimage_registry()
        registry["places"][9]["latitude"] = 27.5
        self.write_pilgrimage_registry(path, registry)
        with self.assertRaisesRegex(ContentValidationError, "half-coordinate"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_017_rejects_coordinate_less_non_unverified_place(self) -> None:
        path, registry = self.pilgrimage_registry()
        registry["places"][9]["coordinate_status"] = "PROBABLE"
        self.write_pilgrimage_registry(path, registry)
        with self.assertRaisesRegex(ContentValidationError, "must have coordinate_status UNVERIFIED"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_017_rejects_invalid_navigation_anchors(self) -> None:
        cases = [
            (123, "invalid navigation_anchor_place_id"),
            ("place.missing", "references missing navigation anchor"),
            ("place.rasa-sthali", "cannot use itself as navigation anchor"),
            ("place.krsna-footprint", "has no coordinate"),
        ]
        for anchor, error in cases:
            with self.subTest(anchor=anchor):
                path, registry = self.pilgrimage_registry()
                registry["places"][9]["navigation_anchor_place_id"] = anchor
                self.write_pilgrimage_registry(path, registry)
                with self.assertRaisesRegex(ContentValidationError, error):
                    compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_task_017_sqlite_preserves_null_coordinates_anchor_and_guidance(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        path = self.root / "build/task017.sqlite"
        report = build_sqlite(path, result)
        self.assertEqual("ok", report["integrity_check"])
        self.assertEqual(0, report["foreign_key_violation_count"])
        connection = sqlite3.connect(path)
        try:
            rows = connection.execute(
                "SELECT map_number, latitude, longitude, coordinate_status, coordinate_confidence, navigation_anchor_place_id, location_guidance FROM pilgrimage_places WHERE map_number IN (10, 12) ORDER BY map_number"
            ).fetchall()
            self.assertEqual([10, 12], [row[0] for row in rows])
            for row in rows:
                self.assertIsNone(row[1])
                self.assertIsNone(row[2])
                self.assertEqual(("UNVERIFIED", "UNKNOWN", "place.ratna-simhasana"), row[3:6])
                self.assertTrue(row[6])
        finally:
            connection.close()

    def test_task_019_approved_places_compile_and_sqlite_preserves_anchor(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        places = result.content["pilgrimage_places"]
        self.assertEqual(20, len(places))
        self.assertEqual(list(range(1, 21)), [place["map_number"] for place in places])
        by_number = {place["map_number"]: place for place in places}

        sant_nivas = by_number[14]
        self.assertEqual("place.sant-nivas", sant_nivas["id"])
        self.assertIsNone(sant_nivas.get("latitude"))
        self.assertIsNone(sant_nivas.get("longitude"))
        self.assertEqual("UNVERIFIED", sant_nivas["coordinate_status"])
        self.assertEqual("UNKNOWN", sant_nivas["coordinate_confidence"])
        self.assertEqual("place.gvala-pokhara", sant_nivas["navigation_anchor_place_id"])
        self.assertIn("approximately 170 m", sant_nivas["location_guidance"])

        expected = {
            15: ("place.jugal-kunda", 27.5049625, 77.4736094, "PROBABLE", "HIGH"),
            16: ("place.kilola-kunda", 27.4997625, 77.4716094, "PROBABLE", "HIGH"),
            17: ("place.panca-tirtha-kunda", 27.4992222, 77.4655167, "VERIFIED", "HIGH"),
            18: ("place.mukharavinda-manasi-ganga", 27.4982875, 77.4654219, "VERIFIED", "HIGH"),
            19: ("place.cakra-tirtha", 27.4985111, 77.4641639, "VERIFIED", "HIGH"),
        }
        for number, values in expected.items():
            place = by_number[number]
            self.assertEqual(values, (
                place["id"], place["latitude"], place["longitude"],
                place["coordinate_status"], place["coordinate_confidence"],
            ))
        self.assertIn("map place #61", by_number[18]["verification_notes"])
        self.assertIn("documented practical arrival point", by_number[19]["verification_notes"])
        self.assertEqual(
            ["OFFICIAL_OR_INSTITUTIONAL_DOCUMENT", "PILGRIMAGE_GUIDE", "PROJECT_RESEARCH"],
            [item["source_type"] for item in by_number[19]["provenance"]],
        )

        path = self.root / "build/task019.sqlite"
        report = build_sqlite(path, result)
        self.assertEqual("ok", report["integrity_check"])
        self.assertEqual(0, report["foreign_key_violation_count"])
        connection = sqlite3.connect(path)
        try:
            row = connection.execute(
                "SELECT latitude, longitude, coordinate_status, coordinate_confidence, "
                "navigation_anchor_place_id, location_guidance "
                "FROM pilgrimage_places WHERE map_number = 14"
            ).fetchone()
            self.assertEqual((None, None, "UNVERIFIED", "UNKNOWN", "place.gvala-pokhara"), row[:5])
            self.assertIn("approximately 170 m", row[5])
        finally:
            connection.close()

    def test_task_020a_4_place_content_is_separate_generic_and_integral(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        contents = result.content["pilgrimage_place_contents"]
        self.assertEqual(
            {
                "place.radhakunda", "place.syamakunda", "place.lalitakunda",
                "place.mukharai", "place.kusumasarovara", "place.uddhava-temple",
                "place.asoka-vana", "place.narada-kunda", "place.ratna-kunda",
                "place.rasa-sthali", "place.ratna-simhasana", "place.krsna-footprint",
                "place.gvala-pokhara", "place.sant-nivas", "place.jugal-kunda",
                "place.kilola-kunda", "place.panca-tirtha-kunda",
                "place.mukharavinda-manasi-ganga", "place.cakra-tirtha",
                "place.manasiganga",
            },
            {item["place_id"] for item in contents},
        )
        by_place = {item["place_id"]: item for item in contents}
        for place_id in [
            "place.radhakunda", "place.syamakunda", "place.lalitakunda",
            "place.mukharai", "place.kusumasarovara", "place.uddhava-temple",
            "place.asoka-vana", "place.narada-kunda", "place.ratna-kunda",
            "place.rasa-sthali", "place.ratna-simhasana", "place.krsna-footprint",
            "place.gvala-pokhara", "place.sant-nivas", "place.jugal-kunda",
            "place.kilola-kunda", "place.panca-tirtha-kunda",
            "place.mukharavinda-manasi-ganga", "place.cakra-tirtha",
            "place.manasiganga",
        ]:
            item = by_place[place_id]
            for field in ["summary", "why_sacred", "lila", "pilgrim_guidance"]:
                self.assertTrue(item[field])
            self.assertTrue(item["what_to_see"])
            self.assertTrue(item["references"])
        self.assertEqual(
            [
                "reference.radhakunda.upadesamrta-9-11",
                "reference.radhakunda.radhakundastakam-1",
                "reference.radhakunda.caitanya-caritamrta-madhya-18",
                "reference.radhakunda.govinda-lilamrta-7-102",
                "reference.radhakunda.local-manifestation-story",
            ],
            [item["id"] for item in by_place["place.radhakunda"]["references"]],
        )
        destinations = [
            reference["destination"]
            for item in contents for reference in item["references"]
            if reference.get("destination")
        ]
        self.assertEqual(
            [
                {"kind": "SOURCE_PASSAGE", "id": "passage.radha-kundastaka.1"},
                {"kind": "STORY_SECTION", "id": "story.radhakunda.manifestation"},
                {"kind": "STORY_SECTION", "id": "story.radhakunda.manifestation"},
            ],
            destinations,
        )
        self.assertIn("Visit #1 and #2", by_place["place.radhakunda"]["pilgrim_guidance"])
        self.assertIn("#5–8", by_place["place.kusumasarovara"]["pilgrim_guidance"])
        self.assertIn("exact modern GPS coordinate remains unverified", by_place["place.rasa-sthali"]["summary"])
        self.assertEqual(
            ["place.ratna-kunda", "place.ratna-simhasana", "place.krsna-footprint"],
            by_place["place.rasa-sthali"]["related_place_ids"],
        )
        self.assertIn("future map place #69", by_place["place.uddhava-temple"]["what_to_see"][2])
        self.assertEqual(
            "Supporting līlā context; exact verse-to-modern-site identification not yet verified.",
            by_place["place.asoka-vana"]["references"][1]["explanation"],
        )
        self.assertIn("place.kusumasarovara", by_place["place.narada-kunda"]["related_place_ids"])
        self.assertIn(
            "geographic association with this modern sacred landscape comes from Vraja pilgrimage tradition",
            by_place["place.ratna-kunda"]["references"][1]["explanation"],
        )
        self.assertIn("#9 together with #10", by_place["place.ratna-kunda"]["summary"])
        self.assertIn("near #11 Ratna-siṁhāsana", by_place["place.rasa-sthali"]["pilgrim_guidance"])
        self.assertIn("not proof of this exact modern shrine", by_place["place.ratna-simhasana"]["why_sacred"])
        self.assertIn("exact modern GPS position", by_place["place.krsna-footprint"]["summary"])
        self.assertIn("does not identify this particular modern rock", by_place["place.krsna-footprint"]["references"][0]["explanation"])
        self.assertIn("do not name this pond", by_place["place.gvala-pokhara"]["why_sacred"])
        self.assertIn("not a claim that it is an ancient Kṛṣṇa-līlā site", by_place["place.sant-nivas"]["summary"])
        self.assertIn("No ancient Kṛṣṇa-līlā", by_place["place.sant-nivas"]["lila"])
        self.assertIn("without inventing a separate yugala-līlā", by_place["place.jugal-kunda"]["summary"])
        self.assertTrue(any(
            "#61" in feature
            for feature in by_place["place.mukharavinda-manasi-ganga"]["what_to_see"]
        ))
        self.assertIn("Adeeng", by_place["place.kilola-kunda"]["why_sacred"])
        self.assertIn("Gomatī, Narmadā, Sarayū, Vetrī, and Kāñcī", by_place["place.panca-tirtha-kunda"]["why_sacred"])
        self.assertIn("Gaṅgā, Puṣkara, Prayāga, Kurukṣetra, and Gayā", by_place["place.panca-tirtha-kunda"]["why_sacred"])
        self.assertIn("three closely related features", by_place["place.cakra-tirtha"]["summary"])
        self.assertIn("not the exact coordinate of every feature", by_place["place.cakra-tirtha"]["pilgrim_guidance"])
        self.assertIn("boating pastimes", by_place["place.manasiganga"]["why_sacred"])
        self.assertEqual(
            ["place.mukharavinda-manasi-ganga", "place.cakra-tirtha"],
            by_place["place.manasiganga"]["related_place_ids"],
        )
        registry_by_number = {
            place["map_number"]: place for place in result.content["pilgrimage_places"]
        }
        self.assertEqual("PROVISIONAL", registry_by_number[20]["coordinate_status"])
        self.assertEqual("LOW", registry_by_number[20]["coordinate_confidence"])
        self.assertNotIn("summary", next(
            place for place in result.content["pilgrimage_places"] if place["id"] == "place.kusumasarovara"
        ))

        path = self.root / "build/task020a.sqlite"
        report = build_sqlite(path, result)
        self.assertEqual("ok", report["integrity_check"])
        self.assertEqual(0, report["foreign_key_violation_count"])
        connection = sqlite3.connect(path)
        try:
            self.assertEqual(7, connection.execute("PRAGMA user_version").fetchone()[0])
            self.assertEqual(20, connection.execute("SELECT count(*) FROM pilgrimage_place_contents").fetchone()[0])
            self.assertEqual(68, connection.execute("SELECT count(*) FROM pilgrimage_place_features").fetchone()[0])
            self.assertEqual(58, connection.execute("SELECT count(*) FROM pilgrimage_place_references").fetchone()[0])
            self.assertEqual(46, connection.execute("SELECT count(*) FROM pilgrimage_place_relationships").fetchone()[0])
        finally:
            connection.close()

    def test_sqlite_foreign_keys_are_enforced(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            connection.execute("PRAGMA foreign_keys = ON")
            with self.assertRaises(sqlite3.IntegrityError):
                connection.execute(
                    "INSERT INTO citations(id, content_block_id, source_passage_id, start_passage_id, end_passage_id, role, sort_order) "
                    "VALUES ('citation.broken', 'block.fixture.opening', 'passage.missing', NULL, NULL, 'primary_support', 1)"
                )
            with self.assertRaises(sqlite3.IntegrityError):
                connection.execute(
                    "INSERT INTO citations(id, content_block_id, source_passage_id, start_passage_id, end_passage_id, role, sort_order) "
                    "VALUES ('citation.broken-start', 'block.fixture.opening', NULL, 'passage.missing', 'passage.fixture.2', 'primary_support', 1)"
                )
            with self.assertRaises(sqlite3.IntegrityError):
                connection.execute(
                    "INSERT INTO citations(id, content_block_id, source_passage_id, start_passage_id, end_passage_id, role, sort_order) "
                    "VALUES ('citation.broken-end', 'block.fixture.opening', NULL, 'passage.fixture.1', 'passage.missing', 'primary_support', 1)"
                )
            with self.assertRaises(sqlite3.IntegrityError):
                connection.execute(
                    "INSERT INTO citations(id, content_block_id, source_passage_id, start_passage_id, end_passage_id, role, sort_order) "
                    "VALUES ('citation.ambiguous', 'block.fixture.opening', 'passage.fixture.1', 'passage.fixture.1', 'passage.fixture.2', 'primary_support', 1)"
                )
        finally:
            connection.close()

    def test_sqlite_citation_resolves_to_canonical_passage_and_work(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            row = connection.execute(
                "SELECT c.id, p.id, w.id FROM citations c "
                "JOIN source_passages p ON p.id = c.source_passage_id "
                "JOIN source_works w ON w.id = p.work_id"
            ).fetchone()
            self.assertEqual(("citation.fixture.opening", "passage.fixture.2", "work.fixture"), row)
        finally:
            connection.close()

    def test_preferred_edition_contains_source_details_provenance(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            row = connection.execute(
                "SELECT translator, translation_provenance FROM source_editions WHERE preferred = 1"
            ).fetchone()
            self.assertEqual("Neutral Fixture Translator", row[0])
            self.assertIn("neutral fixture translation", row[1])
        finally:
            connection.close()

    def test_sqlite_canonical_passage_is_independent_of_representation(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            passage_columns = {row[1] for row in connection.execute("PRAGMA table_info(source_passages)")}
            self.assertNotIn("edition_id", passage_columns)
            self.assertNotIn("text", passage_columns)
            row = connection.execute(
                "SELECT p.id, r.edition_id, r.search_text FROM source_passages p "
                "JOIN passage_representations r ON r.passage_id = p.id WHERE p.id = 'passage.fixture.2'"
            ).fetchone()
            self.assertEqual("passage.fixture.2", row[0])
            self.assertEqual("edition.fixture.reading-v1", row[1])
            self.assertIn("Rādhā-kuṇḍa", row[2])
        finally:
            connection.close()

    def test_story_text_is_searchable_with_fts5(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            rows = connection.execute(
                "SELECT target_id FROM search_documents_fts "
                "WHERE search_documents_fts MATCH 'Unicode' AND content_type = 'story_block'"
            ).fetchall()
            self.assertEqual([("block.fixture.following",)], rows)
        finally:
            connection.close()

    def test_preferred_source_representation_is_searchable_with_fts5(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            rows = connection.execute(
                "SELECT target_id FROM search_documents_fts "
                "WHERE search_documents_fts MATCH 'cited' AND content_type = 'source_passage'"
            ).fetchall()
            self.assertEqual([("passage.fixture.2",)], rows)
        finally:
            connection.close()

    def test_repeated_sqlite_builds_are_logically_deterministic(self) -> None:
        first_path, first_report = self.build_database()
        second_path = self.root / "build" / "second.sqlite"
        second_report = build_sqlite(second_path, compile_manifest(self.root, "fixture"))
        self.assertTrue(first_path.exists())
        self.assertEqual(first_report["logical_content_sha256"], second_report["logical_content_sha256"])

    def test_neutral_witness_mapping_preserves_pdf_index_and_printed_label(self) -> None:
        path, _ = self.build_database()
        connection = sqlite3.connect(path)
        try:
            row = connection.execute(
                "SELECT w.title, w.file_path, w.page_count, m.passage_id, "
                "m.pdf_page_index, m.printed_page_label FROM witness_mappings m "
                "JOIN witnesses w ON w.id=m.witness_id"
            ).fetchone()
            self.assertEqual(
                ("Neutral Original Witness", "task012-neutral-witness.pdf", 3, "passage.fixture.2", 2, "1"),
                row,
            )
            self.assertIsNone(
                connection.execute(
                    "SELECT m.id FROM witness_mappings m WHERE m.passage_id='passage.fixture.1'"
                ).fetchone()
            )
        finally:
            connection.close()

    def test_real_development_slice_passes_task_010_gate_and_splits_compact_passages(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        self.assertEqual(0, result.report["validation"]["broken_citation_targets"])
        self.assertEqual(0, result.report["validation"]["visible_unverified_citation_targets"])
        self.assertEqual(0, result.report["validation"]["duplicate_canonical_ids"])
        self.assertEqual(54, len(result.content["passages"]))
        self.assertEqual(54, len(result.content["passage_representations"]))
        self.assertEqual([], result.content["witnesses"])
        self.assertEqual([], result.content["witness_mappings"])
        self.assertTrue(all("text" not in passage for passage in result.content["passages"]))
        rkma = [
            passage for passage in result.content["passages"]
            if passage["work_id"] == "work.radhakunda-manifestation-puranic-unit"
        ]
        self.assertEqual(20, len(rkma))
        self.assertTrue(all(passage["verification_status"] == "VERIFIED" for passage in rkma))
        ranges = [citation for citation in result.content["citations"] if citation["start_passage_id"]]
        self.assertEqual(5, len(ranges))
        self.assertTrue(all(citation["source_passage_id"] is None for citation in ranges))
        singletons = [citation for citation in result.content["citations"] if citation["source_passage_id"]]
        self.assertEqual(7, len(singletons))
        self.assertTrue(all(citation["start_passage_id"] is None and citation["end_passage_id"] is None for citation in singletons))

    def test_task_013_srimad_bhagavatam_expansion_compiles_exactly(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        passages = [
            passage for passage in result.content["passages"]
            if passage["work_id"] == "work.srimad-bhagavatam"
        ]
        representations = [
            representation for representation in result.content["passage_representations"]
            if representation["edition_id"] == "edition.srimad-bhagavatam.vedabase-project-reading-v1"
        ]
        self.assertEqual(16, len(passages))
        self.assertEqual(list(range(1, 17)), [passage["order"] for passage in sorted(passages, key=lambda item: item["order"])])
        self.assertEqual(16, len(representations))
        self.assertTrue(all(representation["original_text"] for representation in representations))
        self.assertTrue(all(representation["transliteration"] for representation in representations))
        self.assertTrue(all(representation["translation"] for representation in representations))
        citation = next(
            item for item in result.content["citations"]
            if item["id"] == "citation.rk.manifestation.sb.10.36.1-15"
        )
        self.assertEqual("passage.srimad-bhagavatam.10.36.1", citation["start_passage_id"])
        self.assertEqual("passage.srimad-bhagavatam.10.36.15", citation["end_passage_id"])
        self.assertEqual("background", citation["role"])
        self.assertIsNone(citation["source_passage_id"])

    def test_real_packages_follow_manifest_source_package_order(self) -> None:
        loaded_packages = []
        original_load_yaml = content_tooling.load_yaml

        def recording_load_yaml(path: Path) -> dict:
            value = original_load_yaml(path)
            if path.name == "package.yaml":
                loaded_packages.append(value["work"]["id"])
            return value

        with mock.patch.object(content_tooling, "load_yaml", side_effect=recording_load_yaml):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        self.assertEqual(
            [
                "work.radha-kundastaka",
                "work.mathura-mahatmya",
                "work.radhakunda-manifestation-puranic-unit",
                "work.srimad-bhagavatam",
            ],
            loaded_packages,
        )

    def test_real_manifest_missing_package_fails_explicitly(self) -> None:
        package_path = self.root / "content/sources/mathura-mahatmya/package.yaml"
        package_path.unlink()
        with self.assertRaisesRegex(ContentValidationError, "Development manifest target is missing"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_real_manifest_work_id_mismatch_fails_explicitly(self) -> None:
        manifest_path = self.root / "content/manifests/radhakunda-mvp-development-manifest.yaml"
        text = manifest_path.read_text(encoding="utf-8").replace(
            "work_id: work.mathura-mahatmya", "work_id: work.not-mathura-mahatmya", 1
        )
        manifest_path.write_text(text, encoding="utf-8")
        with self.assertRaisesRegex(ContentValidationError, "SOURCE_PACKAGE work_id mismatch"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_real_manifest_duplicate_source_package_work_fails_explicitly(self) -> None:
        manifest_path = self.root / "content/manifests/radhakunda-mvp-development-manifest.yaml"
        text = manifest_path.read_text(encoding="utf-8").replace(
            "work_id: work.mathura-mahatmya", "work_id: work.radha-kundastaka", 1
        )
        manifest_path.write_text(text, encoding="utf-8")
        with self.assertRaisesRegex(ContentValidationError, "Duplicate SOURCE_PACKAGE Work declaration"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_real_registry_package_disagreement_fails_explicitly(self) -> None:
        registry_path = self.root / "content/sources/registry.yaml"
        text = registry_path.read_text(encoding="utf-8").replace(
            "title: Śrī Mathurā-māhātmyam", "title: Incorrect registry title", 1
        )
        registry_path.write_text(text, encoding="utf-8")
        self.refresh_real_checksum("radhakunda-mvp-source-registry.yaml", registry_path)
        with self.assertRaisesRegex(ContentValidationError, "Source registry/package disagreement"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")

    def test_undeclared_yaml_package_is_not_silently_compiled(self) -> None:
        undeclared = self.root / "content/sources/undeclared/package.yaml"
        undeclared.parent.mkdir(parents=True)
        undeclared.write_text(
            "work:\n  id: work.undeclared\n  title: Undeclared\n"
            "edition:\n  id: edition.undeclared\npassages: []\n",
            encoding="utf-8",
        )
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        self.assertNotIn("work.undeclared", {work["id"] for work in result.content["works"]})

    def test_real_development_slice_builds_integral_searchable_sqlite(self) -> None:
        result = compile_manifest(self.root, "radhakunda-mvp-development-manifest")
        path = self.root / "build" / "radhakunda-content.sqlite"
        report = build_sqlite(path, result)
        self.assertEqual("ok", report["integrity_check"])
        self.assertEqual(0, report["foreign_key_violation_count"])
        connection = sqlite3.connect(path)
        try:
            rows = connection.execute(
                "SELECT target_id FROM search_documents_fts "
                "WHERE search_documents_fts MATCH '\"narma-dharmokti\"' ORDER BY content_type"
            ).fetchall()
            self.assertEqual(2, len(rows))
            self.assertIn(("passage.radha-kundastaka.1",), rows)
            self.assertEqual(
                12,
                connection.execute(
                    "SELECT count(*) FROM citations c JOIN source_passages p "
                    "ON p.id = COALESCE(c.source_passage_id, c.start_passage_id)"
                ).fetchone()[0],
            )
            ranges = connection.execute(
                "SELECT id, start_passage_id, end_passage_id FROM citations "
                "WHERE start_passage_id IS NOT NULL ORDER BY id"
            ).fetchall()
            self.assertEqual(
                [
                    ("citation.rk.manifestation.rkma.1-2", "passage.radhakunda-manifestation-puranic-unit.1", "passage.radhakunda-manifestation-puranic-unit.2"),
                    ("citation.rk.manifestation.rkma.11-16", "passage.radhakunda-manifestation-puranic-unit.11", "passage.radhakunda-manifestation-puranic-unit.16"),
                    ("citation.rk.manifestation.rkma.3-6", "passage.radhakunda-manifestation-puranic-unit.3", "passage.radhakunda-manifestation-puranic-unit.6"),
                    ("citation.rk.manifestation.rkma.7-10", "passage.radhakunda-manifestation-puranic-unit.7", "passage.radhakunda-manifestation-puranic-unit.10"),
                    ("citation.rk.manifestation.sb.10.36.1-15", "passage.srimad-bhagavatam.10.36.1", "passage.srimad-bhagavatam.10.36.15"),
                ],
                ranges,
            )
            self.assertEqual(
                7,
                connection.execute(
                    "SELECT count(*) FROM citations WHERE source_passage_id IS NOT NULL "
                    "AND start_passage_id IS NULL AND end_passage_id IS NULL"
                ).fetchone()[0],
            )
        finally:
            connection.close()

    def test_real_development_slice_rejects_visible_unverified_target_without_upgrading_it(self) -> None:
        package_path = self.root / "content/sources/radhakunda-manifestation-puranic-unit/package.yaml"
        package = package_path.read_text(encoding="utf-8").replace(
            "verification_status: VERIFIED", "verification_status: TRANSCRIPTION_COLLATED", 1
        )
        package_path.write_text(package, encoding="utf-8")
        checksum_path = self.root / "content/manifests/SHA256SUMS.json"
        checksum = json.loads(checksum_path.read_text(encoding="utf-8"))
        checksum["radhakunda-manifestation-puranic-unit.yaml"] = hashlib.sha256(package_path.read_bytes()).hexdigest()
        checksum_path.write_text(json.dumps(checksum, indent=2) + "\n", encoding="utf-8")
        with self.assertRaisesRegex(ContentValidationError, "Visible unverified citation targets"):
            compile_manifest(self.root, "radhakunda-mvp-development-manifest")


if __name__ == "__main__":
    unittest.main()
