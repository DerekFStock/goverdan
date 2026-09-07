# GOVARDHANA PILGRIMAGE APP

## MVP-05 — Content Authoring & Packaging Specification

**Document ID:** MVP-05  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00 through MVP-04  
**Primary platform:** iPhone  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP

---

> **v1.0 approval note:** This document incorporates the cross-specification decisions in MVP-BASELINE v1.0. The canonical research and literary corpus remain outside Swift; the iPhone app consumes a generated, validated content package.

# 1. Purpose

This specification defines the bridge between the Mac-based Govardhana Pilgrimage research/writing corpus and the Swift application. It establishes the human-authoring formats, repository structure, scholarly markup, content compiler, validation rules, runtime packaging, versioning, and update workflow.

The governing rule is:

> **Research and literary content are authored outside Swift, validated deterministically, compiled into runtime data, and then rendered by the app.**

# 2. Canonical Workflow

```text
Research / source witnesses / approved Story DOCX
                ↓
       App-authoring content
      Markdown / YAML / JSON
                ↓
         Python compiler
                ↓
 validation + citation audit + Unicode normalization
                ↓
 generated SQLite + FTS + referenced assets
                ↓
             Swift app
```

The Swift source code is never the authoritative home of Story prose, source text, source classifications, translations, or citations.

# 3. Repository Structure

```text
GovardhanaPilgrimage/
├── app/
│   └── GovardhanaPilgrimage/
├── content/
│   ├── stories/
│   ├── sources/
│   ├── images/
│   ├── metadata/
│   ├── manifests/
│   └── fixtures/
├── witnesses/
│   ├── pdf/
│   └── scans/
├── tools/
├── docs/
│   └── app-specs/
├── tests/
├── build/
├── README.md
└── .gitignore
```

Original research files may remain in the larger Project/library, but every app representation must retain provenance back to its source witness or prepared research document.

# 4. Story Authoring

Rādhā-kuṇḍa Story sections are authored as Markdown with YAML front matter.

```text
content/stories/radhakunda/
├── story.yaml
├── 01-at-the-foot-of-govardhana.md
├── 02-aristasura.md
├── 03-manifestation.md
└── ...
```

`story.yaml` owns Story identity, part/section ordering, filenames, and version/status metadata. Filenames are not canonical IDs.

Example:

```yaml
id: story.radhakunda
title: "The Story of Śrī Rādhā-kuṇḍa"
version: "1.0.0"
status: approved
sections:
  - id: story.radhakunda.manifestation
    file: 03-manifestation.md
    order: 3
```

Each section contains front matter:

```yaml
---
id: story.radhakunda.manifestation
title: "The Manifestation of Rādhā-kuṇḍa and Kṛṣṇa-kuṇḍa"
section_number: 3
status: app_ready
version: "1.0"
---
```

# 5. Story DOCX Relationship

Reviewed DOCX files may remain the literary archival artifacts. For the application, approved prose is transferred into canonical app Markdown. Once converted, changes must follow a controlled synchronization workflow so the DOCX archive and app-facing Markdown do not silently diverge.

The application build never parses DOCX at runtime.

# 6. Markdown and Scholarly Directives

Ordinary Markdown handles prose structure. Controlled directives carry scholarly relationships.

Citation:

```text
[[cite:passage.radha-kundastaka.1]]
```

Optional display override:

```text
[[cite:passage.radha-kundastaka.1|Rādhā-kuṇḍāṣṭaka 1]]
```

Citation group:

```text
[[cite-group:passage.radha-kundastaka.1,passage.mathura-mahatmya.421]]
```

Direct source quotation:

```markdown
:::source-quote passage="passage.radha-kundastaka.1"
...
:::
```

Project synthesis/source-critical material may use explicit project-note directives so it cannot be mistaken for source wording.

The compiler—not Swift—parses these directives.

# 7. Citation Rendering Rule

The compiled Story block records citation relationships structurally. In the initial iPhone MVP, citations normally render as restrained citation rows after the relevant paragraph or quotation. Authoring syntax therefore does not determine final visual styling.

# 8. Multilingual Encoding

All authoring files are UTF-8 and normalized to Unicode NFC during build. The pipeline must preserve:

- English;
- IAST;
- Devanāgarī;
- Bengali;
- Braj text/transliteration;
- original verse line breaks;
- combining marks and punctuation.

Substantive readings must never be altered merely to make parsing easier.

# 9. Source Directory Model

```text
content/sources/
├── registry.yaml
├── radha-kundastaka/
├── mathura-mahatmya/
├── radhakunda-manifestation-puranic-unit/
└── ...
```

Each Work directory contains canonical Work metadata and one or more edition representations.

Example:

```text
content/sources/govinda-lilamrta/
├── work.yaml
├── editions/
│   └── project-reading-v1/
│       ├── edition.yaml
│       ├── toc.yaml
│       └── sections/
└── mappings/
    └── witnesses.yaml
```

