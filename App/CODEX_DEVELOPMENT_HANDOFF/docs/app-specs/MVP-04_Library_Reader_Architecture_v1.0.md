# GOVARDHANA PILGRIMAGE APP

## MVP-04 — Library & Reader Architecture Specification

**Document ID:** MVP-04  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00, MVP-01, MVP-02, MVP-03  
**Primary platform:** iPhone  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document defines how source works are presented, opened, read, searched, bookmarked, and cross-referenced inside the Rādhā-kuṇḍa Story MVP.

The Library and Source Reader are secondary to the Story, but they are essential to the app's defining scholarly function:

> **A citation in the Story must open the actual source at the exact passage, while still allowing the user to read the larger work naturally.**

This specification defines:

- Library organization;
- work presentation;
- source-reader behavior;
- normalized reading editions;
- original PDF witnesses;
- source tables of contents;
- passage navigation;
- reading position;
- search within a work;
- bookmarks;
- multilingual typography;
- and Story → Source → Story navigation.

---

# 2. Reader Philosophy

The source reader should feel like a serious reading environment, not a citation popup.

A source passage opened from the Story should allow the user to:

1. immediately recognize the cited verse or section;
2. read the original text;
3. read transliteration and translation where available;
4. continue into preceding or following passages;
5. move through the complete work;
6. search within the work;
7. bookmark meaningful passages;
8. view the original printed witness when useful;
9. return to the exact Story position.

---

# 3. Library Scope

The MVP Library is deliberately curated.

It should contain only works that materially support the Rādhā-kuṇḍa Story.

The Library should not initially expose every file in the larger Govardhana research collection.

A work enters the MVP Library only after it has:

- canonical Work metadata;
- source-layer classification;
- at least one usable Edition;
- structured navigation;
- passage IDs;
- sufficient text quality for its intended use.

---

# 4. Library Top-Level Organization

Recommended MVP organization:

```text
LIBRARY

Primary / Gosvāmī
Early Pilgrimage
Later / Local
Historical / Documentary
```

Only categories containing included works should be shown.

Because the Library is primarily a study context, the evidence-layer organization is appropriate here.

---

# 5. Library Home Screen

The Library home may contain:

### Continue Reading

The last independently read source work.

### Categories

- Primary / Gosvāmī
- Early Pilgrimage
- Later / Local
- Historical / Documentary

### Recent

Optional small list of recently opened works.

### Search Library

A search entry point.

Avoid turning Library into a graphical bookshelf unless that actually improves usability.

---

# 6. Work List

Each Work row should display:

- canonical title;
- author;
- optionally source layer.

Example:

> **Govinda-līlāmṛta**  
> Kṛṣṇadāsa Kavirāja Gosvāmī  
> Primary / Gosvāmī

Do not show:

- internal file names;
- mount paths;
- implementation IDs;
- source-import filenames.

---

# 7. Work Detail Screen

A Work Detail screen is used for every Library Work for consistency; works with multiple representations expose the additional actions described below.

Possible structure:

## Govinda-līlāmṛta

**Kṛṣṇadāsa Kavirāja Gosvāmī**

Primary actions:

- Continue Reading
- Table of Contents
- Search This Work

Secondary:

- Source Details
- View Original Witness

If a Work has only one representation and no special metadata, opening the Work may go directly to the reader.

---

# 8. Work Metadata

Source Details may expose:

- title;
- author;
- parent work;
- source layer;
- preferred reading edition;
- editor;
- translator;
- publication information;
- normalization provenance;
- verification notes.

This metadata should remain secondary to reading.

---

# 9. Preferred Reading Edition

Each Work should have one preferred reading representation used by default.

Preferred forms:

1. structured normalized text;
2. structured EPUB/HTML if used internally;
3. PDF witness only when no better reading representation exists.

The user should normally encounter the clean structured text first.

---

# 10. Normalized Reading Edition

The normalized reading edition should be optimized for the application.

It may normalize:

- Unicode;
- line breaks;
- heading structure;
- verse boundaries;
- transliteration consistency;
- text encoding;
- chapter hierarchy.

It must not silently rewrite substantive source readings.

Any significant editorial correction should be recorded in Edition metadata.

---

# 11. Source Reader Structure

The Source Reader should support a hierarchy such as:

```text
WORK
  SECTION / CHAPTER / SARGA
    PASSAGE
```

Examples:

```text
Govinda-līlāmṛta
  Sarga 7
    7.1
    7.2
    ...
```

```text
Stavāvalī
  Rādhā-kuṇḍāṣṭaka
    Verse 1
    Verse 2
    ...
```

