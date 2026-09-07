# v1.0 Consolidation Notes

This package was consolidated from the user's v0.1 archive and the approved cross-specification baseline.

Key reconciliations:

- fixed MVP scope to the Rādhā-kuṇḍa Story + source study experience only;
- made minimal Home + Story / Library / Search / Bookmarks binding;
- fixed citations as restrained post-paragraph/quotation rows for initial MVP;
- made canonical Passages edition-independent and added Edition-specific Passage Representations;
- required translation provenance whenever translations are displayed;
- fixed range citations to start/end Passage IDs instead of requiring PassageGroup;
- approved Markdown/YAML/JSON authoring → Python compiler → SQLite/FTS runtime package;
- approved SwiftUI + GRDB + separate content/user-state databases;
- moved PDF witness implementation until after the first real-content vertical slice;
- fixed first real vertical slice and its three required source Works;
- created provisional Work identity for the unresolved twenty-verse manifestation unit;
- preserved early Ariṣṭa/Kṛṣṇa-kuṇḍa terminology discipline;
- reordered Codex milestones so real content is reviewed before PDF witness work;
- added Codex Start Here and exact Task 001 prompt.

The original macOS `__MACOSX` metadata files were intentionally excluded and filenames were normalized to ASCII-safe forms for tooling reliability.


## v1.3 execution-path completeness correction

A later end-to-end handoff audit found that the original package named CODEX TASK 002 and TASK 003 in the Baseline but distributed only TASK 001, and that the later MVP-08 milestones had no bounded work-order files. The v1.3 handoff therefore:

- adds `CODEX_TASK_INDEX.md`;
- adds `CODEX_TASK_002.md` through `CODEX_TASK_014.md`, each derived only from already-approved MVP-08 milestone scope;
- adds `CODEX_HANDOFF_INSTALLATION_MAP.md` to remove flat-handoff/repository path ambiguity;
- adds `story.yaml`, required by MVP-05 for Story identity/order;
- moves the development manifest target into `content/manifests/`;
- maps the citation sidecar into existing `content/metadata/` rather than inventing a `content/citations/` directory;
- maps each compact source package into the MVP-05 Work-directory structure;
- makes Task 010 the first real-corpus integration task and keeps Tasks 001–009 fixture/architecture-only;
- preserves all approved MVP-00 through MVP-08 documents unchanged.
