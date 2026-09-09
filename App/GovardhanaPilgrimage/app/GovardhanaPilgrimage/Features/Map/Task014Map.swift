import CoreLocation
import MapLibre
import SwiftUI

extension PilgrimagePlace {
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return .init(latitude: latitude, longitude: longitude)
    }
}

struct PilgrimageMapPresentation: Identifiable {
    let place: PilgrimagePlace
    let coordinate: CLLocationCoordinate2D
    let anchor: PilgrimagePlace?
    let approximateOffsetIndex: Int?

    var id: PilgrimagePlaceID { place.id }
    var isApproximate: Bool { approximateOffsetIndex != nil }
    var anchorDisplayName: String? { anchor.map { "#\($0.mapNumber) \($0.canonicalName)" } }
}

enum PilgrimageMapProjection {
    static let mediumLabelZoom = 14.5

    static func presentations(for places: [PilgrimagePlace]) -> [PilgrimageMapPresentation] {
        let ordered = places.sorted { $0.mapNumber < $1.mapNumber }
        let byID = Dictionary(uniqueKeysWithValues: ordered.map { ($0.id, $0) })
        var anchorCounts: [PilgrimagePlaceID: Int] = [:]
        return ordered.compactMap { place in
            if let coordinate = place.coordinate {
                return PilgrimageMapPresentation(place: place, coordinate: coordinate, anchor: nil, approximateOffsetIndex: nil)
            }
            guard
                let anchorID = place.navigationAnchorPlaceID,
                let anchor = byID[anchorID],
                let coordinate = anchor.coordinate
            else { return nil }
            let index = anchorCounts[anchorID, default: 0]
            anchorCounts[anchorID] = index + 1
            return PilgrimageMapPresentation(place: place, coordinate: coordinate, anchor: anchor, approximateOffsetIndex: index)
        }
    }

    enum LabelPriority: Int, Comparable {
        case ordinary, navigationAnchor, activeTarget
        static func < (lhs: LabelPriority, rhs: LabelPriority) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    static func labelPriority(
        for presentation: PilgrimageMapPresentation,
        activeTarget: PilgrimagePlace
    ) -> LabelPriority {
        if presentation.place.id == activeTarget.id { return .activeTarget }
        if activeTarget.coordinate == nil,
           activeTarget.navigationAnchorPlaceID == presentation.place.id { return .navigationAnchor }
        return .ordinary
    }

    static func showsNameLabel(priority: LabelPriority, zoomLevel: Double) -> Bool {
        priority == .activeTarget || zoomLevel >= mediumLabelZoom
    }

