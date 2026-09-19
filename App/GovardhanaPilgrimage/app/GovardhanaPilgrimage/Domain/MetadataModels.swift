import Foundation

struct StorySummary: Identifiable, Hashable, Sendable {
    let id: StoryID
    let title: String
    let status: String
}

struct SourceWorkSummary: Identifiable, Hashable, Sendable {
    let id: SourceWorkID
    let title: String
    let status: String
    let author: String?
    let sourceLayer: String?
}

struct StorySectionSummary: Identifiable, Hashable, Sendable {
    let id: StorySectionID
    let storyID: StoryID
    let title: String
    let order: Int
}

enum StoryBlockType: String, Hashable, Sendable {
    case heading
    case paragraph
    case quotation
    case verse
}

struct StoryBlock: Identifiable, Hashable, Sendable {
    let id: StoryBlockID
    let sectionID: StorySectionID
    let order: Int
    let type: StoryBlockType
    let text: String
}

enum StoryCitationTarget: Hashable, Sendable {
    case singleton(SourcePassageID)
    case range(start: SourcePassageID, end: SourcePassageID)

    var startPassageID: SourcePassageID {
        switch self {
        case let .singleton(passageID): passageID
        case let .range(start, _): start
        }
    }
}

struct StoryCitationRow: Identifiable, Hashable, Sendable {
    let id: CitationID
    let blockID: StoryBlockID
    let target: StoryCitationTarget
    let label: String
    let role: String

    var passageID: SourcePassageID { target.startPassageID }
}

struct SourceEditionDetails: Hashable, Sendable {
    let title: String
    let status: String
    let translator: String?
    let translationProvenance: String?
    let normalizationProvenance: String?
}

struct SourceWorkDetails: Identifiable, Hashable, Sendable {
    let id: SourceWorkID
    let title: String
    let status: String
    let author: String?
    let sourceLayer: String?
    let preferredEdition: SourceEditionDetails
}

struct SourcePassage: Identifiable, Hashable, Sendable {
    let id: SourcePassageID
    let workID: SourceWorkID
    let canonicalLocus: String
    let displayLocus: String
    let order: Int
    let originalText: String?
    let transliteration: String?
    let translation: String?
    let verificationStatus: String?
    let translationStatus: String?
    let readingNote: String?
    let sectionKind: String?
    let chapterNumber: Int?
    let chapterTitle: String?
    let timeRange: String?
    let passageKind: String?

    var readerLabel: String {
        if let chapterNumber, let chapterTitle {
            return "Chapter \(chapterNumber), passage \(chapterPassageNumber ?? order): \(chapterTitle)"
        }
        return displayLocus
    }

    var chapterPassageNumber: Int? {
        guard let match = id.rawValue.range(of: #"\.p(\d{3})$"#, options: .regularExpression) else { return nil }
        return Int(id.rawValue[match].dropFirst(2))
    }
}

struct SourceReaderContent: Hashable, Sendable {
    let work: SourceWorkDetails
    let passages: [SourcePassage]
    let targetPassageID: SourcePassageID
}

struct OriginalWitnessMapping: Identifiable, Hashable, Sendable {
    let id: WitnessMappingID
    let witnessID: WitnessID
    let passageID: SourcePassageID
    let title: String
    let fileName: String
    let pdfPageIndex: Int
    let printedPageLabel: String?
}

struct StoryReadingPosition: Hashable, Sendable {
    let storyID: StoryID
    let sectionID: StorySectionID
    let blockID: StoryBlockID
}

struct WorkReadingPosition: Equatable, Sendable {
    let workID: SourceWorkID
    let passageID: SourcePassageID
}

enum PersonKind: String, Hashable, Sendable {
    case vrajaAssociate = "vraja_associate"
    case gaudiyaTeacher = "gaudiya_teacher"

    var displayName: String {
        switch self {
        case .vrajaAssociate: "Vraja associate"
        case .gaudiyaTeacher: "Gauḍīya teacher"
        }
    }
}

struct PersonSummary: Identifiable, Hashable, Sendable {
    let id: PersonID
    let kind: PersonKind
    let name: String
    let descriptor: String
}

struct PersonSection: Identifiable, Hashable, Sendable {
    let id: PersonSectionID
    let personID: PersonID
    let title: String
    let order: Int
}

struct PersonBlock: Identifiable, Hashable, Sendable {
    let id: PersonBlockID
    let sectionID: PersonSectionID
    let order: Int
    let type: StoryBlockType
    let text: String
    let citations: [PersonCitationRow]
}

struct PersonCitationRow: Identifiable, Hashable, Sendable {
    let id: CitationID
    let blockID: PersonBlockID
    let target: StoryCitationTarget
    let label: String
    let sourceLayer: String

