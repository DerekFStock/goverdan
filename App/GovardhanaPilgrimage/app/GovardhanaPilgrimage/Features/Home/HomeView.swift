import SwiftUI

struct HomeView: View {
    let model: AppModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rādhā-kuṇḍa Story")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(AppTheme.deepForest)
                    Text("Private offline reading and source study")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    if let story = model.stories.first {
                        destination("Story", systemImage: "book.pages", route: .storyTOC(story.id))
                    }
                    destination("Library", systemImage: "books.vertical", route: .library)
                    destination("Search", systemImage: "magnifyingglass", route: .search)
                    destination("Bookmarks", systemImage: "bookmark", route: .bookmarks)
                    NavigationLink {
                        GovardhanaMapScreen(places: model.pilgrimagePlaces, appModel: model)
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "map").font(.title2).foregroundStyle(AppTheme.coral)
                            Text("Map").font(.headline).foregroundStyle(AppTheme.deepForest)
                        }
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.forest.opacity(0.12), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.map")
                }

                if let position = model.storyPosition {
                    NavigationLink(
                        "Continue Reading",
                        value: AppRoute.storySection(
                            storyID: position.storyID,
                            sectionID: position.sectionID,
                            blockID: position.blockID
                        )
                    )
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.saffron)
                    .foregroundStyle(AppTheme.deepForest)
                    .accessibilityIdentifier("home.continue-reading")
                }

                if let story = model.stories.first {
                    metadataCard(label: "Story", title: story.title)
                }
                if let work = model.works.first {
                    metadataCard(label: "Featured Source", title: work.title)
                }
                }
                .padding()
            }
        }
        .navigationTitle("Home")
    }

    private func destination(_ title: String, systemImage: String, route: AppRoute) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 10) {
                Image(systemName: systemImage).font(.title2).foregroundStyle(AppTheme.coral)
                Text(title).font(.headline).foregroundStyle(AppTheme.deepForest)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.forest.opacity(0.12), lineWidth: 1)
            }
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
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.saffron.opacity(0.35), lineWidth: 1)
        }
    }
}
