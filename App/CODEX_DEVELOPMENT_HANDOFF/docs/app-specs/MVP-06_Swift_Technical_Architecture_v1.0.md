# GOVARDHANA PILGRIMAGE APP

## MVP-06 — Swift Technical Architecture Specification

**Document ID:** MVP-06  
**Version:** v1.0  
**Status:** APPROVED — Pre-Codex Baseline  
**Depends on:** MVP-00 through MVP-05  
**Primary platform:** iPhone  
**Implementation language:** Swift  
**UI framework:** SwiftUI  
**Initial implementation:** Śrī Rādhā-kuṇḍa Story MVP

---

> **v1.0 approval note:** This document is part of the approved Rādhā-kuṇḍa Story MVP pre-Codex baseline. Where earlier draft language offered alternatives, the decisions recorded in `MVP-BASELINE_Cross_Specification_Approval_v1.0.md` control.

# 1. Purpose

This document translates the approved MVP product and content architecture into a concrete Swift implementation strategy.

The goals are to:

- keep the codebase small and understandable;
- preserve clean boundaries between app code and content;
- support exact Story → source navigation;
- keep all essential content offline;
- avoid premature framework complexity;
- make Codex implementation deterministic;
- and leave room for future pilgrimage expansion without designing that expansion now.

This specification covers:

- Xcode project organization;
- app architecture;
- navigation;
- data loading;
- persistence;
- rendering;
- local search;
- source reading;
- PDF witnesses;
- bookmarks;
- reading position;
- dependency policy;
- testing;
- logging;
- and implementation boundaries.

---

# 2. Technical Philosophy

The MVP should be architected around four major concerns:

```text
CONTENT
↓
DATA ACCESS
↓
APPLICATION LOGIC
↓
SWIFTUI PRESENTATION
```

These concerns should remain separated.

The app should not:

- parse raw research files inside views;
- hard-code source passages into Swift;
- embed Story prose inside view files;
- let navigation logic live randomly throughout UI code;
- bind the entire app directly to one persistence technology.

---

# 3. Initial Platform Target

Initial target:

## iPhone

Use the current stable iOS SDK available when Codex begins implementation.

The minimum deployment version should be recent enough to simplify SwiftUI implementation.

Approved MVP deployment baseline:

> iOS 18 or later

Final deployment target can be selected at implementation time based on the user's actual iPhone and installed OS.

Do not support older iOS versions merely for hypothetical public distribution.

---

# 4. Xcode Project

Recommended project:

```text
GovardhanaPilgrimage.xcodeproj
```

Primary target:

```text
GovardhanaPilgrimage
```

Test targets:

```text
GovardhanaPilgrimageTests
GovardhanaPilgrimageUITests
```

No extra app extensions are required for MVP.

---

# 5. Repository Layout

Recommended:

```text
GovardhanaPilgrimage/
│
├── app/
│   └── GovardhanaPilgrimage/
│
├── content/
├── witnesses/
├── tools/
├── docs/
├── build/
└── tests/
```

Inside app source:

```text
GovardhanaPilgrimage/
├── App/
├── Features/
├── Domain/
├── Data/
├── Services/
├── Navigation/
├── DesignSystem/
└── Resources/
```

---

# 6. App Entry Point

One SwiftUI application entry point:

```swift
@main
struct GovardhanaPilgrimageApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

The actual implementation may inject app dependencies through an environment/container.

Avoid global singletons unless genuinely necessary.

---

# 7. Architecture Style

Recommended:

> **Feature-oriented SwiftUI + lightweight dependency injection**

Do not adopt a heavy architecture framework for MVP.

Specifically, do not introduce unless later justified:

- The Composable Architecture;
- Redux-style global state;
- complex coordinator frameworks;
- Clean Architecture boilerplate with excessive layers.

The domain is small enough to remain explicit.

---

# 8. Core Layers

Recommended conceptual layers:

## Domain

Pure app concepts:

- Story
- StorySection
- ContentBlock
- SourceWork
- SourcePassage
- Citation
- Bookmark
- ReadingPosition

## Data

Reads structured runtime content from SQLite/content package.

## Services

Search, bookmarks, reading state, PDF witness resolution.

## Features

SwiftUI screens and feature-specific view models.

---

# 9. Dependency Container

A lightweight AppContainer is recommended.

Conceptually:

```swift
struct AppContainer {
    let contentRepository: ContentRepository
    let searchService: SearchService
    let bookmarkStore: BookmarkStore
    let readingPositionStore: ReadingPositionStore
}
```

Views should depend on protocols/interfaces rather than instantiate persistence directly.

---

# 10. Content Database

Recommended runtime storage:

## SQLite

This follows naturally from MVP-05.

Reasons:

- relational data;
- source passages;
- citation resolution;
- deterministic IDs;
- efficient search;
- future extensibility;
- easy generated package;
- stable local-first behavior.

---

# 11. GRDB Recommendation

Approved Swift SQLite layer:

## GRDB.swift

Reasons:

- mature;
- strongly typed;
- direct SQLite access;
- excellent FTS support;
- migrations;
- less abstraction than Core Data;
- good fit for read-heavy bundled content.

This should be considered the default unless a concrete blocker emerges.

---

# 12. Why Not SwiftData for Canonical Content

SwiftData is not recommended as the primary canonical content layer for MVP.

Reasons:

- the database is generated externally;
- content identities are explicit;
- SQLite FTS is important;
- schema should remain transparent;
- migration/control requirements favor direct SQLite access.

SwiftData may still be usable later for user state, but using one persistence approach is simpler.

---

# 13. Separate Content and User State

The architecture should distinguish:

## Bundled content database

Read-only in normal operation.

Contains:

- Story
- sections
- source works
- passages
- citations
- search index metadata

## User-state database

Writable.

Contains:

- bookmarks
- reading positions
- later personal notes

This separation is strongly recommended.

---

# 14. Content Database Location

Bundled app content:

```text
Bundle/
radhakunda-content.sqlite
```

At startup:

- content DB may be opened read-only directly from bundle;
- or copied into Application Support if SQLite access requirements make that preferable.

Prefer read-only direct access if reliable.

---

# 15. User-State Database

Store in:

```text
Application Support/
user-state.sqlite
```

Backed up by normal iOS device backup unless later configured otherwise.

---

# 16. Content Schema

The content database should approximately include:

```text
stories
story_parts
story_sections
story_blocks
source_works
source_editions
source_sections
source_passages
citations
images
witnesses
witness_mappings
search_documents
```

Exact schema should be generated from MVP-02/03/05.

---

# 17. User-State Schema

Initial tables:

```text
bookmarks
reading_positions
settings
```

No notes table required until that feature is added.

---

# 18. Repository Protocols

Recommended abstractions:

```swift
protocol StoryRepository
protocol SourceRepository
protocol CitationRepository
protocol SearchRepository
```

A combined:

```swift
protocol ContentRepository
```

may be sufficient initially.

Avoid unnecessary protocol proliferation.

---

# 19. Suggested Content Repository API

Conceptually:

```swift
protocol ContentRepository {
    func story(id: StoryID) throws -> Story
    func storySections(storyID: StoryID) throws -> [StorySection]
    func storySection(id: StorySectionID) throws -> StorySection

    func sourceWork(id: SourceWorkID) throws -> SourceWork
    func sourcePassage(id: SourcePassageID) throws -> SourcePassage
    func sourceSection(id: SourceSectionID) throws -> SourceSection

    func citation(id: CitationID) throws -> Citation

    func works(sourceLayer: SourceLayer?) throws -> [SourceWork]
}
```

Async is unnecessary for local SQLite reads unless implementation benefits from it.

---

# 20. Strong ID Types

Do not pass raw Strings everywhere.

Recommended wrappers:

```swift
struct StoryID: Hashable, Codable {
    let rawValue: String
}

