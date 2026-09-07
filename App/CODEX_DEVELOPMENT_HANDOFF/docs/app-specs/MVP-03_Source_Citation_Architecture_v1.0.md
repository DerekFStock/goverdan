# GOVARDHANA PILGRIMAGE APP

## MVP-03 — Source & Citation Architecture Specification

**Document ID:** MVP-03  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00, MVP-01, MVP-02  
**Primary platform:** iPhone  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document defines how scholarly and devotional sources are represented, cited, linked, validated, and opened within the Rādhā-kuṇḍa Story MVP.

This is one of the most important specifications in the project.

The application must be able to answer reliably:

> What work is being cited?

> What exact passage is meant?

> Which edition or witness supplied the text?

> What source layer does the evidence belong to?

> Is the passage root text, commentary, translation, or later tradition?

> How does the app open the exact passage?

> How does the user return to the Story?

The source architecture must reflect the same source discipline that governs the Govardhana Pilgrimage research project.

---

# 2. Governing Scholarly Principle

The application must preserve the distinction among:

- **A — Primary scripture / Gosvāmī sources**
- **B — Early Vraja pilgrimage and localization tradition**
- **C — Later/local devotional tradition**
- **D — Historical/documentary evidence**

The app must not silently flatten these categories into one undifferentiated pool of "sources."

The source architecture must also preserve unresolved provenance, variant readings, and localization cautions rather than smoothing them away.

---

# 3. Core Source Principle

Every important citation in the Story should resolve to a **canonical textual locus**, not merely a file name or PDF page.

Preferred:

> Govinda-līlāmṛta 7.6

Not preferred:

> Govinda-līlāmṛta PDF, page 132

Page numbers may be stored as edition-specific locators, but they do not replace canonical textual identity.

---

# 4. Source Architecture Layers

The source system should distinguish four conceptual levels:

```text
WORK
↓
CANONICAL PASSAGE
↙              ↘
EDITION REPRESENTATION   WITNESS MAPPING
↓
CITATION TARGETS THE CANONICAL PASSAGE
```

Example:

```text
WORK
Govinda-līlāmṛta

EDITION
Project normalized Sanskrit text

PASSAGE
7.6

CITATION
Story section → Govinda-līlāmṛta 7.6
```

---


# 4A. Canonical Passage Independence

A canonical Passage exists independently of any Edition. Editions supply representations of that Passage (original text, transliteration, translation, commentary or normalization). Story Citations always target canonical Passage IDs. This is a binding v1.0 decision and supersedes any draft example that attached Passage identity directly to a single Edition.

# 5. Work

A **Work** represents the abstract literary work.

Examples:

- Śrīmad-Bhāgavatam
- Caitanya-caritāmṛta
- Mathurā-māhātmya
- Stavāvalī
- Rādhā-kuṇḍāṣṭaka
- Govinda-līlāmṛta
- Kṛṣṇa-bhāvanāmṛta
- Vraja-bhakti-vilāsa
- Bhakti-ratnākara

The Work exists independently of any one file or edition.

---

# 6. Canonical Work ID

Each Work should receive a stable ID.

Recommended pattern:

```text
work.srimad-bhagavatam
work.caitanya-caritamrta
work.mathura-mahatmya
work.stavavali
work.radha-kundastaka
work.govinda-lilamrta
work.krsna-bhavanamrta
work.vraja-bhakti-vilasa
work.bhakti-ratnakara
```

IDs should remain stable permanently once approved.

---

# 7. Canonical Display Name

A Work should store:

- canonical display title;
- transliterated title;
- alternate titles;
- conventional abbreviation;
- author.

Example:

```text
ID:
work.govinda-lilamrta

Display title:
Govinda-līlāmṛta

Abbreviation:
GL

Author:
Kṛṣṇadāsa Kavirāja Gosvāmī
```

---

# 8. Work Abbreviations

The app may use short scholarly abbreviations internally and in Research Details.

Examples:

```text
ŚB
CC
MM
RKA
VVS
GL
KBh
VBV
BR
VRC
```

