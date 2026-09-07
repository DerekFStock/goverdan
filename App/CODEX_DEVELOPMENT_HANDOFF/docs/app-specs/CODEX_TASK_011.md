# CODEX TASK 011 — Architecture / UX Review Gate

**Milestone:** 11 — Architecture / UX Review Gate  
**Status:** Review-only task after the first real vertical slice  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-06 v1.0; MVP-08 v1.0; Task 010 handoff

## Goal

Stop feature expansion and evaluate the actual real-content reading experience before adding witness support or more corpus.

## Required review

Assess and report, using the real Task 010 build:

- Does the Story feel like a book?
- Are citation rows too prominent or too subtle?
- Is the Source Reader pleasant?
- Is Return to Story effortless and exact?
- Is semantic position restoration sufficient?
- Are source-language layouts clear?
- Is GRDB/content compilation clean?
- Is any part overengineered?

Run the existing automated suite and the Task 010 acceptance flow again to establish a stable baseline.

## Allowed changes

This task does **not** authorize new features. Small defect fixes that do not change frozen product/domain architecture may be made only when they are necessary to complete the review and are fully reported. Any architecture or UX change requiring a frozen decision must be proposed, not silently implemented.

## Deliverable

Produce a review handoff listing:

- findings;
- defects fixed, if any;
- proposed architecture/UX amendments, if any;
- test results;
- explicit recommendation to proceed or hold.

Then **stop**. Task 012 requires explicit user approval and any approved amendment must be recorded before implementation.
