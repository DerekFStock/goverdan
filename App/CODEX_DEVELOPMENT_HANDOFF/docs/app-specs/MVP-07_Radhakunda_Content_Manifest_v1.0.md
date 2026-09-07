# GOVARDHANA PILGRIMAGE APP

## MVP-07 — Rādhā-kuṇḍa Content Manifest Specification

**Document ID:** MVP-07  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00 through MVP-06  
**Primary platform:** iPhone  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP  
**Purpose:** Define exactly which real Story and source materials enter the first application

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document converts the MVP architecture into an exact content plan.

Earlier specifications defined:

- what the MVP is;
- how the Story should behave;
- how sources and citations work;
- how content is authored;
- how Swift will render it.

MVP-07 answers a different question:

> **What actual Rādhā-kuṇḍa content will be loaded into the app?**

The goal is to prevent Codex development from beginning with vague instructions such as:

> "Put some Rādhā-kuṇḍa content in the app."

Instead, Codex should receive a controlled, staged content manifest.

---

# 2. Governing Content Rule

The first implementation must use **real project content**, not lorem ipsum or invented test material.

However, the entire Rādhā-kuṇḍa corpus does **not** need to be converted before the first code milestone.

Content will enter in controlled stages.

The strategy is:

```text
SMALL REAL VERTICAL SLICE
↓
READER / CITATION ARCHITECTURE VERIFIED
↓
SOURCE CORPUS EXPANDS
↓
COMPLETE APPROVED RĀDHĀ-KUṆḌA STORY
↓
MVP COMPLETE
```

---

# 3. Relationship to Existing Rādhā-kuṇḍa Research

The current project corpus is already sufficiently mature to support Story implementation.

The Rādhā-kuṇḍa Writing Blueprint explicitly states that the textual, theological, nitya-līlā, people-of-the-landscape, and Caitanya/Gosvāmī research blocks are mature enough for composition, while later physical/field-guide material remains partly gated.

The master dossier further records the project's controlled source hierarchy and the major completed research blocks.

Therefore the MVP should prioritize Story sections whose evidence base is already stable.

---

# 4. MVP Content Phases

The content package should develop through four internal phases.

## Phase A — Vertical Slice

One substantial Story section and a tiny but real source corpus.

## Phase B — Story Core

The full manifestation/meaning and Caitanya/Raghunātha core.

## Phase C — Complete Approved Story

Every Story section that is approved for the Rādhā-kuṇḍa literary chapter.

## Phase D — MVP Finalization

Complete supporting source subset, search, citation audit, images, and witness mappings.

---

# 5. Phase A — First Vertical Slice

The first Codex build should use:

## Story Section

### The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa

This is the ideal first implementation because it contains:

- continuous narrative;
- source-critical distinctions;
- Sanskrit terminology;
- direct quotations;
- multiple source relationships;
- theological interpretation;
- source ranges;
- a mixture of root-text and commentary issues.

The Writing Blueprint identifies this section as the narrative heart of the chapter and gives it a 2,000–3,000 word target, preserving the twenty-verse narrative sequence.

---

# 6. Phase A — Required Source Works

The first vertical slice should include at minimum:

1. **Rādhā-kuṇḍāṣṭaka**
2. **Mathurā-māhātmya**
3. **Twenty-verse manifestation account preserved by Viśvanātha Cakravartī**

Deferred to the next content phase unless already prepared:

4. **Śrīmad-Bhāgavatam 10.36**
5. **Sārārtha-darśinī context on ŚB 10.36.16**

This gives Codex enough source variation to test the architecture honestly.

---

# 7. Phase A — Rādhā-kuṇḍāṣṭaka

## Work Identity

**Title:** Śrī Rādhā-kuṇḍāṣṭakam  
**Author:** Raghunātha dāsa Gosvāmī  
**Parent Work:** Stavāvalī  
**Source Layer:** A — Primary / Gosvāmī

## Phase-A Passage Range

Complete verses 1–8. The entire prayer is loaded in Phase A.

## Why It Matters

Verse 1 provides the key phrase:

> *narma-dharmokti-raṅgaiḥ*

which the project uses to control the theological reading of the playful dharma challenge.

The source text is available in the Stavāvalī project source.

---

# 8. Phase A — Mathurā-māhātmya

## Work Identity

**Title:** Śrī Mathurā-māhātmyam  
**Author:** Rūpa Gosvāmī  
**Source Layer:** A — Primary / Gosvāmī

## Minimum Passage Range

### 418–423

