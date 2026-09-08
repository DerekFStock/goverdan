import Foundation
import GRDB

protocol ContentRepository: Sendable {
    func pilgrimagePlaces() throws -> [PilgrimagePlace]
    func stories() throws -> [StorySummary]
    func works() throws -> [SourceWorkSummary]
    func storySections(storyID: StoryID) throws -> [StorySectionSummary]
    func storyBlocks(sectionID: StorySectionID) throws -> [StoryBlock]
    func storyCitations(blockID: StoryBlockID) throws -> [StoryCitationRow]
    func resolveCitation(citationID: CitationID) throws -> SourcePassageID
    func sourceReaderContent(targetPassageID: SourcePassageID) throws -> SourceReaderContent
    func sourceReaderContent(workID: SourceWorkID) throws -> SourceReaderContent
    func search(_ query: String, in workID: SourceWorkID?) throws -> [SearchResult]
    func originalWitnessMapping(passageID: SourcePassageID) throws -> OriginalWitnessMapping?
}

struct SQLiteContentRepository: ContentRepository {
    let database: ContentDatabase

    func pilgrimagePlaces() throws -> [PilgrimagePlace] {
        try database.reader.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT * FROM pilgrimage_places ORDER BY map_number"
            ).map { row in
                let placeID: String = row["id"]
                let aliases = try String.fetchAll(
                    db,
                    sql: "SELECT alias FROM pilgrimage_place_aliases WHERE place_id = ? ORDER BY alias",
                    arguments: [placeID]
                )
                let provenance = try Row.fetchAll(
                    db,
                    sql: "SELECT source_type, description, source_reference FROM pilgrimage_place_provenance WHERE place_id = ? ORDER BY sort_order",
                    arguments: [placeID]
                ).map { evidence in
                    PilgrimagePlaceProvenance(
                        sourceType: evidence["source_type"],
                        description: evidence["description"],
                        sourceReference: evidence["source_reference"]
                    )
                }
                guard
                    let status = CoordinateVerificationStatus(rawValue: row["coordinate_status"]),
                    let confidence = CoordinateConfidence(rawValue: row["coordinate_confidence"])
                else { throw ContentRepositoryError.invalidPilgrimagePlace(placeID) }
                let destinationKind: String? = row["content_destination_kind"]
                let destinationID: String? = row["content_destination_id"]
                let destination: PilgrimageContentDestination?
                switch (destinationKind, destinationID) {
                case let ("STORY_SECTION", id?): destination = .storySection(StorySectionID(rawValue: id))
                case let ("SOURCE_PASSAGE", id?): destination = .sourcePassage(SourcePassageID(rawValue: id))
                case (nil, nil): destination = nil
                default: throw ContentRepositoryError.invalidPilgrimagePlace(placeID)
                }
                return PilgrimagePlace(
                    id: PilgrimagePlaceID(rawValue: placeID),
                    mapNumber: row["map_number"],
                    canonicalName: row["canonical_name"],
                    asciiName: row["ascii_name"],
                    alternateNames: aliases,
                    latitude: row["latitude"],
                    longitude: row["longitude"],
                    coordinateStatus: status,
                    coordinateConfidence: confidence,
                    coordinateAccuracyMeters: row["coordinate_accuracy_meters"],
                    verificationNotes: row["verification_notes"],
                    navigationAnchorPlaceID: (row["navigation_anchor_place_id"] as String?).map(PilgrimagePlaceID.init(rawValue:)),
                    locationGuidance: row["location_guidance"],
                    provenance: provenance,
                    contentDestination: destination
                )
            }
        }
    }

    func stories() throws -> [StorySummary] {
        try database.reader.read { db in
            try Row.fetchAll(db, sql: "SELECT id, title, status FROM stories ORDER BY title").map { row in
                StorySummary(
                    id: StoryID(rawValue: row["id"]),
                    title: row["title"],
                    status: row["status"]
                )
            }
        }
    }

    func works() throws -> [SourceWorkSummary] {
        try database.reader.read { db in
            try Row.fetchAll(
                db,
                sql: """
                    SELECT w.id, w.title, w.status, w.author, w.source_layer
                    FROM source_works w
                    WHERE EXISTS (
                        SELECT 1 FROM source_passages p
                        JOIN source_editions e ON e.work_id = p.work_id AND e.preferred = 1
                        WHERE p.work_id = w.id
                    )
                    ORDER BY w.title
                    """
            ).map { row in
                SourceWorkSummary(
                    id: SourceWorkID(rawValue: row["id"]),
                    title: row["title"],
                    status: row["status"],
                    author: row["author"],
                    sourceLayer: row["source_layer"]
                )
            }
        }
    }

    func storySections(storyID: StoryID) throws -> [StorySectionSummary] {
        try database.reader.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT id, story_id, title, sort_order FROM story_sections WHERE story_id = ? ORDER BY sort_order",
                arguments: [storyID.rawValue]
            ).map { row in
                StorySectionSummary(
                    id: StorySectionID(rawValue: row["id"]),
                    storyID: StoryID(rawValue: row["story_id"]),
                    title: row["title"],
                    order: row["sort_order"]
                )
            }
        }
    }

    func storyBlocks(sectionID: StorySectionID) throws -> [StoryBlock] {
        try database.reader.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT id, section_id, sort_order, block_type, text FROM story_blocks WHERE section_id = ? ORDER BY sort_order",
                arguments: [sectionID.rawValue]
            ).map { row in
                guard let type = StoryBlockType(rawValue: row["block_type"]) else {
                    throw ContentRepositoryError.unsupportedStoryBlockType(row["block_type"])
                }
                return StoryBlock(
                    id: StoryBlockID(rawValue: row["id"]),
                    sectionID: StorySectionID(rawValue: row["section_id"]),
                    order: row["sort_order"],
                    type: type,
                    text: row["text"]
                )
            }
        }
    }

    func storyCitations(blockID: StoryBlockID) throws -> [StoryCitationRow] {
        try database.reader.read { db in
            try Row.fetchAll(
                db,
                sql: """
                    SELECT c.id, c.content_block_id, c.source_passage_id, c.start_passage_id,
                           c.end_passage_id, c.role, w.title,
                           start.display_locus AS start_display_locus,
                           start.canonical_locus AS start_canonical_locus,
                           end.display_locus AS end_display_locus,
                           end.canonical_locus AS end_canonical_locus
                    FROM citations c
                    JOIN source_passages start ON start.id = COALESCE(c.source_passage_id, c.start_passage_id)
                    LEFT JOIN source_passages end ON end.id = c.end_passage_id
                    JOIN source_works w ON w.id = start.work_id
                    WHERE c.content_block_id = ? ORDER BY c.sort_order
                    """,
                arguments: [blockID.rawValue]
            ).map { row in
                let sourcePassageID: String? = row["source_passage_id"]
                let startPassageID: String? = row["start_passage_id"]
                let endPassageID: String? = row["end_passage_id"]
                let target: StoryCitationTarget
                let locus: String
                if let sourcePassageID {
                    target = .singleton(SourcePassageID(rawValue: sourcePassageID))
                    let display: String? = row["start_display_locus"]
                    let canonical: String = row["start_canonical_locus"]
                    locus = display ?? canonical
                } else if let startPassageID, let endPassageID {
                    target = .range(
                        start: SourcePassageID(rawValue: startPassageID),
                        end: SourcePassageID(rawValue: endPassageID)
                    )
                    let startLocus: String = row["start_canonical_locus"]
                    let endLocus: String = row["end_canonical_locus"]
                    locus = "Verses \(Self.compactRangeLocus(start: startLocus, end: endLocus))"
                } else {
                    throw ContentRepositoryError.invalidCitationTarget(CitationID(rawValue: row["id"]))
                }
                return StoryCitationRow(
                    id: CitationID(rawValue: row["id"]),
                    blockID: StoryBlockID(rawValue: row["content_block_id"]),
                    target: target,
                    label: "\(row["title"] as String) \(locus)",
                    role: row["role"]
                )
            }
        }
    }

    private static func compactRangeLocus(start: String, end: String) -> String {
        let startComponents = start.split(separator: ".")
        let endComponents = end.split(separator: ".")
        if startComponents.count == endComponents.count,
           startComponents.dropLast() == endComponents.dropLast(),
           let startLeaf = startComponents.last,
           let endLeaf = endComponents.last {
            return "\(startLeaf)–\(endLeaf)"
        }
        return "\(start)–\(end)"
    }

    func resolveCitation(citationID: CitationID) throws -> SourcePassageID {
        try database.reader.read { db in
            guard let passageID = try String.fetchOne(
                db,
                sql: "SELECT COALESCE(source_passage_id, start_passage_id) FROM citations WHERE id = ?",
                arguments: [citationID.rawValue]
            ) else {
                throw ContentRepositoryError.citationNotFound(citationID)
            }
            return SourcePassageID(rawValue: passageID)
        }
    }

    func sourceReaderContent(targetPassageID: SourcePassageID) throws -> SourceReaderContent {
        try database.reader.read { db in
            guard let metadata = try Row.fetchOne(
                db,
                sql: """
                    SELECT w.id AS work_id, w.title AS work_title, w.status AS work_status,
                           w.author, w.source_layer, e.title AS edition_title, e.status AS edition_status,
                           e.translator, e.translation_provenance, e.normalization_provenance
                    FROM source_passages target
                    JOIN source_works w ON w.id = target.work_id
                    JOIN source_editions e ON e.work_id = w.id AND e.preferred = 1
                    WHERE target.id = ?
                    """,
                arguments: [targetPassageID.rawValue]
            ) else {
                throw ContentRepositoryError.passageNotFound(targetPassageID)
            }

            let workID = SourceWorkID(rawValue: metadata["work_id"])
            let passages = try Row.fetchAll(
                db,
                sql: """
                    SELECT p.id, p.work_id, p.canonical_locus, p.display_locus, p.sort_order,
                           p.verification_status, r.original_text, r.transliteration, r.translation, r.source_notes
                    FROM source_passages p
                    JOIN source_editions e ON e.work_id = p.work_id AND e.preferred = 1
                    JOIN passage_representations r ON r.passage_id = p.id AND r.edition_id = e.id
                    WHERE p.work_id = ? ORDER BY p.sort_order
                    """,
                arguments: [workID.rawValue]
            ).map { row in
                let canonicalLocus: String = row["canonical_locus"]
                let displayLocus: String? = row["display_locus"]
                let sourceNotes: String? = row["source_notes"]
                let noteValues = sourceNotes.flatMap(Self.noteValues)
                return SourcePassage(
                    id: SourcePassageID(rawValue: row["id"]),
                    workID: SourceWorkID(rawValue: row["work_id"]),
                    canonicalLocus: canonicalLocus,
                    displayLocus: displayLocus ?? canonicalLocus,
                    order: row["sort_order"],
                    originalText: row["original_text"],
                    transliteration: row["transliteration"],
                    translation: row["translation"],
                    verificationStatus: row["verification_status"],
                    translationStatus: noteValues?["translation_status"] as? String,
                    readingNote: noteValues?["reading_note"] as? String
                )
            }
            guard passages.contains(where: { $0.id == targetPassageID }) else {
                throw ContentRepositoryError.preferredRepresentationNotFound(targetPassageID)
            }

            return SourceReaderContent(
                work: SourceWorkDetails(
                    id: workID,
                    title: metadata["work_title"],
                    status: metadata["work_status"],
                    author: metadata["author"],
                    sourceLayer: metadata["source_layer"],
                    preferredEdition: SourceEditionDetails(
                        title: metadata["edition_title"],
                        status: metadata["edition_status"],
                        translator: metadata["translator"],
                        translationProvenance: metadata["translation_provenance"],
                        normalizationProvenance: metadata["normalization_provenance"]
                    )
                ),
                passages: passages,
                targetPassageID: targetPassageID
            )
        }
    }

    func sourceReaderContent(workID: SourceWorkID) throws -> SourceReaderContent {
        let firstPassageID: SourcePassageID = try database.reader.read { db in
            guard let rawID = try String.fetchOne(
                db,
                sql: "SELECT id FROM source_passages WHERE work_id = ? ORDER BY sort_order LIMIT 1",
                arguments: [workID.rawValue]
            ) else {
                throw ContentRepositoryError.workHasNoPassages(workID)
            }
            return SourcePassageID(rawValue: rawID)
        }
        return try sourceReaderContent(targetPassageID: firstPassageID)
    }

    func search(_ query: String, in workID: SourceWorkID? = nil) throws -> [SearchResult] {
        try database.reader.read { db in
            var sql = """
                SELECT d.id, f.content_type, f.target_id, f.title,
                       snippet(search_documents_fts, 1, '‹', '›', '…', 18) AS snippet,
                       sb.section_id, ss.story_id, sp.work_id
                FROM search_documents_fts f
                JOIN search_documents d ON d.rowid = f.rowid
                LEFT JOIN story_blocks sb
                    ON f.content_type = 'story_block' AND sb.id = f.target_id
                LEFT JOIN story_sections ss ON ss.id = sb.section_id
                LEFT JOIN source_passages sp
                    ON f.content_type = 'source_passage' AND sp.id = f.target_id
                WHERE search_documents_fts MATCH ?
                """
            // Treat user-entered text as a literal FTS phrase. This keeps punctuation such as
            // the hyphen in “narma-dharmokti” from being interpreted as FTS query syntax.
            let literalQuery = "\"\(query.replacingOccurrences(of: "\"", with: "\"\""))\""
            var arguments: StatementArguments = [literalQuery]
            if let workID {
                sql += " AND f.content_type = 'source_passage' AND sp.work_id = ?"
                arguments += [workID.rawValue]
            }
            sql += " ORDER BY bm25(search_documents_fts), f.title, f.target_id"

            return try Row.fetchAll(db, sql: sql, arguments: arguments).compactMap { row in
                let contentType: String = row["content_type"]
                let targetID: String = row["target_id"]
                let target: SearchResultTarget
                switch contentType {
                case "story_block":
                    guard let sectionID: String = row["section_id"], let storyID: String = row["story_id"] else {
                        return nil
                    }
                    target = .story(
                        storyID: StoryID(rawValue: storyID),
                        sectionID: StorySectionID(rawValue: sectionID),
                        blockID: StoryBlockID(rawValue: targetID)
                    )
                case "source_passage":
                    guard let sourceWorkID: String = row["work_id"] else { return nil }
                    target = .source(
                        passageID: SourcePassageID(rawValue: targetID),
                        workID: SourceWorkID(rawValue: sourceWorkID)
                    )
                default:
                    return nil
                }
                return SearchResult(
                    id: row["id"],
                    title: row["title"],
                    snippet: row["snippet"],
                    target: target
                )
            }
        }
    }

    func originalWitnessMapping(passageID: SourcePassageID) throws -> OriginalWitnessMapping? {
        try database.reader.read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: """
                    SELECT m.id, m.witness_id, m.passage_id, m.pdf_page_index,
                           m.printed_page_label, w.title, w.file_path, w.page_count
                    FROM witness_mappings m
                    JOIN witnesses w ON w.id = m.witness_id
                    WHERE m.passage_id = ? AND w.media_type = 'application/pdf'
                    ORDER BY m.id LIMIT 1
                    """,
                arguments: [passageID.rawValue]
            ) else { return nil }
            let pageIndex: Int = row["pdf_page_index"]
            let pageCount: Int? = row["page_count"]
            guard pageIndex >= 0, pageCount.map({ pageIndex < $0 }) ?? true else { return nil }
            return OriginalWitnessMapping(
                id: WitnessMappingID(rawValue: row["id"]),
                witnessID: WitnessID(rawValue: row["witness_id"]),
                passageID: SourcePassageID(rawValue: row["passage_id"]),
                title: row["title"],
                fileName: row["file_path"],
                pdfPageIndex: pageIndex,
                printedPageLabel: row["printed_page_label"]
            )
        }
    }

    private static func noteValues(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

enum ContentRepositoryError: LocalizedError {
    case invalidPilgrimagePlace(String)
    case unsupportedStoryBlockType(String)
    case citationNotFound(CitationID)
    case passageNotFound(SourcePassageID)
    case preferredRepresentationNotFound(SourcePassageID)
    case workHasNoPassages(SourceWorkID)
    case invalidCitationTarget(CitationID)

    var errorDescription: String? {
        switch self {
        case let .invalidPilgrimagePlace(id): "Invalid compiled Pilgrimage Place: \(id)"
        case let .unsupportedStoryBlockType(type): "Unsupported Story block type: \(type)"
        case let .citationNotFound(id): "Citation not found: \(id.rawValue)"
        case let .passageNotFound(id): "Canonical Passage not found: \(id.rawValue)"
        case let .preferredRepresentationNotFound(id):
            "Preferred representation not found for Passage: \(id.rawValue)"
        case let .workHasNoPassages(id): "Source Work has no canonical Passages: \(id.rawValue)"
        case let .invalidCitationTarget(id): "Citation has an invalid target shape: \(id.rawValue)"
        }
    }
}
