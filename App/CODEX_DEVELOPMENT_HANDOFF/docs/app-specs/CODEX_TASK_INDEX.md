# CODEX TASK INDEX — Approved MVP Execution Path

**Status:** Execution index derived from MVP-BASELINE v1.0 and MVP-08 v1.0.  
**Rule:** This index does not itself authorize execution. The user must explicitly authorize each task/milestone.

| Task | Milestone | Work order | Gate / next step |
|---|---:|---|---|
| 001 | 0 + fixture foundation from 1 | Repository & Content Tooling Foundation | Stop for approval |
| 002 | 2 | SQLite Runtime Content Build | **Review Gate A** |
| 003 | 3 | SwiftUI Application Foundation | Stop for approval |
| 004 | 4 | Story Reader | Stop for approval |
| 005 | 5 | Citation Resolver + Source Reader | Stop for approval |
| 006 | 6 | Story ↔ Source Excursion and Exact Return | **Review Gate B** |
| 007 | 7 | Library | Stop for approval |
| 008 | 8 | Offline Search | Stop for approval |
| 009 | 9 | Bookmarks + Reading Positions | Stop for approval |
| 010 | 10 | First Real Rādhā-kuṇḍa Vertical Slice | **Real-content review gate** |
| 011 | 11 | Architecture / UX Review Gate | Explicit proceed/hold decision |
| 012 | 12 | Original PDF Witness Support | Stop for approval |
| 013 | 13 | Controlled Corpus + Story Expansion | Repeat one explicitly authorized unit at a time |
| 014 | 14 | MVP Stabilization and 1.0 Gate | Final user approval |

## Sequencing clarifications

- Task 001 intentionally combines Milestone 0 with the smallest validated fixture portion of Milestone 1, exactly as `CODEX_TASK_001.md` states.
- Task 002 implements Milestone 2 against the **neutral fixture** and completes Review Gate A. It does not import the real content handoff.
- Tasks 003–009 continue against fixture/generated content architecture.
- Task 010 is the first task authorized to integrate the prepared real Rādhā-kuṇḍa vertical slice in `content-handoff/`.
- Task 011 is a deliberate stop/review gate, not a feature-expansion milestone.
- Task 013 is repeatable and requires an exact user-named content target for each execution.

## Authorization rule

Codex must never infer that completion of one task authorizes the next. After every task it must provide the handoff required by MVP-08 §23 and wait for explicit user approval.