    static func approximateOffset(index: Int, zoomLevel: Double) -> CGVector {
        let minimumRadius = 18.0
        let maximumRadius = 72.0
        let radius = min(maximumRadius, max(minimumRadius, minimumRadius + (zoomLevel - 13.0) * 12.0))
        let angle = (-135.0 + Double(index % 8) * 90.0) * .pi / 180.0
        return CGVector(dx: cos(angle) * radius, dy: sin(angle) * radius)
    }
}

struct PilgrimageTargetCardPresentation {
    let place: PilgrimagePlace
    let anchor: PilgrimagePlace?
    var isApproximate: Bool { anchor != nil }
    var anchorDisplayName: String? { anchor.map { "#\($0.mapNumber) \($0.canonicalName)" } }
    var compactContext: String? { anchorDisplayName.map { "Approximate · via \($0)" } }
    var guidance: String? { isApproximate ? place.locationGuidance : nil }
    var hasExpandableGuidance: Bool { guidance != nil }
}

struct PilgrimagePlaceNavigationRow: Identifiable {
    let place: PilgrimagePlace
    let anchor: PilgrimagePlace?
    var id: PilgrimagePlaceID { place.id }
    var statusText: String {
        if let anchor { return "APPROXIMATE · via #\(anchor.mapNumber) \(anchor.canonicalName)" }
        return "\(place.coordinateStatus.rawValue) · \(place.coordinateConfidence.rawValue)"
    }
    var goTitle: String { anchor == nil ? "Go" : "Go to anchor" }
}

enum PilgrimagePlaceNavigation {
    static func rows(for places: [PilgrimagePlace]) -> [PilgrimagePlaceNavigationRow] {
        let ordered = places.sorted { $0.mapNumber < $1.mapNumber }
        let byID = Dictionary(uniqueKeysWithValues: ordered.map { ($0.id, $0) })
        return ordered.map { place in
            let anchor = place.coordinate == nil ? place.navigationAnchorPlaceID.flatMap { byID[$0] } : nil
            return PilgrimagePlaceNavigationRow(place: place, anchor: anchor)
        }
    }
}

struct LocationSample: Sendable {
    let coordinate: CLLocationCoordinate2D
    let horizontalAccuracy: Double
    let timestamp: Date
    let course: Double
    let speed: Double
}

@MainActor
protocol LocationProvider: AnyObject {
    var onLocation: ((LocationSample) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
final class CoreLocationProvider: NSObject, LocationProvider, @preconcurrency CLLocationManagerDelegate {
    var onLocation: ((LocationSample) -> Void)?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() { manager.stopUpdatingLocation() }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocation?(.init(
            coordinate: location.coordinate,
            horizontalAccuracy: location.horizontalAccuracy,
            timestamp: location.timestamp,
            course: location.course,
            speed: location.speed
        ))
    }
}

@MainActor
final class SimulatedLocationProvider: LocationProvider {
    var onLocation: ((LocationSample) -> Void)?
    private(set) var progress = 0
    private var timer: Timer?
    private let route: [CLLocationCoordinate2D]

    init(route: [CLLocationCoordinate2D]) { self.route = route }

    func start() { emitCurrent() }
    func stop() { pause() }

    func walk(speed: Double = 1) {
        pause()
        timer = Timer.scheduledTimer(withTimeInterval: max(0.05, 0.25 / speed), repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.progress = min(self.progress + 1, self.route.count - 1)
                self.emitCurrent()
                if self.progress == self.route.count - 1 { self.pause() }
            }
        }
    }

    func pause() { timer?.invalidate(); timer = nil }
    func reset() { pause(); progress = 0; emitCurrent() }

    func jump(to coordinate: CLLocationCoordinate2D) {
        pause()
        onLocation?(sample(coordinate, course: -1, speed: 0))
    }

    private func emitCurrent() {
        let coordinate = route[progress]
        let course = progress + 1 < route.count ? GeoMath.bearing(from: coordinate, to: route[progress + 1]) : -1
        onLocation?(sample(coordinate, course: course, speed: timer == nil ? 0 : 1.4))
    }

    private func sample(_ coordinate: CLLocationCoordinate2D, course: Double, speed: Double) -> LocationSample {
        .init(coordinate: coordinate, horizontalAccuracy: 5, timestamp: Date(), course: course, speed: speed)
    }
}

enum SimulationRoute {
    static func task014Coordinates(places: [PilgrimagePlace]) -> [CLLocationCoordinate2D] {
        let stops = [1, 2, 3].compactMap { number in places.first { $0.mapNumber == number }?.coordinate }
        precondition(stops.count == 3, "Task 014 simulation requires registry places 1, 2, and 3")
        return zip(stops, stops.dropFirst()).flatMap { interpolate(from: $0, to: $1, segments: 36).dropLast() } + [stops.last!]
    }

    private static func interpolate(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, segments: Int) -> [CLLocationCoordinate2D] {
        (0...segments).map { index in
            let fraction = Double(index) / Double(segments)
            return .init(latitude: from.latitude + (to.latitude - from.latitude) * fraction,
                         longitude: from.longitude + (to.longitude - from.longitude) * fraction)
        }
    }
}

enum GeoMath {
    static let arrivalRadius = 30.0

