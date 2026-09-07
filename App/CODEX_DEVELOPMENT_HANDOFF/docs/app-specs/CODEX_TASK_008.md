# CODEX TASK 008 — Offline Search

**Milestone:** 8 — Search  
**Status:** Requires explicit user approval after Task 007  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-04 v1.0; MVP-05 v1.0; MVP-06 v1.0; MVP-08 v1.0

## Goal

Implement offline Story + source search using the generated SQLite FTS5 index.

## Required work

- global Search top-level destination;
- Story and Source result groups;
- snippets;
- exact navigation to Story semantic target or canonical source Passage;
- search within one Work;
- Back preserves query/results state;
- source search uses preferred reading representations as defined by the compiled index.

## Tests

- one fixture term present in Story and source returns both result classes;
- both result types navigate to the correct target;
- Work-scoped search excludes other Works;
- Back restores query/results;
- Unicode/IAST fixture search behaves according to the existing generated index design without introducing a new search-normalization policy.

## Forbidden changes

Do not import real corpus, add cloud/network search, add AI search, implement PDF witness search, or change FTS architecture without explicit approval.

## Acceptance criteria

The fixture demonstrates complete offline Story/source search and exact navigation. Provide the standard handoff and **stop** for Task 009 approval.
