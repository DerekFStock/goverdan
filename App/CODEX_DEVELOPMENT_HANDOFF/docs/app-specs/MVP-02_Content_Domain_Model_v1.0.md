# GOVARDHANA PILGRIMAGE APP

## MVP-02 — Content & Domain Model Specification

**Document ID:** MVP-02  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00, MVP-01  
**Primary platform:** iPhone  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document defines the core content objects and relationships used by the Rādhā-kuṇḍa Story MVP.

Its purpose is to ensure that the application is built around a stable, reusable content model rather than hard-coded Swift views.

The model must support:

- long-form Story reading;
- ordered Story sections;
- source works;
- editions;
- exact source passages;
- citations;
- source navigation;
- images;
- bookmarks;
- reading positions;
- search indexing;
- future expansion.

The model should remain small enough for the MVP while avoiding decisions that would make later expansion difficult.

---

# 2. Core Modeling Principle

The MVP should distinguish between:

## Content identity

What something **is**.

Example:

> Govinda-līlāmṛta 7.6

## Presentation

How that content is shown on iPhone.

Example:

- Story citation chip;
- source-reader block;
- search result;
- bookmark row.

Content identity must not depend on UI implementation.

---

# 3. Canonical IDs

Every durable content entity should have a stable canonical identifier.

IDs should:

- be human-readable where practical;
- remain stable across content revisions;
- avoid display-text dependence;
- avoid database-generated meaning;
- never depend on screen order.

Recommended style:

```text
story.radhakunda

story.radhakunda.manifestation

work.govinda-lilamrta

edition.govinda-lilamrta.project-text-v1

passage.govinda-lilamrta.7.6

citation.rk.manifestation.gl.7.6
```

The exact syntax may be refined in MVP-03 and MVP-05.

---

# 4. Primary MVP Entities

The MVP requires these principal content entities:

1. Story
2. Story Section
3. Content Block
4. Source Work
5. Edition
6. Source Passage
7. Citation
10. Image Asset
11. Bookmark
12. Reading Position

Optional support entities:

11. Search Document
12. Source Note
13. Original Witness

---

# 5. Story

A Story represents one complete literary work inside the app.

For MVP:

```text
Story
ID: story.radhakunda
Title: The Story of Śrī Rādhā-kuṇḍa
```

Recommended fields:

```text
id
title
subtitle?
shortTitle?
description?
sectionIds[]
version
status
```

The Story should not contain prose directly.

Its content is composed from ordered Story Sections.

---

# 6. Story Section

A Story Section represents a major literary section.

Example:

```text
ID:
story.radhakunda.manifestation

Title:
The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa
```

Recommended fields:

```text
id
storyId
partId?
sectionNumber
title
subtitle?
slug
order
contentBlocks[]
previousSectionId?
nextSectionId?
version
status
```

---

# 7. Story Part

The final Story may contain broader literary parts.

Example:

```text
PART I
Manifestation and Meaning
```

A Story Part is useful but not strictly required for MVP.

If included:

```text
id
storyId
title
order
sectionIds[]
```

The Story Table of Contents may group Story Sections by Part.

---

# 8. Content Block

Story prose should be represented as ordered blocks rather than one giant HTML string.

Recommended block types:

```text
paragraph
heading
subheading
quote
verse
image
citation_group
note
divider
```

A block can remain flexible enough to render into SwiftUI.

---

# 9. Paragraph Block

Example fields:

```text
type: paragraph
id
text
inlineReferences[]
```

The text may use Markdown or HTML depending on MVP-05.

Important requirement:

citations and cross-links must not be encoded only through visible text.

They need structured references.

---

# 10. Heading Block

Fields:

```text
type: heading
level
text
anchorId?
```

Headings may support in-section navigation later.

---

# 11. Quote Block

Used for primary quotations.

Fields:

```text
type: quote
originalText?
transliteration?
translation?
citationIds[]
```

A quote may contain one or more language representations.

---

# 12. Verse Block

A Verse Block is useful for structured Sanskrit/Bengali/Braj presentation.

Suggested fields:

```text
type: verse
originalScript?
transliteration?
translation?
sourcePassageId?
citationId?
```

This avoids treating verse text as ordinary prose.

---

# 13. Image Block

