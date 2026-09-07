# CODEX TASK 006 — Story ↔ Source Excursion and Exact Return

**Milestone:** 6 — Story ↔ Source Excursion  
**Status:** Requires explicit user approval after Task 005  
**Controlling documents:** MVP-BASELINE v1.0; MVP-01 v1.0; MVP-03 v1.0; MVP-04 v1.0; MVP-06 v1.0; MVP-08 v1.0

## Goal

Complete the defining MVP interaction:

```text
Story block
→ Citation
→ exact Source Passage
→ move within source
→ Return to Story
→ original Story block restored
```

## Required state

Preserve at minimum:

- Story ID;
- Story Section ID;
- Story Block ID;
- originating Citation;
- current source state.

Standard Back must remain natural, and a Story-origin Source session must expose explicit **Return to Story** behavior.

## Required work

- model Story-origin source excursions explicitly enough to restore semantic Story position;
- allow movement away from the cited source Passage while preserving the Story origin;
- explicit Return to Story restores the originating semantic block rather than a raw pixel offset;
- avoid global singleton navigation hacks that conflict with typed routes.

## Mandatory UI test

Automate the complete fixture flow and assert that the original semantic Story block is restored after source navigation and Return to Story.

Also test standard Back behavior separately.

## Forbidden changes

No real corpus import, Library/Search/Bookmarks expansion, PDF witness support, or excluded MVP features.

## Acceptance criteria

The automated and manual fixture excursion both restore the exact semantic Story origin after reading elsewhere in the source.

**Review Gate B occurs here.** Provide the standard handoff and **stop**. Architecture may be corrected only after explicit user review/approval.
