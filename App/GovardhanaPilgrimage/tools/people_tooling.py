"""Validate and project manifest-declared People content into canonical runtime records."""

from __future__ import annotations

import re
from typing import Any


PERSON_KINDS = {"vraja_associate", "gaudiya_teacher"}
PLACE_RELATION_TYPES = {"lila_participant", "residence_tradition", "service_location", "textual_association"}
EVIDENCE_LAYERS = {"A", "B", "C", "D"}
VERIFICATION_STATUSES = {"VERIFIED", "APP_READY"}
BLOCK_TYPES = {"paragraph", "quotation", "verse"}


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def _unique(values: list[str], label: str) -> None:
    _require(len(values) == len(set(values)), f"Duplicate {label}")


def project_people(
    registry: dict[str, Any],
    packages: list[dict[str, Any]],
    manifest_person_ids: list[str],
    passage_by_id: dict[str, dict[str, Any]],
    place_ids: set[str],
) -> dict[str, list[dict[str, Any]]]:
    """Manifest order is authoritative; no directory scan or inferred relationships."""
    records = registry.get("people")
    _require(isinstance(records, list), "People registry must contain people[]")
    registry_ids = [item.get("id") for item in records]
    _unique(registry_ids, "person IDs")
    _unique(manifest_person_ids, "PERSON_PACKAGE declarations")
    _require(set(registry_ids) == set(manifest_person_ids), "People registry and manifest package identities disagree")
    by_id = {item["id"]: item for item in records}
    aliases: list[str] = []
    for record in records:
        _require(record.get("person_kind") in PERSON_KINDS, f"Invalid person kind: {record.get('id')}")
        _require(record.get("published") is True, f"Unpublished person package is not allowed: {record.get('id')}")
        _require(all(isinstance(record.get(k), str) and record[k].strip() for k in ("canonical_name", "sort_name", "descriptor")),
                 f"Incomplete person registry record: {record.get('id')}")
        for alias in record.get("aliases", []):
            _require(isinstance(alias, str) and alias.strip(), f"Empty alias for {record['id']}")
            aliases.append(alias.casefold())
    _unique(aliases, "person aliases")

    people: list[dict[str, Any]] = []
    person_aliases: list[dict[str, Any]] = []
    sections: list[dict[str, Any]] = []
    blocks: list[dict[str, Any]] = []
    citations: list[dict[str, Any]] = []
    place_links: list[dict[str, Any]] = []
    section_ids: list[str] = []
    block_ids: list[str] = []
    citation_ids: list[str] = []
    link_ids: list[str] = []

    for package in packages:
        person_id = package.get("person_id")
        _require(person_id in by_id, f"Published People package lacks registry entry: {person_id}")
        record = by_id[person_id]
        people.append({key: record[key] for key in ("id", "person_kind", "canonical_name", "sort_name", "descriptor", "published")})
        person_aliases.extend({"person_id": person_id, "alias": alias} for alias in record.get("aliases", []))
        own_citation_ids: list[str] = []
        package_sections = package.get("sections")
        _require(isinstance(package_sections, list) and package_sections, f"Person has no article sections: {person_id}")
        for section_order, section in enumerate(package_sections, 1):
            section_id = section.get("id")
            _require(isinstance(section_id, str) and section_id and isinstance(section.get("title"), str),
                     f"Invalid person section in {person_id}")
            section_ids.append(section_id)
            authored_blocks = section.get("blocks")
            _require(isinstance(authored_blocks, list) and authored_blocks, f"Empty person section: {section_id}")
            sections.append({"id": section_id, "person_id": person_id, "title": section["title"], "order": section_order})
            for block_order, block in enumerate(authored_blocks, 1):
                block_id = block.get("id")
                _require(isinstance(block_id, str) and block_id and block.get("type") in BLOCK_TYPES,
                         f"Invalid person content block in {section_id}")
                _require(isinstance(block.get("text"), str) and block["text"].strip(), f"Empty person block: {block_id}")
                _require(not re.search(r"\b\d{4}-\d{2}-\d{2}\b", block["text"]),
                         f"Hard-coded Gregorian date in person block: {block_id}")
                block_ids.append(block_id)
                blocks.append({"id": block_id, "section_id": section_id, "order": block_order,
                               "block_type": block["type"], "text": block["text"]})
                authored_citations = block.get("citations")
                _require(isinstance(authored_citations, list) and authored_citations,
                         f"Uncited reader-facing person claim: {block_id}")
                if block["type"] == "quotation":
                    _require(isinstance(block.get("quotation_provenance"), str) and block["quotation_provenance"].strip(),
                             f"Quotation lacks provenance: {block_id}")
                for citation_order, citation in enumerate(authored_citations, 1):
                    citation_id = citation.get("id")
                    source_id = citation.get("source_passage_id")
                    start_id = citation.get("start_passage_id")
                    end_id = citation.get("end_passage_id")
                    singleton = source_id is not None and start_id is None and end_id is None
                    passage_range = source_id is None and start_id is not None and end_id is not None
                    _require(singleton or passage_range, f"Invalid person citation target: {citation_id}")
                    target_ids = [source_id] if singleton else [start_id, end_id]
                    _require(all(target in passage_by_id for target in target_ids), f"Missing Passage target: {citation_id}")
                    if passage_range:
                        start, end = passage_by_id[start_id], passage_by_id[end_id]
                        _require(start["work_id"] == end["work_id"] and start["order"] <= end["order"],
                                 f"Invalid person citation range: {citation_id}")
                        target_ids = [item["id"] for item in passage_by_id.values()
                                      if item["work_id"] == start["work_id"] and start["order"] <= item["order"] <= end["order"]]
                    _require(all(passage_by_id[target].get("verification_status") in VERIFICATION_STATUSES for target in target_ids),
                             f"Visible unverified person citation target: {citation_id}")
                    _require(citation.get("source_layer") in EVIDENCE_LAYERS, f"Person citation lacks evidence layer: {citation_id}")
                    citation_ids.append(citation_id)
                    own_citation_ids.append(citation_id)
                    citations.append({"id": citation_id, "content_block_id": block_id, "source_passage_id": source_id,
                                      "start_passage_id": start_id, "end_passage_id": end_id,
                                      "role": citation.get("role", "SOURCE"), "source_layer": citation["source_layer"],
                                      "order": citation_order})
        for link in package.get("place_relationships", []):
            link_id = link.get("id")
            _require(isinstance(link_id, str) and link_id, f"Invalid person-place relationship ID: {link_id}")
            _require(link.get("place_id") in place_ids, f"Unknown person-place target: {link_id}")
            _require(link.get("relationship_type") in PLACE_RELATION_TYPES, f"Invalid person-place type: {link_id}")
            _require(link.get("source_layer") in EVIDENCE_LAYERS, f"Person-place link lacks evidence layer: {link_id}")
            _require(link.get("verification_status") in VERIFICATION_STATUSES,
                     f"Person-place link lacks verification status: {link_id}")
            _require(isinstance(link.get("explanation"), str) and link["explanation"].strip(),
                     f"Person-place link lacks explanation: {link_id}")
            _require(isinstance(link.get("citation_ids"), list) and link["citation_ids"],
                     f"Person-place link lacks citations: {link_id}")
            _unique(link["citation_ids"], f"person-place citation IDs in {link_id}")
            _require(set(link["citation_ids"]).issubset(set(own_citation_ids)), f"Unknown person-place citation: {link_id}")
            link_ids.append(link_id)
            place_links.append({**link, "person_id": person_id})

    _unique(section_ids, "person section IDs")
    _unique(block_ids, "person content-block IDs")
    _unique(citation_ids, "person citation IDs")
    _unique(link_ids, "person-place relationship IDs")
    return {"people": people, "person_aliases": person_aliases, "person_sections": sections,
            "person_blocks": blocks, "person_citations": citations, "person_place_relationships": place_links}