---

# 12. Source Reader Entry Modes

The same Source Reader can be entered from several contexts.

## A. Story Citation

Open exact cited passage.

## B. Library

Open saved reading position or work beginning.

## C. Search

Open exact matching passage.

## D. Bookmark

Open bookmarked passage.

Navigation context should be preserved separately from source content.

---

# 13. Story Citation Entry

When opened from a Story citation, the Source Reader must:

- open exact passage;
- mark cited passage;
- know Story origin;
- expose Return to Story.

This is the highest-priority entry behavior.

---

# 14. Independent Library Entry

When opened from Library:

- resume previous source reading position if available;
- otherwise open work beginning or TOC.

No Return to Story action is necessary unless the current navigation stack originated there.

---

# 15. Reader Header

Recommended structure:

```text
‹ Return to Story

Rādhā-kuṇḍāṣṭaka
Verse 1
```

or, for independent reading:

```text
‹ Library

Govinda-līlāmṛta
Sarga 7
```

Author name may appear in work metadata rather than persistently in the reader header.

---

# 16. Passage Layout

Preferred passage layout:

## Locus

**7.6**

## Original text

Primary source text.

## Transliteration

Where appropriate.

## Translation

Where available and approved.

## Commentary

Clearly separated if included.

## Source Notes

Clearly marked as editorial/project notes.

---

# 17. Original Script

The reader should support original script where present.

Expected scripts include:

- Devanāgarī;
- Bengali;
- Roman/IAST;
- English.

If the source edition contains only Roman transliteration, the app should not generate Devanāgarī merely to fill a UI field.

---

# 18. Transliteration

Transliteration should be displayed when it materially assists reading.

For Sanskrit/Bengali texts, a common reader structure may be:

```text
Original Script
IAST
Translation
```

But this is not mandatory for every Work.

The content model should determine what exists.

---

# 19. Translation

Translations must remain traceable to their provenance.

The reader should not imply that every translation comes from the same edition.

Source Details may identify:

- translator;
- project translation;
- published translation;
- working translation.

---

# 20. Translation Display Options

MVP default:

show translation where available.

Potential later option:

- hide translation.

This is useful for direct Sanskrit/Bengali reading but is not required for first implementation.

---

# 21. Commentary

Where commentary is included, it must be visually distinct.

Suggested hierarchy:

**Commentary**

followed by commentary prose.

Root text and commentary must never appear as one undifferentiated block.

---

# 22. Multiple Commentaries

Multiple commentaries are out of MVP scope unless one source Work specifically requires them.

Future architecture may support commentary selection.

Do not build a general commentary-comparison system yet.

---

# 23. Passage Highlighting

When a citation opens an exact passage:

- the passage may receive a subtle temporary background;
- or a left-edge marker;
- or a "Cited Passage" label.

The treatment should remain restrained.

The reader should still feel like a book.

---

# 24. Return to Cited Passage

If the user scrolls far away from the cited passage, a contextual action may allow:

**Return to Cited Passage**

This is desirable but may be deferred if navigation complexity increases.

---

# 25. Continuous Reading

Source works should be readable continuously.

The reader should not require opening each verse on a separate screen.

Preferred:

```text
7.5
[text]

7.6
[text]

7.7
[text]
```

within a scrollable section/chapter.

This makes surrounding-context reading natural.

---

# 26. Section Boundaries

For long works, reading can be segmented by chapter/Sarga.

Example:

- one Sarga loaded as one reading document;
- passages inside that Sarga individually anchored.

This balances performance and navigation.

---

# 27. Previous / Next Chapter

At the end of a major section:

**Previous Sarga**

**Next Sarga**

may be offered.

This is more useful than individual verse navigation buttons.

---

# 28. Passage Anchors

Every canonical passage should have a stable anchor.

Example:

```text
passage.govinda-lilamrta.7.6
```

The reader must be able to scroll directly to it deterministically.

---

# 29. Source Table of Contents

TOC should represent the actual structure of the Work.

Examples:

### Govinda-līlāmṛta

- Sarga 1
- Sarga 2
- ...
- Sarga 23

### Stavāvalī

- Śacī-sūnv-aṣṭaka
- Gaurāṅga-stava-kalpa-taru
- Manaḥ-śikṣā
- Rādhā-kuṇḍāṣṭaka
- Vraja-vilāsa-stava
- Vilāpa-kusumāñjali
- ...

A TOC should not be generated from visual page headings in a PDF.

It should come from structured metadata.

---

# 30. Nested TOC