This is the controlled Rādhā-kuṇḍa sequence used throughout the project.

The master dossier identifies:

- 418 — paired bathing merit;
- 420 — Bahulāṣṭamī/Kārttika observance;
- 421 — the equivalence of Rādhā's dearness and Her kuṇḍa's dearness.

## Preferred App Representation

Include enough surrounding passages to allow meaningful continuous reading rather than loading only six isolated verses.

---

# 9. Phase A — Twenty-Verse Manifestation Account

## Work Identity

The source must **not** be falsely titled as a specific Purāṇa.

Recommended temporary canonical display title:

### Twenty-Verse Rādhā-kuṇḍa Manifestation Account

Secondary description:

> Purāṇic account preserved by Viśvanātha Cakravartī in his commentary on Śrīmad-Bhāgavatam 10.36.16.

The project's reconstruction explicitly preserves the unresolved Purāṇic provenance.

## Passage Range

Verses 1–20.

## Required Structure

Each verse should be an individually addressable Source Passage.

The narrative grouping should also be preserved:

```text
1–2   Playful dharma challenge
3–6   Kṛṣṇa manifests His pond
7–10  Rādhā manifests Her pond
11–16 The tīrthas petition
17    Waters join
18    Kṛṣṇa's declaration
19    Rādhā's reciprocal declaration
20    Rāsa
```

This eight-movement sequence is already controlled by RS-01 and RS-02. 
---

# 10. Phase A — Śrīmad-Bhāgavatam 10.36

This is strongly recommended for the first app source set.

## Why

The Story must preserve the important boundary:

> the Bhāgavatam narrates Ariṣṭāsura's attack and defeat, but its root verses do not narrate the twin-kuṇḍa manifestation.

That negative finding is foundational to the project's source genealogy.

## Minimum Passage Range

Relevant Ariṣṭāsura verses in ŚB 10.36.

## Exact App Range

To be finalized when the direct local text is prepared and checked.

---

# 11. Phase A Acceptance Corpus

The first functioning app should therefore contain approximately:

```text
STORY
1 real Story section

SOURCES
Rādhā-kuṇḍāṣṭaka 1–8
Mathurā-māhātmya 418–423 + context
Twenty-verse manifestation account 1–20
ŚB 10.36 relevant section if ready
```

This is enough to prove:

- Story rendering;
- citations;
- independent Works;
- parent/child Works;
- passage ranges;
- source details;
- source-critical notes;
- exact navigation.

---

# 12. Phase B — Story Core

After the vertical slice is stable, the next Story sections should be added in literary order.

Recommended core:

1. **At the Foot of Govardhana: The Two Waters**
2. **Ariṣṭāsura: The Bhāgavatam Foundation**
3. **The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa**
4. **Meaning and Theology**
5. **Śrī Caitanya Mahāprabhu at Rādhā-kuṇḍa**
6. **Raghunātha dāsa Gosvāmī at Rādhā-kuṇḍa**

These sections give the MVP a coherent theological and historical narrative even before all later sacred-geography material is loaded.

---

# 13. Phase B — Mahāprabhu Source Set

Required Work:

## Caitanya-caritāmṛta

### Minimum range

**Madhya 18.3–15**

This passage is already isolated as a complete narrative unit in RS-03.

The source architecture should preserve:

- 18.3 — arrival;
- 18.4 — inquiry;
- 18.5 — *tīrtha lupta*, *sarvajña bhagavān*, *alpa-jala*;
- 18.6–12 — praise;
- 18.13 — remembrance and dance;
- 18.14 — kuṇḍa earth / tilaka;
- 18.15 — Govardhana handoff.

---

# 14. Phase B — Raghunātha Source Set

Required Work:

## Stavāvalī constituent works

At minimum:

- Rādhā-kuṇḍāṣṭaka
- Vraja-vilāsa-stava
- Vilāpa-kusumāñjali

Important known passage:

### Vilāpa-kusumāñjali 97

The RK-04 ledger treats it as an A-level anchor for Raghunātha's Rādhā-kuṇḍa-centered residence and bhajana.

---

# 15. Phase B — Bhakti-ratnākara

Required Work:

## Bhakti-ratnākara

**Author:** Narahari Cakravartī  
**Source Layer:** B — Early Vraja/Gauḍīya pilgrimage and devotional history

Minimum relevant blocks:

### 5.529–553

Especially:

- 5.530–531 — earlier paddy-field condition;
- 5.532–534 — Raghunātha's desire/renunciation tension;
- 5.537–541 — wealthy donor tradition;
- 5.545–547 — *paṅkoddhāra* and excavation;
- 5.549–553 — Pāṇḍava trees and Śyāma-kuṇḍa shape.

These loci are already controlled in the RK-04 ledger.

The complete searchable Bhakti-ratnākara project source is also available.

---

# 16. Phase C — Complete Story

The app's literary Story should ultimately follow the approved Rādhā-kuṇḍa Writing Blueprint.

The current macro-architecture is:

```text
PART I
Manifestation and Meaning

PART II
The Eternal Rādhā-kuṇḍa

PART III
Recognition, Residence, and Community

PART IV
Physical History and Pilgrim Encounter
```

The Blueprint currently defines fourteen planned sections and requires each literary section to be drafted and approved independently before eventual compilation.

The app should ingest those approved sections as they become ready.

---

# 17. Provisional Complete Story Section Manifest

Subject to final approved writing titles, the app should anticipate:

### Part I — Manifestation and Meaning

1. At the Foot of Govardhana: The Two Waters
2. Ariṣṭāsura: The Bhāgavatam Foundation
3. The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa
4. Meaning and Theology

### Part II — The Eternal Rādhā-kuṇḍa

5. Sacred Architecture of the Eternal Kuṇḍa
6. The Midday Līlā and Movement Through the Landscape
7. The People and Services of Rādhā-kuṇḍa

### Part III — Recognition, Residence, and Community

8. Śrī Caitanya Mahāprabhu at Rādhā-kuṇḍa
9. Raghunātha dāsa Gosvāmī
10. The Early Gauḍīya Community
11. Jāhnavā, Śrīnivāsa, Narottama and the Pilgrimage Network

### Part IV — Physical History and Pilgrim Encounter

12. Historical Transformation of the Twin Kuṇḍas
13. The Present Sacred Landscape
14. Conclusion / Pilgrim Encounter

Final wording must come from approved Story documents, not this provisional software manifest.

---

# 18. Part II Source Corpus — Govinda-līlāmṛta

## Work

Govinda-līlāmṛta  
Kṛṣṇadāsa Kavirāja Gosvāmī  
A — Primary / Gosvāmī

The project has a complete searchable Sanskrit mūla source.

## Required Rādhā-kuṇḍa ranges

At minimum:

### Sarga 7

especially:

- 7.1 — arrival at Rādhā-kuṇḍa;
- 7.2–18 — sacred architecture/service landscape;
- 7.6 — twin-kuṇḍa junction and bridge;
- 7.27 onward — aṣṭa-sakhī directional system;
- 7.31–101 — directional grove architecture;
- 7.100–101 — Anaṅga-mañjarī's central dwelling;
- 7.111–117 — priya-narma-sakhā system.

These are already summarized and verse-controlled in RK-02.

---

# 19. Govinda-līlāmṛta Additional Ranges

For the mature Story, likely relevant:

- GL 5.40 — appointment to come to *sva-kuṇḍa*;
- GL 8.106–115 — approach/first-sight sequence;
- GL 18.25 — dice play in Harit-kuñja;
- GL 18.92–98 + 19.1 — end of midday circuit.

The exact final corpus should follow the approved Story's actual citations rather than loading every theoretically relevant verse.

---

# 20. Part II Source Corpus — Kṛṣṇa-bhāvanāmṛta

## Work

Kṛṣṇa-bhāvanāmṛta Mahākāvya  
Viśvanātha Cakravartī  
A — later Gosvāmī primary devotional source within the project's A-level corpus

Available project witnesses include both searchable and printed/Bengali material. 
## Key established ranges

From RK-02:

- 10.4–5 — six-season geography;
- 11.8;
- 11.45–49 — swing arrangement;
- 14.9–17;
- 14.48–52 — water play and aftermath;
- 15.1–8 — dice setup;
- 15.53–82 — end of midday circuit.

These loci are already promoted to verified or controlled status in RK-02.

---

# 21. Part II Source Corpus — Rādhā-Kṛṣṇa-gaṇoddeśa-dīpikā

## Work

Rādhā-Kṛṣṇa-gaṇoddeśa-dīpikā  
Rūpa Gosvāmī  
A — Primary / Gosvāmī

The app will require relevant passages for:

- aṣṭa-sakhī identities;
- hierarchy;
- service roles;
- key associates.

The People ledger identifies important controlled ranges such as:

- 76–79 — sakhī hierarchy and names;
- 123–127 — general service charter;
- 129 onward — Lalitā;
- corresponding later ranges for the other sakhīs.

