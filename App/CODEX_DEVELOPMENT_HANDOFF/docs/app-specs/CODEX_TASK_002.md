# CODEX TASK 002 — SQLite Runtime Content Build

**Milestone:** 2 — Runtime SQLite + FTS  
**Status:** Ready only after Task 001 is completed, reviewed, and the user explicitly authorizes Task 002  
**Controlling documents:** MVP-BASELINE v1.0; MVP-02 v1.0; MVP-03 v1.0; MVP-05 v1.0; MVP-06 v1.0; MVP-08 v1.0; CODEX_TASK_001.md

## Goal

Extend the validated **neutral fixture** content pipeline from Task 001 so it deterministically generates the runtime SQLite + FTS package required by the approved architecture.

This task remains fixture-only. The prepared Rādhā-kuṇḍa corpus in `content-handoff/` is future Task 010 input and must not be imported here.

## Allowed changes

- `tools/` content compiler and validators;
- `content/fixtures/` neutral fixture authoring files;
- generated files under `build/`;
- `tests/` for compiler/SQLite/FTS validation;
- repository README/build documentation.

Do not create production SwiftUI reader features in this task.

## Required work

1. Generate `build/radhakunda-content.sqlite` (or the same approved bundle filename if the repository already normalized the build-output location) from the neutral fixture.
2. Implement the runtime content schema required by MVP-08 Milestone 2, covering at minimum:
   - Stories;
   - Story Parts/Sections/Blocks;
   - Source Works;
   - Editions;
   - canonical Passages;
   - Passage Representations;
   - Citations;
   - witness metadata/mappings schema;
   - search documents / SQLite FTS5.
3. Preserve the Task 001 invariant that canonical Passage identity is edition-independent and representation text is Edition-owned.
4. Generate deterministic schema/data from the fixture; do not hand-maintain production database rows.
5. Make foreign-key enforcement and build failure behavior explicit.
6. Populate FTS from Story text and preferred source reading representations in the fixture.
7. Extend the machine-readable build report with SQLite/FTS validation results.

## Required tests

Add/run automated tests proving:

- database creation from a clean fixture build;
- row and foreign-key integrity;
- Citation → canonical Passage resolution;
- canonical Passage remains independent of Edition representation;
- Story text is searchable through FTS5;
- preferred source representation text is searchable through FTS5;
- duplicate IDs fail the build;
- broken Citation targets fail the build;
- broken Work/Edition/Passage relationships fail the build;
- repeated builds from identical fixture input are deterministic for logical content.

Also document one or more SQLite inspection queries that demonstrate the relationships without requiring the app.

## Forbidden changes

Do not:

- import any real Rādhā-kuṇḍa content from `content-handoff/`;
- create the production SwiftUI app shell or readers;
- add GRDB or another Swift dependency;
- add networking/backend;
- add maps/GPS/routes/Govardhana;
- change the approved domain identity model to simplify SQL;
- place Edition text/translation/provenance directly on canonical Passage identity.

## Acceptance criteria

Task 002 is complete only when:

- the neutral fixture compiles into a valid inspectable SQLite database;
- FTS5 returns fixture Story and source results;
- all Task 002 tests pass;
- intentionally invalid fixture cases fail for the expected reason;
- the build report records schema/content/FTS validation;
- no production SwiftUI feature work or real corpus import has occurred.

**Review Gate A occurs at completion of this task.** Do not begin Task 003 until the user explicitly approves continuation.

## Required Codex handoff

Report:

1. files created;
2. files modified;
3. final SQLite tables/indexes/FTS objects;
4. compiler/schema decisions that were already permitted by the specs;
5. commands run;
6. test and inspection-query results;
7. known limitations;
8. deviations/blockers/questions.

Then **stop**.
