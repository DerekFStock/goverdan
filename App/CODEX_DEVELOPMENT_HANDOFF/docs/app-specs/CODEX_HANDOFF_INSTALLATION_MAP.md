# CODEX HANDOFF INSTALLATION MAP

**Purpose:** Remove path ambiguity between the flat `content-handoff/` delivery folder and the repository layout approved by MVP-05 / Task 001.

The files in `content-handoff/` are delivery artifacts. They are **not** all meant to remain flat when Task 010 installs the real vertical slice.

## Specification/task documents

Everything in the handoff `docs/app-specs/` folder remains at:

```text
docs/app-specs/<same filename>
```

## Real-content package target paths

The following mapping is authoritative for Task 010:

| Handoff file | Repository target | Runtime? | Earliest authorized use |
|---|---|---:|---|
| `radhakunda-mvp-development-manifest.yaml` | `content/manifests/radhakunda-mvp-development-manifest.yaml` | build input | Task 010 |
| `radhakunda-mvp-source-registry.yaml` | `content/sources/registry.yaml` | build input | Task 010 |
| `story.yaml` | `content/stories/radhakunda/story.yaml` | build input | Task 010 |
| `03-manifestation.md` | `content/stories/radhakunda/03-manifestation.md` | build input | Task 010 |
| `radhakunda-manifestation-citation-map.yaml` | `content/metadata/radhakunda-manifestation-citation-map.yaml` | build input/sidecar | Task 010 |
| `radha-kundastaka.yaml` | `content/sources/radha-kundastaka/package.yaml` | build input | Task 010 |
| `radha-kundastaka_PROVENANCE.md` | `content/sources/radha-kundastaka/PROVENANCE.md` | audit/source-control | Task 010 |
| `mathura-mahatmya.yaml` | `content/sources/mathura-mahatmya/package.yaml` | build input | Task 010 |
| `mathura-mahatmya_PROVENANCE.md` | `content/sources/mathura-mahatmya/PROVENANCE.md` | audit/source-control | Task 010 |
| `radhakunda-manifestation-puranic-unit.yaml` | `content/sources/radhakunda-manifestation-puranic-unit/package.yaml` | build input | Task 010 |
| `radhakunda-manifestation-puranic-unit_PROVENANCE.md` | `content/sources/radhakunda-manifestation-puranic-unit/PROVENANCE.md` | audit/source-control | Task 010 |
| `SHA256SUMS.json` | `content/manifests/SHA256SUMS.json` | audit only | Task 010 |
| `RKST-03_The_Manifestation_of_Radhakunda_and_Krsnakunda_Draft_v0.1.docx` | `docs/content-archives/RKST-03_The_Manifestation_of_Radhakunda_and_Krsnakunda_Draft_v0.1.docx` | no | archive only |

## Important constraints

- Tasks 001–009 may inspect/preserve the delivery folder but must not import the real corpus into the fixture/runtime content package.
- The development manifest's internal `target_path` entries and the source registry package paths must agree with this map.
- `content/metadata/` is used for the citation sidecar because Task 001/MVP-05 already reserve `content/metadata/`; no extra `content/citations/` directory is introduced.
- The three compact source `package.yaml` files are human-authoring containers. The compiler must apply the handoff's `authoring_serialization_contract` and emit separate canonical Passage and Edition-owned Passage Representation runtime records.
- The DOCX is archival/reference material. The application build never parses it at runtime.