These abbreviations should never be ambiguous.

The formal abbreviation registry should live with source metadata.

---

# 9. Parent and Child Works

Composite collections must support nested works.

Example:

```text
Stavāvalī
├── Manaḥ-śikṣā
├── Rādhā-kuṇḍāṣṭaka
├── Vraja-vilāsa-stava
└── Vilāpa-kusumāñjali
```

Recommended architecture:

- each independently cited constituent work receives its own Work ID;
- the constituent Work may reference a parent Work.

Example:

```text
work.radha-kundastaka
parentWorkId:
work.stavavali
```

This is preferable to treating Rādhā-kuṇḍāṣṭaka merely as an anonymous subsection of Stavāvalī.

---

# 10. Edition

An **Edition** represents the specific textual representation used by the project.

Examples:

- printed Sanskrit edition;
- electronic transcription;
- Bengali translation edition;
- project normalized reading text;
- English translation.

A Work may have several Editions.

---

# 11. Edition ID

Recommended pattern:

```text
edition.govinda-lilamrta.project-sanskrit-v1
edition.govinda-lilamrta.haridasa-sastri-print
edition.stavavali.project-text-v1
edition.mathura-mahatmya.project-text-v1
```

Edition IDs should identify the edition meaningfully but not include unstable filenames.

---

# 12. Project Reading Edition

For important works, the app may create a **Project Reading Edition**.

This is a normalized digital representation optimized for:

- Unicode;
- search;
- verse navigation;
- exact citation linking;
- iPhone reading.

It may be derived from one or more controlled witnesses.

If multiple witnesses are used, this must be declared in the Edition metadata.

---

# 13. Edition Provenance

Every Project Reading Edition should record:

- source file(s);
- printed edition basis;
- editor;
- translator where relevant;
- normalization notes;
- known corrections;
- version.

Example:

```text
Govinda-līlāmṛta
Project Reading Edition v1

Based primarily on:
Haridāsa Dāsa electronic text

Secondary comparison:
Haridāsa Śāstrī edition

Normalization:
Unicode cleanup and structural markup
```

The project already distinguishes searchable texts used for discovery from printed witnesses used for verification, and the app should preserve that distinction.

---

# 14. Original Witness

A printed scan or facsimile should be modeled as an **Original Witness** or Witness Edition.

Examples:

- printed Govinda-līlāmṛta scan;
- Bengali Kṛṣṇa-bhāvanāmṛta scan;
- Sārārtha-darśinī scan;
- historical journal PDF.

The witness may be opened from the normalized reading text where a passage-page mapping exists.

---

# 15. Passage

A **Passage** is the smallest stable, edition-independent canonical unit to which the Story can link.

Typical passage units:

- verse;
- paragraph;
- numbered prose section;
- chapter;
- page only when no canonical textual structure exists.

Examples:

```text
Rādhā-kuṇḍāṣṭaka 1
Mathurā-māhātmya 421
Govinda-līlāmṛta 7.6
Caitanya-caritāmṛta Madhya 18.5
Bhakti-ratnākara 5.545
```

---

# 16. Passage ID

Recommended pattern:

```text
passage.radha-kundastaka.1
passage.mathura-mahatmya.421
passage.govinda-lilamrta.7.6
passage.caitanya-caritamrta.madhya.18.5
passage.bhakti-ratnakara.5.545
```

The Passage ID should encode canonical structure rather than edition-specific pagination.

---

# 17. Canonical Locus

Each passage should store a normalized machine locus.

Examples:

```text
1
421
7.6
madhya.18.5
5.545
```

It should also store a display locus:

```text
Verse 1
421
7.6
Madhya 18.5
5.545
```

---

# 18. Passage Hierarchy

Passages should support parent relationships.

Example:

```text
Govinda-līlāmṛta
└── Sarga 7
    ├── 7.1
    ├── 7.2
    ├── 7.3
    ...
    └── 7.6
```

Likewise:

```text
Caitanya-caritāmṛta
└── Madhya-līlā
    └── Chapter 18
        └── Verse 5
```