The reader should support at least two hierarchy levels.

Example:

```text
Caitanya-caritāmṛta
  Madhya-līlā
    Chapter 18
```

Further verse navigation occurs within the chapter reader.

---

# 31. Search Within Work

Every normalized Work should support local search.

Search should return:

- locus;
- snippet;
- matching term.

Example:

> **7.6**  
> "...rādhā-kuṇḍa..."

Tapping opens the exact passage.

---

# 32. Search Original Text

Search should index:

- original text;
- transliteration;
- translation.

Where commentary is included, it may also be indexed but should identify itself as commentary.

---

# 33. Search Result Type

If commentary is indexed:

result should show:

> Commentary on 7.6

rather than simply:

> 7.6

This preserves source distinction.

---

# 34. Unicode Search

The implementation should normalize Unicode consistently.

MVP should handle exact Unicode search reliably.

Desirable future improvements:

- diacritic-insensitive Roman search;
- alternate transliteration forms;
- script-crossing search.

These should not block first implementation.

---

# 35. Work Reading Position

Each Work should remember the latest independent reading position.

Example:

```text
Govinda-līlāmṛta
lastPassage:
7.14
```

This should not overwrite Story-origin context.

If a Story citation temporarily opens GL 7.6, that excursion should not necessarily redefine the user's independent "Continue Reading" position unless the user continues reading meaningfully.

---

# 36. Independent vs Citation Reading State

Recommended rule:

### Opened from Library

Update Work's main reading position normally.

### Opened from Story citation

Maintain a temporary citation session.

If the user reads substantially beyond the cited passage, implementation may optionally update reading position.

For MVP, simplest rule:

**all source reading updates last position**, while Return to Story origin remains separately stored.

This can be refined later.

---

# 37. Bookmarks

Source Reader should support bookmarking canonical passages.

A bookmark target should normally be:

```text
sourcePassageId
```

not raw vertical scroll.

If the user is between passages, attach to the nearest visible canonical passage.

---

# 38. Bookmark Display

Source bookmark:

> **Govinda-līlāmṛta 7.6**

Optionally show a short snippet.

---

# 39. Source Reader Text Selection

Text should ideally support native selection.

Useful actions:

- Copy
- Look Up
- Translate through iOS where available
- standard system actions

Custom annotation is not required.

---

# 40. Highlighting

Persistent user highlighting is not required for MVP.

Bookmarks are enough initially.

Highlighting can be added later if actual usage shows a need.

---

# 41. Personal Notes

Source-specific personal note-taking is deferred.

This simplifies MVP.

A later notes system can attach to Passage IDs without changing source architecture.

---

# 42. Original Witness Viewer

After the first real-content vertical slice is stable, where a PDF/scan exists, Source Reader may offer:

**View Original Witness**

This opens the source PDF.

If exact page mapping exists, open that page.

If not, open the document at its beginning or nearest mapped section.

---

# 43. Original Witness Page Mapping

Mapping should support:

```text
passageId
pdfPageIndex
printedPageLabel
```

Example:

```text
passage.govinda-lilamrta.7.6
→ PDF page index 88
→ printed page 74
```

The exact values will be established during source preparation.

---

# 44. PDF Viewer

PDF witness support is implemented after the first real-content vertical slice. When enabled, MVP PDF functionality uses standard Apple PDF rendering.

Required:

- scrolling;
- zoom;
- page navigation;
- open exact page;
- close/back.

Optional:

- page thumbnails;
- text search if source PDF supports it.

Not required:

- PDF editing;
- drawing;
- annotation system.

---

# 45. PDF Return Behavior

If opened from normalized Source Reader:

Back should return to the same normalized passage.

If opened directly from Library:

Back returns to Work Detail.

---

# 46. Image-Only Works

A source with no reliable normalized text may be represented only by PDF.

Such a Work may still appear in Library if genuinely needed.

However:

- Story citation navigation should preferably target exact PDF pages;
- source search may be unavailable.

The UI should not pretend a searchable text exists.

---

# 47. Mixed-Representation Work

A Work may provide:

```text
Read Text
View Printed Witness
```

This is the preferred arrangement for major scholarly sources.

---

# 48. Library Search

Global Library search should search normalized texts only.

Original PDF witnesses should not produce duplicate search results if their content duplicates the normalized edition.

---

# 49. Work Filtering

MVP Library may allow filtering by source layer.

No advanced metadata filters are required.

---

# 50. Recently Opened

Optional list:

```text
Recently Opened
Govinda-līlāmṛta
Stavāvalī
Mathurā-māhātmya
```

