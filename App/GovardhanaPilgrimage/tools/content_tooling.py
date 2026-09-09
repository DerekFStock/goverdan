"""Task 001/002 content validation and deterministic compilation."""

from __future__ import annotations

import json
import hashlib
import math
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


class ContentValidationError(ValueError):
    """Raised when authored content violates the Task 001 contract."""


@dataclass(frozen=True)
class BuildResult:
    content: dict[str, Any]
    report: dict[str, Any]


BLOCK_PATTERN = re.compile(
    r"<!--\s*content-block-id:\s*([^;\s]+)(?:\s*;\s*type:\s*([a-z_]+))?\s*-->"
)
APPROVED_BLOCK_TYPES = {"heading", "paragraph", "quotation", "verse"}
CITATION_PATTERN = re.compile(r"\[\[cite:([^\]]+)\]\]")
REAL_CITATION_PATTERN = re.compile(r"\[\[(?:cite|cite-group):[^\]]+\]\]")
PILGRIMAGE_COORDINATE_STATUSES = {"UNVERIFIED", "PROVISIONAL", "PROBABLE", "VERIFIED"}
PILGRIMAGE_COORDINATE_CONFIDENCE = {"UNKNOWN", "LOW", "MEDIUM", "HIGH"}


def normalize(value: Any) -> Any:
    """Recursively normalize all authored strings to Unicode NFC."""
    if isinstance(value, str):
        return unicodedata.normalize("NFC", value)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {normalize(key): normalize(item) for key, item in value.items()}
    return value


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ContentValidationError(f"Cannot load JSON {path}: {error}") from error
    if not isinstance(value, dict):
        raise ContentValidationError(f"Expected a JSON object in {path}")
    return normalize(value)


def load_yaml(path: Path) -> dict[str, Any]:
    try:
        value = yaml.safe_load(path.read_text(encoding="utf-8"))
    except (OSError, yaml.YAMLError) as error:
        raise ContentValidationError(f"Cannot load YAML {path}: {error}") from error
    if not isinstance(value, dict):
        raise ContentValidationError(f"Expected a YAML object in {path}")
    return normalize(value)


def _front_matter_value(raw: str) -> Any:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1]
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    if value.lower() in {"true", "false"}:
        return value.lower() == "true"
    return value


