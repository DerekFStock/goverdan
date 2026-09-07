# CODEX TASK 009 — Bookmarks + Reading Positions

**Milestone:** 9 — Bookmarks + Reading Positions  
**Status:** Requires explicit user approval after Task 008  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-02 v1.0; MVP-04 v1.0; MVP-06 v1.0; MVP-08 v1.0

## Goal

Complete the approved local user-state behaviors while keeping the generated content database immutable/read-only.

## Required work

### Bookmarks

- bookmark Story semantic positions;
- bookmark canonical Source Passages;
- top-level Bookmarks destination lists and opens them.

### Reading positions

- current Story position;
- last position per Source Work;
- persist only in `Application Support/user-state.sqlite`.

Persistent highlighting and personal notes remain deferred.

## Tests

- create/remove/open Story bookmark;
- create/remove/open Source bookmark;
- Story and per-Work reading positions survive cold relaunch;
- content database remains read-only and unchanged by user-state operations.

## Acceptance criteria

All approved bookmarks/positions work with fixture content across relaunch, with strict content/user-state database separation.

Do not import real corpus or add deferred notes/highlights. Provide the standard handoff and **stop** for Task 010 approval.
