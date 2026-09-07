# GOVARDHANA PILGRIMAGE APP

## MVP-00 — Rādhā-kuṇḍa Story MVP Scope

**Document ID:** MVP-00  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Project:** Govardhana Pilgrimage App  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story  
**Primary platform:** iPhone  
**Primary user:** Private/personal use

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document defines the deliberately reduced scope of the first working version of the Govardhana Pilgrimage App.

The MVP is **not** the complete pilgrimage application.

It is the first implementation layer from which the larger application can later grow.

The MVP has one central purpose:

> **Turn the complete Rādhā-kuṇḍa Story into a high-quality iPhone reading and study application with direct, reliable navigation from the Story into its primary and supporting source literature.**

The MVP should prove the application's most important intellectual interaction before maps, GPS, pilgrimage routing, fieldwork, Govardhana, or companion-device features are introduced.

---

# 2. MVP Product Statement

The Rādhā-kuṇḍa Story MVP is a private iPhone application for reading, studying, and exploring the complete Rādhā-kuṇḍa Story together with the textual sources upon which it is based.

The application should allow the user to:

1. read the complete Story as a continuous literary work;
2. navigate its sections easily;
3. recognize and open source citations;
4. move directly from a citation to the exact relevant passage in a source;
5. continue reading the surrounding source material;
6. return to the exact position in the Story;
7. browse the Rādhā-kuṇḍa source library independently;
8. search the Story and supported source texts;
9. bookmark meaningful Story and source locations.

The application should function primarily as a **scholarly-devotional hypertext reader**.

---

# 3. Scope Boundary

The first MVP intentionally excludes many features already envisioned for the future application.

## Included in MVP

- Rādhā-kuṇḍa Story
- Story table of contents
- Story reader
- source citations
- source passage navigation
- source reader
- limited Rādhā-kuṇḍa source library
- searchable source texts
- Story search
- bookmarks
- reading position
- original-language text
- transliteration
- translation
- selected images where useful
- optional original source PDF witness viewing after the first real-content vertical slice

## Explicitly excluded from MVP

- maps
- GPS
- pilgrimage routes
- Near Me
- location awareness
- Govardhana Story
- 71 Govardhana pilgrimage places
- field notes
- field photographs
- audio notes
- Kindle generation
- Android support
- E-Ink support
- web version
- public distribution
- accounts
- cloud sync
- backend services
- complex note-taking
- social features
- automatic AI-generated explanations

These are not rejected permanently.

They are **deferred**.

---

# 4. Why Rādhā-kuṇḍa Is the MVP

Rādhā-kuṇḍa is sufficiently developed within the Govardhana Pilgrimage research project to test the application's central architecture.

The research corpus already contains controlled work on:

- the Ariṣṭāsura foundation;
- the twenty-verse manifestation narrative;
- Rūpa Gosvāmī's theological hierarchy;
- Raghunātha dāsa Gosvāmī's Rādhā-kuṇḍa theology;
- nitya-līlā sacred geography;
- the aṣṭa-sakhī landscape;
- associates and service ecology;
- Caitanya Mahāprabhu's recognition of the obscured tīrtha;
- Raghunātha dāsa's residence;
- early Gauḍīya community history;
- historical/documentary questions.

The project writing blueprint likewise treats the Rādhā-kuṇḍa Story as a substantial continuous narrative rather than a short guide entry.

This makes Rādhā-kuṇḍa the best place to test the software against genuine, complex content.

---

# 5. The MVP Is Story-Centered

The Story is the primary application experience.

The application should open into or prominently present:

## The Complete Story of Śrī Rādhā-kuṇḍa

The Story must remain readable from beginning to end without requiring the user to enter source-study mode.

Source links enrich the Story but should not interrupt its literary flow.

The user should always be free to:

> simply read.

---

# 6. Story Architecture

The Story should be represented as an ordered collection of sections or chapters.

The exact final structure will come from the approved Rādhā-kuṇḍa Story documents.

The current writing blueprint organizes the narrative into four broader movements:

1. Manifestation and Meaning
2. The Eternal Rādhā-kuṇḍa
3. Recognition, Residence, and Community
4. Physical History and Pilgrim Encounter

with numbered literary sections beneath them.

The application must support this literary architecture rather than inventing a software-driven chapter sequence.

---

# 7. Story Reader Requirements

The Story reader must support:

- continuous reading;
- section headings;
- subheadings;
- Sanskrit;
- Bengali;
- Braj;
- IAST transliteration;
- English translation;
- quotations;
- inline citations;
- images;
- footnotes or source notes where needed;
- adjustable text size;
- saved reading position.

