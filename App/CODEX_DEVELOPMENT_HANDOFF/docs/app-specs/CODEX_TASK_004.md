# CODEX TASK 004 — Story Reader

**Milestone:** 4 — Story Reader  
**Status:** Requires explicit user approval after Task 003  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-02 v1.0; MVP-05 v1.0; MVP-06 v1.0; MVP-08 v1.0

## Goal

Render structured Story content natively from the fixture database as a calm long-form reading experience. No substantive Story prose may be hard-coded in Swift.

## Required work

- Story destination and Story TOC;
- one Story section per reading unit;
- vertical scrolling;
- structured rendering for the initial approved block types: heading, paragraph, quotation, verse, citation row;
- stable semantic Content Block IDs in the rendered model;
- text-size/accessibility support appropriate to native SwiftUI text;
- Unicode rendering suitable for English, IAST, Devanāgarī, and Bengali fixture coverage;
- automatic semantic Story reading-position persistence using Story + Section + Block, with optional intra-block position only if already needed by the implementation.

Citation rows are rendered but do not need to navigate to a Source Reader until Task 005.

## Tests

- render fixture section from database, not hard-coded Swift text;
- ordered blocks preserve authored order;
- semantic block IDs survive rendering;
- close/relaunch restores the same Story section/block;
- representative Unicode fixture strings render/load without data loss.

## Forbidden changes

Do not implement Source Reader, exact citation navigation, global search, Library browsing, bookmarks UI, PDF witnesses, real corpus import, or excluded MVP features.

## Acceptance criteria

The fixture Story can be opened from Home/TOC, read as a native structured section, and restored to its semantic position after relaunch.

Provide the standard Codex handoff, then **stop** for Task 005 approval.