Useful but not essential.

---

# 51. Library Sorting

Default:

curated project order rather than alphabetical.

For example, Primary / Gosvāmī works may be arranged according to usefulness to the Rādhā-kuṇḍa Story.

Alphabetical sorting may be added later.

---

# 52. Reader Typography

Source reading should prioritize textual clarity.

Requirements:

- reliable IAST rendering;
- Devanāgarī rendering;
- Bengali rendering;
- sensible line height;
- verse indentation/line breaks;
- clear hierarchy between original and translation.

---

# 53. Font Philosophy

Use system or bundled application typography that supports required scripts.

Do not distribute or expose external font files.

Exact font choice belongs to implementation.

---

# 54. Reader Text Size

MVP should provide at least several text-size options or Dynamic Type support.

Because the app will be used for extended reading, this is a functional requirement.

---

# 55. Verse Formatting

Preserve source verse structure where meaningful.

Example:

```text
vṛṣabha-danuja-nāśān narma-dharmokti-raṅgair
nikhila-nija-sakhībhir yat sva-hastena pūrṇam |
...
```

Do not flatten verse into one prose paragraph merely for easy rendering.

---

# 56. Bengali/Braj Formatting

Preserve line breaks where they represent poetic or verse structure.

Translations can follow as separate blocks.

---

# 57. Commentary Typography

Commentary should appear visually subordinate to root text while remaining readable.

Potentially:

- smaller heading;
- normal body text;
- indentation.

Avoid tiny "footnote" typography for substantial commentary.

---

# 58. Source Details Access

Source Reader should expose a discreet info action:

**Source Details**

This may show:

- Work;
- author;
- edition;
- source layer;
- verification status;
- translation;
- witness information.

Do not keep these metadata permanently visible.

---

# 59. Story Origin Indicator

When entered from the Story, Source Reader should know its origin.

Possible subtle label:

> Referenced from: The Manifestation of Rādhā-kuṇḍa

This is especially helpful after prolonged reading.

---

# 60. Return-to-Story Behavior

An explicit action should restore:

- Story section;
- semantic block/anchor;
- precise reading position as closely as practical.

This should work even after:

- changing source sections;
- searching within the source;
- opening PDF witness.

The Story origin belongs to the navigation session, not merely the first screen.

---

# 61. Source Excursion Session

Conceptually, opening a citation begins a Source Excursion:

```text
Origin Story Position
Citation
Source Passage
Current Source Navigation State
```

The session ends when:

- user returns to Story;
- user deliberately navigates elsewhere through top-level navigation.

This concept should inform technical state management.

---

# 62. Navigation Example

```text
Story / Manifestation
↓
Rādhā-kuṇḍāṣṭaka 1
↓
Verse 1
↓
Verse 2
↓
TOC
↓
Vilāpa-kusumāñjali
↓
View PDF witness
↓
Back
↓
Return to Story
↓
exact original paragraph
```

This should remain possible without losing context.

---

# 63. Reader State After App Interruption

If the app is backgrounded during a Source Excursion, restoration should ideally preserve:

- source location;
- Story origin.

If this becomes technically complex, preserving source location is mandatory; origin preservation remains strongly preferred.

---

# 64. App Relaunch

On cold relaunch:

- primary "Continue Story" state should remain available;
- last source position should remain available.

A temporary source excursion need not automatically reopen unless it was the last active screen and restoration is straightforward.

---

# 65. Reader Performance

Source sections should load quickly.

Avoid parsing entire massive works into one giant attributed string at runtime.

Large Works should be segmented into reading units such as chapters/Sargas.

The exact technical solution belongs to MVP-06.

---

# 66. Content Package Independence

The reader should render structured content independent of the source authoring format.

The Swift reader should not need special code for every Work.

Work-specific differences should come primarily through metadata.

---

# 67. Generic Reader Principle

The same Source Reader should handle:

- Govinda-līlāmṛta;
- Mathurā-māhātmya;
- Rādhā-kuṇḍāṣṭaka;
- Bhakti-ratnākara;
- Caitanya-caritāmṛta;

using one generic rendering architecture.

Avoid custom screens per source.

---

# 68. Exceptional Works

Some sources may eventually require specialized presentation.

Example:

- parallel root/commentary;
- complex historical footnotes.

These should be treated as later enhancements rather than forcing the MVP reader into premature complexity.

---

# 69. Story Quotations vs Library Text

The Story may contain selected quotations.

Those quotations should point to the same canonical Passage represented in Library.

There must not be a separately maintained "Story version" of the source text unless intentionally excerpted.