This supports source navigation and TOCs.

---

# 19. Root Text Versus Commentary

The app must never silently merge root text and commentary.

A source passage should identify textual role.

Controlled values may include:

```text
root_text
commentary
translation
editorial_note
project_note
```

Example:

> Śrīmad-Bhāgavatam 10.36.16

is root text.

> Sārārtha-darśinī on ŚB 10.36.16

is commentary.

The twenty-verse Rādhā-kuṇḍa manifestation account preserved by Viśvanātha belongs to the commentary/transmitted Purāṇic layer and must not be displayed as if it were part of the Bhāgavatam root verses.

---

# 20. Commentary Passage IDs

A commentary should receive its own Work or Edition context.

Possible pattern:

```text
work.sarartha-darsini

passage.sarartha-darsini.sb10.36.16.manifestation.1
```

or, if the twenty-verse unit is modeled separately:

```text
work.rk-manifestation-puranic-unit

passage.rk-manifestation-puranic-unit.1
```

The final choice should depend on what best reflects the verified textual witness.

---

# 21. Provenance Caution for the Twenty-Verse Narrative

The project has already established:

- the full twenty-verse manifestation sequence is preserved by Viśvanātha Cakravartī in commentary on ŚB 10.36.16;
- the exact Purāṇic work or recension has not been independently established.

Therefore the app must not label the work:

> Padma Purāṇa — Rādhā-kuṇḍa Manifestation

unless later verification proves it.

The safe source identity should remain something like:

> Twenty-verse Purāṇic account preserved by Viśvanātha Cakravartī

until provenance is resolved.

---

# 22. Translation

Translation should be distinct from root text, and translation provenance is mandatory whenever a translation is displayed.

A passage may include one or more translations.

Recommended structure:

```text
translationId
passageId
language
translator
editionId
text
status
```

For MVP simplicity, translation may initially be stored as structured fields on the reading edition, but provenance must remain available.

---

# 23. Project Translation

Where the project creates its own translation, it should be identified as such.

Example:

```text
Translator:
Govardhana Pilgrimage Project

Status:
working / approved
```

Do not silently present a project translation as though it belongs to the source edition.

---

# 24. Existing Translation

Where a source file contains an existing translation:

store:

- translator;
- publication;
- edition;
- copyright status if relevant to future use.

Because the app is private, redistribution constraints do not control MVP architecture, but provenance still matters scholarly.

---

# 25. Transliteration

Transliteration may be:

- original to the edition;
- project-normalized;
- automatically generated.

If generated automatically in the future, it should not silently replace checked textual content.

For MVP, use checked or normalized project transliteration.

---

# 26. Citation

A Citation represents an explicit authored relationship between Story content and a Source Passage.

A Citation is **not generated automatically** from text similarity.

It is authored and validated.

---

# 27. Citation ID

Recommended pattern:

```text
citation.rk.manifestation.rka.1
citation.rk.manifestation.mm.421
citation.rk.eternal.gl.7.6
```

Exact naming can remain concise so long as IDs are unique and stable.

---

# 28. Citation Fields

Recommended fields:

```text
id
storySectionId
contentBlockId
sourcePassageId
citationRole
displayMode
note?
order?
```

---

# 29. Citation Role

Controlled roles:

```text
primary_support
parallel_support
quotation_source
background
early_pilgrimage_support
later_local_support
historical_documentary_support
```

These roles allow the project to distinguish evidence types internally.

---

# 30. Citation Role Versus Source Layer

These are different.

Example:

**Source Layer**

A — Primary / Gosvāmī

**Citation Role**

parallel_support

A passage may be A-level evidence but only parallel support for a particular Story claim.

---

# 31. Citation Display

Normal Story reading should usually display:

> Govinda-līlāmṛta 7.6 ›

not:

> A / Primary support / verified / edition.project-v1

Detailed metadata can appear under source details.

---

# 32. Citation Detail

A secondary Source Details screen or sheet may expose:

- Work;
- author;
- locus;
- source layer;
- citation role;
- edition;
- verification status;
- provenance note.

This should be optional.

---

# 33. Multiple Citations for One Claim

A Story paragraph may have multiple sources.

Example:

```text
Rādhā-kuṇḍāṣṭaka 1
Govinda-līlāmṛta 7.6
```

The app should support grouped citations without implying they say exactly the same thing.

Citation notes may explain distinct roles where necessary.

---

# 34. Citation Group

A Citation Group may be useful for one paragraph/block.

Conceptually:

```text
citationGroupId
contentBlockId
citationIds[]
```

This is optional but may simplify rendering.

---

# 35. Quoted Text

Where the Story directly quotes a source:

the Citation should have:

```text
citationRole:
quotation_source
```

and point to the exact Passage from which the quotation comes.

The displayed quote must not exceed what the project has approved.

---

# 36. Source-Layer Assignment

The Work should normally carry the primary source layer classification.

Example:

```text
Mathurā-māhātmya
A_PRIMARY_GOSVAMI

Vraja-bhakti-vilāsa
B_EARLY_PILGRIMAGE

Ananta Dāsa Bābājī
C_LATER_LOCAL

Mukherjee/Habib documentary study
D_HISTORICAL_DOCUMENTARY
```

A particular Citation may further specify its role.

---

# 37. Vraja-bhakti-vilāsa Classification

For this project, Vraja-bhakti-vilāsa is intentionally treated as:

> **B — Early Vraja pilgrimage/localization tradition**

rather than A-level primary Gosvāmī evidence.

The app should preserve this project classification.

---

# 38. Bhakti-ratnākara Classification

Bhakti-ratnākara should likewise be treated primarily as:

> **B — Early Vraja/Gauḍīya pilgrimage and devotional-history tradition**

when used for localization or restoration memory.

For example, the Raghunātha excavation/restoration account is treated by the project as B-level evidence, not as a first-person engineering record.

---

# 39. Later/Local Sources

Sources such as modern parikramā guides or Ananta Dāsa Bābājī may preserve valuable devotional/local tradition.

They should remain C-level unless a claim independently rests on an earlier source.

The app should never backdate a C-level tradition merely because it appears in devotional prose.

---

# 40. Documentary Sources

Historical/documentary sources should remain D-level.

Examples:

- land deeds;
- Mughal documents;
- historical maps;
- gazetteers;
- archival studies.

These can support physical/historical claims but should not be allowed to substitute for A-level theological evidence.

---

# 41. Verification Status

Passages and mappings should support a verification state.

Suggested controlled values:

```text
verified
working
unresolved
```

Optional:

```text
needs_print_check
```

This mirrors project research practice.

---

# 42. Verified

Use when:

- exact source locus has been checked;
- text is reliably identified;
- passage mapping is confirmed.

---

# 43. Working

Use when:

- source identity is likely;
- text is useful for development;
- exact witness/locus still needs confirmation.

Working passages should normally not appear as authoritative citations in a release build unless explicitly approved.

---

# 44. Unresolved

Use when:

- provenance is disputed;
- passage mapping is uncertain;
- variant identity cannot yet be resolved.

The app should not hide this status in research metadata.

---

# 45. Release Citation Rule

A release Story citation should normally require:

```text
sourcePassage.verificationStatus == verified
```

Exceptions must be deliberate and documented.

---

# 46. Original-Witness Mapping

A normalized Passage may map to an original witness location.

Recommended structure:

```text
witnessId
pageNumber
region?
anchorText?
```

For MVP, page number is sufficient.

Future implementations may add bounding boxes or paragraph coordinates.

---

# 47. PDF Page Numbering

The source system should distinguish:

- PDF file page index;
- printed page number.

Example:

```text
pdfPageIndex:
132

printedPageLabel:
118
```

This prevents common scan-pagination errors.

---

# 48. Exact-Passage Navigation

When Story opens a source:

the application should resolve:

```text
Citation
→ Passage ID
→ Preferred Reading Edition
→ Source Reader anchor
```

