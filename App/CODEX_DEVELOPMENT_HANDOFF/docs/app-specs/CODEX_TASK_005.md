# CODEX TASK 005 — Citation Resolver + Source Reader

**Milestone:** 5 — Citation Resolver + Source Reader  
**Status:** Requires explicit user approval after Task 004  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-02 v1.0; MVP-03 v1.0; MVP-04 v1.0; MVP-06 v1.0; MVP-08 v1.0

## Goal

Make a fixture Story Citation resolve to the exact canonical source Passage and provide native surrounding source reading.

## Required work

- Citation repository/resolver using canonical Passage IDs;
- Source Reader showing Work identity and canonical locus;
- preferred Edition representation display: original text where present, transliteration, translation;
- translation provenance available through Source Details when a translation is displayed;
- adjacent/surrounding Passages;
- canonical target Passage visibly anchored/highlighted on entry;
- minimum Work/section TOC/navigation required by MVP-08;
- source naming/provenance/status data must come from compiled content, not Swift constants.

## Tests

- tap/resolve fixture Citation → exact canonical Passage;
- preferred representation is selected without changing canonical Passage identity;
- adjacent Passages can be read;
- translation provenance can be retrieved when translation is displayed;
- nonexistent Citation/Passage fails safely in test data.

## Forbidden changes

Do not yet implement the explicit Story-origin excursion/Return-to-Story state machine (Task 006), Library, global Search, bookmarks, PDF witness support, real corpus import, or excluded MVP features.

## Acceptance criteria

Fixture Citation opens the exact canonical Passage and the user can read adjacent Passages in a native Source Reader.

Provide the standard handoff, then **stop** for Task 006 approval.