Fields:

```text
type: image
imageAssetId
caption?
credit?
altText?
```

The Story does not own image files directly.

It references Image Assets.

---

# 14. Inline Reference

A paragraph may contain structured inline references.

Example:

```text
text:
"Raghunātha describes the exchange as narma-dharmokti-raṅgaiḥ."

reference:
passage.radhakundastaka.1
```

The rendering layer may turn this into a tappable citation.

---

# 15. Source Work

A Source Work represents the abstract work independently of a particular edition.

Example:

```text
ID:
work.govinda-lilamrta

Title:
Govinda-līlāmṛta

Author:
Kṛṣṇadāsa Kavirāja Gosvāmī
```

Recommended fields:

```text
id
title
alternateTitles[]
authorIds? or authorText
language[]
sourceLayer
description?
canonicalCitationStyle
editionIds[]
```

---

# 16. Source Layer

The MVP should preserve the research project's evidence layers.

Controlled values:

```text
A_PRIMARY_GOSVAMI
B_EARLY_PILGRIMAGE
C_LATER_LOCAL
D_HISTORICAL_DOCUMENTARY
```

Display values may remain:

- A — Primary / Gosvāmī
- B — Early pilgrimage
- C — Later/local
- D — Historical/documentary

Not every screen must show this value.

---

# 17. Edition

An Edition represents the particular digital or printed witness being used.

Example:

```text
work:
Govinda-līlāmṛta

edition:
Project normalized Sanskrit text based primarily on Haridāsa Dāsa,
secondarily Haridāsa Śāstrī
```

Recommended fields:

```text
id
workId
title
editor?
translator?
publisher?
publicationYear?
language[]
representationType
sourceFile?
originalWitnessId?
isPrimaryReadingEdition
version
```

---

# 18. Representation Type

Controlled values may include:

```text
normalized_text
epub
pdf
scan
html
markdown
```

A Source Work may have several editions/representations.

---

# 19. Original Witness

An Original Witness represents a source PDF or scan preserved for verification.

Recommended fields:

```text
id
workId
editionId?
title
filePath
pageCount?
description?
```

A normalized source text may reference an Original Witness.

---

# 20. Source Passage

A Source Passage is the canonical navigable unit inside a Source Work.

Examples:

```text
Rādhā-kuṇḍāṣṭaka 1
Govinda-līlāmṛta 7.6
Mathurā-māhātmya 421
Caitanya-caritāmṛta Madhya 18.5
Bhakti-ratnākara 5.545
```

This is one of the most important entities in the application.

---

# 21. Source Passage Fields

A Source Passage is an edition-independent canonical identity. Recommended fields:

```text
id
workId
canonicalLocus
displayLocus
parentPassageId?
order
previousPassageId?
nextPassageId?
verificationStatus
```

Textual content belongs to an edition-specific **Passage Representation**, not to canonical Passage identity.

---

# 22. Passage Representation

A Passage Representation attaches edition-specific content to one canonical Source Passage.

Recommended fields:

```text
id
passageId
editionId
originalText?
transliteration?
translation?
translationCredit?
commentary?
sourceNotes[]
originalWitnessLocator?
searchText?
```

The preferred reading edition determines which representation is shown by default. A later edition can replace the reading representation without changing the canonical Passage ID.

# 23. Passage Hierarchy

Source works may have multiple levels.

Example:

```text
Govinda-līlāmṛta
  Sarga 7
    Verse 1
    Verse 2
    ...
    Verse 6
```

This can be represented with:

```text
parentPassageId
```

A chapter/Sarga can itself be a Source Passage container.

---

# 23. Canonical Locus

Each passage should have a stable canonical locus string.

Examples:

```text
1
7.6
421
Madhya 18.5
5.545
```

This field exists independently of the internal ID.

The internal ID can remain machine-friendly.

---

# 24. Display Locus

Some works may require a display form different from the stored canonical value.

Example:

```text
canonicalLocus:
madhya.18.5

displayLocus:
Madhya 18.5
```

This allows consistent UI formatting.

---

# 25. Citation

A Citation links a Story location to a Source Passage.

Example:

```text
Story Section:
Manifestation

Source Passage:
Rādhā-kuṇḍāṣṭaka 1
```