The full project source is available.

---

# 22. Part II Source Corpus — Vraja-rīti-cintāmaṇi

## Work

Vraja-rīti-cintāmaṇi  
Viśvanātha Cakravartī  
A — Gosvāmī devotional source

The app should include only passages actually used by the final Story.

The searchable text and English translation are both available in project sources. 
---

# 23. Part III Source Corpus — Vraja-bhakti-vilāsa

## Work

Vraja-bhakti-vilāsa  
Nārāyaṇa Bhaṭṭa  
B — Early Vraja pilgrimage/localization

The opening explicitly describes the work as a *vraja-māhātmya-darśin* guide associated with *vana-yātrā*, residence, circumambulation, donation, and worship, and names Rādhā-kuṇḍa among the twelve *adhivanas*.

Only passages actually needed by the Story should be included initially.

---

# 24. Historical / Documentary Source Corpus

Historical sources should be added only when the corresponding Story sections become approved.

Likely core works:

## Mukherjee & Habib

"Land Rights in the Reign of Akbar"

Relevant because it directly discusses Aritha/Rādhā-kuṇḍa land documents and Raghunātha/Jīva transactions.

## Mukherjee & Wright

"An Early Testamentary Document in Sanskrit"

Relevant to Jīva and early Gauḍīya institutional history.

## Habib & Mukherjee

*Braj Bhum in Mughal Times*

Especially chapter:

> "From Arith to Radhakund: the History of a Braj Village"

The book's contents explicitly include this historical study.

---

# 25. Additional Historical Works

Potential:

- Entwistle, *Braj: Centre of Krishna Pilgrimage*
- Growse, *Mathura: A District Memoir*
- Drake-Brockman, *Muttra: A Gazetteer*

These should not be normalized in full unless actually useful to the Story.

For long historical works, it may be sufficient initially to structure only cited sections/passages.

---

# 26. Later / Local Source Corpus

Likely principal C-level work:

## Ananta Dāsa Bābājī

*The Glory and Heritage of Śrī Śrī Rādhā-kuṇḍa*

The work contains sections on:

- Rādhā-kuṇḍa's form;
- aṣṭa-sakhī kuñjas;
- appearance;
- historical discovery;
- Jāhnavā Ghāṭ;
- Viśvanātha;
- temples;
- mahantas;
- "must-see" places.

The Readiness report already cautions that this source contains historical inconsistencies and should not control documentary chronology without archival corroboration.

Therefore it should remain clearly C-level.

---

# 27. Source Inclusion Rule

A source Work is included in the MVP package if at least one of the following is true:

1. the Story directly cites it;
2. the Story quotes it;
3. the source is needed to read the immediate context of a citation;
4. it materially supports a completed Story section.

A source should **not** be included merely because it is interesting.

---

# 28. Full Work vs Partial Work

For short works:

include the complete Work.

Examples:

- Rādhā-kuṇḍāṣṭaka;
- perhaps Vraja-vilāsa-stava;
- perhaps Vilāpa-kusumāñjali.

For very large works:

include structured portions first.

Examples:

- Govinda-līlāmṛta;
- Kṛṣṇa-bhāvanāmṛta;
- Bhakti-ratnākara;
- historical monographs.

Later, full normalization may be added if beneficial.

---

# 29. Preferred Full-Work Candidates

The following are especially good candidates for complete normalized MVP inclusion:

- Rādhā-kuṇḍāṣṭaka
- Vraja-vilāsa-stava
- Vilāpa-kusumāñjali
- Mathurā-māhātmya

They are relatively manageable and heavily relevant.

---

# 30. Preferred Partial-Work Candidates

Initially structure only Rādhā-kuṇḍa-relevant sections of:

- Govinda-līlāmṛta
- Kṛṣṇa-bhāvanāmṛta
- Rādhā-Kṛṣṇa-gaṇoddeśa-dīpikā
- Bhakti-ratnākara
- Vraja-bhakti-vilāsa
- historical studies

This keeps source preparation proportional to MVP needs.

---

# 31. Original Witness Priorities

The following original witnesses are particularly valuable because project practice already uses them for visual verification:

- Sārārtha-darśinī printed scan
- Govinda-līlāmṛta printed scan
- Kṛṣṇa-bhāvanāmṛta printed/Bengali edition
- Stavāvalī PDF

PDF viewing is explicitly post-vertical-slice; normalized-text navigation is proven first.

---

# 32. Image Manifest