If a normalized reading edition exists, use it by default.

If not, fall back to the original witness.

---

# 49. Preferred Reading Edition

Each Work may designate:

```text
preferredReadingEditionId
```

This is the edition used for normal Story citation navigation.

The user may still access other witnesses.

---

# 50. Fallback Behavior

Possible resolution order:

```text
1. Preferred normalized reading edition
2. Alternate structured edition
3. Original PDF witness
4. Development error if no usable representation exists
```

A Story citation should never simply fail silently.

---

# 51. Source Reader Title

The source reader should display canonical identity.

Example:

**Śrī Rādhā-kuṇḍāṣṭakam**

**Verse 1**

**Raghunātha dāsa Gosvāmī**

Edition metadata can remain secondary.

---

# 52. Root Text and Translation Layout

Preferred reader hierarchy:

```text
Canonical Locus

Original Text

Transliteration

Translation
```

Where some fields do not exist, omit them.

---

# 53. Commentary Layout

If commentary exists, it should appear under a visibly separate heading:

**Commentary**

Never interleave commentary lines into root text without clear distinction.

---

# 54. Project Note Layout

Project source-critical notes should appear under:

**Source Note**

or:

**Research Note**

not under Commentary.

This prevents confusing project analysis with traditional commentary.

---

# 55. Variants

Variant readings may be represented as Source Notes.

Example:

```text
Variant reading:
Haridāsa Śāstrī edition reads...
```

No full critical apparatus is required for MVP.

---

# 56. Citation Validation

The build pipeline must validate:

- Citation ID exists and is unique;
- Story target exists;
- Source Passage exists;
- Work exists;
- Edition exists;
- preferred reader representation exists;
- witness mapping is valid if declared;
- verification status meets release requirements.

---

# 57. Quotation Validation

Where the Story contains a direct quote, ideally validate that:

- Citation exists;
- quoted source passage exists;
- quote attribution matches Work;
- quotation is not attached to the wrong locus.

Automated exact-string checking may be difficult because of normalized orthography, so editorial validation may remain partly manual.

---

# 58. Canonical Citation Generation

Visible citation strings should normally be generated from metadata.

Example:

```text
Work.shortTitle + " " + displayLocus
```

Result:

> Govinda-līlāmṛta 7.6

This prevents inconsistent manual citation spelling.

---

# 59. Short Title Registry

Each Work may define:

```text
shortTitle:
Govinda-līlāmṛta
```

and:

```text
abbreviation:
GL
```

Normal reader-facing citations should use the short title.

Research details may use abbreviations.

---

# 60. Canonical Citation Examples

Recommended reader-facing style:

> Śrīmad-Bhāgavatam 10.36.16

> Caitanya-caritāmṛta, Madhya 18.5

> Mathurā-māhātmya 421

> Rādhā-kuṇḍāṣṭaka 1

> Govinda-līlāmṛta 7.6

> Bhakti-ratnākara 5.545

---

# 61. Edition Citation

Normal Story prose should not include edition details unless textual variation makes them relevant.

Edition information belongs in Source Details.

---

# 62. Translation Citation

If a displayed translation comes from a published translator:

the Source Details should identify the translator.

If the Story paraphrases independently, the citation points to the source text rather than implying the displayed paraphrase is that edition's translation.

---

# 63. Source Independence

The Story should cite the Work/Passage even if the app representation later changes.

Example:

Today:

```text
Govinda-līlāmṛta 7.6 → project normalized text
```

Later:

```text
Govinda-līlāmṛta 7.6 → improved critical text
```

The Story citation remains unchanged.

---

# 64. Source Import Discipline

A source should not enter the app merely because a file exists in the project.

Each included Work should receive:

- canonical metadata;
- source-layer classification;
- edition metadata;
- structural segmentation;
- passage IDs;
- verification status.

This prevents the Library from becoming a folder dump.

---

# 65. MVP Source Corpus Rule

MVP should include only sources that are:

1. cited by the Rādhā-kuṇḍa Story;
2. useful for surrounding-context reading;
3. sufficiently structured to justify inclusion.

