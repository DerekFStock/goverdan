import SwiftUI

struct HomeView: View {
    let model: AppModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    hero
                    mapDestination

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Explore")
                        LazyVGrid(columns: columns, spacing: 12) {
                            if let story = model.stories.first {
                                destination("Story", systemImage: "book.pages", route: .storyTOC(story.id), identifier: "story")
                            }
                            destination("Sources", systemImage: "books.vertical", route: .library, identifier: "library")
                            destination("Search", systemImage: "magnifyingglass", route: .search, identifier: "search")
                            destination("Bookmarks", systemImage: "bookmark", route: .bookmarks, identifier: "bookmarks")
                        }
                    }

                    if let position = model.storyPosition {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("Continue your journey")
                            NavigationLink(value: AppRoute.storySection(
                                storyID: position.storyID,
                                sectionID: position.sectionID,
                                blockID: position.blockID
                            )) {
                                HStack {
                                    Image(systemName: "book.pages.fill")
                                    Text("Continue Reading").fontWeight(.semibold)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundStyle(AppTheme.deepForest)
                                .padding()
                                .background(AppTheme.saffron, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("home.continue-reading")
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Featured reading")
                        if let story = model.stories.first {
                            metadataCard(label: "Story", title: story.title)
                        }
                        if let work = model.works.first {
                            metadataCard(label: "Source", title: work.title)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Govardhana Pilgrimage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        HStack(spacing: 16) {
            Image("PilgrimageMark")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: AppTheme.deepForest.opacity(0.16), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text("Govardhana")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.deepForest)
                Text("Pilgrimage companion")
                    .font(.headline)
                    .foregroundStyle(AppTheme.forest)
                Text("Govardhana & Rādhā-kuṇḍa · Offline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var mapDestination: some View {
        NavigationLink {
            GovardhanaMapScreen(places: model.pilgrimagePlaces, appModel: model)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.saffron)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Pilgrimage Map").font(.headline)
                    Text("Find sacred places around Govardhana")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white)
            .padding()
            .background(AppTheme.deepForest, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.map")
    }

    private func destination(_ title: String, systemImage: String, route: AppRoute, identifier: String) -> some View {
        NavigationLink(value: route) {
            VStack(spacing: 10) {
                Image(systemName: systemImage).font(.title2).foregroundStyle(AppTheme.coral)
                Text(title).font(.headline).foregroundStyle(AppTheme.deepForest)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(AppTheme.forest.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.\(identifier)")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.title3.weight(.semibold)).foregroundStyle(AppTheme.deepForest)
    }

    private func metadataCard(label: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(AppTheme.forest)
            Text(title).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(AppTheme.saffron.opacity(0.35), lineWidth: 1)
        }
    }
}
