# GOVARDHANA PILGRIMAGE APP

## MVP-BASELINE — Cross-Specification Review & Approval Record

**Document ID:** MVP-BASELINE  
**Version:** v1.0  
**Status:** APPROVED  
**Scope:** Śrī Rādhā-kuṇḍa Story MVP

---

# 1. Purpose and Precedence

This record resolves the implementation-affecting alternatives raised in the earlier v0.1 drafts and establishes the pre-Codex baseline.

If wording in MVP-00 through MVP-08 appears to conflict, this Baseline controls unless a later approved amendment explicitly supersedes it.

# 2. Final Product Definition

The first product is a private iPhone application for reading and studying the complete Story of Śrī Rādhā-kuṇḍa with exact, controlled navigation from Story citations into the source corpus and back to the exact Story context.

Defining interaction:

```text
Story
→ Citation
→ Exact Source Passage
→ Read Surrounding Source
→ Return to Exact Story Position
```

# 3. Binding Scope

Included:

- Story TOC and long-form reader;
- exact Citations;
- Source Reader;
- curated Library;
- global Story/source search;
- search within a Work;
- Bookmarks;
- reading positions;
- multilingual Unicode;
- optional PDF witness viewing after the first real-content vertical slice;
- complete offline operation.

Excluded:

- maps/GPS/routes/Near Me;
- Place database;
- Govardhana implementation;
- fieldwork/photos/audio;
- Kindle;
- Android/E-Ink app;
- web/public version;
- accounts/cloud/backend;
- AI runtime features;
- social/analytics.

# 4. Platform and Architecture

Approved:

- iPhone only for MVP;
- iOS 18+ baseline;
- Swift / SwiftUI;
- typed NavigationStack routes;
- native structured Story/Source rendering;
- vertical scrolling, one Story section per reading unit;
- generated read-only SQLite content database;
- separate writable SQLite user-state database;
- GRDB.swift as the only initial third-party Swift dependency;
- SQLite FTS5;
- Python content compiler;
- PDFKit only after the first real-content vertical slice;
- no networking layer.

# 5. Authoring and Packaging

Approved:

- Story: Markdown + YAML front matter + structured scholarly directives;
- short highly structured sources may use YAML/JSON;
- compiler parses/validates authoring files;
- compiler generates SQLite + FTS + build report + citation audit;
- Swift never parses raw scholarly directives at runtime;
- release manifest explicitly controls content package membership;
- only APP_READY Story and approved release source content enter normal release manifests.

# 6. Canonical Identity

Stable IDs are mandatory for durable entities.

Canonical Passage identity is edition-independent. Editions provide Passage Representations. Story Citations target canonical Passage IDs, so improving/replacing a reading Edition does not break Story links.

Independently cited constituent works receive independent Work IDs plus `parentWorkId` where applicable.

# 7. Source Integrity

Required distinctions:

- Work vs Edition;
- canonical Passage vs Edition representation;
- root text vs commentary;
- original text vs translation;
- source translation vs project translation;
- source wording vs project synthesis;
- A/B/C/D source layer;
- verified vs working/unresolved material.

Translation provenance is mandatory whenever a translation is displayed.

Visible release Citations must target VERIFIED Passages. Broken Citations and visible unresolved targets are release blockers.

# 8. Passage Ranges

MVP range Citations use explicit `startPassageId` / `endPassageId`. No first-class PassageGroup entity is required initially.

# 9. Story UX

Approved:

- minimal Home is required;
- Home exposes Story / Library / Search / Bookmarks;
- Continue Reading resumes Story position;
- Story destination opens Story TOC;
- citations normally render as restrained rows after the relevant paragraph/quotation;
- Story position is semantic: Story + Section + Block;
- Source excursion always preserves Story origin;
- explicit `Return to Story` restores the original semantic block.

# 10. Library / Search / Bookmarks

Library is a top-level MVP destination and is curated, not a raw file browser.

Search is MVP and uses offline FTS over Story and preferred source reading representations.

Bookmarks are MVP and target Story semantic positions or canonical Source Passages. Persistent highlighting and personal notes are deferred.

# 11. First Real Vertical Slice

Fixed Story section:

**The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa**

Required source set:

1. complete Rādhā-kuṇḍāṣṭaka 1–8;
2. Mathurā-māhātmya 418–423 plus immediate useful context;
3. complete Twenty-Verse Rādhā-kuṇḍa Manifestation Account 1–20.

Śrīmad-Bhāgavatam 10.36 follows in the next content phase unless already APP_READY.

No PDF witness is required for this first real-content build.

# 12. Twenty-Verse Unit

Approved provisional Work ID:

```text
work.radhakunda-manifestation-puranic-unit
```

Reader title:

**Twenty-Verse Rādhā-kuṇḍa Manifestation Account**

Description must state that it is a Purāṇic account preserved by Viśvanātha Cakravartī in connection with his commentary on Śrīmad-Bhāgavatam 10.36.16 and that the exact underlying Purāṇic work/recension remains unresolved.

It must not be assigned to Padma Purāṇa or another Purāṇa without later verification.

# 13. Naming Discipline

Early source terminology is preserved exactly enough to distinguish Ariṣṭa-kuṇḍa / Ariṣṭa-saras / Kṛṣṇa-kuṇḍa from the later/common designation Śyāma-kuṇḍa. The application must not silently modernize source wording.

# 14. PDF Witness Timing

PDF witness support is part of the eventual MVP, but it comes **after** the normalized Story/source system and first real-content vertical slice have been reviewed. This is a deliberate sequencing decision.

# 15. Codex Milestone Control

Codex stops for explicit user review after every major milestone.

Mandatory gates:

- after content compiler + SQLite;
- after Story ↔ Source exact-return architecture;
- after first real Rādhā-kuṇḍa vertical slice;
- before MVP completion.

# 16. First Production Tasks

1. CODEX TASK 001 — Repository & Content Tooling Foundation
2. CODEX TASK 002 — SQLite Runtime Content Build
3. CODEX TASK 003 — SwiftUI Application Foundation

Task 001 contains no production SwiftUI feature implementation.

# 17. Deferred Decisions That Do Not Block Codex

- exact color palette;
- final fonts/spacing/iconography;
- sophisticated dark mode;
- image collection;
- later maps/GPS/places;
- Kindle/web;
- future content-import UI;
- future personal notes/highlights.

# 18. Planning Closure

With this Baseline and MVP-00 through MVP-08 at v1.0, the product-planning phase is closed. Any new feature or architectural change must be handled as an explicit amendment rather than informal scope drift.
