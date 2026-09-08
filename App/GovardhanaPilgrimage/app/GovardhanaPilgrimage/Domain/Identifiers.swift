import Foundation

protocol CanonicalIdentifier: Hashable, Codable, Sendable, RawRepresentable where RawValue == String {}

struct StoryID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct SourceWorkID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct StorySectionID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct StoryBlockID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct CitationID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct SourcePassageID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct WitnessID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct WitnessMappingID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}

struct PilgrimagePlaceID: CanonicalIdentifier {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
}
