# Vraja-rīti-cintāmaṇi English Reader Source Provenance

## Reader scope

This package provides one complete English-only reader work: `work.vraja-riti-cintamani`.

It contains 231 English translation blocks covering all 234 canonical verses in three chapters. Chapter 2 verses 7–10 remain one combined witness block. The three supplied witness notes remain attached to verses 1.2, 1.87, and 3.8 rather than becoming independent passages.

## Witnesses

The required import source is the user-supplied `Vraja_Riti_Cintamani_English_Complete.docx`, a lossless modern conversion of the legacy English witness `Vraja riti cintamani.doc`. The Sanskrit file `vraja-riti-cintamani_-_visvanatha_cakravartin.docx` is used only to verify the three-sarga structure and canonical verse coverage.

The English wording and historical transliteration style are preserved. Processing is limited to Unicode NFC normalization, mechanical whitespace cleanup, removal of empty paragraphs, and structural separation of verse numbers and attached notes. Sanskrit root verses are not included in the pilgrim-facing reader.

## Recovery of legacy extraction omissions

The modern DOCX contains Chapter 1 verses 40, 46, 53, 59, 66, 71, and 73. A legacy `.doc` extraction path omitted those paragraphs. The importer requires all seven passages and fails if any is absent.

## Translation and rights status

The supplied English witness does not identify its translator, edition, publisher, or copyright status. The reader therefore displays **Translator not identified in supplied file** and remains private research content. Public distribution is not authorized until publication rights and provenance are confirmed.

## Runtime intent

The work uses the existing immutable content database, Source Reader, offline search, bookmarks, reading positions, and exact canonical deep links. It does not create map relationships automatically from textual place-name matches.