The reading experience should be clean and quiet.

Source metadata should not visually overwhelm the prose.

---

# 8. Core MVP Interaction

The most important interaction in the entire MVP is:

```text
Story
↓
Citation
↓
Exact Source Passage
↓
Read Surrounding Source
↓
Return to Story
```

This interaction must feel immediate and reliable.

Example:

While reading the Story:

> ...Raghunātha dāsa describes the manifestation with the phrase *narma-dharmokti-raṅgaiḥ*.

The citation appears:

**Rādhā-kuṇḍāṣṭaka 1 ›**

Tapping it opens the source reader at the exact verse.

The user may then:

- read the full verse;
- inspect Sanskrit;
- read translation;
- move to verse 2;
- continue through the complete prayer;
- search the work;
- return to the Story.

Returning should restore the exact prior Story position.

---

# 9. Canonical Source References

The app must not depend primarily on PDF page numbers.

Each source link should use a canonical textual identity.

Examples:

```text
RKA.1
GL.7.6
MM.421
BR.5.545
CC.Madhya.18.5
```

These examples are conceptual identifiers.

The formal naming system will be defined in MVP-03.

The scholarly citation remains:

> Govinda-līlāmṛta 7.6

rather than:

> page 142 of a particular PDF.

Edition-specific page or digital location may also be stored for navigation.

---

# 10. Source Library Scope

The MVP does **not** need the entire Govardhana research library.

It should initially include only works necessary to support the Rādhā-kuṇḍa Story.

Potential core works include:

## Primary / Gosvāmī

- Śrīmad-Bhāgavatam 10.36 material
- Caitanya-caritāmṛta Madhya 18
- Rūpa Gosvāmī's Mathurā-māhātmya
- Raghunātha dāsa Gosvāmī's Stavāvalī materials
- Govinda-līlāmṛta
- Kṛṣṇa-bhāvanāmṛta
- Rādhā-Kṛṣṇa-gaṇoddeśa-dīpikā
- Vraja-rīti-cintāmaṇi

## Early Pilgrimage / Historical Devotional

- Vraja-bhakti-vilāsa
- Bhakti-ratnākara

## Later / Local and Historical Sources

Only those actually cited or necessary for completed Story sections.

The definitive MVP source list will be established in MVP-07.

---

# 11. Source Representation

A source may have more than one digital representation.

## Normalized Text

Preferred for:

- reading;
- search;
- direct verse navigation;
- copying;
- cross-references;
- typography.

## Original Witness

PDF or scan retained where useful for:

- visual verification;
- printed commentary;
- edition checking;
- pagination;
- original-script comparison.

A single work may therefore provide both:

**Read Text**

and:

**View Original Witness**

---

# 12. Source Reader

The source reader is the second most important screen after the Story reader.

It must support:

- opening at an exact citation;
- showing canonical source title;
- showing exact locus;
- reading surrounding material;
- previous/next verse or section;
- table of contents where appropriate;
- search within work;
- bookmark;
- return to Story.

The cited passage should be visibly identifiable when opened.

---

# 13. Source Reader Context Preservation

If the user enters a source from the Story, the app should retain the origin.

Example:

> Opened from  
> **The Manifestation of Rādhā-kuṇḍa**

An explicit:

**Return to Story**

action may supplement normal iOS back navigation.

The user should never wonder how to get back to the narrative.

---

# 14. Library

The Library in MVP is intentionally limited.

Its purpose is to expose the source works already included for Rādhā-kuṇḍa.

Possible initial categories:

- Primary / Gosvāmī
- Early Pilgrimage
- Historical / Later Sources

This classification should remain consistent with the research methodology.

The Library is not intended to reproduce every file presently stored in Project Sources.

---

# 15. Library Work Screen

A source work may expose:

- title;
- author;
- source category/layer;
- edition information;
- table of contents;
- Read;
- Search This Work;
- Original Witness where available.

The Library should support direct study independent of Story citations.

---

# 16. Search

MVP search should cover:

- Rādhā-kuṇḍa Story
- normalized source texts included in MVP

Search results should distinguish these categories.

Example:

```text
Search: rādhā-kuṇḍa

STORY
The Manifestation of Rādhā-kuṇḍa

SOURCES
Mathurā-māhātmya 421
Rādhā-kuṇḍāṣṭaka 1
Govinda-līlāmṛta 7.1
...
```

Search of PDFs is not required when a normalized text is unavailable.

---

# 17. Search Philosophy

Search should retrieve text actually present in the project corpus.

It should not silently perform:

- web search;
- AI interpretation;
- speculative semantic answering.

The MVP search system is a local text-retrieval feature.

