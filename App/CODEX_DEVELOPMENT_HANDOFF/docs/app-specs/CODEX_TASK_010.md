# CODEX TASK 010 — First Real Rādhā-kuṇḍa Vertical Slice

**Milestone:** 10 — First Real Rādhā-kuṇḍa Vertical Slice  
**Status:** Requires explicit user approval after Task 009  
**Controlling documents:** MVP-BASELINE v1.0; MVP-02 v1.0; MVP-03 v1.0; MVP-05 v1.0; MVP-07 v1.0; MVP-08 v1.0; `CODEX_HANDOFF_INSTALLATION_MAP.md`; `content-handoff/radhakunda-mvp-development-manifest.yaml`

## Goal

Replace the fixture-only demonstration with the prepared **development** Rādhā-kuṇḍa vertical slice, without reconstructing, editing, or inventing scholarly content.

## Authorized real-content input

Only the package enumerated by `content-handoff/radhakunda-mvp-development-manifest.yaml` and mapped by `CODEX_HANDOFF_INSTALLATION_MAP.md` is authorized in this task.

The Story section is:

`story.radhakunda.manifestation` — **The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa**

Required Works:

1. `work.radha-kundastaka` — 1–8;
2. `work.mathura-mahatmya` — 418–423 plus packaged context;
3. `work.radhakunda-manifestation-puranic-unit` — 1–20.

Śrīmad-Bhāgavatam 10.36 remains deferred unless a later approved content package explicitly adds it.

## Required pre-import audit

Before generation, report and require:

```text
Broken citation targets = 0
Visible unverified citation targets = 0
Duplicate canonical IDs = 0
```

Also validate the development manifest, source registry, Story metadata, Story Markdown, citation sidecar, source packages, Unicode NFC, and the compact-authoring → canonical Passage + Passage Representation split.

Do not reinterpret verification-status enums merely to make the audit pass. If the prepared corpus produces a nonzero **Visible unverified citation targets** result under the approved validator/status rules, stop and report a content-verification blocker. This task does not authorize changing `TRANSCRIPTION_COLLATED`, working-translation, or other development statuses to `VERIFIED`/`APP_READY`.

## Required work

- install/copy the handoff files to their authoritative repository target paths from `CODEX_HANDOFF_INSTALLATION_MAP.md`;
- compile the real development content through the existing compiler into SQLite + FTS;
- do not change substantive Story/source text to satisfy code;
- surface source/translation status where the existing Source Details design requires it;
- run the complete Story → Citation → Source → surrounding reading → exact return flow with real content;
- run real Story/source search;
- exercise a Source bookmark.

## Acceptance flow

On the actual iPhone when available (simulator may supplement but not replace the required user/device review gate):

```text
Launch
→ Story
→ Manifestation
→ read real prose
→ tap Rādhā-kuṇḍāṣṭaka 1
→ exact source opens
→ read verse 2
→ Return to Story
→ original paragraph restored
→ search narma-dharmokti
→ open source result
→ bookmark passage
```

## Forbidden changes

Codex must not:

- rewrite or reconstruct source text/translation/Story prose;
- infer new Citations;
- resolve the unidentified Purāṇic provenance;
- silently modernize Kṛṣṇa-kuṇḍa/Ariṣṭa terminology;
- add PDF witness support yet;
- bulk-import any other project corpus;
- add excluded MVP features.

## Acceptance criteria

- the real slice compiles with zero broken IDs/targets;
- the complete acceptance flow works;
- development/release status distinctions remain intact;
- no scholarly content was invented or silently changed;
- automated tests still pass.

This is a mandatory real-content review gate. Provide the standard handoff and **stop** for explicit approval before Task 011.
