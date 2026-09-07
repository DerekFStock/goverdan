# Twenty-Verse Rādhā-kuṇḍa Manifestation Account — Source Package Provenance

## Status

**NORMALIZED / DEVELOPMENT-READY / NOT YET APP_READY**

This package supplies the complete twenty-verse source unit required by Phase A of the Rādhā-kuṇḍa Story MVP. It is ready to exercise the content compiler, source reader, canonical passage IDs, passage-range navigation, and Story → Citation → Source flow. It is **not** being represented as a publication-critical edition.

## Canonical work identity

**Work ID:** `work.radhakunda-manifestation-puranic-unit`  
**Display title:** *Twenty-Verse Rādhā-kuṇḍa Manifestation Account*

The project deliberately does **not** assign the work to a named Purāṇa. The controlled provenance formula remains:

> a twenty-verse Purāṇic account preserved/transmitted by Viśvanātha Cakravartī in his commentary on Śrīmad-Bhāgavatam 10.36.16.

This follows RS-01's source-critical ruling. The root verses of Śrīmad-Bhāgavatam 10.36 narrate Ariṣṭāsura's defeat but do not themselves narrate the twin-kuṇḍa manifestation.

## Text basis

The normalized IAST was collated from two complete modern transcription witnesses:

1. **Vedabase, Śrīmad-Bhāgavatam 10.36.16 purport** — clean IAST transcription of all twenty quoted verses.
2. **BVMLU, “Conversation Between Radha and Krishna”** — complete independent ASCII transliteration of the same twenty-verse sequence.

A third project-library witness, **Ananta Dāsa Bābājī, *The Glory and Heritage of Sri Sri Radhakund***, preserves the same narrative sequence across PDF pp. 41–47 (printed pp. 29–35). Its OCR and romanization are too noisy to control the Sanskrit, so it is used only as a later corroborating/transmission witness.

These witnesses establish a dependable **development transcription**, but they do not independently identify the underlying Purāṇa or constitute a critical edition of Viśvanātha's commentary.

For development citation use, canonical Passages 1–20 were directly verified against the identified Vedabase and BVMLU transmission witnesses. This verification does not promote the Work or Edition beyond `NORMALIZED`, approve the `WORKING_PROJECT` translations, resolve the underlying Purāṇa/recension, or constitute publication-critical textual verification against a stable printed or manuscript witness.

## Normalization policy

- Unicode NFC normalization.
- Twenty individually addressable canonical passages.
- Four-pāda lineation retained for source reading.
- IAST diacritics normalized from the clean transcription.
- No silent source-critical emendation. Verse 7 retains the transmitted segmentation `paścima-diśya-mando` and carries an explicit reading note.
- Verse 14 records that Vedabase currently reads `tat-pārṣṇi-ghāṭa-kṛta`, while BVMLU and the Ananta Dāsa transmission preserve undiacriticized `ghata`; the project normalized reading remains `tat-pārṣṇi-ghāta-kṛta`. This normalization remains subject to publication-critical rechecking against a stable printed or manuscript witness before APP_READY release.
- Historical terminology is preserved. The unit itself uses `Kṛṣṇa-kuṇḍa` and `ariṣṭa-mardana-saras`; the app must not rewrite those quotations as “Śyāma-kuṇḍa.”
- Verse 8 explicitly describes the sakhīs lifting moist earth with their **own hands**; bangles are not added as digging tools.
- Verse 17's dividing `bhitti` is a feature inside the līlā narrative and is not identified with a modern causeway or engineered bank.

## Translation

The English fields are **fresh literal Govardhana Pilgrimage Project working translations**, prepared from the normalized Sanskrit for source-reader development. They are not copied from the English translations in the transcription witnesses.

Translation status is `WORKING_PROJECT` / `PENDING_PROJECT_APPROVAL`. They may be used in a development manifest but must be approved or revised before an APP_READY release manifest.

## Narrative movement map

The package preserves the controlled eight-movement structure from RS-01 / RS-02:

| Verses | Movement |
|---|---|
| 1–2 | Playful dharma challenge |
| 3–6 | Kṛṣṇa manifests His pond |
| 7–10 | Rādhā and the sakhīs manifest Her pond |
| 11–16 | The tīrthas petition Rādhā |
| 17 | Waters join |
| 18 | Kṛṣṇa's declaration |
| 19 | Rādhā's reciprocal declaration |
| 20 | Rāsa that night |

## Release blockers

1. Approve or revise the twenty working project translations.
2. Before publication-critical release, collate the Sanskrit against a stable printed or manuscript witness of Viśvanātha's commentary or the underlying Purāṇic unit.
3. Keep the exact Purāṇa/recension unresolved until directly verified.

These blockers do **not** prevent use of the package in the first private development vertical slice; the MVP specification explicitly permits development and release manifests to differ.
