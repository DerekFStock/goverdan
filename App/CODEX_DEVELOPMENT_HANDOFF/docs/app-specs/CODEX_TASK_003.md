# CODEX TASK 003 — SwiftUI Application Foundation

**Milestone:** 3 — SwiftUI Application Foundation  
**Status:** Requires explicit approval after Review Gate A / Task 002  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-02 v1.0; MVP-06 v1.0; MVP-08 v1.0; CODEX_TASK_002.md

## Goal

Create the iOS 18+ SwiftUI application shell against the **generated neutral-fixture SQLite database**, without yet building the Story Reader or Source Reader.

## Allowed changes

- `app/` Xcode project and Swift source;
- app resources needed to bundle the fixture content DB;
- minimal user-state database setup;
- app/unit tests;
- README/build instructions.

## Required work

- Create/normalize the iPhone app target for iOS 18+.
- Add **GRDB.swift** through Swift Package Manager; add no other third-party Swift dependency.
- Use `NavigationStack` with typed routes.
- Establish a lightweight `AppContainer`/dependency composition consistent with MVP-06.
- Open bundled `radhakunda-content.sqlite` read-only.
- Create writable `Application Support/user-state.sqlite` with the approved initial user-state tables (`bookmarks`, `reading_positions`, `settings`) or the smallest schema necessary to establish them without implementing their feature behavior yet.
- Add strongly typed canonical ID wrappers where used by the foundation.
- Add repository access sufficient to read fixture Story and Work metadata.
- Implement minimal Home exposing Story / Library / Search / Bookmarks destinations. These destinations may be foundation placeholders; production feature behavior belongs to later tasks.
- Include no networking layer.

## Required tests

- app/database initialization succeeds;
- content DB is opened read-only;
- fixture Story and Work can be read through the repository;
- user-state DB can be created/written independently;
- typed route/ID basics work;
- app target builds and launches in an iPhone simulator.

If an actual iPhone is available to Codex, report that result separately; simulator success is required in the automated handoff.

## Forbidden changes

Do not:

- import the real Rādhā-kuṇḍa corpus;
- implement the production Story Reader;
- implement Source Reader/citation excursions;
- implement Library/Search/Bookmarks beyond minimal navigation shells;
- add PDFKit witness UI;
- add maps/GPS/networking/backend;
- add dependencies other than GRDB.swift.

## Acceptance criteria

- app launches;
- Home exposes the four approved top-level destinations;
- app reads fixture Story/Work metadata from SQLite;
- content DB remains read-only and user state is separate/writable;
- GRDB is the only external Swift dependency;
- no forbidden feature work is present.

## Handoff and stop

Provide the standard Codex handoff required by MVP-08 §23, including build/test commands and exact results. Then **stop** and wait for explicit authorization of Task 004.
