# CODEX START HERE

## Project

**Govardhana Pilgrimage App — Rādhā-kuṇḍa Story MVP**

This is a private iPhone application. Do not design a public product.

## Before writing code

Read these files in order:

1. `MVP-BASELINE_Cross_Specification_Approval_v1.0.md`
2. `MVP-00_Radhakunda_Story_MVP_Scope_v1.0.md`
3. `MVP-01_Radhakunda_Story_UX_Navigation_v1.0.md`
4. `MVP-02_Content_Domain_Model_v1.0.md`
5. `MVP-03_Source_Citation_Architecture_v1.0.md`
6. `MVP-04_Library_Reader_Architecture_v1.0.md`
7. `MVP-05_Content_Authoring_Packaging_v1.0.md`
8. `MVP-06_Swift_Technical_Architecture_v1.0.md`
9. `MVP-07_Radhakunda_Content_Manifest_v1.0.md`
10. `MVP-08_Codex_Build_Plan_v1.0.md`
11. `CODEX_TASK_INDEX.md`
12. `CODEX_HANDOFF_INSTALLATION_MAP.md`

`MVP-BASELINE` has precedence if wording appears inconsistent. If a task work order and an approved specification conflict, stop and report the conflict rather than inventing a resolution.

## What you are implementing

The central experience is deterministic:

```text
Story → Citation → Exact Source Passage → Surrounding Source Reading → Return to Exact Story Position
```

The Story must still feel like a beautiful long-form devotional/scholarly work when the user ignores every citation.

## Binding technology choices

- iOS 18+
- Swift / SwiftUI
- NavigationStack with typed routes
- native structured Story and Source rendering
- generated read-only SQLite content DB
- separate writable SQLite user-state DB
- GRDB.swift only initial external Swift dependency
- SQLite FTS5
- Python content compiler
- PDFKit only after the first real-content vertical slice
- no networking/backend

## Scholarly guardrails

Never invent or silently alter:

- Sanskrit/Bengali/Braj source text;
- translations;
- citations;
- source A/B/C/D classification;
- source provenance;
- commentary/root-text distinction;
- early naming such as Ariṣṭa-kuṇḍa/Kṛṣṇa-kuṇḍa.

Canonical Passage identity is edition-independent. Story citations target canonical Passages, never PDF page numbers or Passage Representation IDs as the primary identity.

## Scope guardrails

Do not build maps, GPS, routes, Govardhana, fieldwork, Kindle, Android, web, accounts, cloud sync, AI features, analytics, or social functionality.

## Work cadence and authorization

Implement **only the task number the user explicitly authorizes**.

- A fresh repository begins with `CODEX_TASK_001.md`.
- Completion of one task never authorizes the next task automatically.
- If the user explicitly authorizes Task NNN, open `CODEX_TASK_NNN.md`, verify all prerequisites/gates in that work order, implement only that scope, provide the required handoff, and stop.
- Use `CODEX_TASK_INDEX.md` as the complete task/milestone path through the MVP.
- The prepared files in `content-handoff/` are real-content Task 010 input. Tasks 001–009 must not import that corpus into the runtime package.

At completion of every task:

- report created/modified files;
- report architecture decisions;
- report tests added and run;
- report exact results;
- report deviations or blockers;
- stop and wait for user approval.

## Current task selection

Do not infer the current task from this document. Use the user's explicit authorization. If no task number is authorized, stop and ask which task to execute.
