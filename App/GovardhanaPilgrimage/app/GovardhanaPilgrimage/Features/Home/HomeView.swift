import SwiftUI

struct HomeView: View {
    let stories: [StorySummary]
    let works: [SourceWorkSummary]
    let storyPosition: StoryReadingPosition?
    let pilgrimagePlaces: [PilgrimagePlace]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rādhā-kuṇḍa Story")
                        .font(.largeTitle.weight(.semibold))
                    Text("Private offline reading and source study")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    if let story = stories.first {
                        destination("Story", systemImage: "book.pages", route: .storyTOC(story.id))
                    }
                    destination("Library", systemImage: "books.vertical", route: .library)
                    destination("Search", systemImage: "magnifyingglass", route: .search)
                    destination("Bookmarks", systemImage: "bookmark", route: .bookmarks)
                    NavigationLink {
                        GovardhanaMapScreen(places: pilgrimagePlaces)
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "map").font(.title2)
                            Text("Map").font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.map")
                }

                if let position = storyPosition {
                    NavigationLink(
                        "Continue Reading",
                        value: AppRoute.storySection(
                            storyID: position.storyID,
                            sectionID: position.sectionID,
                            blockID: position.blockID
                        )
                    )
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("home.continue-reading")
                }

                if let story = stories.first {
                    metadataCard(label: "Story", title: story.title)
                }
                if let work = works.first {
                    metadataCard(label: "Featured Source", title: work.title)
                }
            }
            .padding()
        }
        .navigationTitle("Home")
    }

    private func destination(_ title: String, systemImage: String, route: AppRoute) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 10) {
                Image(systemName: systemImage).font(.title2)
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.\(title.lowercased())")
    }

    private func metadataCard(label: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(title).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
