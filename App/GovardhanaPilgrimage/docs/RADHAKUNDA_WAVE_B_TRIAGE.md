# Rādhā-kuṇḍa Wave B triage — Task 021A.7

Research-only review of the merged [master inventory](../content/research/radhakunda-location-inventory.yaml), [Wave A release gate](RADHAKUNDA_WAVE_A_RELEASE_GATE.md), and [controlled water evidence](RADHAKUNDA_THREE_KUNDA_GEOMETRY_REVIEW.md). The [machine-readable triage](../content/research/radhakunda-wave-b-triage.yaml) classifies **all 53 Wave B records**: 32 location records and 21 ghāṭ candidates. This is prioritization of existing notes, **not** fresh source verification, coordinates, public pins, or production approval. Wave A holds RK-17, RK-27, RK-29, and RK-SAM-01 remain in force; Wave C is untouched.

| Primary triage status | Count |
| --- | ---: |
| `NEXT_COHORT_CANDIDATE` | 4 |
| `CONTROLLED_SOURCE_DISCOVERY_NEEDED` | 16 |
| `FIELD_VERIFICATION_REQUIRED` | 3 |
| `IDENTITY_RECONCILIATION_REQUIRED` | 5 |
| `PARENT_CHILD_RECONCILIATION_REQUIRED` | 14 |
| `DUPLICATE_OR_EXISTING_PLACE_CANDIDATE` | 2 |
| `DEFER_LOW_CONFIDENCE` | 8 |
| `TEXTUAL_ONLY_NO_PHYSICAL_PIN` | 1 |
| **Total** | **53** |

| Possible map representation, not authorized | Count |
| --- | ---: |
| `POINT` | 17 |
| `GHAT_EDGE_OR_SEGMENT` | 10 |
| `WATER_BODY_POLYGON` | 3 |
| `APPROXIMATE_AREA` | 1 |
| `RELATIONSHIP_ONLY` | 19 |
| `NO_MAP_FEATURE` | 3 |
| `COMPOUND_POLYGON` | 0 |
| **Total** | **53** |

## Recommended next evidence cohort: four records

| ID | Why research next | Present evidence / exact gap | Likely representation and fieldwork |
| --- | --- | --- | --- |
| `RK-03` Saṅgama crossing | Essential twin-kuṇḍa connector, separable from water polygons | Govinda-līlāmṛta 7.6 and a present crossing lead; obtain controlled crossing geometry, public-passage evidence, and one-crossing-versus-`RK-GH-07` relationship | Approximate area pending evidence; field check expected |
| `RK-15` Girirāja-jihvā | Distinct living shrine with strong pilgrim value, independent of blocked compounds | Shrine tradition; obtain dated identity/signage, stable physical source, and public doorway | Point only after access verification; field check expected |
| `RK-22` Mahāprabhu baithak complex | Directly links Caitanya pilgrimage and twin-kuṇḍa story | Earlier recognition tradition and later physical localization; verify present parent compound, tree/temple/baithak children, operator, and entrance | One parent point only if controlled; field check expected |
| `RK-GH-09` Mānasa-pāvana Ghāṭ | Important bathing and Gauḍīya-history site | Textual/traditional association; verify current named bank edge, public approach, and `RK-13`/`RK-GH-10` child relationships | Ghāṭ edge or segment; field check expected |

These four are **candidates for controlled-evidence research**, not four future pins. Each needs an auditable present-day source and an explicit physical meaning before any later production proposal. None depends on resolving RK-17, RK-27, RK-29, or RK-SAM-01. If fieldwork or source discovery fails, hold the record rather than promoting an approximate listing. The YAML specifies individual acceptance conditions.

## Key holds and representation discipline

- Existing-place duplication: `RK-09` must reconcile with numbered `place.siva-khari` (#70); `RK-32` likely overlaps held RK-27. Do not add parallel pins.
- Blocked-compound dependencies: `RK-18`/`RK-19` intersect the held Three Goswami memorial question, `RK-KUT-01` shares a plus-code lead with held RK-16, and `RK-23`/`RK-24`/`RK-GH-04` relate to held RK-27. A listing is not a verified entrance.
- Parent/child decisions: `RK-13`, `RK-GH-10`, and the selected `RK-GH-09` may describe one Mānasa-pāvana site with children; `RK-GH-07` is a bank-approach question for selected `RK-03`, not a second Saṅgama pin. `RK-GH-14` remains a child of held RK-21. Nineteen records are recommended as relationship-only pending reconciliation.
- Source and field gaps: Mālyahāri, Nārāyaṇa, and Bhānukhora water leads lack controlled present polygons. Most temple and ghāṭ names lack an auditable current feature or safe public approach. All four selected sites, plus the three primary `FIELD_VERIFICATION_REQUIRED` records (`RK-12`, `RK-GH-03`, `RK-GH-19`), require field checks; other point/ghāṭ proposals cannot become navigable without access verification.
- No invented textual GPS: `RK-37`'s present temple is not the eternal aṣṭa-sakhī directional system; `RK-GH-18` remains textual-only rather than acquiring a bank point from that geography. `RK-34` and `RK-42` remain `NO_MAP_FEATURE` until their multiple identities are enumerated. No Wave B record is promoted solely from a nitya-līlā or early-pilgrimage locus.

## Proposed Task 021A.8 boundary

If separately authorized, collect dated, auditable physical evidence **only for RK-03, RK-15, RK-22, and RK-GH-09**, while examining `RK-GH-07`, `RK-13`, and `RK-GH-10` solely as relationship context. Record source IDs/revisions, independent identity checks, present feature geometry or explicitly meaningful point, public-access/entrance findings, and field-verification gaps. Produce record-by-record release recommendations; keep unresolved records held. Do not ingest places, geometry, navigation points, or labels in Task 021A.8 unless that task is separately scoped and explicitly authorized to do so.

Production remains 72 places, 71 numbered places, and four water polygons. No Wave B runtime record, additional Rādhā-kuṇḍa micro-place, search document, or map behavior is changed by this triage.
