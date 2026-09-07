# GOVARDHANA PILGRIMAGE APP

## MVP-08 — Codex Build Plan & Acceptance Criteria

**Document ID:** MVP-08  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00 through MVP-07  
**Primary platform:** iPhone  
**Implementation:** Swift / SwiftUI  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP

---

# 1. Purpose

This is the final implementation-control document. Codex is not being asked to design the product; it is being asked to implement the approved product in small, testable milestones.

The development rule is:

> **One bounded milestone → tests → written handoff → user review → explicit approval → next milestone.**

# 2. Authoritative Specifications

Codex must read and follow, in order:

1. MVP-00 — Story MVP Scope
2. MVP-01 — Story UX & Navigation
3. MVP-02 — Content & Domain Model
4. MVP-03 — Source & Citation Architecture
5. MVP-04 — Library & Reader Architecture
6. MVP-05 — Content Authoring & Packaging
7. MVP-06 — Swift Technical Architecture
8. MVP-07 — Rādhā-kuṇḍa Content Manifest
9. MVP-08 — this Build Plan
10. MVP-BASELINE — cross-specification approvals and precedence

If ambiguity remains, Codex stops and asks. It does not silently invent product behavior.

# 3. Binding MVP Exclusions

Codex must not add during this MVP:

- maps;
- GPS;
- pilgrimage routes;
- Place entities merely for future use;
- Govardhana implementation;
- field notes/photos/audio;
- Kindle support;
- Android;
- web/backend/API;
- authentication;
- cloud sync;
- analytics;
- AI runtime features;
- social features.

# 4. Approved Technical Baseline

- iOS 18+ baseline;
- Swift / SwiftUI;
- NavigationStack with typed routes;
- generated read-only SQLite content DB;
- separate writable SQLite user-state DB;
- GRDB.swift as the only initial third-party Swift dependency;
- SQLite FTS5 for local search;
- Python content compiler;
- native SwiftUI structured Story and Source readers;
- PDFKit later, after the real-content vertical slice;
- OSLog/Logger;
- no networking layer.

# 5. Development Milestones

The approved sequence is:

0. Repository & documentation foundation
1. Content compiler fixture
2. Runtime SQLite + FTS generation
3. SwiftUI application foundation
4. Story reader
5. Citation resolver + Source reader
6. Story ↔ Source excursion and exact return
7. Library
8. Search
9. Bookmarks + reading positions
10. First real Rādhā-kuṇḍa vertical slice
11. Architecture / UX review gate
12. Original PDF witness support
13. Source corpus + Story expansion
14. MVP stabilization and 1.0 gate

Codex stops after every major milestone.

# 6. Milestone 0 — Repository & Documentation Foundation

## Goal

Create the agreed repository structure and place the approved specifications where all later Codex tasks can read them.

## Required output

```text
GovardhanaPilgrimage/
├── app/
├── content/
├── witnesses/
├── tools/
├── docs/app-specs/
├── tests/
├── build/
├── README.md
└── .gitignore
```

## Acceptance

- all v1.0 specs present under `docs/app-specs/`;
- README explains content/code separation;
- no product features implemented;
- clean Git status after agreed commit.

# 7. Milestone 1 — Content Compiler Fixture

## Goal

Prove the human-authoring → validated structured-content pipeline before building UI.

## Required fixture

- one tiny Story;
- one Story section;
- one source Work;
- several canonical Passages;
- at least one Citation.

Fixture content may be neutral technical material or a tiny approved real excerpt. It must not invent devotional claims.

## Compiler must validate

- unique IDs;
- valid parent relationships;
- Citation target exists;
- Work/Passage exists;
- valid statuses;
- Unicode load/normalization.

## Output

JSON/intermediate output is acceptable at this milestone plus `build-report.json`.

## Acceptance

A Story Citation resolves deterministically to a canonical Passage and Work; intentionally broken fixture data causes a non-zero build failure.

# 8. Milestone 2 — Runtime SQLite + FTS

## Goal

Generate the runtime content package.

## Required tables/concepts

- Stories;
- Story Parts/Sections/Blocks;
- Source Works;
- Editions;
- canonical Passages;
- Passage Representations;
- Citations;
- witness metadata/mappings (schema only is enough);
- search documents/FTS.

## Tests