---

# 18. Bookmarks

Bookmarks should support at minimum:

- Story section/location;
- source passage.

Possible Bookmarks view:

```text
STORY
Manifestation of the Twin Kuṇḍas

SOURCES
Govinda-līlāmṛta 7.6
Rādhā-kuṇḍāṣṭaka 3
```

Complex tags or folders are unnecessary in MVP.

---

# 19. Reading Position

The app should automatically save:

## Story

- current section;
- reading location.

## Source

- last location in each opened work.

This allows:

> Continue Story

and:

> Continue Reading

later.

---

# 20. Images

Images are permitted in MVP where they materially improve the Story.

Examples:

- historical images;
- diagrams;
- sacred-geography illustrations;
- relevant photographs.

Images should not delay MVP development.

The app must be fully useful with a modest image set.

---

# 21. Research Detail Visibility

The first MVP should retain enough research metadata to support source discipline.

However, it does not need to expose full research ledgers in the UI.

Where useful, a citation or source may show:

- source layer;
- edition;
- verification note.

The detailed A/B/C/D research interface can be expanded later.

---

# 22. No Map Dependency

Nothing in the MVP content model should require a map or geographic coordinate to function.

Places may be discussed in the Story as text, but they do not yet need to be structured as geospatial entities.

A future map system can attach to stable content IDs later.

This prevents mapping requirements from contaminating the first implementation.

---

# 23. No Pilgrimage-Route Dependency

The Story should not be authored according to future walking order.

The literary narrative remains primary.

Pilgrimage sequencing will be added later as a separate layer.

---

# 24. No Kindle Dependency

Kindle content generation is not part of MVP development.

The source-processing decisions should avoid unnecessarily preventing later EPUB generation, but Kindle compatibility is not an MVP acceptance criterion.

---

# 25. No Govardhana Dependency

The Rādhā-kuṇḍa Story MVP must be independently complete.

It should not require:

- a Govardhana Story screen;
- Govardhana map;
- 71-place database;
- broader pilgrimage architecture.

References to Govardhana within the Story remain ordinary Story content for now.

---

# 26. No Backend

The MVP should be capable of operating entirely locally.

There is no requirement for:

- authentication;
- database server;
- API server;
- cloud content service.

All Story and source content required by MVP should be packaged locally or imported locally.

---

# 27. MVP Home

The first Home screen should remain extremely simple.

Approved MVP structure:

```text
ŚRĪ RĀDHĀ-KUṆḌA

Continue Reading

Story
Library
Search
Bookmarks
```

The precise screen design belongs to MVP-01.

There is no need yet for a global Govardhana Pilgrimage dashboard.

---

# 28. MVP Information Architecture

The entire first implementation can be represented as:

```text
RĀDHĀ-KUṆḌA
│
├── Story
│   ├── Table of Contents
│   └── Reader
│
├── Library
│   ├── Works
│   ├── Work Contents
│   └── Source Reader
│
├── Search
│   ├── Story Results
│   └── Source Results
│
└── Bookmarks
    ├── Story
    └── Sources
```

This is intentionally small.

---

# 29. Core Content Types

The MVP should require only a small number of content types.

At the conceptual level:

- Story
- Story Section
- Source Work
- Source Passage
- Citation
- Image
- Bookmark

Possibly:

- Edition
- Reading Position

The formal domain model will be specified in MVP-02.

---

# 30. Content Must Remain External to Swift Code

Story prose and source texts should not be embedded directly into Swift source files.

The app should load structured content.

The canonical corpus remains outside the UI/application logic.

This allows:

- editing Story without rewriting views;
- adding sources without recompiling the conceptual UI structure;
- reusing content later;
- validating citations separately.

---

# 31. Content Development While App Development Proceeds

The complete Rādhā-kuṇḍa Story may continue to evolve while the application is being built.

The architecture must tolerate:

- unfinished Story sections;
- updated prose;
- added citations;
- corrected source passages;
- newly normalized books.

Codex development should therefore be based on a controlled content format rather than assumptions about final prose length.

---

# 32. Real Content Requirement

The MVP should use real project content as soon as the architecture supports it.

At minimum, the first integrated prototype should contain one real Story section with real citations and real source passages.

Recommended first vertical slice:

## Manifestation of Rādhā-kuṇḍa

with links into:

- Rādhā-kuṇḍāṣṭaka;
- Mathurā-māhātmya;
- relevant manifestation source material.

The exact content selection will be controlled later.

---

# 33. First Vertical Slice Acceptance Flow

The first end-to-end software slice should accomplish:

```text
Launch
↓
Open Story
↓
Open one real Rādhā-kuṇḍa Story section
↓
Read prose
↓
Tap real citation
↓
Open exact real source passage
↓
Read surrounding source text
↓
Return to exact Story location
↓
Bookmark source
↓
Search for a word found in both Story and source
```

If that works reliably, the foundational architecture is proven.

---

# 34. MVP Quality Standard

Although the MVP is small, it should not feel disposable.

The following should be production-quality from the beginning:

- Unicode handling;
- stable IDs;
- citation resolution;
- navigation;
- text rendering;
- reading-position storage;
- local content loading;
- search correctness.

The following may initially be less polished:

- visual styling;
- image library;
- animation;
- settings;
- secondary metadata views.

---

# 35. Devotional Reading Quality

The MVP is not merely a technical citation browser.

The Story must remain pleasant enough to read for extended periods.

Source links should enhance devotional reading rather than make every paragraph feel like a research report.

A user should be able to ignore all links and simply read the Story.

---

# 36. Scholarly Reliability

Every displayed citation must resolve to the intended passage.

The app must never:

- generate a source reference dynamically without controlled metadata;
- fabricate a missing citation;
- infer a passage from similarity;
- silently substitute another edition or text.

If a citation cannot resolve, development builds should surface a clear validation error.

---

# 37. Validation Requirement

Before content enters a release build, the build pipeline should eventually verify:

- every Story citation references an existing Source Passage;
- every Source Passage references an existing Source Work;
- no duplicate canonical IDs exist;
- required text files exist;
- referenced original witnesses exist where declared.

Detailed validation belongs to MVP-05 and MVP-06.

---

# 38. Deferred Feature Register

The following should be maintained as future expansion ideas but not implemented during MVP unless explicitly promoted:

- maps
- pilgrimage places
- GPS
- Near Me
- routes
- people directory
- prayer-specific mode
- field notes
- photography
- audio
- Kindle
- Govardhana
- web
- Android
- AI assistance inside app
- cloud synchronization

This protects the MVP from scope creep.

---

# 39. MVP Success Definition

The MVP succeeds when the user can sit with an iPhone and use it naturally as a complete Rādhā-kuṇḍa Story study reader.

Specifically:

> The Story reads beautifully.

> Its citations are trustworthy.

> A citation opens the exact source.

> The source can be read in context.

> Returning to the Story is effortless.

> The included library can be browsed independently.

> Search finds relevant Story and source passages.

> Bookmarks and reading positions work reliably.

If these functions are excellent, the MVP is successful.

---

# 40. Expansion Gate

No major map/pilgrimage/Govardhana feature should be added merely because the MVP architecture makes it possible.

Expansion begins only after the Story/source experience has been used and judged satisfactory.

Future additions should extend the proven content model rather than replace it.

---

# 41. Documents Required Before Codex Begins MVP Development

The reduced MVP documentation set is:

1. **MVP-00 — Rādhā-kuṇḍa Story MVP Scope**
2. **MVP-01 — Story UX & Navigation**
3. **MVP-02 — Content & Domain Model**
4. **MVP-03 — Source & Citation Architecture**
5. **MVP-04 — Library & Reader Architecture**
6. **MVP-05 — Content Authoring & Packaging Specification**
7. **MVP-06 — Swift Technical Architecture**
8. **MVP-07 — Rādhā-kuṇḍa Content Manifest**
9. **MVP-08 — Codex Build Plan & Acceptance Criteria**

These nine documents should be sufficiently developed before Codex begins production implementation.

---

# 42. Decisions Established by MVP-00 v0.1

**Product:** Private Rādhā-kuṇḍa Story study app.

**Platform:** iPhone.

**Primary experience:** long-form Story reading.

**Secondary experience:** direct source study.

**Core differentiator:** exact Story → source navigation.

**Local-first:** yes.

**Maps:** deferred.

**Pilgrimage routing:** deferred.

**GPS:** deferred.

**Fieldwork:** deferred.

**Kindle:** deferred.

**Govardhana:** deferred.

**Web/public version:** deferred.

**Android:** deferred.

**Backend:** unnecessary for MVP.

---



# 45. Next Specification

After MVP-00 is approved, proceed to:

## MVP-01 — Rādhā-kuṇḍa Story UX & Navigation Specification

That document will define exactly:

- Home;
- Story table of contents;
- Story reader;
- citation presentation;
- citation interaction;
- source reader transition;
- return-to-Story behavior;
- Library navigation;
- Search;
- Bookmarks;
- reading settings;
- and the complete MVP interaction flow.

---

## Approval

**MVP-00 v1.0 — APPROVED**