    static func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }

    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let φ1 = from.latitude * .pi / 180, φ2 = to.latitude * .pi / 180
        let Δλ = (to.longitude - from.longitude) * .pi / 180
        let y = sin(Δλ) * cos(φ2)
        let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    static func direction(for bearing: Double) -> String {
        ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Int((bearing + 22.5) / 45) % 8]
    }

    static func nearest(to coordinate: CLLocationCoordinate2D, places: [PilgrimagePlace]) -> PilgrimagePlace? {
        places.compactMap { place in place.coordinate.map { (place, $0) } }
            .min { distance(from: coordinate, to: $0.1) < distance(from: coordinate, to: $1.1) }?.0
    }
}

@MainActor
final class PilgrimageMapModel: ObservableObject {
    enum Source: String, CaseIterable { case simulation = "Govardhana Simulation", real = "Real iPhone Location" }
    enum ArrivalPresentationState: Equatable { case enRoute, exactArrival, navigationAnchorArrival }
    @Published var source: Source = .simulation { didSet { selectProvider() } }
    @Published var sample: LocationSample?
    @Published var activeDestination: PilgrimagePlace
    @Published var shouldRecenter = 0
    @Published var requestedCenter: CLLocationCoordinate2D?
    let places: [PilgrimagePlace]
    let simulated: SimulatedLocationProvider
    private let real = CoreLocationProvider()
    private var provider: LocationProvider?

    init(places: [PilgrimagePlace]) {
        precondition(!places.isEmpty, "Pilgrimage registry must contain at least one place")
        precondition(places.contains { $0.coordinate != nil }, "Pilgrimage registry must contain a coordinate-bearing place")
        self.places = places
        activeDestination = places.first(where: { $0.mapNumber == 2 && $0.coordinate != nil })
            ?? places.first(where: { $0.coordinate != nil })!
        simulated = SimulatedLocationProvider(route: SimulationRoute.task014Coordinates(places: places))
        selectProvider()
    }

    var destinationDistance: Double? {
        guard let destination = navigationCoordinate else { return nil }
        return sample.map { GeoMath.distance(from: $0.coordinate, to: destination) }
    }
    var destinationBearing: Double? {
        guard let destination = navigationCoordinate else { return nil }
        return sample.map { GeoMath.bearing(from: $0.coordinate, to: destination) }
    }
    var arrived: Bool { (destinationDistance ?? .greatestFiniteMagnitude) <= GeoMath.arrivalRadius }
    var arrivalPresentationState: ArrivalPresentationState {
        guard arrived else { return .enRoute }
        return activeNavigationAnchor == nil ? .exactArrival : .navigationAnchorArrival
    }
    var nearest: PilgrimagePlace? { sample.flatMap { GeoMath.nearest(to: $0.coordinate, places: places) } }
    var mappablePlaces: [PilgrimagePlace] { places.filter { $0.coordinate != nil } }
    var mapPresentations: [PilgrimageMapPresentation] { PilgrimageMapProjection.presentations(for: places) }
    var activeNavigationAnchor: PilgrimagePlace? {
        guard activeDestination.coordinate == nil, let anchorID = activeDestination.navigationAnchorPlaceID else { return nil }
        return places.first { $0.id == anchorID }
    }
    var navigationCoordinate: CLLocationCoordinate2D? {
        activeDestination.coordinate ?? activeNavigationAnchor?.coordinate
    }
    var targetCardPresentation: PilgrimageTargetCardPresentation {
        .init(place: activeDestination, anchor: activeNavigationAnchor)
    }

    func navigate(to place: PilgrimagePlace) {
        activeDestination = place
        guard let destination = navigationCoordinate else { return }
        requestedCenter = destination
        shouldRecenter += 1
    }

    func resetSimulation() {
        simulated.reset()
        requestedCenter = places.first(where: { $0.mapNumber == 1 })?.coordinate
        shouldRecenter += 1
    }

    func recenter() {
        requestedCenter = sample?.coordinate
        shouldRecenter += 1
    }

    private func selectProvider() {
        provider?.stop()
        provider = source == .simulation ? simulated : real
        provider?.onLocation = { [weak self] value in DispatchQueue.main.async { self?.sample = value } }
        provider?.start()
    }
}