struct SourcePassageID: Hashable, Codable {
    let rawValue: String
}
```

This reduces accidental cross-entity ID mistakes.

A generic typed ID system is optional.

---

# 21. Domain Models

Domain models should remain ordinary Swift value types.

Example:

```swift
struct SourcePassage: Identifiable, Hashable {
    let id: SourcePassageID
    let workID: SourceWorkID
    let canonicalLocus: String
    let displayLocus: String
    let originalText: String?
    let transliteration: String?
    let translation: String?
}
```

Avoid persistence annotations in core domain models if possible.

---

# 22. Swift Concurrency

Use Swift concurrency where it clarifies asynchronous work.

Potential async operations:

- initial database open;
- search;
- PDF loading;
- large section loading.

Do not mark every repository call async merely because modern Swift supports it.

---

# 23. Main Actor

UI-facing observable models should generally be:

```swift
@MainActor
```

Database operations may execute off main thread where necessary.

GRDB can handle database scheduling.

---

# 24. Observation

Recommended current Swift approach:

- `@Observable` where deployment target supports it cleanly;
- otherwise `ObservableObject`.

Do not mix multiple state-observation patterns unnecessarily.

---

# 25. Feature Structure

Recommended:

```text
Features/
├── Home/
├── Story/
├── Library/
├── SourceReader/
├── Search/
└── Bookmarks/
```

Each feature may contain:

```text
View
ViewModel
supporting views
```

Do not create dozens of microfiles prematurely.

---

# 26. Navigation

Use native SwiftUI navigation:

## NavigationStack

Routes should be typed.

Example:

```swift
enum AppRoute: Hashable {
    case storyTOC(StoryID)
    case storySection(StorySectionID)
    case sourceWork(SourceWorkID)
    case sourcePassage(SourcePassageID, SourceOrigin?)
    case search
    case bookmarks
}
```

---

# 27. Navigation Path

Root navigation should be managed in a clear central place.

Possible:

```swift
@Observable
final class NavigationModel {
    var path = NavigationPath()
}
```

No custom navigation framework required.

---

# 28. Source Origin

The Source Reader needs context.

Define a navigation origin object:

```swift
struct StoryOrigin: Hashable, Codable {
    let storyID: StoryID
    let sectionID: StorySectionID
    let blockID: StoryBlockID?
    let semanticAnchor: String?
}
```

Then:

```swift
enum SourceOrigin: Hashable {
    case story(StoryOrigin)
    case library
    case search(query: String)
    case bookmark
}
```

---

# 29. Return-to-Story Behavior

When a source is opened from Story:

store StoryOrigin.

The Source Reader exposes:

```swift
func returnToStory()
```

Navigation should restore the Story section with the semantic anchor.

Do not rely only on raw NavigationStack back traversal.

---

# 30. Story Position Model

Avoid storing only scroll offset.

Preferred:

```swift
struct StoryPosition {
    let sectionID: StorySectionID
    let blockID: StoryBlockID?
}
```

Optional later:

```swift
let characterOffset: Int?
```

---

# 31. Scroll Restoration

For MVP, block-level restoration is sufficient.

Use `ScrollViewReader` or equivalent to scroll to a stable block ID.

Exact pixel restoration is not necessary.

---

# 32. Story Rendering Strategy

Approved MVP strategy:

> **native SwiftUI structured-block renderer**

Rather than rendering the entire Story as one WKWebView HTML document.

Reasons:

- typed citations;
- reliable navigation;
- native accessibility;
- semantic anchors;
- easy source tap handling;
- future extensibility.

---

# 33. Story Block Renderer

Conceptually:

```swift
@ViewBuilder
func view(for block: StoryBlock) -> some View {
    switch block {
    case .paragraph:
        ParagraphBlockView(...)
    case .heading:
        HeadingBlockView(...)
    case .quote:
        QuoteBlockView(...)
    case .verse:
        VerseBlockView(...)
    case .image:
        ImageBlockView(...)
    }
}
```

This matches MVP-02.

---

# 34. Rich Paragraph Text

Paragraphs may need:

- italics;
- bold;
- source links.

Recommended representation:

- precompiled attributed-text runs;
- or Markdown converted to `AttributedString`.

Use native `AttributedString` if it can support the required custom citation links cleanly.

---

# 35. Citation Links in AttributedString

A citation may use custom URLs:

```text
govardhana-source://passage.radha-kundastaka.1
```

or structured tap targets rendered separately.

Prefer typed action handling over parsing arbitrary web URLs where practical.

---

# 36. Story Citation Presentation

Recommended implementation:

- paragraph text;
- citation row immediately below where specified by content model.

This is technically simpler and avoids fragile inline-link parsing.

Inline citations can be added later if desired.

---

# 37. Source Reader Rendering

Use the same structured native approach.

A Source Section contains ordered Source Passages.

Render:

```swift
ScrollView {
    LazyVStack {
        ForEach(passages) {
            SourcePassageView(...)
        }
    }
}
```

This supports exact passage anchors.

---

# 38. LazyVStack

Use `LazyVStack` for large source sections to reduce memory use.

Do not render entire large books in one giant stack.

---

# 39. Source Section Loading

Load one logical section at a time.

Examples:

- one Sarga;
- one chapter;
- one short prayer work.

A short work such as Rādhā-kuṇḍāṣṭaka can load all verses.

---

# 40. Source Passage Anchor

Each passage view:

```swift
.id(passage.id)
```

When opened from citation:

```swift
scrollProxy.scrollTo(passage.id, anchor: .top)
```

This provides deterministic navigation.

---

# 41. Cited-Passage Highlight

Pass:

```swift
highlightedPassageID
```

into Source Reader.

SourcePassageView conditionally applies restrained emphasis.

---

# 42. Source Reader State

Suggested:

```swift
@Observable
final class SourceReaderModel {
    let work: SourceWork
    let section: SourceSection
    let origin: SourceOrigin?
    var highlightedPassageID: SourcePassageID?
}
```

Exact implementation may be simpler.

---

# 43. Library Architecture

Library screens query ContentRepository.

No local filesystem browsing.

Library presents canonical works only.

---

# 44. Search Architecture

Recommended:

## SQLite FTS5

Generated by content compiler.

This is one reason GRDB is strongly preferred.

Search query returns typed result rows.

---

# 45. Search Tables

Possible:

```text
story_fts
source_fts
```

or unified:

```text
search_fts
```

with:

```text
entity_type
entity_id
title
body
```

Unified FTS is recommended if grouping is done in Swift.

---

# 46. Search Service

Conceptually:

```swift
protocol SearchService {
    func search(_ query: String) throws -> [SearchResult]
    func search(_ query: String, in workID: SourceWorkID) throws -> [SearchResult]
}
```

---

# 47. Search Result Type

```swift
enum SearchResultTarget: Hashable {
    case storySection(StorySectionID, anchor: StoryBlockID?)
    case sourcePassage(SourcePassageID)
}
```

Search UI groups by target type.

---

# 48. Search Debouncing

Use a short debounce if live-as-you-type search is implemented.

Alternatively, submit-on-search is acceptable.

Do not overengineer.

---

# 49. Bookmarks Service

Recommended:

```swift
protocol BookmarkStore {
    func bookmarks() throws -> [Bookmark]
    func add(_ bookmark: Bookmark) throws
    func remove(id: BookmarkID) throws
    func contains(target: BookmarkTarget) throws -> Bool
}
```

Stored in user-state DB.

---

# 50. Bookmark Targets

MVP:

```swift
enum BookmarkTarget {
    case story(StoryPosition)
    case source(SourcePassageID)
}
```

---

# 51. Reading Position Store

```swift
protocol ReadingPositionStore {
    func storyPosition(storyID: StoryID) throws -> StoryPosition?
    func saveStoryPosition(_ position: StoryPosition)