def parse_front_matter(text: str, path: Path) -> tuple[dict[str, Any], str]:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ContentValidationError(f"Missing YAML front matter in {path}")
    try:
        end = next(index for index, line in enumerate(lines[1:], 1) if line.strip() == "---")
    except StopIteration as error:
        raise ContentValidationError(f"Unclosed YAML front matter in {path}") from error
    metadata: dict[str, Any] = {}
    for line_number, line in enumerate(lines[1:end], 2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise ContentValidationError(f"Invalid front matter at {path}:{line_number}")
        key, raw_value = line.split(":", 1)
        key = key.strip()
        if not key or key in metadata:
            raise ContentValidationError(f"Invalid or duplicate front matter key at {path}:{line_number}")
        metadata[key] = _front_matter_value(raw_value)
    return normalize(metadata), normalize("\n".join(lines[end + 1 :]).strip())


def parse_citation(raw: str, block_id: str, path: Path) -> dict[str, Any]:
    fields: dict[str, str] = {}
    for component in raw.split(";"):
        if "=" not in component:
            raise ContentValidationError(f"Invalid Citation directive in {path}: {raw}")
        key, value = (part.strip() for part in component.split("=", 1))
        if not key or not value or key in fields:
            raise ContentValidationError(f"Invalid Citation directive in {path}: {raw}")
        fields[key] = value
    required = {"id", "passage", "role"}
    missing = sorted(required - fields.keys())
    if missing:
        raise ContentValidationError(f"Citation in {path} is missing: {', '.join(missing)}")
    return {
        "id": fields["id"],
        "content_block_id": block_id,
        "source_passage_id": fields["passage"],
        "role": fields["role"],
    }


def load_story(path: Path) -> dict[str, Any]:
    metadata, body = parse_front_matter(path.read_text(encoding="utf-8"), path)
    required = {
        "story_id",
        "story_title",
        "section_id",
        "section_title",
        "section_order",
        "status",
    }
    missing = sorted(required - metadata.keys())
    if missing:
        raise ContentValidationError(f"Story {path} is missing front matter: {', '.join(missing)}")

    matches = list(BLOCK_PATTERN.finditer(body))
    if not matches:
        raise ContentValidationError(f"Story {path} has no Content Blocks")
    blocks: list[dict[str, Any]] = []
    citations: list[dict[str, Any]] = []
    for order, match in enumerate(matches, 1):
        end = matches[order].start() if order < len(matches) else len(body)
        block_text = body[match.end() : end].strip()
        block_id = match.group(1)
        block_type = match.group(2) or "paragraph"
        if block_type not in APPROVED_BLOCK_TYPES:
            raise ContentValidationError(f"Content Block '{block_id}' has unsupported type '{block_type}'")
        block_citations = [parse_citation(raw, block_id, path) for raw in CITATION_PATTERN.findall(block_text)]
        citations.extend(block_citations)
        rendered_text = CITATION_PATTERN.sub("", block_text).strip()
        blocks.append(
            {
                "id": block_id,
                "section_id": metadata["section_id"],
                "order": order,
                "block_type": block_type,
                "text": rendered_text,
            }
        )

    return {
        "story": {"id": metadata["story_id"], "title": metadata["story_title"], "status": metadata["status"]},
        "section": {
            "id": metadata["section_id"],
            "story_id": metadata["story_id"],
            "title": metadata["section_title"],
            "order": metadata["section_order"],
        },
        "blocks": blocks,
        "citations": citations,
    }


def _require_fields(entity: dict[str, Any], fields: set[str], label: str) -> None:
    missing = sorted(fields - entity.keys())
    if missing:
        raise ContentValidationError(f"{label} is missing fields: {', '.join(missing)}")


def _check_unique(entities: list[dict[str, Any]]) -> None:
    seen: dict[str, str] = {}
    for entity in entities:
        entity_id = entity.get("id")
        if not isinstance(entity_id, str) or not entity_id:
            raise ContentValidationError("Every durable entity must have a non-empty string ID")
        entity_type = entity["entity_type"]
        if entity_id in seen:
            raise ContentValidationError(f"Duplicate ID '{entity_id}' ({seen[entity_id]} and {entity_type})")
        seen[entity_id] = entity_type


def _typed(entity_type: str, values: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [{"entity_type": entity_type, **value} for value in values]


def validate_pilgrimage_places(document: dict[str, Any], label: str) -> list[dict[str, Any]]:
    """Validate durable pilgrimage identity separately from geographic basemap data."""
    _require_fields(document, {"schema_version", "registry", "places"}, label)
    places = document["places"]
    if not isinstance(places, list):
        raise ContentValidationError(f"{label} places must be a list")
    seen_ids: set[str] = set()
    seen_numbers: set[int] = set()
    seen_names: set[str] = set()
    for place in places:
        if not isinstance(place, dict):
            raise ContentValidationError(f"{label} contains a non-object place record")
        _require_fields(
            place,
            {
                "id", "map_number", "canonical_name", "alternate_names",
                "coordinate_status", "coordinate_confidence", "verification_notes", "provenance",
                "content_destination",
            },
            f"Pilgrimage Place {place.get('id', '<unknown>')}",
        )
        place_id = place["id"]
        map_number = place["map_number"]
        canonical_name = place["canonical_name"]
        if not isinstance(place_id, str) or not place_id:
            raise ContentValidationError("Pilgrimage Place ID must be a non-empty string")
        if place_id in seen_ids:
            raise ContentValidationError(f"Duplicate Pilgrimage Place ID: {place_id}")
        seen_ids.add(place_id)
        if not isinstance(map_number, int) or isinstance(map_number, bool) or map_number < 1:
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid map_number")
        if map_number in seen_numbers:
            raise ContentValidationError(f"Duplicate Pilgrimage Place map_number: {map_number}")
        seen_numbers.add(map_number)
        if not isinstance(canonical_name, str) or not canonical_name.strip():
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has an empty canonical_name")
        normalized_name = canonical_name.casefold()
        if normalized_name in seen_names:
            raise ContentValidationError(f"Duplicate Pilgrimage Place canonical_name: {canonical_name}")
        seen_names.add(normalized_name)
        latitude, longitude = place.get("latitude"), place.get("longitude")
        if (latitude is None) != (longitude is None):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has a half-coordinate")
        if latitude is not None and (
            not isinstance(latitude, (int, float)) or isinstance(latitude, bool)
            or not math.isfinite(latitude) or not -90 <= latitude <= 90
        ):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid latitude")
        if longitude is not None and (
            not isinstance(longitude, (int, float)) or isinstance(longitude, bool)
            or not math.isfinite(longitude) or not -180 <= longitude <= 180
        ):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid longitude")
        if place["coordinate_status"] not in PILGRIMAGE_COORDINATE_STATUSES:
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid coordinate_status")
        if place["coordinate_confidence"] not in PILGRIMAGE_COORDINATE_CONFIDENCE:
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid coordinate_confidence")
        if latitude is None and place["coordinate_status"] != "UNVERIFIED":
            raise ContentValidationError(
                f"Coordinate-less Pilgrimage Place '{place_id}' must have coordinate_status UNVERIFIED"
            )
        accuracy = place.get("coordinate_accuracy_meters")
        if accuracy is not None and (
            not isinstance(accuracy, (int, float)) or isinstance(accuracy, bool) or accuracy <= 0
        ):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid coordinate_accuracy_meters")
        aliases = place["alternate_names"]
        if not isinstance(aliases, list) or any(not isinstance(alias, str) or not alias.strip() for alias in aliases):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has malformed alternate_names")
        if len({alias.casefold() for alias in aliases}) != len(aliases):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has duplicate alternate_names")
        provenance = place["provenance"]
        if not isinstance(provenance, list) or not provenance:
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' requires coordinate provenance")
        for evidence in provenance:
            if not isinstance(evidence, dict) or not all(
                isinstance(evidence.get(key), str) and evidence[key].strip()
                for key in ("source_type", "description")
            ):
                raise ContentValidationError(f"Pilgrimage Place '{place_id}' has malformed provenance")
        destination = place["content_destination"]
        if destination is not None and (
            not isinstance(destination, dict)
            or destination.get("kind") not in {"STORY_SECTION", "SOURCE_PASSAGE"}
            or not isinstance(destination.get("id"), str)
            or not destination["id"]
        ):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid content_destination")
        anchor_id = place.get("navigation_anchor_place_id")
        if anchor_id is not None and (not isinstance(anchor_id, str) or not anchor_id):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid navigation_anchor_place_id")
        guidance = place.get("location_guidance")
        if guidance is not None and (not isinstance(guidance, str) or not guidance.strip()):
            raise ContentValidationError(f"Pilgrimage Place '{place_id}' has invalid location_guidance")
    places_by_id = {place["id"]: place for place in places}
    for place in places:
        anchor_id = place.get("navigation_anchor_place_id")
        if anchor_id is None:
            continue
        if anchor_id == place["id"]:
            raise ContentValidationError(f"Pilgrimage Place '{place['id']}' cannot use itself as navigation anchor")
        anchor = places_by_id.get(anchor_id)
        if anchor is None:
            raise ContentValidationError(
                f"Pilgrimage Place '{place['id']}' references missing navigation anchor '{anchor_id}'"
            )
        if anchor.get("latitude") is None or anchor.get("longitude") is None:
            raise ContentValidationError(
                f"Pilgrimage Place '{place['id']}' navigation anchor '{anchor_id}' has no coordinate"
            )
    return places


def validate_pilgrimage_place_contents(document: dict[str, Any], label: str) -> list[dict[str, Any]]:
    """Validate pilgrim-facing prose separately from geographic registry records."""
    _require_fields(document, {"schema_version", "contents"}, label)
    contents = document["contents"]
    if not isinstance(contents, list):
        raise ContentValidationError(f"{label} contents must be a list")
    seen_places: set[str] = set()
    seen_references: set[str] = set()
    for content in contents:
        if not isinstance(content, dict):
            raise ContentValidationError(f"{label} contains a non-object content record")
        _require_fields(
            content,
            {
                "place_id", "summary", "why_sacred", "what_to_see", "lila",
                "pilgrim_guidance", "references", "related_place_ids",
            },
            "Pilgrimage Place Content",
        )
        place_id = content["place_id"]
        if not isinstance(place_id, str) or not place_id:
            raise ContentValidationError("Pilgrimage Place Content place_id must be a non-empty string")
        if place_id in seen_places:
            raise ContentValidationError(f"Duplicate Pilgrimage Place Content: {place_id}")
        seen_places.add(place_id)
        for field in ("summary", "why_sacred", "lila", "pilgrim_guidance"):
            if not isinstance(content[field], str) or not content[field].strip():
                raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has invalid {field}")
        category = content.get("category")
        if category is not None and (not isinstance(category, str) or not category.strip()):
            raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has invalid category")
        features = content["what_to_see"]
        if not isinstance(features, list) or not features or any(
            not isinstance(feature, str) or not feature.strip() for feature in features
        ):
            raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has invalid what_to_see")
        related = content["related_place_ids"]
        if not isinstance(related, list) or any(not isinstance(item, str) or not item for item in related):
            raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has invalid related_place_ids")
        if place_id in related or len(set(related)) != len(related):
            raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has invalid related-place relationship")
        references = content["references"]
        if not isinstance(references, list):
            raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has invalid references")
        for reference in references:
            if not isinstance(reference, dict):
                raise ContentValidationError(f"Pilgrimage Place Content '{place_id}' has malformed reference")
            _require_fields(reference, {"id", "source_title", "explanation"}, "Pilgrimage Place Reference")
            reference_id = reference["id"]
            if not isinstance(reference_id, str) or not reference_id or reference_id in seen_references:
                raise ContentValidationError(f"Duplicate or invalid Pilgrimage Place Reference ID: {reference_id}")
            seen_references.add(reference_id)
            for field in ("source_title", "explanation"):
                if not isinstance(reference[field], str) or not reference[field].strip():
                    raise ContentValidationError(f"Pilgrimage Place Reference '{reference_id}' has invalid {field}")
            for field in ("locus", "quotation"):
                value = reference.get(field)
                if value is not None and (not isinstance(value, str) or not value.strip()):
                    raise ContentValidationError(f"Pilgrimage Place Reference '{reference_id}' has invalid {field}")
            destination = reference.get("destination")
            if destination is not None and (
                not isinstance(destination, dict)
                or destination.get("kind") not in {"STORY_SECTION", "SOURCE_PASSAGE"}
                or not isinstance(destination.get("id"), str)
                or not destination["id"]
            ):
                raise ContentValidationError(f"Pilgrimage Place Reference '{reference_id}' has invalid destination")
    return contents


def compile_manifest(root: Path, manifest_name: str) -> BuildResult:
    real_manifest_path = root / "content" / "manifests" / f"{manifest_name}.yaml"
    if real_manifest_path.exists():
        return compile_development_manifest(root, real_manifest_path)
    manifest_path = root / "content" / "manifests" / f"{manifest_name}.json"
    manifest = load_json(manifest_path)
    _require_fields(manifest, {"id", "schema_version", "story_files", "source_files"}, "Manifest")

    stories = [load_story(root / path) for path in manifest["story_files"]]
    sources = [load_json(root / path) for path in manifest["source_files"]]
    if not stories or not sources:
        raise ContentValidationError("Manifest must contain at least one Story and one Source package")

    story_entities = [item["story"] for item in stories]
    sections = [item["section"] for item in stories]
    blocks = [block for item in stories for block in item["blocks"]]
    citations = [citation for item in stories for citation in item["citations"]]
    works = [item["work"] for item in sources]
    editions = [item["edition"] for item in sources]
    passages = [passage for item in sources for passage in item.get("passages", [])]
    representations = [rep for item in sources for rep in item.get("representations", [])]
    witnesses = [witness for item in sources for witness in item.get("witnesses", [])]
    witness_mappings = [mapping for item in sources for mapping in item.get("witness_mappings", [])]
    pilgrimage_places: list[dict[str, Any]] = []

    for work in works:
        _require_fields(work, {"id", "title"}, f"Work {work.get('id', '<unknown>')}")
    for edition in editions:
        _require_fields(edition, {"id", "work_id", "title"}, f"Edition {edition.get('id', '<unknown>')}")
    for passage in passages:
        _require_fields(passage, {"id", "work_id", "locus", "order"}, f"Passage {passage.get('id', '<unknown>')}")
        forbidden = {"text", "original_text", "transliteration", "translation"} & passage.keys()
        if forbidden:
            raise ContentValidationError(
                f"Canonical Passage '{passage['id']}' contains edition-owned fields: {', '.join(sorted(forbidden))}"
            )
    for representation in representations:
        _require_fields(
            representation,
            {"id", "passage_id", "edition_id", "text"},
            f"Passage Representation {representation.get('id', '<unknown>')}",
        )
    for witness in witnesses:
        _require_fields(
            witness, {"id", "work_id", "title", "file_path", "media_type", "page_count"},
            f"Witness {witness.get('id', '<unknown>')}",
        )
    for mapping in witness_mappings:
        _require_fields(
            mapping, {"id", "witness_id", "passage_id", "pdf_page_index"},
            f"Witness Mapping {mapping.get('id', '<unknown>')}",
        )

    all_entities = (
        _typed("story", story_entities)
        + _typed("story_section", sections)
        + _typed("content_block", blocks)
        + _typed("citation", citations)
        + _typed("work", works)
        + _typed("edition", editions)
        + _typed("passage", passages)
        + _typed("passage_representation", representations)
        + _typed("witness", witnesses)
        + _typed("witness_mapping", witness_mappings)
        + _typed("pilgrimage_place", pilgrimage_places)
    )
    _check_unique(all_entities)

    story_ids = {item["id"] for item in story_entities}
    section_ids = {item["id"] for item in sections}
    block_ids = {item["id"] for item in blocks}
    work_ids = {item["id"] for item in works}
    edition_by_id = {item["id"]: item for item in editions}
    passage_by_id = {item["id"]: item for item in passages}
    representation_by_id = {item["id"]: item for item in representations}
    witness_by_id = {item["id"]: item for item in witnesses}

    for section in sections:
        if section["story_id"] not in story_ids:
            raise ContentValidationError(f"Story Section '{section['id']}' references missing Story '{section['story_id']}'")
    for block in blocks:
        if block["section_id"] not in section_ids:
            raise ContentValidationError(f"Content Block '{block['id']}' references missing Section '{block['section_id']}'")
    for work in works:
        parent = work.get("parent_work_id")
        if parent is not None and parent not in work_ids:
            raise ContentValidationError(f"Work '{work['id']}' references missing parent Work '{parent}'")
    for edition in editions:
        if edition["work_id"] not in work_ids:
            raise ContentValidationError(f"Edition '{edition['id']}' references missing Work '{edition['work_id']}'")
    for passage in passages:
        if passage["work_id"] not in work_ids:
            raise ContentValidationError(f"Passage '{passage['id']}' references missing Work '{passage['work_id']}'")
        parent = passage.get("parent_passage_id")
        if parent is not None and parent not in passage_by_id:
            raise ContentValidationError(f"Passage '{passage['id']}' references missing parent Passage '{parent}'")
    for representation in representations:
        passage = passage_by_id.get(representation["passage_id"])
        edition = edition_by_id.get(representation["edition_id"])
        if passage is None:
            raise ContentValidationError(
                f"Passage Representation '{representation['id']}' references missing Passage '{representation['passage_id']}'"
            )
        if edition is None:
            raise ContentValidationError(
                f"Passage Representation '{representation['id']}' references missing Edition '{representation['edition_id']}'"
            )
        if passage["work_id"] != edition["work_id"]:
            raise ContentValidationError(
                f"Passage Representation '{representation['id']}' links Passage and Edition from different Works"
            )
    for citation in citations:
        if citation["content_block_id"] not in block_ids:
            raise ContentValidationError(f"Citation '{citation['id']}' references missing Content Block")
        if citation["source_passage_id"] not in passage_by_id:
            raise ContentValidationError(
                f"Citation '{citation['id']}' references missing canonical Passage '{citation['source_passage_id']}'"
            )
    for witness in witnesses:
        if witness["work_id"] not in work_ids:
            raise ContentValidationError(f"Witness '{witness['id']}' references missing Work")
        if witness.get("edition_id") not in {None, *edition_by_id.keys()}:
            raise ContentValidationError(f"Witness '{witness['id']}' references missing Edition")
        if witness["media_type"] != "application/pdf" or witness["page_count"] < 1:
            raise ContentValidationError(f"Witness '{witness['id']}' has invalid PDF metadata")
    for mapping in witness_mappings:
        witness = witness_by_id.get(mapping["witness_id"])
        passage = passage_by_id.get(mapping["passage_id"])
        if witness is None or passage is None:
            raise ContentValidationError(f"Witness Mapping '{mapping['id']}' has a missing target")
        if passage["work_id"] != witness["work_id"]:
            raise ContentValidationError(f"Witness Mapping '{mapping['id']}' crosses Works")
        representation_id = mapping.get("representation_id")
        if representation_id is not None and representation_id not in representation_by_id:
            raise ContentValidationError(f"Witness Mapping '{mapping['id']}' references missing Representation")
        if not 0 <= mapping["pdf_page_index"] < witness["page_count"]:
            raise ContentValidationError(f"Witness Mapping '{mapping['id']}' has an out-of-range PDF page index")

    content = {
        "schema_version": 1,
        "manifest_id": manifest["id"],
        "stories": sorted(story_entities, key=lambda item: item["id"]),
        "story_sections": sorted(sections, key=lambda item: item["id"]),
        "content_blocks": sorted(blocks, key=lambda item: item["id"]),
        "citations": sorted(citations, key=lambda item: item["id"]),
        "works": sorted(works, key=lambda item: (item.get("parent_work_id") is not None, item["id"])),
        "editions": sorted(editions, key=lambda item: item["id"]),
        "passages": sorted(passages, key=lambda item: item["id"]),
        "passage_representations": sorted(representations, key=lambda item: item["id"]),
        "witnesses": sorted(witnesses, key=lambda item: item["id"]),
        "witness_mappings": sorted(witness_mappings, key=lambda item: item["id"]),
        "pilgrimage_places": pilgrimage_places,
    }
    counts = {key: len(value) for key, value in content.items() if isinstance(value, list)}
    report = {
        "schema_version": 1,
        "manifest_id": manifest["id"],
        "status": "success",
        "counts": counts,
        "validation": {
            "citation_targets_resolve": True,
            "ids_unique": True,
            "parent_references_resolve": True,
            "passages_are_edition_independent": True,
            "unicode_normalization": "NFC",
            "work_edition_passage_relationships_resolve": True,
        },
    }
    return BuildResult(content=content, report=report)


def compile_development_manifest(root: Path, manifest_path: Path) -> BuildResult:
    """Compile the authorized compact YAML development package without altering authored content."""
    manifest = load_yaml(manifest_path)
    content_root = root / "content"
    registry = load_yaml(content_root / "sources" / "registry.yaml")
    story_metadata = load_yaml(content_root / "stories" / "radhakunda" / "story.yaml")
    citation_map = load_yaml(content_root / "metadata" / "radhakunda-manifestation-citation-map.yaml")
    story_path = content_root / "stories" / "radhakunda" / "03-manifestation.md"
    for item in manifest["compile_sequence"]:
        target = root / item["target_path"]
        if not target.exists():
            raise ContentValidationError(f"Development manifest target is missing: {item['target_path']}")

    source_entries = [
        item for item in manifest["compile_sequence"] if item.get("role") == "SOURCE_PACKAGE"
    ]
    pilgrimage_entries = [
        item for item in manifest["compile_sequence"] if item.get("role") == "PILGRIMAGE_PLACE_REGISTRY"
    ]
    pilgrimage_content_entries = [
        item for item in manifest["compile_sequence"] if item.get("role") == "PILGRIMAGE_PLACE_CONTENT"
    ]
    if len(pilgrimage_entries) != 1:
        raise ContentValidationError("Development manifest must declare exactly one PILGRIMAGE_PLACE_REGISTRY")
    pilgrimage_entry = pilgrimage_entries[0]
    if pilgrimage_entry.get("required") is not True or pilgrimage_entry.get("development_eligible") is not True:
        raise ContentValidationError("PILGRIMAGE_PLACE_REGISTRY must be required and development eligible")
    pilgrimage_places = validate_pilgrimage_places(
        load_yaml(root / pilgrimage_entry["target_path"]), "Pilgrimage Place Registry"
    )
    if len(pilgrimage_content_entries) != 1:
        raise ContentValidationError("Development manifest must declare exactly one PILGRIMAGE_PLACE_CONTENT")
    pilgrimage_content_entry = pilgrimage_content_entries[0]
    if pilgrimage_content_entry.get("required") is not True or pilgrimage_content_entry.get("development_eligible") is not True:
        raise ContentValidationError("PILGRIMAGE_PLACE_CONTENT must be required and development eligible")
    pilgrimage_place_contents = validate_pilgrimage_place_contents(
        load_yaml(root / pilgrimage_content_entry["target_path"]), "Pilgrimage Place Content"
    )
    declared_work_ids = [item.get("work_id") for item in source_entries]
    duplicate_work_ids = sorted(
        {work_id for work_id in declared_work_ids if declared_work_ids.count(work_id) > 1}
    )
    if duplicate_work_ids:
        raise ContentValidationError(
            f"Duplicate SOURCE_PACKAGE Work declaration: {', '.join(duplicate_work_ids)}"
        )
    packages: list[dict[str, Any]] = []
    for item in source_entries:
        work_id = item.get("work_id")
        if not isinstance(work_id, str) or not work_id:
            raise ContentValidationError("SOURCE_PACKAGE manifest entry is missing work_id")
        if item.get("required") is not True:
            raise ContentValidationError(f"SOURCE_PACKAGE '{work_id}' must be required")
        if item.get("development_eligible") is not True:
            raise ContentValidationError(f"SOURCE_PACKAGE '{work_id}' is not development eligible")
        package = load_yaml(root / item["target_path"])
        package_work = package.get("work")
        if not isinstance(package_work, dict) or package_work.get("id") != work_id:
            actual = package_work.get("id") if isinstance(package_work, dict) else None
            raise ContentValidationError(
                f"SOURCE_PACKAGE work_id mismatch: manifest '{work_id}', package '{actual}'"
            )
        packages.append(package)

    checksum_path = content_root / "manifests" / "SHA256SUMS.json"
    checksums = load_json(checksum_path)
    installed_by_source_name = {
        item["file"]: root / item["target_path"]
        for item in manifest["compile_sequence"] + manifest["non_runtime_assets"]
    }
    installed_by_source_name[manifest_path.name] = manifest_path
    for filename, expected in checksums.items():
        path = installed_by_source_name.get(filename)
        if path is None or not path.exists():
            raise ContentValidationError(f"Checksum target is missing: {filename}")
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != expected:
            raise ContentValidationError(f"Checksum mismatch: {filename}")

    authored_paths = [manifest_path, story_path, checksum_path]
    authored_paths += [root / item["target_path"] for item in manifest["compile_sequence"]]
    authored_paths += [path for path in content_root.rglob("PROVENANCE.md")]
    for path in set(authored_paths):
        if path.suffix.lower() in {".yaml", ".md", ".json"}:
            text = path.read_text(encoding="utf-8")
            if not unicodedata.is_normalized("NFC", text):
                raise ContentValidationError(f"Authored file is not Unicode NFC: {path.relative_to(root)}")

    story = story_metadata["story"]
    section_metadata = story_metadata["sections"][0]
    front_matter, body = parse_front_matter(story_path.read_text(encoding="utf-8"), story_path)
    if front_matter["id"] != section_metadata["id"] or section_metadata["id"] != citation_map["story_section"]["id"]:
        raise ContentValidationError("Story metadata, Markdown, and citation sidecar Section IDs disagree")
    matches = list(BLOCK_PATTERN.finditer(body))
    blocks: list[dict[str, Any]] = []
    for order, match in enumerate(matches, 1):
        end = matches[order].start() if order < len(matches) else len(body)
        text = body[match.end():end].strip()
        text = re.sub(r"^#.*$", "", text, count=1, flags=re.MULTILINE).strip()
        text = REAL_CITATION_PATTERN.sub("", text).strip()
        blocks.append(
            {
                "id": match.group(1),
                "section_id": section_metadata["id"],
                "order": order,
                "block_type": "paragraph",
                "text": text,
            }
        )
    expected_blocks = [item["id"] for item in citation_map["block_anchors"]]
    if [item["id"] for item in blocks] != expected_blocks:
        raise ContentValidationError("Story Markdown Content Block IDs do not match the citation sidecar")

    packaged_work_ids = set(manifest["runtime_contract"]["expected_packaged_work_ids"])
    registry_works = {item["id"]: item for item in registry["works"]}
    package_by_work = {item["work"]["id"]: item for item in packages}
    if set(declared_work_ids) != packaged_work_ids:
        raise ContentValidationError("Development manifest packaged Work IDs disagree with SOURCE_PACKAGE declarations")
    if set(package_by_work) != packaged_work_ids:
        raise ContentValidationError("Development manifest packaged Work IDs do not match installed packages")
    for package in packages:
        package_work = package["work"]
        work_id = package_work["id"]
        registered = registry_works.get(work_id)
        if registered is None:
            raise ContentValidationError(f"SOURCE_PACKAGE Work is missing from source registry: {work_id}")
        compared_fields = ("title", "parent_work_id", "source_layer", "status")
        disagreements = [field for field in compared_fields if package_work.get(field) != registered.get(field)]
        if disagreements:
            raise ContentValidationError(
                f"Source registry/package disagreement for '{work_id}': {', '.join(disagreements)}"
            )
        if registered.get("registry_role") != "PACKAGED_WORK":
            raise ContentValidationError(f"Source registry does not mark '{work_id}' as a PACKAGED_WORK")
        if registered.get("development_eligible") is not True:
            raise ContentValidationError(f"Source registry Work is not development eligible: {work_id}")
        expected_package_path = (content_root / "sources" / registered["package_file"]).resolve()
        manifest_entry = next(item for item in source_entries if item["work_id"] == work_id)
        actual_package_path = (root / manifest_entry["target_path"]).resolve()
        if actual_package_path != expected_package_path:
            raise ContentValidationError(f"Source registry/package path disagreement for '{work_id}'")
        if registered.get("preferred_reading_edition") != package.get("edition", {}).get("id"):
            raise ContentValidationError(f"Source registry/package preferred Edition disagreement for '{work_id}'")

    works: list[dict[str, Any]] = []
    parent_ids = {pkg["work"].get("parent_work_id") for pkg in packages} - {None}
    for work_id in sorted(packaged_work_ids | parent_ids):
        authored = package_by_work.get(work_id, {}).get("work", registry_works[work_id])
        works.append(
            {
                "id": authored["id"],
                "parent_work_id": authored.get("parent_work_id"),
                "title": authored["title"],
                "status": authored["status"],
                "author": authored.get("author"),
                "source_layer": authored.get("source_layer"),
            }
        )

    editions: list[dict[str, Any]] = []
    passages: list[dict[str, Any]] = []
    representations: list[dict[str, Any]] = []
    passage_by_id: dict[str, dict[str, Any]] = {}
    for package in packages:
        work = package["work"]
        edition = package["edition"]
        translation_provenance = edition.get("translation_provenance")
        text_provenance = edition.get("text_provenance")
        editions.append(
            {
                "id": edition["id"],
                "work_id": work["id"],
                "title": edition["title"],
                "status": edition["status"],
                "translator": translation_provenance.get("translator") if isinstance(translation_provenance, dict) else None,
                "translation_provenance": json.dumps(translation_provenance, ensure_ascii=False, sort_keys=True),
                "normalization_provenance": json.dumps(text_provenance, ensure_ascii=False, sort_keys=True),
                "preferred": bool(edition.get("preferred")),
            }
        )
        edition_key = edition["id"].split(".", 2)[-1]
        for authored in package["passages"]:
            passage = {
                "id": authored["id"],
                "work_id": work["id"],
                "locus": str(authored["locus"]),
                "display_locus": authored.get("display_locus"),
                "order": authored["order"],
                "parent_passage_id": authored.get("parent_passage_id"),
                "verification_status": authored.get("verification_status"),
            }
            passages.append(passage)
            passage_by_id[passage["id"]] = passage
            representation_text = "\n\n".join(
                value for key in ("original_text", "original", "transliteration", "translation")
                if isinstance((value := authored.get(key)), str) and value
            )
            suffix = passage["id"].removeprefix("passage.")
            source_notes = {
                key: authored[key]
                for key in ("reading_note", "translation_note", "translation_status", "source_notes", "rupa_attribution")
                if key in authored
            }
            representations.append(
                {
                    "id": f"representation.{suffix}.{edition_key}",
                    "passage_id": passage["id"],
                    "edition_id": edition["id"],
                    "text": representation_text,
                    "original_text": authored.get("original_text") or authored.get("original"),
                    "transliteration": authored.get("transliteration"),
                    "translation": authored.get("translation"),
                    "commentary": authored.get("commentary"),
                    "source_notes": source_notes or None,
                    "search_text": representation_text,
                }
            )

    citations: list[dict[str, Any]] = []
    broken_targets: list[str] = []
    visible_unverified: set[str] = set()
    for authored in citation_map["citations"]:
        source_id = authored.get("sourcePassageId")
        start_id = authored.get("startPassageId")
        end_id = authored.get("endPassageId")
        is_singleton = source_id is not None and start_id is None and end_id is None
        is_range = source_id is None and start_id is not None and end_id is not None
        if not (is_singleton or is_range):
            raise ContentValidationError(
                f"Citation '{authored['id']}' must contain sourcePassageId or both range endpoints"
            )
        target_ids = [source_id] if is_singleton else [start_id, end_id]
        broken_targets.extend(target for target in target_ids if target not in passage_by_id)
        if is_range and start_id in passage_by_id and end_id in passage_by_id:
            start = passage_by_id[start_id]
            end = passage_by_id[end_id]
            if start["work_id"] != end["work_id"] or start["order"] > end["order"]:
                raise ContentValidationError(f"Citation '{authored['id']}' has an invalid canonical Passage range")
            target_ids = [
                passage["id"] for passage in passages
                if passage["work_id"] == start["work_id"] and start["order"] <= passage["order"] <= end["order"]
            ]
        visible_unverified.update(
            target for target in target_ids
            if target in passage_by_id and passage_by_id[target].get("verification_status") not in {"VERIFIED", "APP_READY"}
        )
        citations.append(
            {
                "id": authored["id"],
                "content_block_id": authored["contentBlockId"],
                "source_passage_id": source_id,
                "start_passage_id": start_id,
                "end_passage_id": end_id,
                "role": authored["citationRole"],
                "order": authored.get("order", 1),
            }
        )
    if broken_targets:
        raise ContentValidationError(f"Broken citation targets: {', '.join(broken_targets)}")
    if visible_unverified:
        raise ContentValidationError(f"Visible unverified citation targets: {', '.join(sorted(visible_unverified))}")

    story_entities = [{"id": story["id"], "title": story["title"], "status": story["status"]}]
    sections = [
        {
            "id": section_metadata["id"],
            "story_id": story["id"],
            "part_id": None,
            "title": section_metadata["title"],
            "order": section_metadata["order"],
        }
    ]
    all_entities = (
        _typed("story", story_entities) + _typed("story_section", sections) + _typed("content_block", blocks)
        + _typed("citation", citations) + _typed("work", works) + _typed("edition", editions)
        + _typed("passage", passages) + _typed("passage_representation", representations)
        + _typed("pilgrimage_place", pilgrimage_places)
    )
    _check_unique(all_entities)
    block_ids = {item["id"] for item in blocks}
    if any(item["content_block_id"] not in block_ids for item in citations):
        raise ContentValidationError("Citation sidecar references a missing Story Content Block")
    for place in pilgrimage_places:
        destination = place.get("content_destination")
        if destination and destination["kind"] == "STORY_SECTION" and destination["id"] not in {
            item["id"] for item in sections
        }:
            raise ContentValidationError(f"Pilgrimage Place '{place['id']}' references a missing Story Section")
        if destination and destination["kind"] == "SOURCE_PASSAGE" and destination["id"] not in passage_by_id:
            raise ContentValidationError(f"Pilgrimage Place '{place['id']}' references a missing Source Passage")

    place_ids = {item["id"] for item in pilgrimage_places}
    content_place_ids = {item["place_id"] for item in pilgrimage_place_contents}
    missing_content_places = sorted(content_place_ids - place_ids)
    if missing_content_places:
        raise ContentValidationError(
            f"Pilgrimage Place Content references missing Places: {', '.join(missing_content_places)}"
        )
    for item in pilgrimage_place_contents:
        missing_related = sorted(set(item["related_place_ids"]) - place_ids)
        if missing_related:
            raise ContentValidationError(
                f"Pilgrimage Place Content '{item['place_id']}' references missing related Places: {', '.join(missing_related)}"
            )
        for reference in item["references"]:
            destination = reference.get("destination")
            if destination and destination["kind"] == "STORY_SECTION" and destination["id"] not in {
                section["id"] for section in sections
            }:
                raise ContentValidationError(
                    f"Pilgrimage Place Reference '{reference['id']}' references a missing Story Section"
                )
            if destination and destination["kind"] == "SOURCE_PASSAGE" and destination["id"] not in passage_by_id:
                raise ContentValidationError(
                    f"Pilgrimage Place Reference '{reference['id']}' references a missing Source Passage"
                )

    content = {
        "schema_version": 1,
        "manifest_id": manifest["manifest"]["id"],
        "stories": story_entities,
        "story_sections": sections,
        "content_blocks": sorted(blocks, key=lambda item: item["order"]),
        "citations": sorted(citations, key=lambda item: item["id"]),
        "works": sorted(works, key=lambda item: (item.get("parent_work_id") is not None, item["id"])),
        "editions": sorted(editions, key=lambda item: item["id"]),
        "passages": sorted(passages, key=lambda item: item["id"]),
        "passage_representations": sorted(representations, key=lambda item: item["id"]),
        "witnesses": [],
        "witness_mappings": [],
        "pilgrimage_places": sorted(pilgrimage_places, key=lambda item: item["map_number"]),
        "pilgrimage_place_contents": sorted(pilgrimage_place_contents, key=lambda item: item["place_id"]),
    }
    counts = {key: len(value) for key, value in content.items() if isinstance(value, list)}
    report = {
        "schema_version": 1,
        "manifest_id": manifest["manifest"]["id"],
        "status": "success",
        "counts": counts,
        "validation": {
            "broken_citation_targets": 0,
            "visible_unverified_citation_targets": 0,
            "duplicate_canonical_ids": 0,
            "citation_targets_resolve": True,
            "ids_unique": True,
            "passages_are_edition_independent": True,
            "unicode_normalization": "NFC",
            "compact_authoring_split": True,
        },
    }
    return BuildResult(content=content, report=report)


def deterministic_json(value: dict[str, Any]) -> str:
    return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def write_intermediate(root: Path, result: BuildResult) -> Path:
    build_dir = root / "build"
    build_dir.mkdir(parents=True, exist_ok=True)
    filename = "fixture-content.json" if result.content["manifest_id"] == "manifest.fixture" else "radhakunda-mvp-development-content.json"
    content_path = build_dir / filename
    content_path.write_text(deterministic_json(result.content), encoding="utf-8")
    return content_path


def write_report(root: Path, report: dict[str, Any]) -> Path:
    report_path = root / "build" / "build-report.json"
    report_path.write_text(deterministic_json(report), encoding="utf-8")
    return report_path