A complete source-corpus manifest will be defined in MVP-07.

---

# 66. Source Text Normalization

Normalization may include:

- Unicode cleanup;
- correcting obvious encoding corruption;
- consistent line breaks;
- identifying verse boundaries;
- heading structure;
- consistent IAST representation.

Normalization must not silently alter substantive readings.

Substantive corrections should be documented.

---

# 67. OCR-Derived Text

OCR-derived text must be identified as such where reliability is uncertain.

Do not treat OCR as equivalent to a checked transcription.

For difficult Sanskrit/Bengali scans, the project should continue preferring searchable transcriptions for reading and printed witnesses for verification when appropriate.

---

# 68. Image-Only Witnesses

Image-only sources may still be included as original witnesses.

They are not required to become searchable source texts during MVP.

Examples include scans where the project presently relies on visual verification. 
---

# 69. Passage Granularity

Preferred passage granularity:

## Verse works

one verse per Passage.

## Numbered prose/texts

one numbered unit per Passage.

## Unnumbered historical prose

paragraph or logical section.

## Scans only

page as fallback.

Granularity should support meaningful citation and reading.

---

# 70. Source Ranges

A Story claim may cite a range.

Example:

> Caitanya-caritāmṛta Madhya 18.3–15

The model should support:

```text
startPassageId
endPassageId
```

or a Citation storing explicit startPassageId and endPassageId values.

---

# 71. Passage Group — Deferred

No first-class `PassageGroup` entity is implemented in the MVP. Range Citations store `startPassageId` and `endPassageId` directly. A PassageGroup abstraction may be added later if repeated range/group use demonstrates a concrete need; canonical Passage IDs will not change.

---

# 72. Range Navigation

Opening a range citation should:

- land on the first passage;
- indicate the cited range;
- allow continuous reading through the range.

---

# 73. Multiple Works Supporting One Statement

The app should allow a Story block to cite:

```text
Rādhā-kuṇḍāṣṭaka 1
Mathurā-māhātmya 421
Govinda-līlāmṛta 7.6
```

without implying they have identical evidentiary function.

Citation roles can preserve that distinction.

---

# 74. Negative Findings

The project sometimes makes important negative findings.

Example:

> The Bhāgavatam root verses do not narrate the twin-kuṇḍa manifestation.

This is supported by checked source boundaries rather than by a verse that says "this is omitted."

The app should allow a Research Note attached to the Story citation cluster explaining such negative findings.

---

# 75. Source-Critical Statements

Statements such as:

> "The exact Purāṇic recension remains unresolved"

must link to source/research metadata, not be presented as scriptural quotation.

The app should visually distinguish:

- quotation;
- source paraphrase;
- project synthesis;
- source-critical note.

---

# 76. Project Synthesis

The project uses controlled synthesis phrases such as:

> "visible littleness, revealed fullness"

These are not quotations.

The app should never display quotation styling around project synthesis unless explicitly labeled as project language.

---

# 77. Source-Layer UI Philosophy

Default Story:

minimal citation display.

Source Reader:

show canonical Work and locus.

Source Details:

show source layer, edition, provenance, verification.

This layered approach preserves both readability and rigor.

---

# 78. MVP Source Details Screen

Recommended fields:

```text
Work
Author
Canonical locus
Source layer
Edition
Translation source
Verification status
Original witness
Source note
```

Not every field must appear when empty.

---

# 79. Citation Tap Behavior

Normal tap:

> Open exact Passage.

Secondary long-press/context action later:

> View Citation Details.

No intermediate citation dialog should block normal reading.

---

# 80. Citation Color/Style

The UX specification should eventually choose a restrained visual treatment.

Architecturally, citations should expose:

```text
isInteractive = true
```

while remaining readable as ordinary bibliographic text.

---

# 81. Source Reader Origin

When entering from Story, the navigation state should store:

```text
originStoryId
originSectionId
originBlockId
originScrollPosition
citationId
```

This supports exact return.

---

