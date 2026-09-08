import CoreLocation
import MapLibre
import SwiftUI

extension PilgrimagePlace {
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return .init(latitude: latitude, longitude: longitude)
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
        guard let destination = activeDestination.coordinate else { return nil }
        return sample.map { GeoMath.distance(from: $0.coordinate, to: destination) }
    }
    var destinationBearing: Double? {
        guard let destination = activeDestination.coordinate else { return nil }
        return sample.map { GeoMath.bearing(from: $0.coordinate, to: destination) }
    }
    var arrived: Bool { (destinationDistance ?? .greatestFiniteMagnitude) <= GeoMath.arrivalRadius }
    var nearest: PilgrimagePlace? { sample.flatMap { GeoMath.nearest(to: $0.coordinate, places: places) } }
    var mappablePlaces: [PilgrimagePlace] { places.filter { $0.coordinate != nil } }

    func jump(_ place: PilgrimagePlace) {
        guard let coordinate = place.coordinate else { return }
        source = .simulation
        simulated.jump(to: coordinate)
        requestedCenter = coordinate
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

    init(places: [PilgrimagePlace]) {
        _model = StateObject(wrappedValue: PilgrimageMapModel(places: places))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            OfflineMapLibreView(places: model.mappablePlaces, sample: model.sample, recenterCoordinate: model.requestedCenter, recenterToken: model.shouldRecenter) { selectedPlace = $0 }
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
        .navigationDestination(item: $selectedPlace) { PlaceDetailView(place: $0) }
    }

    private var destinationPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.arrived ? "Arrived at" : "Next").font(.caption).foregroundStyle(.secondary)
            Text("#\(model.activeDestination.mapNumber) \(model.activeDestination.canonicalName)").font(.headline)
            if let distance = model.destinationDistance, let bearing = model.destinationBearing {
                Text("\(Int(distance.rounded())) m  •  \(Int(bearing.rounded()))° \(GeoMath.direction(for: bearing))")
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    #if DEBUG
    private var controls: some View {
        DisclosureGroup("Location & Offline Debug", isExpanded: $debugExpanded) {
            Picker("Location Source", selection: $model.source) { ForEach(PilgrimageMapModel.Source.allCases, id: \.self) { Text($0.rawValue) } }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 6) {
                ForEach(model.places) { place in
                    if place.coordinate != nil {
                        Button("#\(place.mapNumber)") { model.jump(place) }
                    } else {
                        Button("#\(place.mapNumber) Details") { selectedPlace = place }
                    }
                }
            }
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

struct PlaceDetailView: View {
    let place: PilgrimagePlace
    var body: some View {
        Form {
            Section("Mapping Test") {
                Text("#\(place.mapNumber)").font(.largeTitle.bold())
                Text(place.canonicalName).font(.title2)
                if let latitude = place.latitude, let longitude = place.longitude {
                    Text(String(format: "%.6f, %.6f", latitude, longitude)).monospaced()
                } else {
                    Text("Coordinate not yet established").foregroundStyle(.secondary)
                }
                Text("Registry coordinate — \(place.coordinateStatus.rawValue) / \(place.coordinateConfidence.rawValue)")
                    .foregroundStyle(.secondary)
            }
            #if DEBUG
            Section("Research Metadata") {
                LabeledContent("Stable ID", value: place.id.rawValue)
                LabeledContent("Status", value: place.coordinateStatus.rawValue)
                LabeledContent("Confidence", value: place.coordinateConfidence.rawValue)
                if let accuracy = place.coordinateAccuracyMeters {
                    LabeledContent("Accuracy", value: "\(Int(accuracy.rounded())) m")
                }
                if !place.alternateNames.isEmpty {
                    LabeledContent("Aliases", value: place.alternateNames.joined(separator: ", "))
                }
                Text(place.verificationNotes)
                if let anchor = place.navigationAnchorPlaceID {
                    LabeledContent("Navigation anchor", value: anchor.rawValue)
                }
                if let guidance = place.locationGuidance {
                    LabeledContent("Location guidance", value: guidance)
                }
                ForEach(Array(place.provenance.enumerated()), id: \.offset) { _, evidence in
                    VStack(alignment: .leading) {
                        Text(evidence.sourceType).font(.caption.bold())
                        Text(evidence.description)
                    }
                }
            }
            #endif
        }.navigationTitle(place.canonicalName)
    }
}

private final class PlaceAnnotation: MLNPointAnnotation {
    let place: PilgrimagePlace
    init(_ place: PilgrimagePlace, coordinate: CLLocationCoordinate2D) {
        self.place = place
        super.init()
        self.coordinate = coordinate
        title = place.canonicalName
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
    let places: [PilgrimagePlace]
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
        map.addAnnotations(places.compactMap { place in
            place.coordinate.map { PlaceAnnotation(place, coordinate: $0) }
        })
        context.coordinator.map = map
        return map
    }

    func updateUIView(_ map: MLNMapView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateUser(sample)
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
                mapView.addAnnotations(Self.basemapLabels(from: dataURL, pilgrimagePlaces: parent.places))
            }
        }

        private static func basemapLabels(from url: URL, pilgrimagePlaces: [PilgrimagePlace]) -> [BasemapLabelAnnotation] {
            guard
                let data = try? Data(contentsOf: url),
                let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let features = root["features"] as? [[String: Any]]
            else { return [] }

            let sacredNames = Set(pilgrimagePlaces.filter { $0.coordinate != nil }.flatMap { place in
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
            let view = AccessibleAnnotationView(reuseIdentifier: annotation is UserAnnotation ? "user" : "place")
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 34, height: 34))
            label.textAlignment = .center; label.textColor = .white; label.font = .boldSystemFont(ofSize: 15)
            label.backgroundColor = annotation is UserAnnotation ? .systemBlue : .systemRed
            label.layer.cornerRadius = 17; label.clipsToBounds = true
            label.text = annotation is UserAnnotation ? "●" : String((annotation as! PlaceAnnotation).place.mapNumber)
            view.frame = label.frame; view.addSubview(label)
            view.isAccessibilityElement = true
            if let place = (annotation as? PlaceAnnotation)?.place {
                view.activate = { [weak self] in self?.parent.onSelect(place) }
                view.isAccessibilityElement = false
                let button = UIButton(frame: label.frame)
                button.accessibilityIdentifier = "map.pin.\(place.mapNumber)"
                button.accessibilityLabel = "#\(place.mapNumber) \(place.canonicalName)"
                button.addAction(UIAction { [weak self] _ in self?.parent.onSelect(place) }, for: .touchUpInside)
                view.addSubview(button)
                let orderedPlaces = parent.places.sorted { $0.mapNumber < $1.mapNumber }
                let index = orderedPlaces.firstIndex(where: { $0.id == place.id }) ?? 0
                let offsets: [CGPoint] = [
                    .init(x: 38, y: -8), .init(x: 38, y: 18),
                    .init(x: -129, y: -8), .init(x: -129, y: 18),
                ]
                let offset = offsets[index % offsets.count]
                let name = UILabel(frame: CGRect(x: offset.x, y: offset.y, width: 125, height: 24))
                name.tag = 15_016
                name.isHidden = mapView.zoomLevel < 14.5
                name.text = "#\(place.mapNumber) \(place.canonicalName)"
                name.font = .systemFont(ofSize: 11, weight: .bold)
                name.textColor = .label
                name.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.88)
                name.layer.cornerRadius = 5
                name.clipsToBounds = true
                name.textAlignment = .center
                view.addSubview(name)
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
            for annotation in mapView.annotations ?? [] {
                guard annotation is PlaceAnnotation,
                      let name = mapView.view(for: annotation)?.viewWithTag(15_016) else { continue }
                name.isHidden = mapView.zoomLevel < 14.5
            }
        }
    }
}
