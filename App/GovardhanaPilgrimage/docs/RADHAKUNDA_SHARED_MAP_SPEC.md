# Rādhā-kuṇḍa / Śyāma-kuṇḍa shared-map research specification

Status: research and design only. This document does **not** authorize runtime micro-place ingestion. The companion [inventory](../content/research/radhakunda-location-inventory.yaml) preserves RK-01–RK-45, extensions, and a separate ghāṭ candidate register. Proposed IDs and RK codes are internal, never new public map numbers.

## Shared map contract

Keep one offline MapLibre map. The existing Govardhana collection, its map numbers 1–71, IDs, navigation and runtime SQLite remain unchanged. A future Rādhā-kuṇḍa micro collection would coexist on that same map; it is not another screen or route. Reuse `place.radhakunda`, `place.syamakunda`, `place.lalitakunda`, `place.siva-khari`, and `place.radha-kunjabihari-gaudiya-matha` where inventory records refer to them. No duplicate markers for these sites; no #72 or secondary integer numbering. Research IDs (RK-01 etc.) may be shown as local labels only if later approved.

The pilgrim should zoom from Govardhana Hill into Rādhā-kuṇḍa / Śyāma-kuṇḍa and naturally see more sacred detail without changing maps. At regional zoom show the Govardhana numbered circuit only (including its existing twin-kuṇḍa places); at precinct zoom show verified `CORE` micro detail; at walking zoom reveal verified `HIGH` detail; at close-detail zoom show separately justified ghāṭs and child features. Use collision and density controls rather than promoting unlocated candidates. Exact zoom thresholds need device testing during later runtime work. Govardhana labels retain `#1`–`#71`; micro-site names get no public numeric label, and internal RK codes stay in a DEBUG/research inspector until separately approved. Category/priority controls density, not per-site special cases.

## Physical marker semantics

| Kind | Meaning and behavior |
| --- | --- |
| Exact point | Field/official/structured-map controlled physical feature or access point; navigation can target it. |
| Practical arrival | A safe, identifiable entrance or compound approach, not a claim that the marker is the sacred feature itself. Arrival wording must say “at navigation anchor” where appropriate. |
| Area | Water, grove, or precinct with geometry; a centroid is not automatically an entrance. |
| Combined site | One physical complex serving several traditions or named features; child relationships prevent duplicate pins. |
| Child feature | Detail nested under a parent place or ghāṭ; expose in details unless a separate physical point and user value are established. |
| Textual-only annotation | Conceptual geography without a current physical coordinate; never a GPS target or ordinary physical map pin. |

Marker treatment should be driven by verified status, map priority, evidence layer, and geometry, not name-specific code. Keep internal research status distinct from runtime production eligibility. Present-day coordinates are absent for unverified candidates; plus codes and approximate centers in research notes are investigation aids, not compiled positions. A distinct public arrival point may need a different coordinate from a water-body center.

## Three evidence layers

1. **Present physical map:** contemporary water outlines, lanes, verified shrines, institutions, entrances and ghāṭs. This alone can provide GPS navigation. An existing runtime coordinate is a working marker, not proof of exact sacred-feature geometry.
2. **Early pilgrimage localization:** historical attestations, especially Bhakti-ratnākara, tied to modern sites only when continuity is supported. Show provenance and uncertainty; a textual relationship does not by itself verify the present entrance.
3. **Nitya-līlā conceptual geography:** Govinda-līlāmṛta and related service geography. Present as a clearly labeled conceptual/reading layer rather than parcel boundaries, surveyed points, or navigable destination pins. Do not flatten its directions or names into modern physical claims.

A future layer control can make the distinction legible while preserving one map. Absence of a physical point should not hide a textual item from research and reading, but the MapLibre physical layer must not invent a coordinate. Source notes in the inventory record the layer and locus for each claim. The scanned *Vraja Maṇḍala Parikramā* guide and modern public maps are discovery aids, not sole authority for early textual claims.

Future collection filters may offer `All`, `Govardhana`, and `Rādhā-kuṇḍa`. Advanced research filters may group waters, ghāṭs, Gosvāmī sites, temples, and līlā sites. These are design affordances only; no filtering UI ships in this task.

## Reconciliation and release gates

The preliminary Wave A set consists of existing RK-01/02/04, RK-16/17/20/21/27/29, plus RK-SAM-01 and RK-INST-01. “Wave A” is a research priority, not an instruction to ingest all eleven immediately. Before any new marker, check its exact location or practical arrival, identity, provenance, access, parent/child relationship, and whether an existing runtime ID already covers it. RK-09 must reconcile with `place.siva-khari`; RK-10/11 remain textual-only. RK-13, RK-GH-09/10, and the shared Saṅgama ghāṭ require combined-site decisions. RK-16 and RK-KUT-01 share a current plus code and may be one compound. RK-17 is distinct from the three-Gosvāmī memorial complex, but related features require careful labels.

Treat all ghāṭs as candidates, not automatic pins. Saṅgama occurs in lists for both banks, so RK-GH-07 is one candidate with two bank approaches, not two independent places. Verify a bank-side point, signage, earliest attestation, neighboring temple/kuṭīra, and separate-pin value before runtime mapping. Waves B and C keep unresolved and textual candidates visible for research without crowding the production map.

Task 021A.1 stops at the inventory and this design. No route/polyline, historical-map georeferencing, public RK numbering, mass ghāṭ pins, new runtime place records, CI work, or production map-layer code is included. Task 021A.2 requires separate review and authorization.