---

# 70. Translation Consistency

If the Story quotes a translation different from the Library's main translation, that distinction must be explicit in content metadata.

Do not silently assume the Library translation is the quoted Story wording.

---

# 71. Source Range Display

A citation to a range such as:

> Caitanya-caritāmṛta Madhya 18.3–15

should open at 18.3 and indicate the range.

The user may scroll through the complete range naturally.

---

# 72. Range Indicator

Possible subtle display:

> Cited range: Madhya 18.3–15

The indicator can disappear after scrolling if desired.

---

# 73. Search Index Scope

For each preferred reading edition, index:

- work title;
- section titles;
- canonical loci;
- original text;
- transliteration;
- translation;
- commentary where intentionally searchable.

---

# 74. Search Result Ranking

Simple MVP ranking may prioritize:

1. exact title/locus match;
2. original/transliteration match;
3. translation match.

Sophisticated semantic ranking is unnecessary.

---

# 75. Search Without Network

All search must work offline.

No web service or AI search dependency.

---

# 76. Reader Bookmarks Offline

Bookmarks are local application data.

No cloud sync required.

---

# 77. Reader Failure Modes

Potential failures:

- missing passage;
- malformed section;
- missing edition;
- missing PDF witness.

Development build:

show explicit diagnostic.

Release build:

packaging should prevent broken source links.

---

# 78. Source Reader Validation

Before release, validate:

- preferred reading edition exists;
- TOC targets exist;
- passage anchors resolve;
- Story citation targets open;
- PDF mappings reference existing pages;
- source ordering is valid.

---

# 79. First Vertical Slice Library

The first implementation should include only a few source works.

Recommended:

### Rādhā-kuṇḍāṣṭaka

Complete short work if practical.

### Mathurā-māhātmya

At least the relevant Rādhā-kuṇḍa section; ideally enough surrounding structure to test larger Work navigation.

### Twenty-verse manifestation source

Structured sufficiently to test source-critical material.

The Library can then expand source by source.

---

# 80. MVP Library Completion Strategy

Do not wait to normalize every Rādhā-kuṇḍa source before building the app.

Recommended progression:

1. 3-source vertical slice;
2. reader architecture validation;
3. add source works incrementally;
4. validate each Work;
5. complete MVP source manifest before first pilgrimage-ready build.

---

# 81. Source Import Quality Levels

During preparation, sources may have internal statuses:

```text
Raw
Structured
Normalized
Verified
App Ready
```

Only **App Ready** sources should enter normal release builds.

---

# 82. App-Ready Source Definition

A source is App Ready when:

- Work metadata complete;
- edition metadata complete;
- readable Unicode text available or intentional PDF-only representation;
- TOC valid;
- Passage IDs assigned;
- cited passages verified;
- Story links resolve;
- search works if text representation exists.

---

# 83. Reader Non-Goals

MVP reader does not require:

- highlighting system;
- handwritten annotation;
- side-by-side editions;
- comparative textual apparatus;
- automatic translations;
- dictionary integration;
- AI chat;
- citation export;
- public sharing;
- cloud sync;
- collaborative notes.

---

# 84. Library Non-Goals

MVP Library does not attempt:

- file management;
- arbitrary user imports;
- general ebook-store behavior;
- Calibre replacement;
- complete personal ebook collection.

It is the curated source library for the Rādhā-kuṇḍa Story.

---

# 85. Acceptance Criteria

MVP-04 succeeds when:

1. a Work can be browsed independently;
2. Work structure is clear;
3. exact cited passages can be opened;
4. surrounding passages can be read naturally;
5. original/transliteration/translation are clearly distinguished;
6. commentary is distinct from root text;
7. source search works offline;
8. bookmarks resolve to canonical passages;
9. reading position persists;
10. original PDF witness can be opened where available;
11. return to Story preserves context;
12. one generic reader architecture supports multiple source structures.

---



# 88. Next Specification

After MVP-04, proceed to:

## MVP-05 — Content Authoring & Packaging Specification

This will define the critical bridge between our research/writing workflow and the Swift application:

- canonical source-folder structure;
- Story authoring format;
- Markdown/JSON/YAML decisions;
- multilingual content encoding;
- citation markup;
- source-work files;
- passage markup;
- image references;
- edition metadata;
- validation;
- content compilation;
- app-ready package structure;
- versioning;
- and how a newly approved Rādhā-kuṇḍa Story section moves from our project into the app without being hard-coded into Swift.

---

## Approval

**MVP-04 v1.0 — APPROVED**