struct GovardhanaMapScreen: View {
    @StateObject private var model: PilgrimageMapModel
    @State private var selectedPlace: PilgrimagePlace?
    @State private var debugExpanded = false
    @State private var showingPlaces = false
    @State private var guidanceExpanded = false
    let appModel: AppModel

    init(places: [PilgrimagePlace], appModel: AppModel) {
        _model = StateObject(wrappedValue: PilgrimageMapModel(places: places))
        self.appModel = appModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            OfflineMapLibreView(
                presentations: model.mapPresentations,
                activeTarget: model.activeDestination,
                sample: model.sample,
                recenterCoordinate: model.requestedCenter,
                recenterToken: model.shouldRecenter
            ) { selectedPlace = $0 }
                .ignoresSafeArea(edges: .bottom)
            VStack(spacing: 8) {
                destinationPanel
                #if DEBUG
                controls
                #endif
            }.padding()
        }
        .navigationTitle("Govardhana Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Places") { showingPlaces = true }.accessibilityIdentifier("map.places") }
        .sheet(isPresented: $showingPlaces) {
            PilgrimagePlaceList(places: model.places, appModel: appModel) { place in
                model.navigate(to: place)
                showingPlaces = false
            }
        }
        .navigationDestination(item: $selectedPlace) {
            PlaceDetailView(place: $0, allPlaces: model.places, model: appModel)
        }
        .onChange(of: model.activeDestination.id) { guidanceExpanded = false }
    }

    private var destinationPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(destinationHeading).font(.caption).foregroundStyle(.secondary)
            Text("#\(model.activeDestination.mapNumber) \(model.activeDestination.canonicalName)").font(.headline)
            if let context = model.targetCardPresentation.compactContext {
                Text(context).font(.caption).foregroundStyle(.secondary)
            }
            if let distance = model.destinationDistance, let bearing = model.destinationBearing {
                Text("\(Int(distance.rounded())) m  •  \(Int(bearing.rounded()))° \(GeoMath.direction(for: bearing))")
            }
            if let guidance = model.targetCardPresentation.guidance {
                Button(guidanceExpanded ? "Hide guidance" : "Show guidance") {
                    guidanceExpanded.toggle()
                }
                .font(.caption.bold())
                .accessibilityIdentifier("map.target.guidance")
                if guidanceExpanded {
                    if let anchor = model.targetCardPresentation.anchorDisplayName {
                        Text("Navigation anchor: \(anchor)").font(.caption.bold())
                    }
                    Text(guidance).font(.caption).foregroundStyle(.secondary)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var destinationHeading: String {
        switch model.arrivalPresentationState {
        case .exactArrival: "Arrived at"
        case .navigationAnchorArrival: "At navigation anchor"
        case .enRoute: model.activeNavigationAnchor == nil ? "Next" : "Target"
        }
    }

    #if DEBUG
    private var controls: some View {
        DisclosureGroup("Location & Offline Debug", isExpanded: $debugExpanded) {
            Picker("Location Source", selection: $model.source) { ForEach(PilgrimageMapModel.Source.allCases, id: \.self) { Text($0.rawValue) } }
            HStack {
                Button("Start Test Walk") { model.source = .simulation; model.simulated.walk(speed: 5) }
                Button("Pause") { model.simulated.pause() }
                Button("Reset") { model.resetSimulation() }
                Button("Recenter") { model.recenter() }
            }.buttonStyle(.bordered)
            if let sample = model.sample {
                Text(String(format: "LOCATION SOURCE: %@\n%.6f, %.6f  accuracy %.0f m\ncourse %.0f° speed %.1f m/s\nnearest: %@\nMap source: LOCAL\nNetwork map dependency: NONE", model.source == .simulation ? "SIMULATED" : "REAL", sample.coordinate.latitude, sample.coordinate.longitude, sample.horizontalAccuracy, sample.course, sample.speed, model.nearest?.canonicalName ?? "—"))
                    .font(.caption.monospaced())
            }
        }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
    #endif
}

private struct PilgrimagePlaceList: View {
    @Environment(\.dismiss) private var dismiss
    let places: [PilgrimagePlace]
    let appModel: AppModel
    let onGo: (PilgrimagePlace) -> Void

    var body: some View {
        NavigationStack {
            List(PilgrimagePlaceNavigation.rows(for: places)) { row in
                VStack(alignment: .leading, spacing: 8) {
                    Text("#\(row.place.mapNumber) \(row.place.canonicalName)").font(.headline)
                    Text(row.statusText).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button(row.goTitle) { onGo(row.place) }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("places.go.\(row.place.mapNumber)")
                        NavigationLink("Details") {
                            PlaceDetailView(place: row.place, allPlaces: places, model: appModel)
                        }
                            .accessibilityIdentifier("places.details.\(row.place.mapNumber)")
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Pilgrimage Places")
            .toolbar { Button("Done") { dismiss() } }
            .navigationDestination(for: AppRoute.self) { route in
                DestinationView(route: route, model: appModel)
            }
        }
    }

}

struct PlaceDetailView: View {
    let place: PilgrimagePlace
    let allPlaces: [PilgrimagePlace]
    let model: AppModel
    private var content: PilgrimagePlaceContent? { model.pilgrimagePlaceContent(for: place.id) }

    var body: some View {
        Form {
            Section {
                Text("#\(place.mapNumber)").font(.largeTitle.bold())
                Text(place.canonicalName).font(.title2)
                if let category = content?.category {
                    Text(category).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if let content {
                pilgrimSection("Sacred Summary", text: content.summary)
                pilgrimSection("Why This Place Is Sacred", text: content.whySacred)
                Section("What To See Here") {
                    ForEach(Array(content.whatToSee.enumerated()), id: \.offset) { _, feature in
                        Label(feature, systemImage: "eye")
                    }
                }
                pilgrimSection("Līlā / Sacred Association", text: content.lila)
                pilgrimSection("Pilgrim Guidance", text: content.pilgrimGuidance)
                if !content.references.isEmpty {
                    Section("Textual References") {
                        ForEach(content.references) { reference in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(reference.sourceTitle).font(.headline)
                                if let locus = reference.locus {
                                    Text(locus).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Text(reference.explanation)
                                if let quotation = reference.quotation {
                                    Text(quotation).italic().padding(.leading, 8)
                                }
                                if let route = route(for: reference.destination) {
                                    NavigationLink("Read in the app", value: route)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                let related = content.relatedPlaceIDs.compactMap { relatedID in
                    allPlaces.first { $0.id == relatedID }
                }
                if !related.isEmpty {
                    Section("Related Places") {
                        ForEach(related) { relatedPlace in
                            NavigationLink {
                                PlaceDetailView(place: relatedPlace, allPlaces: allPlaces, model: model)
                            } label: {
                                Text("#\(relatedPlace.mapNumber) \(relatedPlace.canonicalName)")
                            }
                        }
                    }
                }
            } else {
                Section("Pilgrim Guide") {
                    Text("Pilgrim-facing guide content has not yet been authored for this place.")
                        .foregroundStyle(.secondary)
                    if let guidance = place.locationGuidance { Text(guidance) }
                }
            }
            Section {
                DisclosureGroup("Research & location information") {
                    LabeledContent("Coordinate status", value: place.coordinateStatus.rawValue)
                    LabeledContent("Confidence", value: place.coordinateConfidence.rawValue)
                    if let latitude = place.latitude, let longitude = place.longitude {
                        LabeledContent("Coordinate", value: String(format: "%.6f, %.6f", latitude, longitude))
                    } else {
                        LabeledContent("Coordinate", value: "Not yet established")
                    }
                    if let anchor = place.navigationAnchorPlaceID {
                        LabeledContent("Navigation anchor", value: anchor.rawValue)
                    }
                    if !place.alternateNames.isEmpty {
                        LabeledContent("Aliases", value: place.alternateNames.joined(separator: ", "))
                    }
                    Text(place.verificationNotes)
                    ForEach(Array(place.provenance.enumerated()), id: \.offset) { _, evidence in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(evidence.sourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption.bold())
                            Text(evidence.description)
                            if let sourceReference = evidence.sourceReference,
                               let url = URL(string: sourceReference) {
                                Link("Source reference", destination: url)
                            }
                        }
                    }
                    LabeledContent("Stable ID", value: place.id.rawValue)
                }
            }
        }
        .navigationTitle(place.canonicalName)
        .accessibilityIdentifier("place.detail.\(place.mapNumber)")
    }

    @ViewBuilder
    private func pilgrimSection(_ title: String, text: String) -> some View {
        Section(title) { Text(text) }
    }

    private func route(for destination: PilgrimageContentDestination?) -> AppRoute? {
        switch destination {
        case let .storySection(sectionID):
            guard let section = model.storySections.first(where: { $0.id == sectionID }) else { return nil }
            return .storySection(storyID: section.storyID, sectionID: sectionID, blockID: nil)
        case let .sourcePassage(passageID):
            return .searchSource(passageID)
        case nil:
            return nil
        }
    }
}

private final class PlaceAnnotation: MLNPointAnnotation {
    let presentation: PilgrimageMapPresentation
    var place: PilgrimagePlace { presentation.place }
    init(_ presentation: PilgrimageMapPresentation) {
        self.presentation = presentation
        super.init()
        coordinate = presentation.coordinate
        title = presentation.place.canonicalName
    }
    required init?(coder: NSCoder) { nil }
}

private final class UserAnnotation: MLNPointAnnotation {}

private final class BasemapLabelAnnotation: MLNPointAnnotation {
    let displayName: String
    init(name: String, coordinate: CLLocationCoordinate2D) {
        displayName = name
        super.init()
        self.coordinate = coordinate
    }
    required init?(coder: NSCoder) { nil }
}

private final class AccessibleAnnotationView: MLNAnnotationView {
    var activate: (() -> Void)?
    override func accessibilityActivate() -> Bool {
        activate?()
        return activate != nil
    }
}

struct OfflineMapLibreView: UIViewRepresentable {
    let presentations: [PilgrimageMapPresentation]
    let activeTarget: PilgrimagePlace
    let sample: LocationSample?
    let recenterCoordinate: CLLocationCoordinate2D?
    let recenterToken: Int
    let onSelect: (PilgrimagePlace) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = Bundle.main.url(forResource: "govardhana-offline-style", withExtension: "json")!
        let map = MLNMapView(frame: .zero, styleURL: styleURL)
        map.accessibilityIdentifier = "govardhana.map"
        map.delegate = context.coordinator
        map.logoView.isHidden = true
        map.setCenter(.init(latitude: 27.5252, longitude: 77.4920), zoomLevel: 15.4, animated: false)
        map.addAnnotations(presentations.map(PlaceAnnotation.init))
        context.coordinator.map = map
        return map
    }

    func updateUIView(_ map: MLNMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateUser(sample)
        context.coordinator.updatePlaceLabels(in: map)
        if context.coordinator.lastRecenter != recenterToken, let recenterCoordinate {
            context.coordinator.lastRecenter = recenterToken
            map.setCenter(recenterCoordinate, zoomLevel: 15.4, animated: true)
        }
    }

    @MainActor
    final class Coordinator: NSObject, @preconcurrency MLNMapViewDelegate {
        var parent: OfflineMapLibreView
        weak var map: MLNMapView?
        private var user: UserAnnotation?
        var lastRecenter = 0
        private var installedBasemapLabels = false
        init(_ parent: OfflineMapLibreView) { self.parent = parent }

        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            // A relative GeoJSON string in a file-based style did not resolve reliably in
            // an installed application. Bind the source to its absolute bundle URL so the
            // exact same local data is used on Simulator and physical devices.
            guard
                let dataURL = Bundle.main.url(forResource: "govardhana-base", withExtension: "geojson"),
                let source = style.source(withIdentifier: "govardhana") as? MLNShapeSource
            else { return }
            source.url = dataURL
            if !installedBasemapLabels {
                installedBasemapLabels = true
                mapView.addAnnotations(Self.basemapLabels(from: dataURL, pilgrimagePlaces: parent.presentations.map(\.place)))
            }
        }

        private static func basemapLabels(from url: URL, pilgrimagePlaces: [PilgrimagePlace]) -> [BasemapLabelAnnotation] {
            guard
                let data = try? Data(contentsOf: url),
                let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let features = root["features"] as? [[String: Any]]
            else { return [] }

            let sacredNames = Set(pilgrimagePlaces.flatMap { place in
                [place.canonicalName, place.asciiName].compactMap { $0 } + place.alternateNames
            }.map { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) })
            var seen = Set<String>()
            return features.compactMap { feature in
                guard
                    let properties = feature["properties"] as? [String: Any],
                    let name = properties["name"] as? String,
                    !name.isEmpty,
                    !sacredNames.contains(name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)),
                    seen.insert(name).inserted,
                    let geometry = feature["geometry"] as? [String: Any],
                    let coordinates = geometry["coordinates"]
                else { return nil }
                var points: [(longitude: Double, latitude: Double)] = []
                collectCoordinates(coordinates, into: &points)
                guard
                    let minLongitude = points.map(\.longitude).min(),
                    let maxLongitude = points.map(\.longitude).max(),
                    let minLatitude = points.map(\.latitude).min(),
                    let maxLatitude = points.map(\.latitude).max()
                else { return nil }
                return BasemapLabelAnnotation(
                    name: name,
                    coordinate: .init(latitude: (minLatitude + maxLatitude) / 2,
                                      longitude: (minLongitude + maxLongitude) / 2)
                )
            }
        }

        private static func collectCoordinates(_ value: Any, into points: inout [(longitude: Double, latitude: Double)]) {
            guard let array = value as? [Any] else { return }
            if array.count == 2, let longitude = array[0] as? Double, let latitude = array[1] as? Double {
                points.append((longitude, latitude))
            } else {
                for child in array { collectCoordinates(child, into: &points) }
            }
        }

        func updateUser(_ sample: LocationSample?) {
            guard let map, let sample else { return }
            if let user { user.coordinate = sample.coordinate } else { let value = UserAnnotation(); value.coordinate = sample.coordinate; user = value; map.addAnnotation(value) }
        }

        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            if let labelAnnotation = annotation as? BasemapLabelAnnotation {
                let label = UILabel()
                label.text = labelAnnotation.displayName
                label.font = .systemFont(ofSize: 11, weight: .semibold)
                label.textColor = .label
                label.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.82)
                label.layer.cornerRadius = 4
                label.clipsToBounds = true
                label.textAlignment = .center
                label.sizeToFit()
                label.frame = label.frame.insetBy(dx: -5, dy: -3)
                let view = MLNAnnotationView(reuseIdentifier: "basemap-label")
                view.frame = label.bounds
                view.addSubview(label)
                view.isAccessibilityElement = false
                return view
            }
            let placeAnnotation = annotation as? PlaceAnnotation
            let isApproximate = placeAnnotation?.presentation.isApproximate == true
            let view = AccessibleAnnotationView(reuseIdentifier: annotation is UserAnnotation ? "user" : isApproximate ? "approximate-place" : "place")
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
            label.textAlignment = .center; label.font = .boldSystemFont(ofSize: isApproximate ? 13 : 15)
            label.textColor = isApproximate ? .systemRed : .white
            label.backgroundColor = annotation is UserAnnotation ? .systemBlue : isApproximate ? UIColor.systemBackground.withAlphaComponent(0.94) : .systemRed
            label.layer.borderWidth = isApproximate ? 2 : 0
            label.layer.borderColor = isApproximate ? UIColor.systemRed.cgColor : nil
            label.layer.cornerRadius = 17; label.clipsToBounds = true
            label.text = annotation is UserAnnotation ? "●" : isApproximate ? "\(placeAnnotation!.place.mapNumber)?" : String(placeAnnotation!.place.mapNumber)
            view.frame = label.frame; view.addSubview(label)
            view.isAccessibilityElement = true
            if let placeAnnotation {
                let place = placeAnnotation.place
                if let offsetIndex = placeAnnotation.presentation.approximateOffsetIndex {
                    view.centerOffset = PilgrimageMapProjection.approximateOffset(
                        index: offsetIndex,
                        zoomLevel: mapView.zoomLevel
                    )
                }
                view.activate = { [weak self] in self?.parent.onSelect(place) }
                view.isAccessibilityElement = false
                let button = UIButton(frame: label.frame)
                button.accessibilityIdentifier = isApproximate ? "map.approximate-pin.\(place.mapNumber)" : "map.pin.\(place.mapNumber)"
                button.accessibilityLabel = "#\(place.mapNumber) \(place.canonicalName)\(isApproximate ? " — approximate location" : "")"
                button.addAction(UIAction { [weak self] _ in self?.parent.onSelect(place) }, for: .touchUpInside)
                view.addSubview(button)
                let orderedPlaces = parent.presentations.map(\.place).sorted { $0.mapNumber < $1.mapNumber }
                let index = orderedPlaces.firstIndex(where: { $0.id == place.id }) ?? 0
                let name = UILabel()
                name.tag = 15_016
                name.text = "#\(place.mapNumber) \(place.canonicalName)"
                name.font = .systemFont(ofSize: 12, weight: .semibold)
                name.textColor = .label
                name.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.88)
                name.layer.cornerRadius = 5
                name.clipsToBounds = true
                name.textAlignment = .center
                name.sizeToFit()
                let width = min(name.frame.width + 12, 190)
                let position = index % 4
                name.frame = CGRect(
                    x: position < 2 ? 38 : -(width + 4),
                    y: position.isMultiple(of: 2) ? -8 : 18,
                    width: width, height: 24
                )
                view.addSubview(name)
                updateLabel(name, for: placeAnnotation.presentation, zoomLevel: mapView.zoomLevel)
            } else {
                view.accessibilityIdentifier = "map.user-location"
                view.accessibilityLabel = "Current simulated location"
            }
            return view
        }

        func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
            if let place = (annotation as? PlaceAnnotation)?.place { parent.onSelect(place) }
        }

        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            updatePlaceLabels(in: mapView)
        }

        func updatePlaceLabels(in mapView: MLNMapView) {
            for annotation in mapView.annotations ?? [] {
                guard let placeAnnotation = annotation as? PlaceAnnotation,
                      let annotationView = mapView.view(for: annotation),
                      let name = annotationView.viewWithTag(15_016) as? UILabel else { continue }
                if let offsetIndex = placeAnnotation.presentation.approximateOffsetIndex {
                    annotationView.centerOffset = PilgrimageMapProjection.approximateOffset(
                        index: offsetIndex,
                        zoomLevel: mapView.zoomLevel
                    )
                }
                updateLabel(name, for: placeAnnotation.presentation, zoomLevel: mapView.zoomLevel)
            }
        }

        private func updateLabel(
            _ label: UILabel,
            for presentation: PilgrimageMapPresentation,
            zoomLevel: Double
        ) {
            let priority = PilgrimageMapProjection.labelPriority(
                for: presentation,
                activeTarget: parent.activeTarget
            )
            label.isHidden = !PilgrimageMapProjection.showsNameLabel(priority: priority, zoomLevel: zoomLevel)
            label.font = .systemFont(
                ofSize: priority == .activeTarget ? 12 : 11,
                weight: priority == .activeTarget ? .bold : .semibold
            )
            label.backgroundColor = UIColor.systemBackground.withAlphaComponent(priority == .activeTarget ? 0.94 : 0.82)
        }
    }
}
