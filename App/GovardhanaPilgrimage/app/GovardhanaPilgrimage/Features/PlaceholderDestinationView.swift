import SwiftUI

struct DestinationView: View {
    let route: AppRoute
    let model: AppModel

    @ViewBuilder
    var body: some View {
        switch route {
        case let .storyTOC(storyID):
            StoryTOCView(storyID: storyID, model: model)
        case let .storySection(storyID, sectionID, blockID):
            StoryReaderView(
                storyID: storyID,
                sectionID: sectionID,
                initialBlockID: blockID,
                model: model
            )
        case let .sourcePassage(excursion):
            SourceReaderView(context: .story(excursion), model: model)
        case .library:
            LibraryView(model: model)
        case let .libraryWork(workID):
            WorkDetailView(workID: workID, model: model)
        case let .librarySource(workID, passageID):
            SourceReaderView(context: .library(workID: workID, passageID: passageID), model: model)
        case let .workSearch(workID):
            SearchView(model: model, workID: workID)
        case let .searchSource(passageID):
            SourceReaderView(context: .search(passageID: passageID), model: model)
        case let .bookmarkSource(passageID):
            SourceReaderView(context: .bookmark(passageID: passageID), model: model)
        case let .originalWitness(mapping):
            OriginalWitnessView(mapping: mapping, fileURL: model.witnessURL(for: mapping))
        case .search:
            SearchView(model: model)
        case .bookmarks:
            BookmarksView(model: model)
        }
    }

    private func placeholder(_ title: String, systemImage: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text("Foundation ready. Feature implementation follows in a later authorized task.")
        )
        .navigationTitle(title)
    }
}

struct BookmarksView: View {
    let model: AppModel

    private var storyBookmarks: [BookmarkRecord] {
        model.bookmarks.filter { if case .story = $0.target { return true }; return false }
    }

    private var sourceBookmarks: [BookmarkRecord] {
        model.bookmarks.filter { if case .source = $0.target { return true }; return false }
    }

