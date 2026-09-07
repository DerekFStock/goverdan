# Govardhana Pilgrimage App — Rādhā-kuṇḍa Story MVP Handoff

This package contains the approved v1.0 product/architecture specifications, complete bounded Codex work orders for Milestones 0–14, and the prepared future real-content package for the first Rādhā-kuṇḍa vertical slice.

## Product in one sentence

A calm, offline iPhone reader for the Story of Śrī Rādhā-kuṇḍa in which controlled citations open the exact source passage, allow surrounding source reading, and return to the exact Story context.

## Read first

1. `CODEX_START_HERE.md`
2. `MVP-BASELINE_Cross_Specification_Approval_v1.0.md`
3. MVP-00 through MVP-08 in numeric order
4. `CODEX_TASK_INDEX.md`
5. the **explicitly authorized** `CODEX_TASK_NNN.md`
6. `CODEX_HANDOFF_INSTALLATION_MAP.md` before Task 010 real-content integration

## Precedence

`MVP-BASELINE` controls approved product/architecture decisions. Codex must not invent missing product behavior. The Task work orders translate the approved MVP-08 milestones into bounded implementation scopes; they do not override the baseline.

## Complete task path

`CODEX_TASK_001.md` through `CODEX_TASK_014.md` are present. Each task stops at its approval gate. `CODEX_TASK_INDEX.md` is the authoritative execution index.

Important sequencing:

- Tasks 001–009 use neutral fixture/generated architecture and do **not** import the real Rādhā-kuṇḍa content handoff.
- Task 010 is the first authorized real-content integration task.
- Task 011 is an architecture/UX review stop.
- Task 013 is repeatable one explicitly user-named content unit at a time.

## Real vertical-slice handoff

`../../content-handoff/` contains the prepared development Story/source package for Task 010, including Story metadata, Story Markdown, source registry/packages, citation sidecar, provenance notes, manifest, checksums, and the archival Word draft.

Repository target paths are defined in `CODEX_HANDOFF_INSTALLATION_MAP.md`; do not guess them from the flat delivery folder.

## Scope

Included: Story, exact citations, Source Reader, curated Library, Search, Bookmarks, reading position, offline structured content, and later PDF witness support.

Excluded: maps, GPS, routes, Govardhana implementation, fieldwork, Kindle, Android, web/backend, AI runtime features, social features, and analytics.
