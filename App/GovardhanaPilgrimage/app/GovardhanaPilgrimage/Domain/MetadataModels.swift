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

enum SearchResultTarget: Hashable, Sendable {
    case story(storyID: StoryID, sectionID: StorySectionID, blockID: StoryBlockID)
    case source(passageID: SourcePassageID, workID: SourceWorkID)
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
}

struct BookmarkRecord: Identifiable, Hashable, Sendable {
    let id: String
    let target: BookmarkTarget
    let createdAt: Date
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

enum PilgrimageContentDestination: Hashable, Sendable {
    case storySection(StorySectionID)
    case sourcePassage(SourcePassageID)
}

struct PilgrimagePlace: Identifiable, Hashable, Sendable {
    let id: PilgrimagePlaceID
    let mapNumber: Int
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
