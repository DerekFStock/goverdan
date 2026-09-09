import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var container: AppContainer?
    private(set) var stories: [StorySummary] = []
    private(set) var works: [SourceWorkSummary] = []
    private(set) var storySections: [StorySectionSummary] = []
    private(set) var storyBlocks: [StorySectionID: [StoryBlock]] = [:]
    private(set) var storyCitations: [StoryBlockID: [StoryCitationRow]] = [:]
    private(set) var storyPosition: StoryReadingPosition?
    private(set) var workPositions: [SourceWorkID: WorkReadingPosition] = [:]
    private(set) var bookmarks: [BookmarkRecord] = []
    private(set) var pilgrimagePlaces: [PilgrimagePlace] = []
    var navigationPath: [AppRoute] = []
    private(set) var sourceExcursion: SourceExcursion?
    private(set) var errorMessage: String?

    init() {
        do {
            let container = try AppContainer.live()
            self.container = container
            stories = try container.contentRepository.stories()
            works = try container.contentRepository.works()
            pilgrimagePlaces = try container.contentRepository.pilgrimagePlaces()
            bookmarks = try container.userStateDatabase.bookmarks()
            for work in works {
                workPositions[work.id] = try container.userStateDatabase.workPosition(workID: work.id)
            }
            if let story = stories.first {
                storySections = try container.contentRepository.storySections(storyID: story.id)
                for section in storySections {
                    let blocks = try container.contentRepository.storyBlocks(sectionID: section.id)
                    storyBlocks[section.id] = blocks
                    for block in blocks {
                        storyCitations[block.id] = try container.contentRepository.storyCitations(blockID: block.id)
                    }
                }
                storyPosition = try container.userStateDatabase.storyPosition(storyID: story.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveStoryPosition(_ position: StoryReadingPosition) {
        guard storyPosition != position, let container else { return }
        do {
            try container.userStateDatabase.saveStoryPosition(position)
            storyPosition = position
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sourceReaderContent(for passageID: SourcePassageID) -> SourceReaderContent? {
        try? container?.contentRepository.sourceReaderContent(targetPassageID: passageID)
    }

    func sourceReaderContent(for workID: SourceWorkID) -> SourceReaderContent? {
        try? container?.contentRepository.sourceReaderContent(workID: workID)
    }

    func pilgrimagePlaceContent(for placeID: PilgrimagePlaceID) -> PilgrimagePlaceContent? {
        try? container?.contentRepository.pilgrimagePlaceContent(placeID: placeID)
    }

    func saveWorkPosition(workID: SourceWorkID, passageID: SourcePassageID) {
        let position = WorkReadingPosition(workID: workID, passageID: passageID)
        guard workPositions[workID] != position, let container else { return }
        do {
            try container.userStateDatabase.saveWorkPosition(position)
            workPositions[workID] = position
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search(_ query: String, in workID: SourceWorkID? = nil) throws -> [SearchResult] {
        guard let container else { return [] }
        return try container.contentRepository.search(query, in: workID)
    }

    func originalWitnessMapping(for passageID: SourcePassageID) -> OriginalWitnessMapping? {
        guard let mapping = try? container?.contentRepository.originalWitnessMapping(passageID: passageID),
              witnessURL(for: mapping) != nil else { return nil }
        return mapping
    }

    func witnessURL(for mapping: OriginalWitnessMapping, bundle: Bundle = .main) -> URL? {
        let path = mapping.fileName as NSString
        return bundle.url(
            forResource: path.deletingPathExtension,
            withExtension: path.pathExtension.isEmpty ? nil : path.pathExtension
        )
    }

    func isBookmarked(_ target: BookmarkTarget) -> Bool {
        bookmarks.contains { $0.target == target }
    }

    func toggleBookmark(_ target: BookmarkTarget) {
        guard let container else { return }
        do {
            if isBookmarked(target) {
                try container.userStateDatabase.removeBookmark(target)
            } else {
                try container.userStateDatabase.saveBookmark(target)
            }
            bookmarks = try container.userStateDatabase.bookmarks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBookmarks(at offsets: IndexSet, from records: [BookmarkRecord]) {
        for index in offsets { toggleBookmark(records[index].target) }
    }

    func beginSourceExcursion(_ excursion: SourceExcursion) {
        sourceExcursion = excursion
    }

    func updateSourceExcursion(currentPassageID: SourcePassageID) {
        sourceExcursion?.currentPassageID = currentPassageID
    }

    func endSourceExcursion(_ excursion: SourceExcursion) {
        guard sourceExcursion?.origin == excursion.origin else { return }
        sourceExcursion = nil
    }

    func returnToStory(from fallback: SourceExcursion) {
        let excursion = sourceExcursion ?? fallback
        let origin = excursion.origin
        saveStoryPosition(
            StoryReadingPosition(
                storyID: origin.storyID,
                sectionID: origin.sectionID,
                blockID: origin.blockID
            )
        )
        navigationPath = [
            .storyTOC(origin.storyID),
            .storySection(
                storyID: origin.storyID,
                sectionID: origin.sectionID,
                blockID: origin.blockID
            ),
        ]
        sourceExcursion = nil
    }
}
