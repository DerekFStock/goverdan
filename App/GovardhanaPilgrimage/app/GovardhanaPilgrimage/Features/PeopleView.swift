import SwiftUI

struct PeopleView: View {
    let model: AppModel

    var body: some View {
        List(model.people) { person in
            NavigationLink(value: AppRoute.person(
                personID: person.id,
                blockID: model.personPositions[person.id]?.blockID
            )) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(person.name).font(.headline)
                    Text(person.descriptor).font(.subheadline).foregroundStyle(.secondary)
                    Text(person.kind.displayName).font(.caption).foregroundStyle(AppTheme.forest)
                }
                .padding(.vertical, 5)
            }
            .accessibilityIdentifier("people.item.\(person.id.rawValue)")
        }
        .navigationTitle("People of Vraja")
        .accessibilityIdentifier("people.collection")
    }
}

struct PersonDetailView: View {
    let personID: PersonID
    let initialBlockID: PersonBlockID?
    let model: AppModel
    @State private var visibleBlockID: String?

    private var person: PersonSummary? { model.people.first { $0.id == personID } }
    private var sections: [PersonSection] { model.personSections(for: personID) }
    private var relationships: [PersonPlaceRelationship] { model.personPlaceRelationships(for: personID) }
    private var focusedPosition: PersonReadingPosition? {
        guard let visibleBlockID else { return model.personPositions[personID] }
        for section in sections where model.personBlocks(for: section.id).contains(where: { $0.id.rawValue == visibleBlockID }) {
            return PersonReadingPosition(personID: personID, sectionID: section.id,
                                         blockID: PersonBlockID(rawValue: visibleBlockID))
        }
        return nil
    }

    var body: some View {
        if let person {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(person.name).font(.largeTitle.bold()).foregroundStyle(AppTheme.deepForest)
                            Text(person.descriptor).font(.title3).foregroundStyle(.secondary)
                            Text(person.kind.displayName).font(.caption.bold()).foregroundStyle(AppTheme.forest)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 15) {
                                Text(section.title)
                                    .font(.title2.bold())
                                    .foregroundStyle(AppTheme.deepForest)
                                    .accessibilityAddTraits(.isHeader)
                                ForEach(model.personBlocks(for: section.id)) { block in
                                    blockView(block, section: section)
                                        .id(block.id.rawValue)
                                }
                            }
                        }
                        if !relationships.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Associated places").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                                ForEach(relationships) { relationship in
                                    if let place = model.pilgrimagePlaces.first(where: { $0.id == relationship.placeID }) {
                                        NavigationLink {
                                            PlaceDetailView(place: place, allPlaces: model.pilgrimagePlaces, model: model)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("#\(place.mapNumber) \(place.canonicalName)").font(.headline)
                                                Text(relationship.explanation).font(.subheadline)
                                                Text("Evidence \(relationship.sourceLayer) · \(relationship.verificationStatus)")
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                        }
                                        .accessibilityIdentifier("person.place.\(place.id.rawValue)")
                                    }
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                    .frame(maxWidth: 700, alignment: .leading)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                }
                .scrollPosition(id: $visibleBlockID, anchor: .top)
                .onChange(of: visibleBlockID) { _, _ in
                    if let focusedPosition { model.savePersonPosition(focusedPosition) }
                }
                .onAppear {
                    let target = initialBlockID ?? model.personPositions[personID]?.blockID
                        ?? sections.first.flatMap { model.personBlocks(for: $0.id).first?.id }
                    guard let target else { return }
                    Task { @MainActor in
                        await Task.yield()
                        visibleBlockID = target.rawValue
                        proxy.scrollTo(target.rawValue, anchor: .top)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu("Contents", systemImage: "list.bullet") {
                            ForEach(sections) { section in
                                Button(section.title) {
                                    guard let first = model.personBlocks(for: section.id).first else { return }
                                    visibleBlockID = first.id.rawValue
                                    model.savePersonPosition(PersonReadingPosition(
                                        personID: personID, sectionID: section.id, blockID: first.id
                                    ))
                                    withAnimation { proxy.scrollTo(first.id.rawValue, anchor: .top) }
                                }
                            }
                        }
                        .accessibilityIdentifier("person.contents")
                    }
                    if let position = focusedPosition {
                        let target = BookmarkTarget.person(position)
                        ToolbarItem(placement: .bottomBar) {
                            Button {
                                model.toggleBookmark(target)
                            } label: {
                                Label(model.isBookmarked(target) ? "Remove Bookmark" : "Bookmark",
                                      systemImage: model.isBookmarked(target) ? "bookmark.fill" : "bookmark")
                            }
                            .accessibilityIdentifier("person.bookmark")
                        }
                    }
                }
            }
            .navigationTitle(person.name)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("person.detail.\(personID.rawValue)")
        } else {
            ContentUnavailableView("Person unavailable", systemImage: "person.crop.circle.badge.exclamationmark")
        }
    }

    @ViewBuilder
    private func blockView(_ block: PersonBlock, section: PersonSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(block.text)
                .font(block.type == .quotation ? .body.italic() : .body)
                .foregroundStyle(AppTheme.deepForest)
                .textSelection(.enabled)
                .accessibilityIdentifier("person.block.\(block.id.rawValue)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(block.type == .quotation ? 14 : 0)
                .background(block.type == .quotation ? AppTheme.surface : .clear,
                            in: RoundedRectangle(cornerRadius: 12))
            ForEach(block.citations) { citation in
                NavigationLink(value: AppRoute.personSource(PersonSourceExcursion(
                    origin: PersonReadingPosition(personID: personID, sectionID: section.id, blockID: block.id),
                    citationID: citation.id,
                    citedPassageID: citation.passageID,
                    currentPassageID: citation.passageID
                ))) {
                    Label(citation.label, systemImage: "text.book.closed")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.forest)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    model.savePersonPosition(PersonReadingPosition(personID: personID, sectionID: section.id, blockID: block.id))
                })
                .accessibilityIdentifier("person.citation.\(citation.id.rawValue)")
            }
        }
    }
}