Recommended fields:

```text
id
storySectionId
contentBlockId
sourcePassageId
label
citationRole
note?
order?
```

---

# 26. Citation Role

Possible controlled values:

```text
primary_support
parallel_support
quotation_source
historical_support
local_tradition
background
```

This is useful internally even if not always visible.

---

# 27. Citation Label

A citation may display:

```text
Rādhā-kuṇḍāṣṭaka 1
```

or:

```text
Govinda-līlāmṛta 7.6
```

The label may usually be generated from Source Work + display locus.

It should not need to be hand-authored except when stylistically necessary.

---

# 28. Citation Navigation

A Citation always resolves to:

```text
Citation
→ Source Passage
→ Source Work
```

The application must never treat a Citation as a plain text string when a structured target exists.

---

# 29. Source Note

A Source Note is optional contextual metadata attached to a Source Passage.

Examples:

- translation note;
- variant reading;
- edition note;
- provenance caution.

Recommended fields:

```text
id
sourcePassageId
type
text
```

MVP can expose these sparingly.

---

# 30. Image Asset

An Image Asset represents one reusable image.

Fields:

```text
id
filePath
title?
caption?
credit?
source?
altText?
width?
height?
```

A Story Section may reference the same image in multiple contexts without duplicating the image file.

---

# 31. Bookmark

A Bookmark is user-generated local state.

Fields:

```text
id
targetType
targetId
createdAt
label?
position?
```

Target types for MVP:

```text
story_position
source_passage
```

---

# 32. Story Bookmark Position

A Story bookmark may need:

```text
storySectionId
contentBlockId?
scrollAnchor?
```

Prefer semantic anchors over raw pixel offsets where possible.

---

# 33. Source Bookmark

A Source bookmark should normally target:

```text
sourcePassageId
```

This is more stable than storing only scroll position.

---

# 34. Reading Position

Reading Position is not the same as Bookmark.

It is automatically updated.

Recommended fields:

```text
targetType
targetId
subLocation?
updatedAt
```

Examples:

```text
Story:
story.radhakunda.manifestation
block-27

Source:
work.govinda-lilamrta
passage.govinda-lilamrta.7.14
```

---

# 35. Story Reading Position

Recommended semantic hierarchy:

1. Story Section
2. Content Block
3. optional intra-block offset

The app should avoid depending exclusively on a raw scroll pixel value because content may change between versions.

---

# 36. Source Reading Position

Preferred:

```text
sourcePassageId
```

Optional:

```text
intraPassageOffset
```

This allows reliable restore even after text layout changes.

---

# 37. Search Document

Search may index Story and Sources through a normalized Search Document representation.

Conceptually:

```text
id
entityType
entityId
title
body
keywords?
```

This can later feed SQLite FTS.

It does not need to be a canonical authored entity.

It may be generated during packaging.

---

# 38. Searchable Story Content

Story search should index:

- section title;
- body prose;
- quotations;
- transliterations where useful.

Search should not index hidden internal metadata unless intentionally desired.

---

# 39. Searchable Source Content

Source search should index:

- work title;
- canonical locus;
- original text;
- transliteration;
- translation.

Commentary may be indexed if included in the reading edition.

---

# 40. Ordering

Ordering should be explicit.

Do not rely on:

- filesystem alphabetical order;
- database insertion order;
- object IDs.

Story Sections need:

```text
order
```

Source Passages need:

```text
order
```

Content Blocks need their list position or explicit order.

---

# 41. Status

Content entities should support development state.

Suggested controlled values:

```text
draft
reviewed
approved
deprecated
```

For MVP releases, only approved Story/source content should be packaged unless explicitly testing drafts.

---

# 42. Versioning

Content versions should remain separate from application versions.

Example:

```text
App version:
0.3

Content package:
radhakunda-content-0.8
```

This allows research/content updates without confusing them with Swift code changes.

---

# 43. Story Versioning

A Story may contain:

```text
version: 0.4
```

but stable IDs should remain unchanged when prose is revised.

Do not create:

```text
story.radhakunda.manifestation.v4
```

as a new identity every time wording changes.

---

# 44. Passage Versioning

If a normalized source passage is corrected:

- keep the same canonical passage ID;
- increment edition/content version;
- record significant corrections separately if needed.

