import Foundation

enum AppRoute: Hashable, Sendable {
    case storyTOC(StoryID)
    case storySection(storyID: StoryID, sectionID: StorySectionID, blockID: StoryBlockID?)
    case sourcePassage(SourceExcursion)
    case library
    case libraryWork(SourceWorkID)
    case librarySource(workID: SourceWorkID, passageID: SourcePassageID)
    case workSearch(SourceWorkID)
    case searchSource(SourcePassageID)
    case bookmarkSource(SourcePassageID)
    case originalWitness(OriginalWitnessMapping)
    case search
    case bookmarks
}
