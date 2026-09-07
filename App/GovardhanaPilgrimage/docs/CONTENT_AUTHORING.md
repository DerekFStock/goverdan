# Initial content-authoring conventions

Task 001 implements the smallest authoring surface needed to prove stable identity and deterministic citation resolution.

## Manifest

`content/manifests/fixture.json` names the Story Markdown and source-package JSON files. Paths are relative to the repository root. Manifest order is preserved only where the field is explicitly an array; compiled entity collections are sorted by stable ID.

## Story Markdown

A Story file uses a small YAML front matter subset containing scalar `key: value` pairs. Required fields are `story_id`, `story_title`, `section_id`, `section_title`, `section_order`, and `status`.

Story blocks begin with a stable anchor:

```markdown
<!-- content-block-id: block.fixture.opening; type: paragraph -->
```

A citation is an inline directive inside that block:

```text
[[cite:id=citation.fixture.opening;passage=passage.fixture.2;role=primary_support]]
```

The directive targets an edition-independent canonical Passage ID. It never targets an Edition or Passage Representation.

The optional block `type` is `heading`, `paragraph`, `quotation`, or `verse`; an omitted type defaults to `paragraph`. The compiler stores this structured value in SQLite so Swift never parses authoring directives at runtime.

## Source package JSON

The source package contains separate collections for:

- `work`: stable intellectual-work identity;
- `edition`: a reading edition owned by the Work;
- `passages`: canonical, edition-independent Passage identities and loci;
- `representations`: edition-owned textual representations referring to both a Passage and an Edition.

Text belongs to a Passage Representation, not to canonical Passage identity. Replacing the preferred Edition must not change a Passage ID or break a Story Citation.

Preferred Edition metadata may include translator, translation provenance, and normalization provenance. These compiled fields drive Source Details whenever a translation is displayed; they must not be supplied as Swift constants.

All source and Story text is normalized to Unicode NFC before validation and compilation. Unknown fields are preserved after normalization, allowing the schema to grow without embedding devotional content in Swift code.

## Runtime projection

Task 002 generates `build/radhakunda-content.sqlite` from the validated intermediate model. Foreign keys are enforced during generation. The database contains separate canonical `source_passages` and edition-owned `passage_representations` tables, plus FTS5 search documents derived from Story blocks and preferred-edition source representations.

Witness, witness-mapping, Story Part, source-section, and image tables are present as schema-only extension points in the neutral fixture. User state is deliberately excluded and will live in a separate writable database.