The passage remains the same textual locus.

---

# 45. Stable-ID Rule

The following should **not** change an ID:

- spelling correction;
- revised translation;
- added note;
- improved citation;
- image replacement;
- revised Story prose.

An ID changes only when the underlying conceptual entity changes.

---

# 46. Relationship Summary

Core relationships:

```text
Story
  has many Story Sections

Story Section
  has many Content Blocks

Content Block
  may have many Citations

Citation
  targets one Source Passage

Source Work
  has many Editions

Edition
  has many Source Passages

Source Passage
  belongs to one Source Work
  is edition-independent

Passage Representation
  belongs to one Source Passage
  belongs to one Edition
  may have parent/child passages

Image Asset
  may be referenced by Story Blocks

Bookmark
  targets Story position or Source Passage

Reading Position
  tracks Story or Source reading state
```

---

# 47. Entity Relationship Overview

```text
STORY
  │
  └── STORY SECTION
        │
        └── CONTENT BLOCK
              │
              └── CITATION
                    │
                    ▼
              SOURCE PASSAGE
                    │
                    ▼
               SOURCE WORK
                    │
                    └── EDITION
                          │
                          └── ORIGINAL WITNESS
```

User state:

```text
BOOKMARK
READING POSITION
```

references Story or Source entities.

---

# 48. First Vertical Slice Minimum Data

The initial implementation needs only:

```text
1 Story
1 Story Section
several Content Blocks
3 Source Works
3–10 Source Passages
3+ Citations
0–2 Images
Bookmarks
Reading Position
```

This is enough to prove the domain model before loading the complete corpus.

---

# 49. Example Story Section

Conceptual example:

```text
id:
story.radhakunda.manifestation

title:
The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa

order:
3

blocks:
[
  paragraph...
  quote...
  paragraph...
  citation...
]
```

---

# 50. Example Source Work

```text
id:
work.radhakundastaka

title:
Śrī Rādhā-kuṇḍāṣṭakam

author:
Raghunātha dāsa Gosvāmī

sourceLayer:
A_PRIMARY_GOSVAMI
```

---

# 51. Example Source Passage

```text
id:
passage.radhakundastaka.1

workId:
work.radhakundastaka

canonicalLocus:
1

displayLocus:
Verse 1
```

---

# 52. Example Citation

```text
id:
citation.rk.manifestation.rka1

storySectionId:
story.radhakunda.manifestation

contentBlockId:
rk-manifestation-block-14

sourcePassageId:
passage.radhakundastaka.1

citationRole:
primary_support
```

---

# 53. Example Edition

```text
id:
edition.stavavali.project-v1

workId:
work.stavavali

representationType:
normalized_text

isPrimaryReadingEdition:
true
```

For nested works such as Rādhā-kuṇḍāṣṭaka inside Stavāvalī, the exact work/subwork model will be finalized in MVP-03.

---

# 54. Composite Works

Some sources contain smaller independently cited works.

Example:

**Stavāvalī**

contains:

- Manaḥ-śikṣā
- Rādhā-kuṇḍāṣṭaka
- Vraja-vilāsa-stava
- Vilāpa-kusumāñjali

The model must support this.

Two viable approaches:

## A. Parent/child Source Work

```text
work.stavavali
  └── work.radhakundastaka
```

## B. One Source Work with nested Passage hierarchy

MVP-03 should make the final decision.

The domain model must permit either without major rework.

---

# 55. Work Relationships

Recommended optional field:

```text
parentWorkId?
```

This allows:

```text
Rādhā-kuṇḍāṣṭaka
parentWork:
Stavāvalī
```

while still allowing the prayer to be cited as an independent work.

---

# 56. Translation Provenance

A translation should eventually be traceable to its source.

Possible representation:

```text
translationText
translationCredit?
translationEditionId?
```

MVP-03/05 will decide how detailed this needs to be.

The model should not assume every translation is authored by the app project.

---

# 57. Text Variants

The MVP does not require a critical-apparatus engine.

However, the model should allow a passage note such as:

```text
type:
variant

text:
"Local witness reads..."
```

This avoids future redesign.

---

# 58. Commentary

Some source editions include commentary.

Commentary should not be merged silently into root source text.