# 82. Source Reader Independent Entry

When entering from Library:

origin is Library.

When entering from Search:

origin is Search.

The Passage entity is unchanged.

---

# 83. Search Result Source Identity

Source search results should display:

```text
Work title
Locus
Text snippet
```

not filenames.

---

# 84. Search Across Editions

MVP should index only the preferred normalized reading edition by default.

Otherwise the same verse might appear multiple times from several editions.

Original witnesses should not create duplicate search results unless intentionally enabled later.

---

# 85. Search Commentary

If commentary is included:

search results should identify:

> Commentary

versus:

> Root Text

This prevents users from mistaking commentary wording for the root source.

---

# 86. Citation Integrity Audit

Before each content release, produce a machine-readable citation audit:

```text
Total citations
Resolved citations
Unresolved citations
Working citations
Missing targets
Unverified targets
```

Release should require:

```text
Missing targets = 0
```

---

# 87. Work Registry

The project should maintain one authoritative Work Registry.

Example columns:

```text
Work ID
Title
Author
Abbreviation
Parent Work
Source Layer
Preferred Edition
Status
```

This becomes the canonical source identity list.

---

# 88. Edition Registry

Similarly:

```text
Edition ID
Work ID
Description
Source Files
Editor/Translator
Representation
Preferred Reading?
Verification Notes
```

---

# 89. Passage Registry

Passages may be generated from structured source content rather than maintained manually in a giant table.

However, canonical Passage IDs must be deterministic and validated.

---

# 90. First Vertical Slice Source Set

For the first code slice, use a deliberately small source set.

Recommended:

## Rādhā-kuṇḍāṣṭaka

At least verses 1–3.

## Mathurā-māhātmya

At least 418–423.

## Twenty-verse manifestation unit

At least enough verified structured material to test exact source navigation.

This produces different source structures and tests the architecture realistically.

---

# 91. Why These First Sources

They test:

- independent short work;
- larger numbered work;
- source-critical/commentarial material;
- Sanskrit;
- translation;
- passage navigation;
- exact citation targets.

That makes them a stronger test than loading three structurally identical texts.

---

# 92. Acceptance Test Example

Story contains:

> Raghunātha describes the exchange as playful dharma speech.

Citation:

**Rādhā-kuṇḍāṣṭaka 1 ›**

Tap.

App resolves:

```text
citation.rk.manifestation.rka.1
↓
passage.radha-kundastaka.1
↓
work.radha-kundastaka
↓
preferred reading edition
```

Source Reader displays verse 1.

User proceeds to verse 2.

User taps Return to Story.

Exact Story position is restored.

---

# 93. Source Architecture Non-Goals

MVP-03 does not attempt:

- full critical editions;
- automatic collation;
- automatic OCR correction;
- semantic citation generation;
- web source synchronization;
- public bibliographic export;
- Zotero integration;
- multi-user annotation;
- automated translation.

These may be considered later.

---

# 94. Source Architecture Acceptance Criteria

MVP-03 succeeds if:

1. every Work has a stable identity;
2. composite works can contain independently citable subworks;
3. editions are distinct from works;
4. canonical passages are independent of PDF pagination;
5. root text is distinct from commentary;
6. translation provenance can be preserved;
7. citations explicitly target passages;
8. citations can have evidentiary roles;
9. A/B/C/D layers remain available;
10. original witnesses can be mapped;
11. exact source navigation is deterministic;
12. unresolved provenance can remain unresolved;
13. release builds can validate citation integrity.

---



# 97. Next Specification

After MVP-03, proceed to:

## MVP-04 — Library & Reader Architecture Specification

That document will define:

- how included books appear in the Library;
- normalized text representation;
- reader hierarchy;
- tables of contents;
- source passage display;
- continuous reading;
- original PDF witnesses;
- search within books;
- bookmarks;
- reading positions;
- source-reader state;
- typography;
- multilingual rendering;
- and the exact behavior of Story → Source → Story reading.

---

## Approval

**MVP-03 v1.0 — APPROVED**
