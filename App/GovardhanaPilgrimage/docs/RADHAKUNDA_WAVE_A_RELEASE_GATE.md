# Rādhā-kuṇḍa Wave A release gate (Task 021A.2; Task 021A.3 evidence update)

Status: **research decision only**. The [machine-readable gate](../content/research/radhakunda-wave-a-release-gate.yaml) decides the same 12 identities marked Wave A in the [inventory](../content/research/radhakunda-location-inventory.yaml). Wave A is research priority, **not** permission to add places, pins, navigation targets, search documents, or public numbers. Inventory labels such as `MAP_NOW_EXACT` are leads, not production approvals.

| Research ID | Decision now | Place identity / release boundary |
| --- | --- | --- |
| RK-01 | `REUSE_EXISTING_NO_NEW_ID` | `place.radhakunda` (#1); water geometry and public edge remain separate controls. |
| RK-02 | `REUSE_EXISTING_NO_NEW_ID` | `place.syamakunda` (#2); preserve Śyāma/Kṛṣṇa/Ariṣṭa naming history. |
| RK-04 | `REUSE_EXISTING_NO_NEW_ID` | `place.lalitakunda` (#3); no duplicate or textual-sector GPS claim. |
| RK-05 | `ELIGIBLE_AS_AREA_NOT_ARRIVAL` | Retain `place.rk.mohana-kunda` as a proposed water *area*, not a navigable centroid. |
| RK-16 | `HOLD_IDENTITY_RECONCILIATION` | Retain `place.rk.raghunatha-dasa-bhajana-kutira`; GFGR+6QP also labels RK-KUT-01. |
| RK-17 | `HOLD_IDENTITY_RECONCILIATION` | Retain `place.rk.raghunatha-dasa-samadhi` as a research ID; physical distinctness from RK-SAM-01 is disputed. |
| RK-20 | `HOLD_ACCESS_VERIFICATION` | Retain `place.rk.gopala-bhatta-bhajana-kutira`; entrance and present fabric unverified. |
| RK-21 | `HOLD_COMPOUND_RECONCILIATION` | Retain `place.rk.jiva-gosvami-site` provisionally; RK-GH-14 remains a child candidate. |
| RK-27 | `HOLD_ACCESS_VERIFICATION` | Retain `place.rk.radha-gopinatha-temple`; verify local temple, entrance, and related-site identities. |
| RK-29 | `HOLD_ACCESS_VERIFICATION` | Retain `place.rk.radha-govinda-temple`; distinguish Vṛndāvana and Govinda-kuṇḍa namesakes. |
| RK-SAM-01 | `HOLD_IDENTITY_RECONCILIATION` | Retain `place.rk.three-goswami-samadhi` as a compound research ID; Raghunātha dāsa constituent relationship needs field verification. |
| RK-INST-01 | `REUSE_EXISTING_NO_NEW_ID` | `place.radha-kunjabihari-gaudiya-matha` (#71); keep its existing #70 navigation-anchor role. |

## Release boundary

The four **already represented** identities are RK-01, RK-02, RK-04, and RK-INST-01. Their existing runtime points are working markers, not newly verified entrances. No second IDs or pins are allowed. RK-09 continues to reconcile with existing `place.siva-khari`; RK-10 and RK-11 remain textual-only. The Saṅgama ghāṭ remains one shared candidate with two bank approaches, and RK-GH-10 remains a child of the Pañca-Pāṇḍava complex; this task does not revisit those Wave B decisions.

The **potential first new cohort** was RK-17, RK-27, RK-29, and RK-SAM-01, but **none is production-ready today**. The inventory's plus codes (GFGR+7GG, GFGR+QC5, GFGR+9MQ, GFGR+6PG) are locator leads, not controlled feature points or public entrances. For each, obtain a dated, auditable latitude/longitude or geometry source, identify a legitimate public approach, and confirm what physical feature the eventual marker represents. Task 021A.3 found [first-party local evidence](https://www.radharani.com/copy-of-manasa-pavana-ghat) placing a Raghunātha dāsa memorial platform in the Three Goswami compound, while a [separately named OSM building](https://www.openstreetmap.org/way/335571304) remains a lead. Keep both research IDs, but do not assert separate physical pins until the relationship is field-verified.

RK-05 has a dated, complete research-only export of [OpenStreetMap way 430061166](https://www.openstreetmap.org/way/430061166) in the [evidence package](../content/research/radhakunda-wave-a-controlled-evidence.yaml) and [GeoJSON](../content/research/radhakunda-wave-a-controlled-evidence.geojson). Its **area identity** passes this classification gate, but a separately authorized task is required for any area ingestion. A water centroid or polygon is neither a safe approach nor an arrival point; public-edge verification remains open. No RK-05 navigation anchor is approved.

The **held initial-ingestion records** are RK-16, RK-20, and RK-21. RK-16 shares GFGR+6QP with the Viśvanātha Cakravartī kuṭīra listing; do not infer two structures or merge traditions from the plus code. RK-20 needs entrance control, and Bhakti-ratnākara's early kuṭīra attestation does not prove surviving historic masonry. RK-21 needs a decision among a parent compound with child features, one practical arrival with internally described features, or separately evidenced places. Its ghāṭ RK-GH-14 is a child/reconciliation candidate, not a new pin. Property tradition does not by itself prove permanent Jīva residence.

Task 021A.2 originally used only repository evidence; Task 021A.3 independently retrieved the specific OSM objects and contemporary site accounts listed in the evidence package on 2026-09-17. No public entrance was field-verified or added to runtime. Nitya-līlā texts and early pilgrimage localizations establish different kinds of claims from present mapping; neither is a GPS source. The Braj Development Plan is physical-planning context, not primary devotional or historical proof.

## Task 021A.3 outcome

The [controlled evidence package](../content/research/radhakunda-wave-a-controlled-evidence.yaml) covers only these five records. RK-05 is **area-only**; RK-17, RK-27, and RK-SAM-01 need field verification; RK-29 has a supported local identity but no controlled location or public approach. No reviewed site has a controlled public entrance. Use the [field checklist](RADHAKUNDA_WAVE_A_FIELD_VERIFICATION_CHECKLIST.md) before proposing any later production ingestion. No RK-16/20/21, Wave B/C, new public numbering, routes, or automatic ghāṭ pins are included.

## Task 021A.4 subsequent authorization

Task 021A.4 authorized production ingestion of **RK-05 alone**, as an unnumbered non-navigable water polygon. The original release-gate decisions above remain the research history; the later explicit authorization does not upgrade a water edge, entrance, or any other candidate. The app retains 71 numbered Govardhana places and adds one unnumbered Rādhā-kuṇḍa micro-place (72 total). RK-17, RK-27, RK-29, RK-SAM-01, every other Wave A candidate, and Waves B/C remain blocked. No public arrival point has been accepted.

## Task 021A.6 subsequent geometry authorization

Task 021A.5 documented the three existing kuṇḍas' separate [controlled OSM water polygons](RADHAKUNDA_THREE_KUNDA_GEOMETRY_REVIEW.md). Task 021A.6 then authorized their production **water-outline geometry only** for existing IDs `place.radhakunda`, `place.syamakunda`, and `place.lalitakunda`. There are now four production water polygons, including Mohana-kuṇḍa, but still 72 places and 71 numbered Govardhana places. Existing numbered points and navigation behavior are unchanged; none is promoted to a verified entrance. Polygon edges, bathing access, and public approaches still need field confirmation. RK-17, RK-27, RK-29, RK-SAM-01, all other Wave A records, and Waves B/C remain blocked.