Possible model:

```text
Source Passage
  root text

Commentary Passage
  references Source Passage
```

or a commentary field tied to an Edition.

MVP-04 will refine this.

---

# 59. Source Integrity Rule

A Source Passage must never silently combine text from different editions.

If the normalized reading edition synthesizes witnesses, that synthesis must be declared at the Edition level.

---

# 60. Story Source Discipline

Every Story citation should point to a controlled Source Passage.

Story prose may contain interpretive synthesis, but the app must never fabricate source relationships based on text similarity.

Relationships are authored explicitly.

---

# 61. Content Validation Rules

Before packaging, validate:

- every entity ID is unique;
- every referenced Story ID exists;
- every Citation target exists;
- every Source Passage references a valid Source Work;
- every Passage Representation references a valid Source Passage and Edition;
- every Edition references a valid Source Work;
- every Image reference exists;
- Story ordering is valid;
- Source Passage ordering is valid;
- no broken parent relationships;
- no cyclic passage hierarchy;
- no missing required fields.

---

# 62. Search Validation

Search index generation should verify:

- every indexed entity exists;
- each result can navigate to a valid target;
- hidden/deprecated content is excluded.

---

# 63. Deprecated Content

If content is replaced:

```text
status:
deprecated
```

The old entity may remain in development archives but should not appear in release builds.

---

# 64. Data Storage Independence

This domain specification does not yet require:

- SQLite tables;
- Swift structs;
- JSON files;
- Core Data;
- GRDB.

The same conceptual model should be implementable in any of those.

MVP-05 and MVP-06 will map the domain model to actual file and Swift representations.

---

# 65. Future Expansion Compatibility

Although maps and pilgrimage places are deferred, the model should later allow additional entities such as:

```text
Place
Route
Prayer
Person
FieldObservation
MapLayer
```

without changing the identities of:

- Story;
- Source Work;
- Source Passage;
- Citation.

This is why citations should point to stable Source Passages now.

---

# 66. No Premature Place Entity

For MVP, do not create Place entities merely because the Story mentions Rādhā-kuṇḍa, Govardhana, or Mānasa-gaṅgā.

Place modeling belongs to future pilgrimage expansion.

This keeps the current domain model focused.

---

# 67. No Premature Person Entity

Likewise, people may remain ordinary Story/source text during MVP.

A reusable Person model can be added when needed.

Do not expand scope merely because future architecture will eventually benefit from it.

---

# 68. Serialization Requirements

Whatever authoring format is chosen later must preserve:

- Unicode;
- ordered blocks;
- stable IDs;
- relationships;
- optional fields;
- multilingual content.

The format should remain human-reviewable where possible.

---

# 69. Human Readability

The canonical content files should ideally allow a developer/researcher to inspect:

```text
What does this citation point to?
What is this Story section?
What passage ID represents GL 7.6?
```

without querying an opaque binary database.

Generated app databases may be binary, but source content should remain intelligible.

---

# 70. Recommended Separation

Long-term structure:

```text
Authoring Content
  Markdown / YAML / JSON / source texts

        ↓ build

Validated Content Package

        ↓ import

App Database / Index
```

The exact formats belong to MVP-05.

---

# 71. Domain Acceptance Criteria

MVP-02 succeeds if:

1. Story content can be represented without Swift hard-coding.
2. Story Sections can be ordered.
3. multilingual blocks can be represented.
4. a Story citation can point reliably to an exact Source Passage.
5. Source Works are distinct from editions.
6. Source Passages can form hierarchies.
7. original witnesses can coexist with normalized reading text.
8. bookmarks and reading position reference stable entities.
9. content can be versioned without changing identity.
10. later pilgrimage entities can be added without replacing the MVP model.

---



# 74. Next Specification

After MVP-02, proceed to:

## MVP-03 — Source & Citation Architecture Specification

That document will resolve the most important scholarly implementation questions:

- canonical work IDs;
- subworks;
- canonical loci;
- editions;
- normalized texts;
- translations;
- commentary;
- citation roles;
- exact passage targeting;
- source-layer handling;
- original-witness mapping;
- source provenance;
- and validation of every Story citation.

---

## Approval

**MVP-02 v1.0 — APPROVED**
