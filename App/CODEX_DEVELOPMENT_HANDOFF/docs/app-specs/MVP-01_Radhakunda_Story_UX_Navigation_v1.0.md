# GOVARDHANA PILGRIMAGE APP

## MVP-01 — Rādhā-kuṇḍa Story UX & Navigation Specification

**Document ID:** MVP-01  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00 — Rādhā-kuṇḍa Story MVP Scope  
**Primary platform:** iPhone  
**Primary experience:** Story reading with exact source navigation

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document defines the user experience and navigation for the Rādhā-kuṇḍa Story MVP.

The MVP is intentionally narrow.

It is not yet a pilgrimage map, route planner, fieldwork tool, Govardhana guide, or multi-device application.

Its central experience is:

> **Read the complete Rādhā-kuṇḍa Story, open exact textual sources when desired, read those sources in context, and return effortlessly to the Story.**

This specification defines:

- MVP screen hierarchy;
- home behavior;
- Story table of contents;
- Story reader;
- source-citation presentation;
- source navigation;
- Library navigation;
- Search;
- Bookmarks;
- reading-state preservation;
- and the principal end-to-end interaction flows.

---

# 2. UX Goals

The MVP should feel first like a **beautiful book** and second like a **scholarly research tool**.

The app should support two equally legitimate behaviors:

## Simple reading

The user can open the Story and read continuously without interacting with citations.

## Deep study

The user can follow a citation into the source corpus, read surrounding material, search, compare, bookmark, and return.

The study functionality must never damage the literary reading experience.

---

# 3. UX Character

The application should feel:

- calm;
- devotional;
- text-centered;
- spacious;
- readable;
- precise;
- serious;
- uncluttered.

It should not feel like:

- a productivity dashboard;
- a research database UI;
- a tourism application;
- a social application;
- a generic file browser;
- a flashy ebook demonstration.

---

# 4. MVP Top-Level Navigation

The first MVP requires only four top-level destinations:

```text
Story
Library
Search
Bookmarks
```

The app launches into a minimal Home screen containing these destinations. This is the approved MVP entry model.

For specification purposes, the logical hierarchy is:

```text
RāDHĀ-KUṆḌA
│
├── Story
├── Library
├── Search
└── Bookmarks
```

---

# 5. MVP Home Screen

The Home screen is required and should be extremely simple.

Recommended structure:

```text
ŚRĪ RĀDHĀ-KUṆḌA

Continue Reading
The Manifestation of Rādhā-kuṇḍa

Story
Library
Search
Bookmarks
```

If there is no stored reading position, replace "Continue Reading" with:

**Begin the Story**

No dashboard metrics or progress statistics are required.

---

# 6. Story Entry Experience

Tapping **Story** should open either:

1. the Story Table of Contents; or
2. the last reading position if a prior position exists.

Recommended behavior:

- tapping **Continue Reading** resumes;
- tapping **Story** opens the Story Table of Contents;
- selecting a section opens that section.

This gives the user both continuity and direct access.

---

# 7. Story Table of Contents

The Story Table of Contents should mirror the approved literary structure.

It should not be generated from software convenience.

Representative form:

```text
THE STORY OF ŚRĪ RĀDHĀ-KUṆḌA

PART I — MANIFESTATION AND MEANING
1. At the Foot of Govardhana
2. Ariṣṭāsura
3. The Manifestation of the Twin Kuṇḍas
4. Meaning and Theology

PART II — THE ETERNAL RĀDHĀ-KUṆḌA
5. ...
```

The exact titles come from the approved Story writing files.

---

# 8. Story TOC Behavior

Each section row should show:

- section number;
- title;
- optional reading-position indicator.

The current reading section may be subtly highlighted.

No percentage-complete indicators are required.

---

# 9. Story Reader

The Story Reader is the central screen of the MVP.

It must support:

- continuous long-form reading;
- section headers;
- paragraphs;
- block quotations;
- Sanskrit;
- Bengali;
- Braj;
- IAST;
- translation;
- citations;
- images;
- footnotes or notes where necessary.

The default visual hierarchy should privilege the Story prose.

---

# 10. Reader Navigation

The Story Reader should support:

- swipe/scroll reading;
- previous section;
- next section;
- open Story TOC;
- resume position automatically.

The MVP should use normal vertical scrolling.

Page-turn simulation is not necessary.

Vertical scrolling is simpler and more natural on iPhone.

---

# 11. Reader Header

The reader header should be visually minimal.

Possible content:

```text
‹ Story
The Manifestation of the Twin Kuṇḍas
```

On scroll, the header may collapse.

Exact visual implementation is deferred.

---