    func sourcePosition(workID: SourceWorkID) throws -> SourcePassageID?
    func saveSourcePosition(...)
}
```

Implementation may batch/debounce writes.

---

# 52. Reading Position Update Frequency

Do not write on every scroll pixel.

Update when:

- visible semantic block changes;
- app backgrounds;
- reader disappears.

Same for source passages.

---

# 53. Visible Block Tracking

Possible SwiftUI approach:

- Geometry/scroll position APIs available in target iOS;
- section anchor updates.

Use the simplest stable mechanism supported by chosen iOS target.

Do not build custom UIScrollView introspection unless necessary.

---

# 54. PDF Witness Support — Post-Vertical-Slice

After the first real-content vertical slice is stable, use:

## PDFKit

Native Apple framework.

No third-party PDF dependency needed.

---

# 55. PDF Screen

Represent with `PDFView` wrapped in `UIViewRepresentable`.

Requirements:

- open file;
- jump to page;
- zoom;
- scroll.

No annotation architecture.

---

# 56. Witness Resolution

A service:

```swift
protocol WitnessService {
    func witness(for passageID: SourcePassageID) throws -> WitnessLocation?
}
```

returns:

```swift
struct WitnessLocation {
    let resourceName: String
    let pdfPageIndex: Int?
    let printedPageLabel: String?
}
```

---

# 57. Images

Story images should be packaged as local assets referenced from content DB.

Use SwiftUI:

```swift
Image(...)
```

or filesystem-based loading if assets are outside Assets.xcassets.

Because content is generated, file-resource loading may be more flexible than Xcode asset catalogs.

---

# 58. Image Cache

Native image caching is sufficient initially.

No third-party image library required because all images are local.

---

# 59. Reader Settings

MVP setting:

## text scale

Could be stored as:

```swift
enum ReaderTextSize
```

or a numeric scale.

Use environment to apply reader typography consistently.

---

# 60. Dynamic Type

Support Dynamic Type where practical.

However, custom reader-scale controls may provide more predictable devotional text layout.

A hybrid is acceptable.

---

# 61. Script Fonts

Use installed/system fonts supporting:

- Latin/IAST;
- Devanāgarī;
- Bengali.

Do not bundle unnecessary custom fonts unless a real rendering issue demands it.

---

# 62. Design System

Create a very small DesignSystem area.

Possible tokens:

```swift
ReaderTypography
Spacing
CitationStyle
SourceLayerStyle
```

Do not build a large corporate design system.

---

# 63. Appearance

Support:

- system light/dark mode.

The final devotional visual language can be refined after functionality works.

---

# 64. Content Loading at Startup

App startup sequence:

```text
Launch
↓
Open content database
↓
Verify schema compatibility
↓
Open user-state database
↓
Construct AppContainer
↓
Render RootView
```

Should be fast.

---

# 65. Schema Compatibility

Bundled content package includes:

```text
schemaVersion
contentVersion
```

App checks supported schema.

If incompatible in development:

fail visibly.

For bundled MVP, incompatibility should never ship.

---

# 66. Database Migrations

## Content DB

Generated fresh by content build. No runtime migration required initially.

## User DB

GRDB migrations should manage bookmark/reading-state schema.

This distinction simplifies architecture.

---

# 67. Content Version Exposure

Optional Settings/About screen may show:

```text
App 0.3
Rādhā-kuṇḍa Content 0.6.2
```

Useful for debugging.

Not required on primary UI.

---

# 68. Error Handling

Define app-level errors such as:

```swift
enum ContentError: Error {
    case missingStory(StoryID)
    case missingPassage(SourcePassageID)
    case incompatibleSchema(Int)
    case missingWitness(String)
}
```

Development builds should expose useful diagnostics.

---

# 69. Logging

Use Apple's:

## OSLog / Logger

Categories:

- content
- navigation
- search
- reader
- database

Do not add a third-party logging system.

---

# 70. Analytics

None.

This is a private app.

No telemetry or behavior tracking.

---

# 71. Networking

MVP requires no network layer.

Do not add:

- URLSession service layer;
- API client;
- authentication;
- remote config.

External web links may use system browser.

---

# 72. Permissions

MVP requires no special permissions.

No:

- location;
- camera;
- microphone;
- contacts.

This is another benefit of the reduced Story MVP.

---

# 73. Security

Standard iOS sandboxing is sufficient.

No encryption layer required.

---

# 74. App Lifecycle

On background:

- save current Story reading position;
- save source position.

On foreground:

- restore current UI naturally.

No background processing required.

---

# 75. Dependency Policy

Keep dependencies minimal.

Proposed external dependency:

## GRDB.swift

Potentially no others.

Avoid third-party:

- navigation frameworks;
- image libraries;
- Markdown frameworks unless native parsing proves inadequate;
- PDF libraries;
- analytics.

---

# 76. Swift Package Manager

Use Swift Package Manager for dependencies.

No CocoaPods.

---

# 77. Markdown Parsing

Preferred initial strategy:

use Apple's `AttributedString(markdown:)` for simple inline formatting.

The content compiler should already transform custom directives into structured runtime blocks.

Swift should not parse custom scholarly directives.

---

# 78. Content Compiler Boundary

This is strict:

## Python/compiler responsibility

- parse authoring Markdown/YAML;
- validate citations;
- generate Story blocks;
- generate source passages;
- build SQLite;
- build search indexes.

## Swift responsibility

- query generated DB;
- render content;
- navigate;
- persist user state.

This boundary should not be violated casually.

---

# 79. Tests

Three primary testing layers:

## Unit Tests

- ID parsing
- repository behavior
- citation resolution
- bookmark store
- reading position
- search

## Content Validation Tests

Mostly Python/compiler side.

## UI Tests

Minimal critical flows.

---

# 80. Essential Unit Test: Citation Resolution

Given:

```text
citation.rk.manifestation.rka.1
```

expect:

```text
passage.radha-kundastaka.1
```

and valid Work/Edition.

---

# 81. Essential Unit Test: Search Navigation

Search result target must resolve to an existing Story Section or Source Passage.

---

# 82. Essential Unit Test: Reading Position

Save StoryPosition.

Reinitialize store.

Restore identical semantic position.

---

# 83. Essential UI Test

Automate:

```text
Launch
→ Story
→ Manifestation
→ citation
→ Source Reader
→ Return to Story
```

Verify original section restored.

This is the single most important UI test.

---

# 84. Fixture Content

Tests should use a small generated fixture database.

Do not depend on entire production Rādhā-kuṇḍa corpus for every unit test.

---

# 85. Preview Data

SwiftUI previews can load the same fixture DB.

This ensures preview behavior resembles real architecture.

---

# 86. Build Configurations

Standard:

- Debug
- Release

Optional later:

- Development Content
- Release Content

Not necessary initially if manifest selection occurs before Xcode build.

---

# 87. Development Content

Debug app may package:

```text
radhakunda-dev.sqlite
```

Release:

```text
radhakunda-mvp.sqlite
```

This can be controlled by build script/environment.

---

# 88. Build Script Integration

Eventually add an Xcode build phase:

```text
Build Rādhā-kuṇḍa Content
```

that invokes content compiler.

However, for the first Codex milestone it is acceptable to run content build manually.

Do not let build-script complexity delay app architecture.

---

# 89. SwiftLint / Formatting

Optional:

- SwiftFormat;
- SwiftLint.

Not required unless Codex code quality drifts.

Prefer standard Swift conventions.

---

# 90. File Size

Keep Swift files focused.

But do not mechanically split every small struct into its own file.

Readability over dogma.

---

# 91. Documentation in Code

Public/internal APIs should be clear enough that excessive comments are unnecessary.

Document:

- non-obvious navigation state;
- semantic reading-position behavior;
- content schema assumptions.

Do not litter code with comments restating obvious Swift.

---

# 92. Naming

Use full domain names:

```swift
SourcePassage
StorySection
ReadingPosition
```

Avoid vague:

```swift
Item
Thing
Node
Record
```

unless truly generic.

---

# 93. No Content Strings in Views

Views may contain UI strings:

> "Return to Story"

but not substantive project content:

> manifestation narrative paragraphs.

All Story/source text comes from content DB.

---

# 94. Localization

App UI localization is not needed for MVP.

Content may itself be multilingual.

Do not add `.strings` infrastructure unless helpful.

---

# 95. Future Web Compatibility

No Swift technical decision needs to support future web implementation directly.

The shared value lies in the structured content repository, not Swift code reuse.

---

# 96. Future Maps Compatibility

Later Place/Map entities can be added to Domain and DB.

Current architecture should not include placeholder location services.

No CoreLocation dependency yet.

---

# 97. Future Notes Compatibility

Later notes can target stable IDs.

Current strong ID architecture provides this.

No notes feature required now.

---

# 98. Future Prayer Mode

Prayers can later be specialized Source Works or a Prayer entity.

Do not build Prayer-specific architecture in MVP-06.

---

# 99. Future Govardhana Compatibility

The content DB should support multiple Stories later.

Do not name tables:

```text
radhakunda_story_sections
```

Use:

```text
stories
story_sections
```

This is a small future-proofing step with little complexity.

---

# 100. Performance Target

The app should feel instantaneous for:

- opening Story sections;
- opening source passages;
- search over MVP corpus.

No formal millisecond SLA needed.

Local text should not visibly "load."

---

# 101. Memory Target

Avoid loading:

- all Story sections;
- all source works;
- all PDFs

into memory simultaneously.

Query only current reading unit.

---

# 102. Database Read Strategy

GRDB value observation is probably unnecessary for static content.

Simple fetches are sufficient.

User-state screens may use observation if helpful.

---

# 103. Content Models vs Database Records

Recommended distinction:

```text
StorySectionRecord
```

database representation.

```text
StorySection
```

domain representation.

However, if schemas map cleanly, this distinction can remain lightweight.

Do not introduce mapping boilerplate without benefit.

---

# 104. View Models

Not every tiny view needs a ViewModel.

Use ViewModels for screens with meaningful state:

- StoryReader
- SourceReader
- Search
- Library
- Bookmarks

Simple rows can take domain values directly.

---

# 105. Home Screen State

Home needs:

- Story reading position;
- optional last source position.

Can query stores directly through HomeViewModel.

---

# 106. Story Reader ViewModel

Responsibilities:

- load Story Section;
- load blocks;
- handle citation taps;
- update reading position;
- bookmark current position.

It should not resolve raw database joins itself.

---

# 107. Source Reader ViewModel

Responsibilities:

- load Work;
- load current Source Section;
- identify highlighted passage;
- navigate section/TOC;
- bookmark passage;
- preserve reading state;
- Return to Story.

---

# 108. Search ViewModel

Responsibilities:

- query;
- debounce/submit;
- group results;
- route result selection.

---

# 109. Library ViewModel

Responsibilities:

- fetch works;
- group by source layer;
- retrieve recent/position state if shown.

---

# 110. Bookmarks ViewModel

Responsibilities:

- load bookmarks;
- resolve display information;
- navigate target;
- delete bookmark.

---

# 111. Original Witness ViewModel

May simply receive:

- PDF resource URL;
- page index.

No complex model needed.

---

# 112. Technical Acceptance Criteria

MVP-06 succeeds when:

1. SwiftUI is the UI framework.
2. content remains external to Swift.
3. SQLite is the runtime content store.
4. GRDB is the default persistence layer.
5. user state is separated from bundled content.
6. navigation uses typed SwiftUI NavigationStack routes.
7. Story and Source readers render structured native content.
8. citations resolve deterministically.
9. semantic reading positions are preserved.
10. Source Reader can return exactly to Story.
11. SQLite FTS powers local search.
12. PDFKit handles original witnesses.
13. no backend/network architecture is introduced.
14. external dependencies remain minimal.
15. automated tests cover the critical source excursion flow.
16. architecture can later add Place/Map entities without redesigning the Story/source core.

---

# 113. Codex Guardrails Derived from MVP-06

Codex must not:

- hard-code Story prose in Swift;
- introduce Core Data or SwiftData without approval;
- add a backend;
- add networking services;
- add maps;
- add GPS;
- add field notes;
- add authentication;
- add a large architecture framework;
- invent new domain entities casually;
- parse raw project DOCX/PDF source files at runtime;
- generate citations dynamically;
- silently alter source text.

Codex should implement the specification as written.

---



# 116. Next Specification

After MVP-06, proceed to:

## MVP-07 — Rādhā-kuṇḍa Content Manifest Specification

This document will stop discussing abstract architecture and specify **exactly what real Rādhā-kuṇḍa material enters the first application**, including:

- Story sections;
- initial vertical-slice section;
- source works;
- exact source ranges;
- normalized source requirements;
- original witnesses;
- images;
- which material is required for the first Codex build;
- which material may be added before MVP completion;
- and the definition of a complete Rādhā-kuṇḍa Story content package.

After MVP-07, only **MVP-08 — Codex Build Plan & Acceptance Criteria** remains before we have the full reduced MVP specification set.

---

## Approval

**MVP-06 v1.0 — APPROVED**
