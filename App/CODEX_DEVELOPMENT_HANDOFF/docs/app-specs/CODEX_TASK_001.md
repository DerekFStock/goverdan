# CODEX TASK 001 — Repository & Content Tooling Foundation

**Milestone:** 0 + the smallest validated portion of Milestone 1  
**Status:** Ready to execute after user authorizes Codex development  
**Controlling documents:** MVP-BASELINE v1.0, MVP-05 v1.0, MVP-08 v1.0

## Goal

Establish the repository/documentation/content-tooling foundation for the Rādhā-kuṇḍa Story MVP without implementing production SwiftUI features.

The task proves that human-readable Story/source metadata can be represented with stable IDs and validated deterministically.

## Required work

### 1. Repository structure

Create or normalize:

```text
GovardhanaPilgrimage/
├── app/
├── content/
│   ├── stories/
│   ├── sources/
│   ├── images/
│   ├── metadata/
│   ├── manifests/
│   └── fixtures/
├── witnesses/
│   ├── pdf/
│   └── scans/
├── tools/
├── docs/
│   └── app-specs/
├── tests/
├── build/
├── README.md
└── .gitignore
```

Place the approved v1.0 specification package under `docs/app-specs/` or preserve an equivalent existing location and document it.

### 2. Minimal fixture corpus

Create a small, neutral fixture demonstrating:

- one Story;
- one Story Section;
- ordered Story blocks;
- one Source Work;
- one Edition;
- at least three canonical Passages;
- edition-specific Passage Representations;
- at least one Citation from a Story block to a canonical Passage.

Do not invent a fake scriptural claim. Neutral fixture text is acceptable.

### 3. Initial authoring schemas/conventions

Implement the minimum human-readable formats needed by MVP-05:

- Story metadata/front matter;
- Work metadata;
- Edition metadata;
- Passage IDs/loci;
- Citation markup or sidecar metadata.

Do not overbuild every future directive yet.

### 4. Python validator/compiler foundation

Create tooling capable of:

- loading the fixture manifest;
- parsing fixture Story/source files;
- Unicode NFC normalization;
- validating unique IDs;
- validating parent references;
- validating Citation target existence;
- validating Work/Edition/Passage relationships;
- distinguishing canonical Passage from Edition representation;
- producing deterministic intermediate JSON;
- producing a machine-readable build report.

At this task, SQLite generation is **not required**; that is Task 002.

### 5. Automated tests

Add tests that prove:

- valid fixture builds successfully;
- duplicate ID fails;
- missing Citation target fails;
- missing Work/Edition relationship fails;
- canonical Passage can have an Edition representation without being edition-owned;
- Unicode input survives normalization.

## Forbidden changes

Do not:

- create production SwiftUI reader screens;
- add GRDB yet unless needed only to scaffold a future empty app target (prefer not to in this task);
- create SQLite runtime schema;
- add networking/backend;
- add maps/GPS/routes;
- add Govardhana content;
- import the full Rādhā-kuṇḍa source corpus;
- rewrite devotional/source content;
- add third-party Python dependencies unless clearly justified and reported.

## Deliverables

- repository structure;
- fixture authoring files;
- Python tooling;
- automated tests;
- intermediate generated fixture JSON;
- `build-report.json`;
- updated repository README with exact commands.

## Suggested commands

The exact CLI may differ, but the repository should provide an equally simple documented path, for example:

```bash
python3 tools/validate_content.py --manifest fixture
python3 tools/build_content.py --manifest fixture
python3 -m unittest discover tests
```

If using `pytest`, document the dependency and reason before adding it. Standard-library `unittest` is sufficient initially.

## Acceptance criteria

Task 001 is complete only when:

- fixture corpus builds from a clean checkout;
- every validator test passes;
- intentionally invalid fixture tests fail for the expected reason;
- generated JSON contains Story → Citation → canonical Passage → Work/Edition-representation relationships;
- no production UI feature work has been added;
- README explains how to run validation/build/tests;
- Codex provides a written handoff.

## Required Codex handoff

Report:

1. files created;
2. files modified;
3. schema/convention decisions made;
4. commands run;
5. test results;
6. known limitations;
7. any deviation from the specifications;
8. questions that must be resolved before Task 002.

Then **stop**. Do not begin Task 002 until the user explicitly approves continuation.