    var body: some View {
        Group {
            if model.bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark",
                    description: Text("Bookmark a Story position or canonical source Passage while reading.")
                )
            } else {
                List {
                    if !storyBookmarks.isEmpty {
                        Section("Story") {
                            ForEach(storyBookmarks) { bookmark in
                                NavigationLink(value: route(for: bookmark.target)) {
                                    bookmarkRow(bookmark.target)
                                }
                                .accessibilityIdentifier("bookmarks.item.\(bookmark.id)")
                            }
                            .onDelete { model.removeBookmarks(at: $0, from: storyBookmarks) }
                        }
                    }
                    if !sourceBookmarks.isEmpty {
                        Section("Sources") {
                            ForEach(sourceBookmarks) { bookmark in
                                NavigationLink(value: route(for: bookmark.target)) {
                                    bookmarkRow(bookmark.target)
                                }
                                .accessibilityIdentifier("bookmarks.item.\(bookmark.id)")
                            }
                            .onDelete { model.removeBookmarks(at: $0, from: sourceBookmarks) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
        .accessibilityIdentifier("bookmarks.home")
    }

    private func route(for target: BookmarkTarget) -> AppRoute {
        switch target {
        case let .story(position):
            .storySection(
                storyID: position.storyID,
                sectionID: position.sectionID,
                blockID: position.blockID
            )
        case let .source(passageID):
            .bookmarkSource(passageID)
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ target: BookmarkTarget) -> some View {
        switch target {
        case let .story(position):
            let storyTitle = model.stories.first { $0.id == position.storyID }?.title ?? "Story"
            let sectionTitle = model.storySections.first { $0.id == position.sectionID }?.title
            let text = model.storyBlocks[position.sectionID]?.first { $0.id == position.blockID }?.text
            VStack(alignment: .leading, spacing: 4) {
                Text(storyTitle).font(.headline)
                if let sectionTitle { Text(sectionTitle).foregroundStyle(.secondary) }
                if let text { Text(text).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
            }
        case let .source(passageID):
            if let content = model.sourceReaderContent(for: passageID),
               let passage = content.passages.first(where: { $0.id == passageID }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(content.work.title) \(passage.displayLocus)").font(.headline)
                    if let translation = passage.translation {
                        Text(translation).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
            } else {
                Text("Source Passage unavailable")
            }
        }
    }
}

struct LibraryView: View {
    let model: AppModel

    private var groupedWorks: [(layer: String, works: [SourceWorkSummary])] {
        Dictionary(grouping: model.works) { $0.sourceLayer ?? "Other" }
            .map { (layer: $0.key, works: $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.layer < $1.layer }
    }

    var body: some View {
        List {
            if let position = model.works.compactMap({ model.workPositions[$0.id] }).first,
               let work = model.works.first(where: { $0.id == position.workID }) {
                Section("Continue Reading") {
                    NavigationLink(
                        value: AppRoute.librarySource(workID: work.id, passageID: position.passageID)
                    ) {
                        WorkRow(work: work, showsLayer: false)
                    }
                    .accessibilityIdentifier("library.continue-reading")
                }
            }

            ForEach(groupedWorks, id: \.layer) { group in
                Section(layerTitle(group.layer)) {
                    ForEach(group.works) { work in
                        NavigationLink(value: AppRoute.libraryWork(work.id)) {
                            WorkRow(work: work, showsLayer: true)
                        }
                        .accessibilityIdentifier("library.work.\(work.id.rawValue)")
                    }
                }
            }
        }
        .navigationTitle("Library")
        .accessibilityIdentifier("library.home")
    }

    private func layerTitle(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct WorkRow: View {
    let work: SourceWorkSummary
    let showsLayer: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(work.title).font(.headline)
            if let author = work.author { Text(author).foregroundStyle(.secondary) }
            if showsLayer, let layer = work.sourceLayer {
                Text(layer.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct WorkDetailView: View {
    let workID: SourceWorkID
    let model: AppModel
    @State private var showingDetails = false

    private var content: SourceReaderContent? { model.sourceReaderContent(for: workID) }

    var body: some View {
        if let content, let beginning = content.passages.first?.id {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        if let author = content.work.author { Text(author).font(.headline) }
                        if let layer = content.work.sourceLayer {
                            Text(layer.replacingOccurrences(of: "_", with: " ").capitalized)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    NavigationLink(
                        "Continue Reading",
                        value: AppRoute.librarySource(
                            workID: workID,
                            passageID: model.workPositions[workID]?.passageID ?? beginning
                        )
                    )
                    .accessibilityIdentifier("work.continue-reading")

                    Button("Source Details", systemImage: "info.circle") { showingDetails = true }
                        .accessibilityIdentifier("work.source-details")

                    NavigationLink("Search This Work", value: AppRoute.workSearch(workID))
                        .accessibilityIdentifier("work.search")
                }

                Section("Table of Contents") {
                    ForEach(content.passages) { passage in
                        NavigationLink(
                            "Passage \(passage.displayLocus)",
                            value: AppRoute.librarySource(workID: workID, passageID: passage.id)
                        )
                        .accessibilityIdentifier("work.toc.passage.\(passage.id.rawValue)")
                    }
                }
            }
            .navigationTitle(content.work.title)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("work.detail")
            .sheet(isPresented: $showingDetails) { SourceDetailsView(work: content.work) }
        } else {
            ContentUnavailableView("Work unavailable", systemImage: "exclamationmark.triangle")
                .navigationTitle("Library")
        }
    }
}

struct SearchView: View {
    let model: AppModel
    let workID: SourceWorkID?
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var searchError: String?

    init(model: AppModel, workID: SourceWorkID? = nil) {
        self.model = model
        self.workID = workID
    }

    private var storyResults: [SearchResult] {
        results.filter { if case .story = $0.target { return true }; return false }
    }

    private var sourceResults: [SearchResult] {
        results.filter { if case .source = $0.target { return true }; return false }
    }

    private var workTitle: String? { model.works.first { $0.id == workID }?.title }

    var body: some View {
        List {
            if let searchError {
                Section { Text(searchError).foregroundStyle(.secondary) }
            } else if !query.isEmpty, results.isEmpty {
                ContentUnavailableView.search(text: query)
            }

            if !storyResults.isEmpty {
                Section("Story") {
                    ForEach(storyResults) { result in resultRow(result) }
                }
            }
            if !sourceResults.isEmpty {
                Section("Sources") {
                    ForEach(sourceResults) { result in resultRow(result) }
                }
            }
        }
        .navigationTitle(workID == nil ? "Search" : "Search This Work")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: workTitle.map { "Search \($0)" } ?? "Search Story and Sources")
        .onSubmit(of: .search, runSearch)
        .accessibilityIdentifier(workID == nil ? "search.global" : "search.work")
    }

    private func resultRow(_ result: SearchResult) -> some View {
        NavigationLink(value: route(for: result.target)) {
            VStack(alignment: .leading, spacing: 5) {
                Text(result.title).font(.headline)
                Text(result.snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .accessibilityIdentifier("search.result.\(result.id)")
    }

    private func route(for target: SearchResultTarget) -> AppRoute {
        switch target {
        case let .story(storyID, sectionID, blockID):
            .storySection(storyID: storyID, sectionID: sectionID, blockID: blockID)
        case let .source(passageID, _):
            .searchSource(passageID)
        }
    }

    private func runSearch() {
        let submittedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedQuery.isEmpty else {
            results = []
            searchError = nil
            return
        }
        do {
            results = try model.search(submittedQuery, in: workID)
            searchError = nil
        } catch {
            results = []
            searchError = "Search could not be completed for this query."
        }
    }
}

struct StoryTOCView: View {
    let storyID: StoryID
    let model: AppModel

    private var story: StorySummary? { model.stories.first { $0.id == storyID } }

    var body: some View {
        List(model.storySections) { section in
            let restoredBlock = model.storyPosition?.sectionID == section.id ? model.storyPosition?.blockID : nil
            NavigationLink(
                value: AppRoute.storySection(
                    storyID: storyID,
                    sectionID: section.id,
                    blockID: restoredBlock
                )
            ) {
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("\(section.order)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                        if restoredBlock != nil {
                            Label("Current position", systemImage: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .accessibilityIdentifier("story.toc.section.\(section.id.rawValue)")
        }
        .navigationTitle(story?.title ?? "Story")
        .accessibilityIdentifier("story.toc")
    }
}

struct StoryReaderView: View {
    let storyID: StoryID
    let sectionID: StorySectionID
    let initialBlockID: StoryBlockID?
    let model: AppModel
    @State private var focusedBlockID: StoryBlockID?
    @State private var isRestoringInitialBlock: Bool
    @State private var visibleBlockID: String?

    init(
        storyID: StoryID,
        sectionID: StorySectionID,
        initialBlockID: StoryBlockID?,
        model: AppModel
    ) {
        self.storyID = storyID
        self.sectionID = sectionID
        self.initialBlockID = initialBlockID
        self.model = model
        _focusedBlockID = State(initialValue: initialBlockID)
        _isRestoringInitialBlock = State(initialValue: initialBlockID != nil)
    }

    private var section: StorySectionSummary? { model.storySections.first { $0.id == sectionID } }
    private var blocks: [StoryBlock] { model.storyBlocks[sectionID] ?? [] }
    private var bookmarkTarget: BookmarkTarget? {
        guard let blockID = focusedBlockID ?? blocks.first?.id else { return nil }
        return .story(StoryReadingPosition(storyID: storyID, sectionID: sectionID, blockID: blockID))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    ForEach(blocks) { block in
                        StoryBlockView(
                            storyID: storyID,
                            block: block,
                            citations: model.storyCitations[block.id] ?? []
                        )
                            .id(block.id.rawValue)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("story.block.\(block.id.rawValue)")
                    }
                }
                .scrollTargetLayout()
                .frame(maxWidth: 680, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
            .scrollPosition(id: $visibleBlockID, anchor: .top)
            .onChange(of: visibleBlockID) { _, rawID in
                guard !isRestoringInitialBlock,
                      let rawID,
                      let block = blocks.first(where: { $0.id.rawValue == rawID }) else { return }
                focusedBlockID = block.id
                model.saveStoryPosition(
                    StoryReadingPosition(storyID: storyID, sectionID: sectionID, blockID: block.id)
                )
            }
            .onAppear {
                guard let initialBlockID else { return }
                Task { @MainActor in
                    await Task.yield()
                    proxy.scrollTo(initialBlockID.rawValue, anchor: .top)
                    visibleBlockID = initialBlockID.rawValue
                    focusedBlockID = initialBlockID
                    try? await Task.sleep(for: .milliseconds(250))
                    isRestoringInitialBlock = false
                }
            }
        }
        .navigationTitle(section?.title ?? "Story")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("story.reader")
        .toolbar {
            if let bookmarkTarget {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.toggleBookmark(bookmarkTarget)
                    } label: {
                        Label(
                            model.isBookmarked(bookmarkTarget) ? "Remove Bookmark" : "Bookmark",
                            systemImage: model.isBookmarked(bookmarkTarget) ? "bookmark.fill" : "bookmark"
                        )
                    }
                    .accessibilityIdentifier("story.bookmark")
                    .accessibilityValue(focusedBlockID?.rawValue ?? "")
                }
            }
        }
    }
}

private struct StoryBlockView: View {
    let storyID: StoryID
    let block: StoryBlock
    let citations: [StoryCitationRow]

    var body: some View {
        VStack(alignment: block.type == .verse ? .center : .leading, spacing: 12) {
            switch block.type {
            case .heading:
                Text(block.text)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
            case .paragraph:
                Text(block.text)
                    .font(.body)
                    .lineSpacing(5)
            case .quotation:
                Text(block.text)
                    .font(.body.italic())
                    .lineSpacing(5)
                    .padding(.leading, 16)
                    .overlay(alignment: .leading) { Rectangle().frame(width: 3).foregroundStyle(.tertiary) }
            case .verse:
                Text(block.text)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity)
            }

            ForEach(citations) { citation in
                let origin = StoryOrigin(
                    storyID: storyID,
                    sectionID: block.sectionID,
                    blockID: block.id,
                    citationID: citation.id
                )
                let excursion = SourceExcursion(
                    origin: origin,
                    citedPassageID: citation.passageID,
                    currentPassageID: citation.passageID
                )
                NavigationLink(value: AppRoute.sourcePassage(excursion)) {
                    Label(citation.label, systemImage: "text.quote")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Citation: \(citation.label)")
                .accessibilityIdentifier("story.citation.\(citation.id.rawValue)")
            }
        }
        .frame(maxWidth: .infinity, alignment: block.type == .verse ? .center : .leading)
    }
}

enum SourceReaderContext: Hashable, Sendable {
    case story(SourceExcursion)
    case library(workID: SourceWorkID, passageID: SourcePassageID)
    case search(passageID: SourcePassageID)
    case bookmark(passageID: SourcePassageID)

    var entryPassageID: SourcePassageID {
        switch self {
        case let .story(excursion): excursion.citedPassageID
        case let .library(_, passageID): passageID
        case let .search(passageID): passageID
        case let .bookmark(passageID): passageID
        }
    }

    var targetLabel: String {
        switch self {
        case .story: "Cited passage"
        case .library: "Current passage"
        case .search: "Search result"
        case .bookmark: "Bookmarked passage"
        }
    }
}

struct SourceReaderView: View {
    let context: SourceReaderContext
    let model: AppModel
    @State private var showingDetails = false
    @State private var focusedPassageID: SourcePassageID
    @State private var visiblePassageID: String?

    init(context: SourceReaderContext, model: AppModel) {
        self.context = context
        self.model = model
        _focusedPassageID = State(initialValue: context.entryPassageID)
    }

    private var content: SourceReaderContent? { model.sourceReaderContent(for: context.entryPassageID) }
    private var originSectionTitle: String? {
        guard case let .story(excursion) = context else { return nil }
        return model.storySections.first { $0.id == excursion.origin.sectionID }?.title
    }

    var body: some View {
        if let content {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(content.passages) { passage in
                            SourcePassageView(
                                passage: passage,
                                targetLabel: passage.id == content.targetPassageID
                                    ? context.targetLabel
                                    : nil
                            )
                            .id(passage.id.rawValue)
                            .accessibilityIdentifier("source.passage.\(passage.id.rawValue)")
                        }
                    }
                    .scrollTargetLayout()
                    .frame(maxWidth: 680, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
                .scrollPosition(id: $visiblePassageID, anchor: .top)
                .onChange(of: visiblePassageID) { _, rawID in
                    guard let rawID,
                          let passage = content.passages.first(where: { $0.id.rawValue == rawID }) else { return }
                    focusedPassageID = passage.id
                    switch context {
                    case .story:
                        model.updateSourceExcursion(currentPassageID: passage.id)
                    case let .library(workID, _):
                        model.saveWorkPosition(workID: workID, passageID: passage.id)
                    case .search, .bookmark:
                        break
                    }
                }
                .onAppear {
                    if case let .story(excursion) = context {
                        model.beginSourceExcursion(excursion)
                    } else if case let .library(workID, passageID) = context {
                        model.saveWorkPosition(workID: workID, passageID: passageID)
                    }
                    Task { @MainActor in
                        await Task.yield()
                        let passageID: SourcePassageID
                        if case let .story(excursion) = context {
                            passageID = excursion.currentPassageID
                        } else {
                            passageID = context.entryPassageID
                        }
                        visiblePassageID = passageID.rawValue
                        proxy.scrollTo(passageID.rawValue, anchor: .center)
                    }
                }
                .toolbar {
                    if case let .story(excursion) = context {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Return to Story", systemImage: "arrow.uturn.backward") {
                                model.returnToStory(from: excursion)
                            }
                            .accessibilityIdentifier("source.return-to-story")
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu("Contents", systemImage: "list.bullet") {
                            ForEach(content.passages) { passage in
                                Button("Passage \(passage.displayLocus)") {
                                    switch context {
                                    case .story:
                                        model.updateSourceExcursion(currentPassageID: passage.id)
                                    case let .library(workID, _):
                                        model.saveWorkPosition(workID: workID, passageID: passage.id)
                                    case .search:
                                        break
                                    case .bookmark:
                                        break
                                    }
                                    focusedPassageID = passage.id
                                    withAnimation { proxy.scrollTo(passage.id.rawValue, anchor: .top) }
                                }
                            }
                        }
                        .accessibilityIdentifier("source.contents")

                        Button("Source Details", systemImage: "info.circle") {
                            showingDetails = true
                        }
                        .accessibilityIdentifier("source.details")
                    }
                    ToolbarItem(placement: .bottomBar) {
                        let bookmarkTarget = BookmarkTarget.source(focusedPassageID)
                        Button {
                            model.toggleBookmark(bookmarkTarget)
                        } label: {
                            Label(
                                model.isBookmarked(bookmarkTarget) ? "Remove Bookmark" : "Bookmark",
                                systemImage: model.isBookmarked(bookmarkTarget) ? "bookmark.fill" : "bookmark"
                            )
                        }
                        .accessibilityIdentifier("source.bookmark")
                        .accessibilityValue(focusedPassageID.rawValue)
                    }
                    if let mapping = model.originalWitnessMapping(for: focusedPassageID) {
                        ToolbarItem(placement: .bottomBar) {
                            NavigationLink(value: AppRoute.originalWitness(mapping)) {
                                Label("View Original Witness", systemImage: "doc.richtext")
                            }
                            .accessibilityIdentifier("source.original-witness")
                        }
                    }
                }
            }
            .navigationTitle(content.work.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                if let originSectionTitle {
                    Text("Referenced from: \(originSectionTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(.bar)
                        .accessibilityIdentifier("source.story-origin")
                }
            }
            .onDisappear {
                if case let .story(excursion) = context { model.endSourceExcursion(excursion) }
            }
            .sheet(isPresented: $showingDetails) {
                SourceDetailsView(work: content.work)
            }
        } else {
            ContentUnavailableView(
                "Source unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("The canonical passage or its preferred reading representation could not be resolved.")
            )
            .navigationTitle("Source")
        }
    }
}

private struct SourcePassageView: View {
    let passage: SourcePassage
    let targetLabel: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Passage \(passage.displayLocus)")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if let targetLabel {
                    Label(targetLabel, systemImage: "scope")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityIdentifier("source.canonical-target")
                }
            }

            if let originalText = passage.originalText {
                sourceText("Original", text: originalText)
            }
            if let transliteration = passage.transliteration {
                sourceText("Transliteration", text: transliteration)
            }
            if let translation = passage.translation {
                sourceText("Translation", text: translation)
            }
            if let translationStatus = passage.translationStatus {
                sourceText("Translation status", text: translationStatus.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            if let verificationStatus = passage.verificationStatus {
                sourceText("Text verification", text: verificationStatus.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            if let readingNote = passage.readingNote {
                sourceText("Reading note", text: readingNote)
            }
        }
        .padding(18)
        .background(
            targetLabel != nil ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            if targetLabel != nil {
                RoundedRectangle(cornerRadius: 14).stroke(Color.accentColor.opacity(0.45), lineWidth: 1)
            }
        }
    }

    private func sourceText(_ label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(text).font(.body).textSelection(.enabled)
        }
    }
}

private struct SourceDetailsView: View {
    let work: SourceWorkDetails
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Work") {
                    detail("Title", work.title)
                    detail("Status", work.status)
                    if let author = work.author { detail("Author", author) }
                    if let sourceLayer = work.sourceLayer { detail("Source layer", sourceLayer) }
                }
                Section("Preferred Edition") {
                    detail("Edition", work.preferredEdition.title)
                    detail("Status", work.preferredEdition.status)
                    if let translator = work.preferredEdition.translator { detail("Translator", translator) }
                    if let provenance = work.preferredEdition.translationProvenance {
                        detail("Translation provenance", provenance)
                    }
                    if let provenance = work.preferredEdition.normalizationProvenance {
                        detail("Normalization provenance", provenance)
                    }
                }
            }
            .navigationTitle("Source Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
        }
    }
}