- row/foreign-key integrity;
- Citation resolution;
- canonical Passage independent of Edition representation;
- FTS Story/source results;
- duplicate-ID and broken-target failures.

## Acceptance

`content.sqlite` can be inspected with standard SQLite tooling and all fixture acceptance queries pass.

**Review Gate A occurs here before Swift product UI work expands.**

# 9. Milestone 3 — SwiftUI Application Foundation

## Goal

Create the iPhone app shell against the generated fixture DB.

## Tasks

- Xcode project;
- iOS 18+;
- add GRDB through Swift Package Manager;
- AppContainer/dependency setup;
- read-only bundled content DB;
- writable user-state DB;
- typed canonical ID wrappers;
- repositories;
- minimal Home with Story / Library / Search / Bookmarks.

## Acceptance

- app launches on simulator and actual iPhone;
- reads fixture Story/Work from SQLite;
- no backend/network code;
- GRDB is the only external dependency.

# 10. Milestone 4 — Story Reader

## Goal

Render structured Story content natively.

## Initial block types

- heading;
- paragraph;
- quotation;
- verse;
- citation row.

## Behavior

- vertical scrolling;
- Story TOC;
- one literary section per reading unit;
- semantic block IDs;
- text-size support;
- Unicode IAST/Devanāgarī/Bengali rendering;
- semantic Story reading-position persistence.

## Acceptance

Close/relaunch and restore the same Story section/block. No substantive Story text is hard-coded in Swift.

# 11. Milestone 5 — Citation Resolver + Source Reader

## Goal

A Story Citation opens the exact canonical source Passage.

## Source reader

- Work identity;
- canonical locus;
- original text;
- transliteration;
- translation with provenance available in Source Details;
- surrounding Passages;
- canonical anchor highlighting;
- Work/section TOC minimum.

## Acceptance

Tap fixture Citation → exact Passage opens → adjacent source Passages can be read.

# 12. Milestone 6 — Story ↔ Source Excursion

## Goal

Perfect the defining MVP behavior.

```text
Story block
→ Citation
→ exact Source Passage
→ move within source
→ Return to Story
→ original Story block restored
```

## Required state

- Story ID;
- Story Section ID;
- Story Block ID;
- originating Citation;
- current source state.

Standard Back should work, but explicit `Return to Story` is required for Story-origin source sessions.

## Mandatory UI test

Automate the complete flow and verify the original semantic Story block is restored.

**Review Gate B occurs here. Architecture may be corrected before real corpus expansion.**

# 13. Milestone 7 — Library

## Goal

Allow independent source study.

## Required

- Library as top-level destination;
- grouped source layers;
- canonical Work rows;
- Work Detail;
- TOC;
- Continue Reading;
- Source Details.

No filesystem-browser UI.

## Acceptance

Open source independently from Library and read/navigate it without Story context.

# 14. Milestone 8 — Search

## Goal

Offline Story + source search using generated FTS5.

## Required

- global search;
- Story and Source result groups;
- snippets;
- exact result navigation;
- search within one Work;
- Back preserves query/results.

## Acceptance

A term present in Story and source text produces both classes of result and both targets navigate correctly.

# 15. Milestone 9 — Bookmarks + Reading Positions

## Bookmarks

- Story semantic positions;
- canonical Source Passages.

## Reading positions

- current Story position;
- last position per Source Work.

Stored in user-state SQLite, never in generated content DB.

## Acceptance

State survives cold relaunch and content DB remains read-only.

# 16. Milestone 10 — First Real Rādhā-kuṇḍa Vertical Slice

## Story

`story.radhakunda.manifestation`

**The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa**

## Required source set

1. complete `work.radha-kundastaka` (1–8);
2. `work.mathura-mahatmya` 418–423 plus immediate useful context;
3. complete `work.radhakunda-manifestation-puranic-unit` (1–20).

Śrīmad-Bhāgavatam 10.36 is added in the next content phase unless already APP_READY.

## Required pre-import audit

```text
Broken citation targets = 0
Visible unverified citation targets = 0
Duplicate canonical IDs = 0
```

Codex ingests prepared content only. Codex does not reconstruct source texts or author Story prose.

# 17. Milestone 10 Acceptance Flow

On the actual iPhone:

```text
Launch
→ Story
→ Manifestation
→ read real prose
→ tap Rādhā-kuṇḍāṣṭaka 1
→ exact source opens
→ read verse 2
→ Return to Story
→ original paragraph restored
→ search narma-dharmokti
→ open source result
→ bookmark passage
```

This flow must be pleasant, not merely technically correct.

# 18. Milestone 11 — Architecture / UX Review Gate

Stop development and review actual use before corpus expansion.

Questions:

- Does the Story feel like a book?
- Are citation rows too prominent or too subtle?
- Is the Source Reader pleasant?
- Is Return to Story effortless?
- Is semantic position restoration sufficient?
- Are source-language layouts clear?
- Is GRDB/content compilation working cleanly?
- Is any part overengineered?

Changes to frozen architecture require an explicit decision recorded in docs before continuing.

# 19. Milestone 12 — Original Witness Support

Only after normalized reading works well:

- PDFKit viewer;
- witness metadata;
- canonical Passage → PDF page mapping;
- both PDF page index and printed page label;
- `View Original Witness`;
- Back returns to normalized source Passage.

PDF witnesses remain optional per Work.

# 20. Milestone 13 — Corpus + Story Expansion

Add one Work/Story section at a time according to MVP-07 priority.

For every Work:

1. prepare;
2. structure;
3. normalize;
4. verify cited passages;
5. mark APP_READY;
6. compile;
7. test search/navigation;
8. inspect in app;
9. commit.

Do not bulk-import unverified sources.

For every Story section:

- APP_READY prose;
- stable ID;
- validated citation markup;
- correct TOC order;
- zero broken targets.

# 21. Milestone 14 — MVP Stabilization

Required before v1.0 internal release:

- complete intended approved Rādhā-kuṇḍa Story corpus;
- every visible citation resolves to VERIFIED Passage;
- Library and search complete for included sources;
- bookmarks and positions reliable;
- Unicode rendering reviewed;
- original witnesses work where included;
- no normal-flow crashes;
- content build/audit clean;
- automated tests pass;
- actual iPhone reading review passed.

Maps/GPS/Kindle/Govardhana remain explicitly excluded.

# 22. Codex Task Contract

Every Codex task prompt contains:

- **Goal** — one bounded objective;
- **Controlling specs** — exact files;
- **Allowed changes** — files/modules;
- **Forbidden changes** — scope exclusions;
- **Acceptance criteria** — observable outcomes;
- **Tests** — what to add/run;
- **Handoff** — required completion report.

# 23. Required Codex Handoff

After each task Codex reports:

- files created;
- files modified;
- architecture decisions made;
- tests added;
- commands/tests run;
- results;
- limitations;
- any spec deviation;
- blockers/questions.

Codex must not simply say “done.”

# 24. Dependency Guardrail

Approved initial third-party Swift dependency:

- GRDB.swift

Codex must ask before adding anything else.

No Core Data, SwiftData, Realm, Firebase, networking SDKs, analytics, or architecture frameworks without explicit approval.

# 25. Rendering Guardrail

Native structured SwiftUI Story/Source readers are binding for initial implementation. Codex may not substitute a giant WKWebView/eBook framework without approval.

# 26. Scholarly Guardrails

Codex must not:

- invent source text;
- edit substantive source readings to satisfy parser code;
- invent translations;
- infer Citations;
- assign A/B/C/D layers;
- resolve uncertain provenance;
- relabel early Ariṣṭa/Kṛṣṇa-kuṇḍa terminology;
- merge commentary into root text;
- present project synthesis as quotation.

# 27. Milestone Approval Rule

Codex stops after each milestone. The user reviews and explicitly authorizes continuation. Small refactors within the currently approved milestone are allowed if they do not change product/domain architecture and are documented in the handoff.

# 28. First Production Task

The first task after the documentation package is installed in the repository is:

## CODEX TASK 001 — Repository & Content Tooling Foundation

It contains **no production SwiftUI feature work**.

Its detailed prompt is distributed as `CODEX_TASK_001.md` in the v1.0 package.

# 29. MVP Completion Definition

The MVP is complete only when the user can comfortably read the complete intended Rādhā-kuṇḍa Story and, whenever desired, move into exact controlled sources and back without losing literary context.

Functional completion alone is insufficient if the reading experience feels like using a database instead of reading a devotional/scholarly work.

# 30. Approved Status

**MVP-08 v1.0 — APPROVED**