# 10. Work Metadata

Example:

```yaml
id: work.govinda-lilamrta
title: "Govinda-līlāmṛta"
short_title: "Govinda-līlāmṛta"
abbreviation: "GL"
author: "Kṛṣṇadāsa Kavirāja Gosvāmī"
source_layer: A_PRIMARY_GOSVAMI
preferred_reading_edition: edition.govinda-lilamrta.project-reading-v1
status: approved
```

Constituent works receive independent Work IDs plus `parent_work_id` where applicable.

# 11. Edition Metadata

Example:

```yaml
id: edition.govinda-lilamrta.project-reading-v1
work_id: work.govinda-lilamrta
title: "Govardhana Pilgrimage Project Reading Edition"
representation: normalized_text
version: "1.0"
status: approved
preferred: true
basis:
  - "Haridāsa Dāsa electronic text"
  - "Haridāsa Śāstrī printed edition"
normalization_notes:
  - "Unicode normalization"
  - "Verse segmentation"
```

Project Reading Editions must disclose their basis and normalization. If multiple witnesses inform a normalized reading edition, that fact is recorded here.

# 12. Canonical Passage and Edition Representation

Canonical Passage identity is edition-independent.

Example:

```text
passage.govinda-lilamrta.7.6
```

Edition-specific content attaches to the Passage through a Passage Representation containing some or all of:

- original text;
- transliteration;
- translation;
- translation provenance;
- commentary;
- source notes;
- witness mapping.

A new preferred Edition must not require changing Story Citation IDs.

# 13. Source Authoring Formats

The project does not force every source into one authoring syntax.

Preferred:

- Markdown for large prose/verse sections;
- YAML or JSON for compact highly structured works such as short stotras;
- PDF only as a witness representation, not as the canonical source model when a reliable structured text exists.

The compiler normalizes all supported authoring formats into one runtime domain model.

# 14. Passage Markup

Large textual sections may use passage directives:

```markdown
:::passage id="passage.govinda-lilamrta.7.6" locus="7.6"
...
:::
```

Short works may use YAML:

```yaml
passages:
  - id: passage.radha-kundastaka.1
    locus: "1"
    original: |
      ...
    transliteration: |
      ...
    translation:
      text: |
        ...
      credit: "..."
```

Translation provenance is mandatory whenever a translation is displayed in the application.

# 15. Root Text, Commentary, and Project Notes

The authoring system must keep these distinct:

- root text;
- traditional commentary;
- translation;
- editorial/source note;
- project synthesis/research note.

The compiler may reject ambiguous structures where commentary has been mixed into root text without a declared role.

# 16. Source Registry

`content/sources/registry.yaml` is the authoritative list of Works eligible for packaging.

It records at minimum:

- Work ID;
- title;
- abbreviation;
- parent Work if any;
- source layer;
- preferred Edition;
- status.

A release manifest may include only registered Works.

# 17. Original Witnesses

Witness PDFs/scans live outside normalized source text:

```text
witnesses/pdf/
```

Witness metadata contains:

- Witness ID;
- Work ID;
- Edition/witness description;
- filename;
- page count;
- status.

Passage-to-witness mappings distinguish PDF page index from printed page label:

```yaml
passage_id: passage.govinda-lilamrta.7.6
witness_id: witness.govinda-lilamrta.print
pdf_page_index: 112
printed_page_label: "97"
```

Witness files are not required for the first real-content vertical slice; normalized text is proven first.

# 18. Images

Images are reusable assets with stable IDs and metadata rather than raw filenames embedded in Story prose.

```yaml
id: image.radhakunda.example
title: "..."
file: story/radhakunda-example.jpg
caption: "..."
credit: "..."
alt_text: "..."
status: approved
```

Story content references `image.radhakunda.example`. Images are optional in the first vertical slice.

# 19. Content Statuses

Story lifecycle:

```text
NOT_STARTED → DRAFT → REVIEWED → APPROVED → APP_READY
```

Source lifecycle:

```text
RAW → STRUCTURED → NORMALIZED → VERIFIED → APP_READY
```

Only APP_READY Story sections and approved release source material enter the normal MVP release manifest.

# 20. Release Manifest

A manifest explicitly states what enters a build.

```yaml
id: manifest.radhakunda-mvp
version: "0.1.0"
story: story.radhakunda
story_sections:
  - story.radhakunda.manifestation
works:
  - work.radha-kundastaka
  - work.mathura-mahatmya
  - work.radhakunda-manifestation-puranic-unit
```

The build system must never package every file under `content/` by accident.

Development and release manifests may differ.

# 21. Python Content Compiler

Python is the approved compiler/tooling language.

The compiler must:

1. read the selected manifest;
2. read Work and Edition registries;
3. parse Story Markdown/front matter;
4. parse source Markdown/YAML/JSON;
5. resolve canonical IDs;
6. resolve Citations;
7. validate Passage ranges;
8. normalize Unicode;
9. validate source statuses;
10. validate image and witness references;
11. generate ordered Story blocks;
12. generate source TOCs and Passage structures;
13. generate SQLite runtime tables;
14. generate FTS5 search tables;
15. copy selected assets/witnesses;
16. produce a build report and citation audit.

# 22. Validation Errors

A release content build fails for:

- duplicate canonical ID;
- Story Citation target missing;
- missing Work;
- missing Passage;
- invalid parent relationship;
- broken TOC target;
- missing required APP_READY Story section;
- visible citation target not VERIFIED;
- missing required translation provenance;
- invalid image reference;
- invalid declared witness page mapping;
- unsupported schema version.

Warnings may cover non-blocking gaps such as an absent optional translation or absent optional witness.

# 23. Citation Audit

Every release build generates an audit including:

```text
Total citations
Resolved citations
Unverified citations
Missing targets
Range citations
Works referenced
```

Required release condition:

```text
Missing targets = 0
Unverified visible citation targets = 0
```

# 24. Runtime Package

Approved direction:

```text
build/radhakunda-content/
├── manifest.json
├── content.sqlite
├── assets/
├── witnesses/        # only when selected
├── build-report.json
└── citation-audit.json
```

`content.sqlite` is generated, never hand-edited.

# 25. Runtime Schema Responsibilities

The generated SQLite database contains the read-only content model:

- Stories;
- Parts;
- Sections;
- Blocks;
- Source Works;
- Editions;
- canonical Passages;
- Passage Representations;
- Citations;
- witness metadata/mappings;
- image metadata;
- FTS search documents.

Bookmarks, reading positions, and preferences are not part of this package.

# 26. User State Separation

User state is stored by the app in a separate writable database. Content package replacement must not overwrite bookmarks or reading positions as long as stable target IDs remain valid.

# 27. Content Package Metadata

Every package includes:

```json
{
  "packageId": "radhakunda-mvp",
  "version": "0.1.0",
  "schemaVersion": 1,
  "builtAt": "...",
  "sourceCommit": "..."
}
```

Content version is separate from app version and schema version.

# 28. Versioning

Recommended content versioning:

```text
major.minor.patch
```

Stable IDs do not change for ordinary prose revisions, corrected translations, added notes, or improved Edition representations.

# 29. Build Reproducibility

Given the same repository commit, manifest, and compiler version, a content build should be reproducible in semantic content. Generated timestamps may differ.

Git version-controls human-authored Story/source metadata and tooling. Generated SQLite/build products are normally not hand-edited.

# 30. Fast Development Loop

The intended loop is:

```text
Edit approved app Markdown/source files
↓
run content compiler
↓
validation succeeds
↓
launch app
↓
inspect change
```

This should be fast enough for iterative Story development.

# 31. Fixture Corpus

A tiny fixture corpus lives under `content/fixtures/` for parser tests, SwiftUI previews, and deterministic unit tests. It must obey the same schema as real content. It should not contain fabricated devotional claims presented as real sources.

# 32. First Real Content Package

The first real vertical slice contains:

- `story.radhakunda.manifestation`;
- complete `work.radha-kundastaka` verses 1–8;
- `work.mathura-mahatmya` 418–423 plus immediate useful context;
- complete `work.radhakunda-manifestation-puranic-unit` verses 1–20.

Śrīmad-Bhāgavatam 10.36 is added in the next content phase unless already prepared.

# 33. Content Preparation Responsibilities

Codex may build importers, validators, schemas, and conversion tools.

Codex must not independently:

- rewrite Sanskrit/Bengali source text;
- invent translations;
- invent source classifications;
- assign unresolved provenance;
- author the Rādhā-kuṇḍa Story;
- infer citations from text similarity.

Research/editorial decisions come from the approved project corpus.

# 34. App Bundle Strategy

For MVP, the generated content package is bundled with the app. There is no remote content service or runtime import UI.

A later Mac → iPhone content-import workflow may be added after the MVP if useful.

# 35. Package Size

No commercial app-size target controls the private MVP. Nevertheless, only required witnesses/assets should be bundled. Large unrelated project PDFs remain outside the package.

# 36. Acceptance Criteria

MVP-05 is satisfied when:

- Story prose is fully external to Swift;
- source content is fully external to Swift;
- stable citations are human-readable and machine-resolvable;
- canonical Passage identity survives Edition changes;
- multilingual Unicode is preserved;
- translation provenance is preserved;
- a release manifest controls package membership;
- the Python compiler produces validated SQLite + FTS;
- broken citations fail the build;
- user state remains separate;
- the first real vertical-slice corpus can be compiled without app-code edits.

# 37. Approved Status

**MVP-05 v1.0 — APPROVED**