Images are not a blocking MVP feature.

Phase A may contain no images.

Phase B/C can include selected images only when they improve Story reading.

Potential image classes:

- historical photograph;
- old map;
- manuscript/printed page;
- simple sacred-geography diagram;
- approved present photograph later.

No image should be added merely for decoration.

---

# 33. First Vertical Slice Images

Recommended:

**none required**.

This keeps the first acceptance test focused on:

> Story → citation → source → return.

---

# 34. Story Citation Density

The Story should not mechanically expose every internal research citation.

Reader-facing citations should focus on:

- important source anchors;
- direct quotations;
- contested claims;
- source-layer changes;
- key historical facts.

The app can preserve deeper citation metadata without making the Story visually academic.

---

# 35. Internal Citation Corpus

The Markdown/app content may contain more structured citations than are visibly rendered.

This allows later:

- Research Details;
- source matrix;
- web publication;
- scholarly audit.

Visible citation density and underlying citation density are not necessarily identical.

---

# 36. Story Section Readiness Status

Each Story section should have one of:

```text
NOT_STARTED
DRAFT
REVIEWED
APPROVED
APP_READY
```

Only APP_READY sections enter the release content manifest.

---

# 37. Source Readiness Status

Each source Work/section should progress through:

```text
RAW
STRUCTURED
NORMALIZED
VERIFIED
APP_READY
```

This status should be tracked outside the Swift app.

---

# 38. First Build Required Story Status

The first vertical slice requires:

```text
The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa
→ APP_READY
```

If the literary section is still under revision when Codex begins, a reviewed snapshot may be used for development, but it must be explicitly marked as development content.

---

# 39. First Build Required Source Status

Required passages should be:

```text
VERIFIED
```

before they are used as Story citation targets.

A structured but unverified surrounding passage may be included for reading context if clearly marked internally.

---

# 40. Search Corpus Requirements

The Phase-A search corpus should include:

- full vertical-slice Story section;
- Rādhā-kuṇḍāṣṭaka text;
- Mathurā-māhātmya included range;
- twenty-verse manifestation account.

This is enough to test Story/source grouped search results.

---

# 41. Bookmark Test Corpus

At least one bookmarkable target of each type:

- Story position;
- Source Passage.

No special content preparation required beyond stable IDs.

---

# 42. Content Package Phase A

Example:

```yaml
id: manifest.radhakunda-phase-a
version: "0.1.0"

story:
  story.radhakunda

story_sections:
  - story.radhakunda.manifestation

works:
  - work.radha-kundastaka
  - work.mathura-mahatmya
  - work.rk-manifestation-twenty-verse

optional_works:
  - work.srimad-bhagavatam
  - work.sarartha-darsini
```

---

# 43. Content Package Phase B

Adds:

```text
At the Foot of Govardhana
Ariṣṭāsura
Meaning and Theology
Mahāprabhu
Raghunātha dāsa
```

and relevant:

```text
Caitanya-caritāmṛta
Stavāvalī subworks
Bhakti-ratnākara
Śrīmad-Bhāgavatam
```

---

# 44. Content Package Phase C

Adds:

- nitya-līlā Story sections;
- people/service sections;
- early Gauḍīya community;
- historical sections;
- all Story-approved source subsets.

---

# 45. MVP Final Content Package

The final MVP is considered content-complete when:

1. every approved Story section is present;
2. every visible Story citation resolves;
3. every cited Work is represented;
4. surrounding source context is readable;
5. core source text is searchable;
6. major short works are complete;
7. source metadata identifies evidence layer;
8. citation validation produces zero broken targets;
9. Story reading order is final;
10. content version is designated Rādhā-kuṇḍa Story MVP 1.0.

---

# 46. Final MVP Does Not Require

Even at content completion, MVP does **not** require:

- maps;
- GPS data;
- pilgrimage stop database;
- Govardhana Story;
- Kindle editions;
- field photographs;
- route sequencing;
- public-web metadata.

These remain post-MVP.

---

# 47. Source Corpus Priority Order

For normalization work, recommended order:

1. Rādhā-kuṇḍāṣṭaka
2. Mathurā-māhātmya
3. twenty-verse manifestation source
4. Śrīmad-Bhāgavatam 10.36
5. Caitanya-caritāmṛta Madhya 18.3–15
6. Vraja-vilāsa-stava
7. Vilāpa-kusumāñjali
8. Govinda-līlāmṛta Rādhā-kuṇḍa sections
9. Bhakti-ratnākara Rādhā-kuṇḍa blocks
10. Kṛṣṇa-bhāvanāmṛta relevant ranges
11. Rādhā-Kṛṣṇa-gaṇoddeśa-dīpikā
12. Vraja-bhakti-vilāsa
13. historical/documentary sources
14. later/local sources