# 12. Reader Footer or Section Navigation

At the end of each Story section:

```text
Previous
Next
```

may be displayed.

Example:

**← Ariṣṭāsura**

**Meaning and Theology →**

This is helpful when reading sequentially.

---

# 13. Citation Presentation

Citations should be visible but restrained.

Preferred presentation:

> Rādhā-kuṇḍāṣṭaka 1 ›

or:

> Govinda-līlāmṛta 7.6 ›

The citation should look tappable without looking like a web hyperlink embedded every few words.

Avoid bright-blue default-link styling if possible.

---

# 14. Citation Placement

For the initial MVP, citations normally render as a restrained citation row immediately after the relevant paragraph or quotation. This protects literary readability and creates a reliable tap target. Inline citation rendering may be added later where editorially useful.

---

# 15. Quotation-to-Source Link

When a Sanskrit/Bengali/Braj quotation is reproduced in the Story, the quote itself may be tappable or may have a citation immediately below it.

Preferred MVP behavior:

- the text is selectable/readable normally;
- the citation beneath it is the link target.

This avoids accidental navigation while selecting text.

---

# 16. Tapping a Citation

Tapping a citation should open the Source Reader directly at the relevant canonical passage.

No intermediate "citation detail" screen should be required for normal use.

Example:

```text
Story
↓
Rādhā-kuṇḍāṣṭaka 1
↓
Source Reader
```

---

# 17. Source Reader Entry State

When opened from a citation, the Source Reader should know:

- source work;
- exact cited locus;
- Story origin;
- Story reading position.

The cited passage should be visibly identifiable.

---

# 18. Source Reader Header

Recommended source header:

```text
‹ Return to Story

Rādhā-kuṇḍāṣṭaka
Verse 1
Raghunātha dāsa Gosvāmī
```

If opened from Library rather than Story, the header may simply show:

```text
‹ Library
```

The source entity is the same; the navigation context differs.

---

# 19. Cited Passage Highlight

When a source opens from a Story citation:

- cited verse/paragraph should receive a subtle highlight or marker;
- surrounding text remains visible;
- the user can immediately continue reading.

The highlight should not obscure original text.

---

# 20. Source Reader Content

A structured source passage may show:

### Canonical locus

**Rādhā-kuṇḍāṣṭaka 1**

### Original text

Sanskrit/Bengali/Braj.

### Transliteration

Where appropriate.

### Translation

Where available and approved.

### Commentary or source notes

Only where the project source includes them or where the source representation intentionally includes commentary.

The MVP must not automatically generate explanatory commentary.

---

# 21. Source Reader Continuous Reading

The user must be able to move beyond the cited passage.

For a verse work:

```text
Verse 1
Verse 2
Verse 3
...
```

For prose:

- preceding paragraph;
- following paragraph;
- chapter continuation.

The source reader should behave like a book, not like a citation popup.

---

# 22. Source Navigation

At minimum, Source Reader should support:

- previous passage;
- next passage;
- work table of contents;
- search within work;
- bookmark;
- return to origin.

---

# 23. Return to Story

This interaction is mission-critical.

If a source was opened from Story:

**Return to Story**

must restore:

- the same Story section;
- the same scroll position.

The user should not return merely to the top of the Story section.

---

# 24. Standard Back Navigation

Standard iOS back behavior should also work.

However, because users may read several pages of source material, an explicit **Return to Story** affordance is recommended.

This protects against deep navigation confusion.

---

# 25. Source Table of Contents

Each source work should expose a TOC appropriate to the work.

Examples:

## Stavāvalī

- Śacī-sūnv-aṣṭaka
- Gaurāṅga-stava-kalpa-taru
- Manaḥ-śikṣā
- Rādhā-kuṇḍāṣṭaka
- Vraja-vilāsa-stava
- Vilāpa-kusumāñjali
- etc.

## Govinda-līlāmṛta

- Sarga 1
- Sarga 2
- ...
- Sarga 23

The TOC should be derived from source metadata, not improvised in the UI.

---

# 26. Library

The Library should provide direct access to included Rādhā-kuṇḍa sources.

The MVP Library should remain curated.

Recommended categories:

```text
Primary / Gosvāmī
Early Pilgrimage
Historical / Later
```

The source layer should be visible here because Library is explicitly a study context.

---

# 27. Library Work Row

A work row should show:

- title;
- author;
- optional source category.

Example:

```text
Govinda-līlāmṛta
Kṛṣṇadāsa Kavirāja

PRIMARY / GOSVĀMĪ
```

Avoid showing file names such as:

`govinda-lilamrtam_mula_v2.docx`

The user sees canonical work identity, not storage implementation.

