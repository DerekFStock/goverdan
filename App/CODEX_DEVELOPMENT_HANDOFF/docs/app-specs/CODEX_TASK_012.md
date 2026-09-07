# CODEX TASK 012 — Original PDF Witness Support

**Milestone:** 12 — Original Witness Support  
**Status:** Requires explicit user approval after Task 011  
**Controlling documents:** MVP-BASELINE v1.0; MVP-03 v1.0; MVP-04 v1.0; MVP-06 v1.0; MVP-08 v1.0; any approved Task 011 amendments

## Goal

Add optional PDF witness viewing **after** normalized Story/source reading has passed the real-content review gate.

## Required work

- PDFKit-based viewer;
- Original Witness metadata from compiled content;
- canonical Passage → witness PDF page mapping;
- preserve both PDF page index and printed page label when provided;
- `View Original Witness` from normalized source context where a mapping exists;
- Back returns to the normalized source Passage;
- Works without a PDF witness remain fully usable.

If no real PDF witness package has been explicitly authorized for this task, use a neutral test PDF/mapping fixture to prove the generic architecture rather than inventing real witness mappings.

## Tests

- mapped Passage opens correct fixture PDF page;
- printed page label and PDF index remain distinct;
- Back restores normalized Passage;
- no mapping → no broken/false witness action;
- existing Story/source flow remains intact.

## Forbidden changes

Do not invent witness mappings, OCR source content, infer printed page labels, bulk-import witnesses, or add excluded features.

## Acceptance criteria

Optional witness viewing works generically and does not disturb normalized reading/navigation. Provide the standard handoff and **stop** for Task 013 approval.