This prioritizes the earliest/highest-value sources first.

---

# 48. Direct Verification Priority

Particularly important quotations should be checked against the best available source witness before APP_READY status.

This follows the Story Blueprint's existing rule that important publication quotations should be checked directly rather than relying only on project ledgers.

---

# 49. Manifestation Source Caution

Because the twenty-verse unit's precise Purāṇic provenance remains unresolved, its app metadata should include a permanent source note until that question is resolved.

Do not allow future UI simplification to silently relabel it.

---

# 50. Śyāma-kuṇḍa Naming Caution

The app Story/source corpus must preserve early terminology where the source uses:

- Ariṣṭa-kuṇḍa;
- Ariṣṭa-saras;
- Kṛṣṇa-kuṇḍa.

The master dossier explicitly notes that "Śyāma-kuṇḍa" is a later/common designation whose earliest secure occurrence remains a research question.

The app must not retroactively rewrite early source wording.

---

# 51. Sacred Geography Caution

When Part II enters the app, eternal-līlā descriptions must remain textual descriptions.

Even though maps are outside MVP, the prose and source notes must not imply that present masonry structures automatically occupy the exact textual positions described in Govinda-līlāmṛta.

This distinction is already fundamental to RK-02.

---

# 52. People Content Caution

When aṣṭa-sakhī and associate content enters the Story, the app should preserve the distinction between:

- identity/service information from Gaṇoddeśa-dīpikā;
- directional geography from Govinda-līlāmṛta;
- project interpretation linking the two.

The People ledger explicitly preserves this distinction.

---

# 53. Historical Source Caution

Later devotional histories and modern sources must not control documentary chronology when documentary evidence disagrees or remains unresolved.

This is already an explicit project rule and should be reflected in Story source metadata.

---

# 54. Manifest Ownership

MVP-07 defines the **content target**.

It does not itself contain all source text.

Actual content files remain under:

```text
content/
sources/
stories/
```

The manifest only identifies what should be included.

---

# 55. Codex Responsibilities for Content

Codex may:

- create schemas;
- create parsers;
- import approved prepared files;
- generate runtime databases;
- validate IDs;
- generate search indexes.

Codex must not:

- invent missing Sanskrit;
- invent translations;
- assign uncertain provenance;
- choose source layers independently;
- normalize substantive readings without instruction;
- create new Story prose.

---

# 56. Human/Research Responsibilities

The project workflow remains responsible for:

- approving Story prose;
- selecting source passages;
- validating quotations;
- approving translations;
- resolving source identity;
- assigning A/B/C/D classification;
- determining whether material is APP_READY.

Codex implements the corpus; it does not curate it.

---

# 57. Phase-A Acceptance Criteria

Phase A content is ready for the first Codex integrated build when:

- one Story section is app-ready;
- at least three Source Works are structured;
- at least ten real Passage IDs exist;
- every Story citation resolves;
- at least one parent/child Work relationship exists;
- at least one source range exists;
- search index can be generated;
- zero broken citation targets remain.

---

# 58. MVP Final Acceptance Criteria

The full Rādhā-kuṇḍa Story MVP content is ready when:

- all intended Story sections are approved;
- all Story sections are APP_READY;
- every visible citation resolves;
- all direct quotations have controlled provenance;
- every included Work has metadata;
- every cited Passage is VERIFIED;
- all preferred reading editions are readable;
- Story/source search is complete;
- citation audit reports zero errors;
- content manifest is versioned 1.0.0.

---



# 61. Next and Final Pre-Codex Specification

After MVP-07, proceed to:

## MVP-08 — Codex Build Plan & Acceptance Criteria

This is the final document in the reduced MVP planning set.

It will convert MVP-00 through MVP-07 into a deterministic implementation program for Codex:

- repository setup;
- exact milestone order;
- what Codex may and may not change;
- first fixture build;
- content compiler;
- SQLite schema;
- Swift project;
- Story reader;
- citation resolver;
- Source Reader;
- Search;
- Library;
- Bookmarks;
- reading-state persistence;
- tests;
- vertical-slice acceptance test;
- MVP completion gate;
- and the exact handoff instructions you will give Codex before it writes production code.

---

## Approval

**MVP-07 v1.0 — APPROVED**