    var passageID: SourcePassageID { target.startPassageID }
}

struct PersonReadingPosition: Hashable, Sendable {
    let personID: PersonID
    let sectionID: PersonSectionID
    let blockID: PersonBlockID
}

struct PersonPlaceRelationship: Identifiable, Hashable, Sendable {
    let id: String
    let personID: PersonID
    let placeID: PilgrimagePlaceID
    let type: String
    let explanation: String
    let sourceLayer: String
    let verificationStatus: String
    let caution: String?
}

enum SearchResultTarget: Hashable, Sendable {
    case story(storyID: StoryID, sectionID: StorySectionID, blockID: StoryBlockID)
    case source(passageID: SourcePassageID, workID: SourceWorkID)
    case person(PersonID)
}

struct SearchResult: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let snippet: String
    let target: SearchResultTarget
}

enum BookmarkTarget: Hashable, Sendable {
    case story(StoryReadingPosition)
    case source(SourcePassageID)
    case person(PersonReadingPosition)
}

struct BookmarkRecord: Identifiable, Hashable, Sendable {
    let id: String
    let target: BookmarkTarget
    let createdAt: Date
}

struct VedabaseBookmarkRecord: Identifiable, Hashable, Sendable {
    let url: URL
    let title: String
    let createdAt: Date

    var id: String { url.absoluteString }

    static func isBookmarkable(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
            && ["vedabase.io", "www.vedabase.io"].contains(url.host?.lowercased() ?? "")
            && (url.path == "/en/library" || url.path.hasPrefix("/en/library/"))
    }
}

struct StoryOrigin: Hashable, Codable, Sendable {
    let storyID: StoryID
    let sectionID: StorySectionID
    let blockID: StoryBlockID
    let citationID: CitationID
}

struct SourceExcursion: Hashable, Codable, Sendable {
    let origin: StoryOrigin
    let citedPassageID: SourcePassageID
    var currentPassageID: SourcePassageID
}

struct PersonSourceExcursion: Hashable, Sendable {
    let origin: PersonReadingPosition
    let citationID: CitationID
    let citedPassageID: SourcePassageID
    var currentPassageID: SourcePassageID
}

enum CoordinateVerificationStatus: String, Hashable, Sendable {
    case unverified = "UNVERIFIED"
    case provisional = "PROVISIONAL"
    case probable = "PROBABLE"
    case verified = "VERIFIED"
}

enum CoordinateConfidence: String, Hashable, Sendable {
    case unknown = "UNKNOWN"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

struct PilgrimagePlaceProvenance: Hashable, Sendable {
    let sourceType: String
    let description: String
    let sourceReference: String?
}

struct PilgrimagePolygonVertex: Hashable, Sendable {
    let longitude: Double
    let latitude: Double
}

struct PilgrimagePlaceGeometry: Hashable, Sendable {
    let geometryType: String
    let coordinateSemantics: String
    let minZoom: Double
    let labelMinZoom: Double
    let vertices: [PilgrimagePolygonVertex]
    let sourceID: String
    let sourceURL: String
    let sourceVersion: Int?
    let sourceChangeset: Int?
    let sourceRetrievedOn: String
    let attribution: String
}

enum PilgrimageContentDestination: Hashable, Sendable {
    case storySection(StorySectionID)
    case sourcePassage(SourcePassageID)
}

struct PilgrimagePlace: Identifiable, Hashable, Sendable {
    let id: PilgrimagePlaceID
    let mapNumber: Int?
    let collection: String
    let geometryType: String
    let coordinateSemantics: String
    let mapVisibility: String
    let navigationEligible: Bool
    let geometry: PilgrimagePlaceGeometry?
    let canonicalName: String
    let asciiName: String?
    let alternateNames: [String]
    let latitude: Double?
    let longitude: Double?
    let coordinateStatus: CoordinateVerificationStatus
    let coordinateConfidence: CoordinateConfidence
    let coordinateAccuracyMeters: Double?
    let verificationNotes: String
    let navigationAnchorPlaceID: PilgrimagePlaceID?
    let locationGuidance: String?
    let provenance: [PilgrimagePlaceProvenance]
    let contentDestination: PilgrimageContentDestination?
}

struct PilgrimagePlaceReference: Identifiable, Hashable, Sendable {
    let id: String
    let sourceTitle: String
    let locus: String?
    let explanation: String
    let quotation: String?
    let destination: PilgrimageContentDestination?
}

struct PilgrimagePlaceContent: Hashable, Sendable {
    let placeID: PilgrimagePlaceID
    let category: String?
    let summary: String
    let whySacred: String
    let whatToSee: [String]
    let lila: String
    let pilgrimGuidance: String
    let references: [PilgrimagePlaceReference]
    let relatedPlaceIDs: [PilgrimagePlaceID]
}