---

# 28. Library Work Detail

Tapping a work may open either:

1. its table of contents directly; or
2. a compact Work Detail screen.

Recommended MVP behavior:

Open the Work Detail screen if multiple representations exist.

Example:

```text
GOVINDA-LĪLĀMṚTA
Kṛṣṇadāsa Kavirāja

Read Text
Table of Contents
Search This Work
View Original Witness
```

If only normalized text exists, Read Text can open directly.

---

# 29. Original Witness Access

After the first real-content vertical slice is stable, where an original PDF/scan is available:

**View Original Witness**

opens it.

This is optional per work.

The app should not display this action if no witness is packaged.

---

# 30. PDF Witness Navigation

PDF witness support is part of MVP architecture but is implemented after the first real-content vertical slice. When implemented, it remains minimal:

- open correct PDF;
- optionally jump to mapped page;
- zoom;
- scroll;
- close/return.

Full PDF annotation is not required.

---

# 31. Search

Search should be globally available from the MVP top level.

Search should search:

- Story text;
- normalized source text.

Results should be grouped.

Example:

```text
Search: kuṇḍa

STORY
The Manifestation of the Twin Kuṇḍas
...

SOURCES
Rādhā-kuṇḍāṣṭaka 1
Mathurā-māhātmya 421
Govinda-līlāmṛta 7.1
...
```

---

# 32. Search Result Preview

Each result should display:

- result type;
- title/locus;
- short text snippet with matching term.

Example:

```text
SOURCE

Govinda-līlāmṛta 7.6

"...rādhā-kuṇḍaṁ..."
```

Tapping opens directly at the relevant passage.

---

# 33. Search Result Return

If the user opens a result then goes back:

- query remains;
- results remain;
- scroll position remains.

This is normal research behavior and should be preserved.

---

# 34. Search Within a Source Work

The Source Reader or Work Detail screen should support:

**Search This Work**

Results should remain limited to the selected work.

This is separate from global search.

---

# 35. Search Behavior for Sanskrit/IAST

Search should eventually account for Unicode normalization.

At minimum, MVP search must correctly handle the stored Unicode text.

Potential future support:

- diacritic-insensitive search;
- Devanāgarī/transliteration equivalence.

These are valuable but not required for the first vertical slice unless easy to support.

---

# 36. Bookmarks

Bookmarks are intentionally simple.

The user can bookmark:

- Story position;
- source passage.

A bookmark should store enough context to restore the location.

---

# 37. Bookmark Action in Story

Possible reader action:

**Bookmark**

The MVP does not need paragraph-level visible bookmark icons.

A toolbar action is sufficient.

---

# 38. Bookmark Action in Source Reader

The bookmark should attach to the canonical source passage currently in focus.

Example:

> Govinda-līlāmṛta 7.6

not an arbitrary pixel scroll offset if a canonical passage is available.

---

# 39. Bookmark List

Bookmarks should be grouped:

```text
STORY
The Manifestation of the Twin Kuṇḍas

SOURCES
Rādhā-kuṇḍāṣṭaka 1
Govinda-līlāmṛta 7.6
```

No folders or tagging required.

---

# 40. Reading Position

The app should automatically remember:

## Story

- last Story section;
- last scroll position.

## Source Works

- last passage or position within each work.

---

# 41. Continue Reading

Home may display:

```text
Continue Story
The Manifestation of the Twin Kuṇḍas
```

and optionally:

```text
Continue Source
Govinda-līlāmṛta — Sarga 7
```

The MVP should not show too many resume cards.

Story resume has priority.

---

# 42. Reader Settings

MVP Reader Settings should remain modest.

Required:

- text size.

Recommended:

- system light/dark appearance support.

Optional later:

- line spacing;
- font selection;
- hide/show transliteration;
- hide/show translation.

Do not delay MVP over advanced typography settings.

---

# 43. Script Rendering

The UI must correctly display:

- English;
- IAST;
- Devanāgarī;
- Bengali.

No custom script-specific navigation behavior is required.

The main requirement is reliable rendering and layout.

---

# 44. Story Footnotes

Footnotes should be used sparingly.

Possible behaviors:

### Short note

Open as a small sheet/popover.

### Source citation

Open Source Reader.

The system should distinguish explanatory notes from source links.

---

# 45. External Web Links

External web links are not central to MVP.

If present:

- open using standard system browser/web view.

No core source citation should rely on a website.

---

# 46. Loading Behavior

All core content is local.

Opening:

- Story;
- source passage;
- Library work;
- Search

should feel immediate.

Avoid loading spinners for local content unless genuinely necessary.

---

# 47. Missing Citation Behavior

In development builds, an unresolved citation should show an obvious development error.

Example:

> Citation target missing: GL.7.6

In production/pilgrimage builds, broken citation targets should never be present because packaging validation should prevent release.

---

# 48. Missing Translation Behavior

If a source has original text but no translation:

show only what exists.

Do not create placeholder text such as:

> Translation unavailable

unless useful.

The UI may simply omit the translation section.

---

# 49. Missing Original Witness Behavior

If no PDF witness exists:

do not display **View Original Witness**.

No disabled buttons.

---

# 50. MVP Screen Inventory

The MVP requires the following primary screens:

1. Home
2. Story Table of Contents
3. Story Reader
4. Library
5. Work Detail / Work TOC
6. Source Reader
7. PDF Witness Viewer
8. Global Search
9. Search Results
10. Bookmarks
11. Reader Settings

Some may be combined.

For example Search and Search Results can be one screen.

---

# 51. Minimum Vertical Slice Screens

The very first Codex vertical slice requires only:

1. Home
2. Story Reader
3. Source Reader
4. Search
5. Bookmarks

The Story TOC and Library can follow shortly afterward.

However, the architecture should anticipate all MVP screens from the start.

---

# 52. First Vertical Slice Content

The first integrated UX should use real content.

Recommended:

## Story Section

**The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa**

## Source Links

At minimum:

- Rādhā-kuṇḍāṣṭaka 1
- Mathurā-māhātmya 421
- one additional controlled primary passage

Exact inclusion will be finalized in MVP-07.

---

# 53. First Vertical Slice Flow

```text
Launch App
↓
Continue / Open Story
↓
Read real Rādhā-kuṇḍa section
↓
Tap citation
↓
Source opens at exact passage
↓
Read next passage
↓
Return to Story
↓
Bookmark Story
↓
Search a term
↓
Open source result
↓
Bookmark source
```

This is the UX acceptance flow that should be perfected first.

---

# 54. Navigation State Requirements

The app should preserve state for:

- Story scroll position;
- source reading location;
- search query/results;
- navigation origin when entering a source.

These state requirements should influence the later technical architecture.

---

# 55. No Modal Overuse

Sources should normally open through standard navigation rather than full-screen modal sheets.

Modals/sheets may be useful for:

- reader settings;
- short footnotes;
- minor metadata.

The reading experience should feel spatially coherent.

---

# 56. No Nested Tab Bars

Do not put a second tab bar inside Rādhā-kuṇḍa.

The MVP is simple enough that standard navigation stacks are sufficient.

---

# 57. Accessibility and Readability

Even though this is a private app, it should use normal iOS readability conventions.

Support:

- Dynamic Type where practical;
- sufficient text contrast;
- large tap targets;
- VoiceOver-compatible labels where easy.

The user may want larger text during extended reading.

---

# 58. Orientation

Portrait is the primary MVP orientation.

Landscape may work naturally but does not require custom optimization initially.

PDF witness viewing may benefit from landscape.

---

# 59. Selection and Copying

Story and source text should ideally permit text selection and copying.

This is useful for study.

Citation metadata need not be copied automatically.

---

# 60. Sharing

Public sharing is not an MVP requirement.

Standard copy/share functionality may remain available through iOS text selection, but the app does not need custom social sharing.

---

# 61. Error UX

Because content is local, error states should be rare.

Possible errors:

- malformed content package;
- missing source target;
- missing asset.

During development, errors should be explicit.

Release packaging should validate these away.

---

# 62. MVP UX Non-Goals

Do not design yet:

- maps;
- GPS;
- routes;
- place cards;
- field notes;
- photo capture;
- Govardhana navigation;
- Kindle integration;
- web synchronization;
- user accounts;
- cloud notes;
- AI chatbot.

---

# 63. UX Acceptance Criteria

MVP-01 is successful when the design clearly supports:

1. pleasant Story reading;
2. obvious but unobtrusive citations;
3. one-tap exact source navigation;
4. continuous reading within source;
5. reliable Return to Story;
6. independent Library browsing;
7. useful local Search;
8. simple Bookmarks;
9. preserved reading positions;
10. a navigation model that does not feel complicated.

---



# 66. Next Specification

After MVP-01, proceed to:

## MVP-02 — Content & Domain Model Specification

That document will define the actual reusable data objects behind the MVP:

- Story;
- Story Section;
- Source Work;
- Edition;
- Source Passage;
- Citation;
- Image;
- Bookmark;
- Reading Position;
- identifiers;
- relationships;
- ordering;
- metadata;
- validation rules;
- and versioning.

---

## Approval

**MVP-01 v1.0 — APPROVED**
