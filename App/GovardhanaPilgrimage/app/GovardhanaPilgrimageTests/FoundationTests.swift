import GRDB
import CoreLocation
import PDFKit
import XCTest
@testable import GovardhanaPilgrimage

final class FoundationTests: XCTestCase {
    @MainActor
    func testTask021A6ExistingKundaPointsAndSeparateWaterPolygons() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        XCTAssertEqual(72, places.count)
        XCTAssertEqual(71, places.compactMap(\.mapNumber).count)
        XCTAssertEqual(4, places.compactMap(\.geometry).count)
        let areas = places.filter { $0.geometry != nil }
        let expected: [(String, Int, Double, Double, Int, String)] = [
            ("place.radhakunda", 1, 27.525256, 77.491353, 17, "OSM-WAY-335571302-V1"),
            ("place.syamakunda", 2, 27.525200, 77.492500, 17, "OSM-WAY-335571305-V1"),
            ("place.lalitakunda", 3, 27.526200, 77.493100, 13, "OSM-WAY-335571300-V1"),
        ]
        let presentations = PilgrimageMapProjection.presentations(for: places)
        XCTAssertEqual(71, presentations.count)
        let model = PilgrimageMapModel(places: places)
        for (placeID, number, latitude, longitude, vertexCount, sourceID) in expected {
            let place = try XCTUnwrap(places.first { $0.id.rawValue == placeID })
            let geometry = try XCTUnwrap(place.geometry)
            XCTAssertEqual(number, place.mapNumber)
            XCTAssertEqual("POINT", place.geometryType)
            XCTAssertEqual("ALL_ZOOMS", place.mapVisibility)
            XCTAssertTrue(place.navigationEligible)
            XCTAssertEqual(latitude, place.latitude)
            XCTAssertEqual(longitude, place.longitude)
            XCTAssertEqual(vertexCount, geometry.vertices.count)
            XCTAssertEqual("WATER_BODY_POLYGON", geometry.geometryType)
            XCTAssertEqual("POLYGON_VERTEX", geometry.coordinateSemantics)
            XCTAssertEqual(sourceID, geometry.sourceID)
            XCTAssertEqual("https://www.openstreetmap.org/way/\(sourceID.components(separatedBy: "-")[2])", geometry.sourceURL)
            XCTAssertEqual(1, geometry.sourceVersion)
            XCTAssertEqual(29850243, geometry.sourceChangeset)
            XCTAssertEqual("2026-09-17", geometry.sourceRetrievedOn)
            XCTAssertTrue(geometry.attribution.contains("ODbL"))
            XCTAssertFalse(PilgrimageAreaMapProjection.isVisible(place, zoomLevel: 14.9))
            XCTAssertTrue(PilgrimageAreaMapProjection.isVisible(place, zoomLevel: 15))
            XCTAssertFalse(PilgrimageAreaMapProjection.showsLabel(place, zoomLevel: 20))
            XCTAssertEqual(place.id, PilgrimageAreaMapProjection.selectedPlace(featurePlaceID: placeID, areas: areas)?.id)
            XCTAssertEqual(1, presentations.filter { $0.place.id == place.id }.count)
            XCTAssertEqual(place.id, presentations.first { $0.place.id == place.id }?.place.id)
            XCTAssertTrue(PilgrimageAreaMapProjection.highlightsOutline(place, selectedAreaID: place.id))
            XCTAssertEqual(1, areas.filter { PilgrimageAreaMapProjection.highlightsOutline($0, selectedAreaID: place.id) }.count)
            let priorSample = model.sample?.coordinate
            let priorSource = model.source
            model.navigate(to: place)
            XCTAssertEqual(priorSource, model.source)
            XCTAssertEqual(priorSample?.latitude, model.sample?.coordinate.latitude)
            XCTAssertEqual(priorSample?.longitude, model.sample?.coordinate.longitude)
            XCTAssertEqual(place.id, model.activeDestination.id)
            XCTAssertEqual(latitude, model.navigationCoordinate?.latitude)
            XCTAssertEqual(longitude, model.navigationCoordinate?.longitude)
        }
        let mohana = try XCTUnwrap(places.first { $0.id.rawValue == "place.rk.mohana-kunda" })
        XCTAssertNil(mohana.mapNumber)
        XCTAssertTrue(PilgrimageAreaMapProjection.showsLabel(mohana, zoomLevel: 15))
        XCTAssertFalse(presentations.contains { $0.place.id == mohana.id })
    }

    @MainActor
    func testTask021A4AreaOnlyPlaceCannotEnterPointNavigation() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let area = try XCTUnwrap(places.first { $0.id.rawValue == "place.rk.mohana-kunda" })
        let geometry = try XCTUnwrap(area.geometry)
        XCTAssertEqual(72, places.count)
        XCTAssertEqual(71, places.compactMap(\.mapNumber).count)
        XCTAssertNil(area.mapNumber)
        XCTAssertNil(area.coordinate)
        XCTAssertNil(area.navigationAnchorPlaceID)
        XCTAssertFalse(area.navigationEligible)
        XCTAssertEqual("RADHA_KUNDA_MICRO", area.collection)
        XCTAssertEqual("WATER_BODY_POLYGON", geometry.geometryType)
        XCTAssertEqual("POLYGON_VERTEX", geometry.coordinateSemantics)
        XCTAssertEqual(81, geometry.vertices.count)
        XCTAssertEqual(geometry.vertices.first, geometry.vertices.last)
        XCTAssertFalse(PilgrimageAreaMapProjection.isVisible(area, zoomLevel: 13))
        XCTAssertTrue(PilgrimageAreaMapProjection.isVisible(area, zoomLevel: geometry.minZoom))
        XCTAssertFalse(PilgrimageAreaMapProjection.showsLabel(area, zoomLevel: geometry.minZoom - 0.1))
        XCTAssertTrue(PilgrimageAreaMapProjection.showsLabel(area, zoomLevel: geometry.minZoom))
        XCTAssertTrue(PilgrimageAreaMapProjection.showsLabel(area, zoomLevel: geometry.labelMinZoom))
        let labelCoordinate = try XCTUnwrap(PilgrimageAreaMapProjection.labelCoordinate(area))
        XCTAssertGreaterThan(labelCoordinate.latitude, geometry.vertices.map(\.latitude).min()!)
        XCTAssertLessThan(labelCoordinate.latitude, geometry.vertices.map(\.latitude).max()!)
        XCTAssertEqual(area.id, PilgrimageAreaMapProjection.selectedPlace(featurePlaceID: area.id.rawValue, areas: places)?.id)
        XCTAssertFalse(PilgrimageMapProjection.presentations(for: places).contains { $0.place.id == area.id })
        XCTAssertFalse(PilgrimagePlaceNavigation.rows(for: places).first { $0.place.id == area.id }!.place.navigationEligible)
        let model = PilgrimageMapModel(places: places)
        let priorDestination = model.activeDestination
        let priorRecenter = model.shouldRecenter
        let priorSample = model.sample?.coordinate
        model.navigate(to: area)
        XCTAssertEqual(priorDestination, model.activeDestination)
        XCTAssertEqual(priorRecenter, model.shouldRecenter)
        XCTAssertEqual(priorSample?.latitude, model.sample?.coordinate.latitude)
        XCTAssertNotEqual(area.id, model.nearest?.id)
        XCTAssertNil(model.places.first { $0.id == area.id }?.coordinate)
        XCTAssertTrue(geometry.attribution.contains("OpenStreetMap"))
        XCTAssertEqual("OSM-WAY-430061166-V2", geometry.sourceID)
    }

    func testSanskritTextLayoutPreservesAuthoredPadasAndRemovesBlankSerializationLines() {
        let text = """
        first pāda

        second pāda
        third pāda

        fourth pāda
        """
        XCTAssertEqual(
            ["first pāda", "second pāda", "third pāda", "fourth pāda"],
            SanskritTextLayout.padas(from: text)
        )
    }

    private final class FixtureLocationProvider: LocationProvider {
        let coordinate: CLLocationCoordinate2D
        init(coordinate: CLLocationCoordinate2D) { self.coordinate = coordinate }
        var onLocation: ((LocationSample) -> Void)?
        func start() { onLocation?(.init(coordinate: coordinate, horizontalAccuracy: 3, timestamp: Date(), course: 0, speed: 0)) }
        func stop() {}
    }

    @MainActor
    func testTask014DistanceBearingNearestArrivalAndProviderAbstraction() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let firstCoordinate = try XCTUnwrap(places[0].coordinate)
        let secondCoordinate = try XCTUnwrap(places[1].coordinate)
        let distance = GeoMath.distance(from: firstCoordinate, to: secondCoordinate)
        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 125)
        let bearing = GeoMath.bearing(from: firstCoordinate, to: secondCoordinate)
        XCTAssertGreaterThan(bearing, 85)
        XCTAssertLessThan(bearing, 100)
        XCTAssertEqual("E", GeoMath.direction(for: bearing))
        XCTAssertEqual(places[1], GeoMath.nearest(to: secondCoordinate, places: places))
        XCTAssertFalse(distance <= GeoMath.arrivalRadius)
        XCTAssertTrue(GeoMath.distance(from: secondCoordinate, to: .init(latitude: 27.52521, longitude: 77.49251)) <= GeoMath.arrivalRadius)

        let provider: LocationProvider = FixtureLocationProvider(coordinate: firstCoordinate)
        var received: LocationSample?
        provider.onLocation = { received = $0 }
        provider.start()
        XCTAssertEqual(places[0].latitude, received?.coordinate.latitude)
    }

    @MainActor
    func testTask020BManualLocationUsesProviderContextAndCannotReplaceRealGPS() async throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let model = PilgrimageMapModel(places: places)
        let place5 = try XCTUnwrap(places.first { $0.mapNumber == 5 })
        let manualCoordinate = CLLocationCoordinate2D(latitude: 27.51210, longitude: 77.47835)

        model.setManualSimulatedLocation(manualCoordinate)
        await Task.yield()
        XCTAssertTrue(model.manualSimulatedLocationActive)
        XCTAssertEqual(.simulation, model.source)
        XCTAssertEqual(manualCoordinate.latitude, model.sample?.coordinate.latitude)
        XCTAssertEqual(manualCoordinate.longitude, model.sample?.coordinate.longitude)
        XCTAssertEqual(place5.id, model.nearest?.id)
        XCTAssertEqual(place5.id, model.nearbyPlace?.id)
        XCTAssertLessThan(try XCTUnwrap(model.nearestDistance), GeoMath.nearbyPlaceRadius)
        XCTAssertNotNil(model.destinationDistance)
        XCTAssertNotNil(model.destinationBearing)

        let realSample = LocationSample(
            coordinate: .init(latitude: 34.0, longitude: -118.0),
            horizontalAccuracy: 4,
            timestamp: Date(),
            course: 0,
            speed: 0
        )
        model.source = .real
        model.sample = realSample
        model.setManualSimulatedLocation(.init(latitude: 27.5, longitude: 77.5))
        await Task.yield()
        XCTAssertFalse(model.manualSimulatedLocationActive)
        XCTAssertEqual(.real, model.source)
        XCTAssertEqual(realSample.coordinate.latitude, model.sample?.coordinate.latitude)
        XCTAssertEqual(realSample.coordinate.longitude, model.sample?.coordinate.longitude)
        XCTAssertNil(model.nearbyPlace)
    }

    func testTask015PermanentPilgrimageRegistryIdentityMetadataAndSimulationProjection() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let allPlaces = try repository.pilgrimagePlaces()
        let places = allPlaces.filter { [1, 2, 3, 20].contains($0.mapNumber) }
        XCTAssertEqual([1, 2, 3, 20], places.compactMap(\.mapNumber))
        XCTAssertEqual(
            ["place.radhakunda", "place.syamakunda", "place.lalitakunda", "place.manasiganga"],
            places.map(\.id.rawValue)
        )
        XCTAssertTrue(places.allSatisfy { $0.coordinateStatus == .provisional && $0.coordinateConfidence == .low })
        XCTAssertTrue(places.allSatisfy { $0.provenance.first?.sourceType == "PROJECT_FIXTURE" })
        let route = SimulationRoute.task014Coordinates(places: allPlaces)
        XCTAssertEqual(places[0].coordinate?.latitude, route.first?.latitude)
        XCTAssertEqual(places[2].coordinate?.longitude, route.last?.longitude)
    }

    @MainActor
    func testTask016ApprovedPlacesSurviveSQLiteAndMapModelWithoutChangingSimulation() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        XCTAssertEqual(
            [1, 2, 3, 4, 5, 6, 7, 8, 20],
            places.filter { [1, 2, 3, 4, 5, 6, 7, 8, 20].contains($0.mapNumber) }.compactMap(\.mapNumber)
        )
        let expected: [Int: (String, Double, Double, CoordinateVerificationStatus, CoordinateConfidence)] = [
            4: ("place.mukharai", 27.51031, 77.49956, .probable, .medium),
            5: ("place.kusumasarovara", 27.51209, 77.47834, .verified, .high),
            6: ("place.uddhava-temple", 27.51141, 77.47705, .probable, .high),
            7: ("place.asoka-vana", 27.5111752, 77.4785779, .probable, .high),
            8: ("place.narada-kunda", 27.50819, 77.47980, .probable, .high),
        ]
        for place in places where expected[place.mapNumber ?? -1] != nil {
            let value = try XCTUnwrap(expected[place.mapNumber ?? -1])
            XCTAssertEqual(value.0, place.id.rawValue)
            XCTAssertEqual(value.1, try XCTUnwrap(place.latitude), accuracy: 0.00000001)
            XCTAssertEqual(value.2, try XCTUnwrap(place.longitude), accuracy: 0.00000001)
            XCTAssertEqual(value.3, place.coordinateStatus)
            XCTAssertEqual(value.4, place.coordinateConfidence)
            XCTAssertFalse(place.alternateNames.isEmpty)
            XCTAssertFalse(place.provenance.isEmpty)
            XCTAssertNil(place.contentDestination)
        }
        let model = PilgrimageMapModel(places: places)
        XCTAssertEqual(places.count, model.places.count)
        let route = SimulationRoute.task014Coordinates(places: places)
        XCTAssertEqual(places.first { $0.mapNumber == 1 }?.coordinate?.latitude, route.first?.latitude)
        XCTAssertEqual(places.first { $0.mapNumber == 3 }?.coordinate?.longitude, route.last?.longitude)
    }

    @MainActor
    func testTask017CoordinateLessPlacesUseAnchoredPresentationAndStayOutOfGeoCalculations() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let allPlaces = try repository.pilgrimagePlaces()
        let places = allPlaces.filter { (1...13).contains($0.mapNumber ?? -1) || $0.mapNumber == 20 }
        XCTAssertEqual(Array(1...13) + [20], places.compactMap(\.mapNumber))
        let byNumber = Dictionary(uniqueKeysWithValues: places.compactMap { place in place.mapNumber.map { ($0, place) } })
        for number in [10, 12] {
            let place = try XCTUnwrap(byNumber[number])
            XCTAssertNil(place.latitude)
            XCTAssertNil(place.longitude)
            XCTAssertNil(place.coordinate)
            XCTAssertEqual(.unverified, place.coordinateStatus)
            XCTAssertEqual(.unknown, place.coordinateConfidence)
            XCTAssertEqual("place.ratna-simhasana", place.navigationAnchorPlaceID?.rawValue)
            XCTAssertFalse(try XCTUnwrap(place.locationGuidance).isEmpty)
        }
        let model = PilgrimageMapModel(places: places)
        XCTAssertEqual(12, model.mappablePlaces.count)
        XCTAssertFalse(model.mappablePlaces.contains { [10, 12].contains($0.mapNumber) })
        XCTAssertEqual(14, model.mapPresentations.count)
        let approximate = model.mapPresentations.filter(\.isApproximate)
        XCTAssertEqual([10, 12], approximate.map { $0.place.mapNumber })
        XCTAssertTrue(approximate.allSatisfy { $0.anchor?.mapNumber == 11 })
        XCTAssertEqual([0, 1], approximate.compactMap(\.approximateOffsetIndex))
        XCTAssertTrue(approximate.allSatisfy { $0.coordinate.latitude == byNumber[11]?.coordinate?.latitude })
        let rows = PilgrimagePlaceNavigation.rows(for: places)
        XCTAssertEqual(Array(1...13) + [20], rows.map { $0.place.mapNumber })
        XCTAssertEqual("APPROXIMATE · via #11 Ratna-siṁhāsana", rows.first { $0.place.mapNumber == 10 }?.statusText)
        XCTAssertEqual("Go to anchor", rows.first { $0.place.mapNumber == 12 }?.goTitle)
        let anchor = try XCTUnwrap(byNumber[11]?.coordinate)
        XCTAssertNotEqual(10, GeoMath.nearest(to: anchor, places: places)?.mapNumber)
        XCTAssertNotEqual(12, GeoMath.nearest(to: anchor, places: places)?.mapNumber)
        XCTAssertEqual(11, GeoMath.nearest(to: anchor, places: places)?.mapNumber)
        model.navigate(to: try XCTUnwrap(byNumber[10]))
        XCTAssertEqual(10, model.activeDestination.mapNumber)
        XCTAssertEqual(11, model.activeNavigationAnchor?.mapNumber)
        XCTAssertEqual(anchor.latitude, model.requestedCenter?.latitude)
        let route = SimulationRoute.task014Coordinates(places: places)
        XCTAssertEqual(byNumber[1]?.coordinate?.latitude, route.first?.latitude)
        XCTAssertEqual(byNumber[3]?.coordinate?.longitude, route.last?.longitude)
    }

    @MainActor
    func testTask019ApprovedPlacesSurviveSQLiteAndProjectGenericallyToMap() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        XCTAssertEqual(72, places.count)
        XCTAssertEqual(Array(1...71), places.compactMap(\.mapNumber))
        let byNumber = Dictionary(uniqueKeysWithValues: places.compactMap { place in place.mapNumber.map { ($0, place) } })

        let santNivas = try XCTUnwrap(byNumber[14])
        XCTAssertNil(santNivas.latitude)
        XCTAssertNil(santNivas.longitude)
        XCTAssertEqual(.unverified, santNivas.coordinateStatus)
        XCTAssertEqual(.unknown, santNivas.coordinateConfidence)
        XCTAssertEqual("place.gvala-pokhara", santNivas.navigationAnchorPlaceID?.rawValue)
        XCTAssertTrue(try XCTUnwrap(santNivas.locationGuidance).contains("approximately 170 m"))

        let expected: [Int: (String, Double, Double, CoordinateVerificationStatus, CoordinateConfidence)] = [
            15: ("place.jugal-kunda", 27.5049625, 77.4736094, .probable, .high),
            16: ("place.kilola-kunda", 27.4997625, 77.4716094, .probable, .high),
            17: ("place.panca-tirtha-kunda", 27.4992222, 77.4655167, .verified, .high),
            18: ("place.mukharavinda-manasi-ganga", 27.4982875, 77.4654219, .verified, .high),
            19: ("place.cakra-tirtha", 27.4985111, 77.4641639, .verified, .high),
        ]
        for (number, value) in expected {
            let place = try XCTUnwrap(byNumber[number])
            XCTAssertEqual(value.0, place.id.rawValue)
            XCTAssertEqual(value.1, try XCTUnwrap(place.latitude), accuracy: 0.00000001)
            XCTAssertEqual(value.2, try XCTUnwrap(place.longitude), accuracy: 0.00000001)
            XCTAssertEqual(value.3, place.coordinateStatus)
            XCTAssertEqual(value.4, place.coordinateConfidence)
        }
        XCTAssertTrue(try XCTUnwrap(byNumber[18]?.verificationNotes).contains("map place #61"))

        let presentations = PilgrimageMapProjection.presentations(for: places)
        let expectedPresentationCount = places.filter { place in
            if place.coordinate != nil { return true }
            guard let anchorID = place.navigationAnchorPlaceID else { return false }
            return places.first { $0.id == anchorID }?.coordinate != nil
        }.count
        XCTAssertEqual(expectedPresentationCount, presentations.count)
        XCTAssertEqual(71, presentations.count)
        let approximate14 = try XCTUnwrap(presentations.first { $0.place.mapNumber == 14 })
        XCTAssertTrue(approximate14.isApproximate)
        XCTAssertEqual(13, approximate14.anchor?.mapNumber)
        XCTAssertEqual(byNumber[13]?.coordinate?.latitude, approximate14.coordinate.latitude)

        let rows = PilgrimagePlaceNavigation.rows(for: places)
        XCTAssertEqual("APPROXIMATE · via #13 Gvāla-pokhara", rows.first { $0.place.mapNumber == 14 }?.statusText)
        XCTAssertEqual("Go to anchor", rows.first { $0.place.mapNumber == 14 }?.goTitle)

        let model = PilgrimageMapModel(places: places)
        let original = LocationSample(
            coordinate: .init(latitude: 27.525256, longitude: 77.491353),
            horizontalAccuracy: 4, timestamp: Date(timeIntervalSince1970: 123), course: 90, speed: 1
        )
        model.source = .real
        model.sample = original
        model.navigate(to: santNivas)
        XCTAssertEqual(.real, model.source)
        XCTAssertEqual(14, model.activeDestination.mapNumber)
        XCTAssertEqual(13, model.activeNavigationAnchor?.mapNumber)
        XCTAssertEqual(original.timestamp, model.sample?.timestamp)
    }

    @MainActor
    func testTask017PilgrimageNavigationPreservesLocationSourceAndDistinguishesAnchorArrival() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let byNumber = Dictionary(uniqueKeysWithValues: places.compactMap { place in place.mapNumber.map { ($0, place) } })
        let model = PilgrimageMapModel(places: places)
        let original = LocationSample(
            coordinate: .init(latitude: 27.525256, longitude: 77.491353),
            horizontalAccuracy: 4,
            timestamp: Date(timeIntervalSince1970: 123),
            course: 90,
            speed: 1
        )

        model.source = .real
        model.sample = original
        model.navigate(to: try XCTUnwrap(byNumber[13]))
        XCTAssertEqual(.real, model.source)
        XCTAssertEqual(13, model.activeDestination.mapNumber)
        XCTAssertEqual(original.coordinate.latitude, model.sample?.coordinate.latitude)
        XCTAssertEqual(original.timestamp, model.sample?.timestamp)
        XCTAssertEqual(byNumber[13]?.coordinate?.latitude, model.requestedCenter?.latitude)

        model.navigate(to: try XCTUnwrap(byNumber[10]))
        XCTAssertEqual(.real, model.source)
        XCTAssertEqual(10, model.activeDestination.mapNumber)
        XCTAssertEqual(11, model.activeNavigationAnchor?.mapNumber)
        XCTAssertEqual(byNumber[11]?.coordinate?.longitude, model.navigationCoordinate?.longitude)
        XCTAssertEqual(original.coordinate.longitude, model.sample?.coordinate.longitude)
        XCTAssertEqual(original.timestamp, model.sample?.timestamp)

        model.source = .simulation
        model.sample = original
        model.navigate(to: try XCTUnwrap(byNumber[9]))
        XCTAssertEqual(.simulation, model.source)
        XCTAssertEqual(original.coordinate.latitude, model.sample?.coordinate.latitude)
        XCTAssertEqual(original.timestamp, model.sample?.timestamp)

        model.sample = .init(
            coordinate: try XCTUnwrap(byNumber[9]?.coordinate), horizontalAccuracy: 1,
            timestamp: original.timestamp, course: 0, speed: 0
        )
        XCTAssertEqual(.exactArrival, model.arrivalPresentationState)
        model.navigate(to: try XCTUnwrap(byNumber[10]))
        model.sample = .init(
            coordinate: try XCTUnwrap(byNumber[11]?.coordinate), horizontalAccuracy: 1,
            timestamp: original.timestamp, course: 0, speed: 0
        )
        XCTAssertEqual(.navigationAnchorArrival, model.arrivalPresentationState)
    }

    @MainActor
    func testTask018MapLabelPriorityAndCompactApproximateCard() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let byNumber = Dictionary(uniqueKeysWithValues: places.compactMap { place in place.mapNumber.map { ($0, place) } })
        let presentations = PilgrimageMapProjection.presentations(for: places)
        let presentationByNumber = Dictionary(uniqueKeysWithValues: presentations.map { ($0.place.mapNumber, $0) })

        let target10 = try XCTUnwrap(byNumber[10])
        XCTAssertEqual(.activeTarget, PilgrimageMapProjection.labelPriority(
            for: try XCTUnwrap(presentationByNumber[10]), activeTarget: target10
        ))
        XCTAssertEqual(.navigationAnchor, PilgrimageMapProjection.labelPriority(
            for: try XCTUnwrap(presentationByNumber[11]), activeTarget: target10
        ))
        XCTAssertEqual(.ordinary, PilgrimageMapProjection.labelPriority(
            for: try XCTUnwrap(presentationByNumber[12]), activeTarget: target10
        ))

        let target13 = try XCTUnwrap(byNumber[13])
        XCTAssertEqual(.activeTarget, PilgrimageMapProjection.labelPriority(
            for: try XCTUnwrap(presentationByNumber[13]), activeTarget: target13
        ))
        XCTAssertTrue(presentations.filter { $0.place.mapNumber != 13 }.allSatisfy {
            PilgrimageMapProjection.labelPriority(for: $0, activeTarget: target13) == .ordinary
        })

        let model = PilgrimageMapModel(places: places)
        model.navigate(to: target10)
        let card = model.targetCardPresentation
        XCTAssertEqual(10, card.place.mapNumber)
        XCTAssertTrue(card.isApproximate)
        XCTAssertEqual("#11 Ratna-siṁhāsana", card.anchorDisplayName)
        XCTAssertEqual("Approximate · via #11 Ratna-siṁhāsana", card.compactContext)
        XCTAssertTrue(card.hasExpandableGuidance)
        XCTAssertFalse(try XCTUnwrap(card.guidance).isEmpty)
        XCTAssertNil(target10.latitude)
        XCTAssertNil(target10.longitude)
    }

    @MainActor
    func testAdaptivePilgrimageLabelsAndApproximateOffsetsRespondToZoom() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let byNumber = Dictionary(uniqueKeysWithValues: places.compactMap { place in place.mapNumber.map { ($0, place) } })
        let presentations = PilgrimageMapProjection.presentations(for: places)
        let byPresentationNumber = Dictionary(uniqueKeysWithValues: presentations.map { ($0.place.mapNumber, $0) })
        let target13 = try XCTUnwrap(byNumber[13])
        let ordinary = PilgrimageMapProjection.labelPriority(
            for: try XCTUnwrap(byPresentationNumber[15]), activeTarget: target13
        )
        let active = PilgrimageMapProjection.labelPriority(
            for: try XCTUnwrap(byPresentationNumber[13]), activeTarget: target13
        )

        XCTAssertFalse(PilgrimageMapProjection.showsNameLabel(priority: ordinary, zoomLevel: 13.0))
        XCTAssertTrue(PilgrimageMapProjection.showsNameLabel(priority: ordinary, zoomLevel: 15.4))
        XCTAssertTrue(PilgrimageMapProjection.showsNameLabel(priority: ordinary, zoomLevel: 17.0))
        XCTAssertTrue(PilgrimageMapProjection.showsNameLabel(priority: active, zoomLevel: 10.0))

        let approximate10 = try XCTUnwrap(byPresentationNumber[10])
        let approximate12 = try XCTUnwrap(byPresentationNumber[12])
        XCTAssertTrue(approximate10.isApproximate)
        XCTAssertTrue(approximate12.isApproximate)
        XCTAssertNil(byNumber[10]?.coordinate)
        XCTAssertNil(byNumber[12]?.coordinate)

        let far10 = PilgrimageMapProjection.approximateOffset(
            index: try XCTUnwrap(approximate10.approximateOffsetIndex), zoomLevel: 13.0
        )
        let close10 = PilgrimageMapProjection.approximateOffset(
            index: try XCTUnwrap(approximate10.approximateOffsetIndex), zoomLevel: 17.0
        )
        let close12 = PilgrimageMapProjection.approximateOffset(
            index: try XCTUnwrap(approximate12.approximateOffsetIndex), zoomLevel: 17.0
        )
        XCTAssertGreaterThan(hypot(close10.dx, close10.dy), hypot(far10.dx, far10.dy))
        XCTAssertGreaterThan(hypot(close10.dx - close12.dx, close10.dy - close12.dy), 90)
        XCTAssertEqual(close10.dx, PilgrimageMapProjection.approximateOffset(index: 0, zoomLevel: 17.0).dx)
        XCTAssertEqual(close10.dy, PilgrimageMapProjection.approximateOffset(index: 0, zoomLevel: 17.0).dy)
        XCTAssertLessThanOrEqual(hypot(
            PilgrimageMapProjection.approximateOffset(index: 0, zoomLevel: 30).dx,
            PilgrimageMapProjection.approximateOffset(index: 0, zoomLevel: 30).dy
        ), 72.000001)
    }

    @MainActor
    func testTask020A13RepositoryLoadsCompleteSeventyOnePlaces() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let places = try repository.pilgrimagePlaces()
        let byNumber = Dictionary(uniqueKeysWithValues: places.compactMap { place in place.mapNumber.map { ($0, place) } })

        for number in 1...71 {
            let place = try XCTUnwrap(byNumber[number])
            let content = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: place.id))
            XCTAssertFalse(content.summary.isEmpty)
            XCTAssertFalse(content.whySacred.isEmpty)
            XCTAssertFalse(content.whatToSee.isEmpty)
            XCTAssertFalse(content.lila.isEmpty)
            XCTAssertFalse(content.pilgrimGuidance.isEmpty)
            XCTAssertFalse(content.references.isEmpty)
            XCTAssertFalse(place.verificationNotes.isEmpty)
        }

        let radhakunda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[1]).id))
        XCTAssertEqual("Supreme sacred kuṇḍa", radhakunda.category)
        XCTAssertEqual(
            [
                "reference.radhakunda.upadesamrta-9-11",
                "reference.radhakunda.radhakundastakam-1",
                "reference.radhakunda.caitanya-caritamrta-madhya-18",
                "reference.radhakunda.govinda-lilamrta-7-102",
                "reference.radhakunda.local-manifestation-story",
            ],
            radhakunda.references.map(\.id)
        )
        XCTAssertEqual(.sourcePassage(SourcePassageID(rawValue: "passage.radha-kundastaka.1")), radhakunda.references[1].destination)
        XCTAssertEqual(.storySection(StorySectionID(rawValue: "story.radhakunda.manifestation")), radhakunda.references[4].destination)

        let kusuma = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[5]).id))
        XCTAssertEqual("Sacred flower-gathering reservoir", kusuma.category)
        XCTAssertFalse(kusuma.summary.isEmpty)
        XCTAssertEqual(4, kusuma.whatToSee.count)
        XCTAssertEqual([6, 7, 8], kusuma.relatedPlaceIDs.compactMap { id in
            places.first { $0.id == id }?.mapNumber
        })

        let uddhava = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[6]).id))
        XCTAssertTrue(uddhava.whatToSee.contains { $0.contains("future map place #69") })
        let asoka = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[7]).id))
        XCTAssertTrue(asoka.references.contains { $0.explanation.contains("exact verse-to-modern-site identification not yet verified") })
        let narada = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[8]).id))
        XCTAssertEqual([5, 6, 7], narada.relatedPlaceIDs.compactMap { id in places.first { $0.id == id }?.mapNumber })
        let ratna = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[9]).id))
        XCTAssertTrue(ratna.references.contains { $0.explanation.contains("geographic association with this modern sacred landscape") })

        let rasa = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[10]).id))
        XCTAssertTrue(rasa.summary.contains("exact modern GPS coordinate remains unverified"))
        XCTAssertTrue(rasa.pilgrimGuidance.contains("exact GPS coordinate has not yet been field verified"))
        XCTAssertEqual([9, 11, 12], rasa.relatedPlaceIDs.compactMap { id in places.first { $0.id == id }?.mapNumber })
        XCTAssertEqual(3, rasa.references.count)
        let rasaPlace = try XCTUnwrap(byNumber[10])
        XCTAssertNil(rasaPlace.latitude)
        XCTAssertNil(rasaPlace.longitude)
        XCTAssertEqual(11, rasaPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)

        let throne = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[11]).id))
        XCTAssertEqual("Sacred throne-place and Śyāmavana shrine", throne.category)
        XCTAssertTrue(throne.whySacred.contains("not proof of this exact modern shrine"))
        XCTAssertEqual([9, 10, 12], throne.relatedPlaceIDs.compactMap { id in places.first { $0.id == id }?.mapNumber })

        let footprintPlace = try XCTUnwrap(byNumber[12])
        let footprint = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: footprintPlace.id))
        XCTAssertNil(footprintPlace.coordinate)
        XCTAssertEqual(11, footprintPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        XCTAssertTrue(footprint.summary.contains("exact modern GPS position"))

        let gvala = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[13]).id))
        XCTAssertTrue(gvala.whySacred.contains("do not name this pond"))

        let santPlace = try XCTUnwrap(byNumber[14])
        let sant = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: santPlace.id))
        XCTAssertNil(santPlace.coordinate)
        XCTAssertEqual(13, santPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        XCTAssertTrue(sant.summary.contains("not a claim that it is an ancient Kṛṣṇa-līlā site"))

        let jugal = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[15]).id))
        XCTAssertTrue(jugal.summary.contains("without inventing a separate yugala-līlā"))

        let mukharavinda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[18]).id))
        XCTAssertTrue(mukharavinda.whatToSee.contains { $0.contains("#61") })
        XCTAssertEqual([19, 20], mukharavinda.relatedPlaceIDs.compactMap { id in places.first { $0.id == id }?.mapNumber })

        let kilola = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[16]).id))
        XCTAssertTrue(kilola.whySacred.contains("Adeeng"))
        let pancaTirtha = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[17]).id))
        XCTAssertTrue(pancaTirtha.whySacred.contains("Gomatī, Narmadā, Sarayū, Vetrī, and Kāñcī"))
        XCTAssertTrue(pancaTirtha.whySacred.contains("Gaṅgā, Puṣkara, Prayāga, Kurukṣetra, and Gayā"))

        let cakraPlace = try XCTUnwrap(byNumber[19])
        XCTAssertEqual("Cakra-tīrtha", cakraPlace.canonicalName)
        XCTAssertEqual(.verified, cakraPlace.coordinateStatus)
        XCTAssertEqual(.high, cakraPlace.coordinateConfidence)
        XCTAssertTrue(cakraPlace.verificationNotes.contains("documented practical arrival point"))
        XCTAssertEqual(
            ["OFFICIAL_OR_INSTITUTIONAL_DOCUMENT", "PILGRIMAGE_GUIDE", "PROJECT_RESEARCH"],
            cakraPlace.provenance.map(\.sourceType)
        )
        let cakra = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: cakraPlace.id))
        XCTAssertTrue(cakra.summary.contains("three closely related features"))
        XCTAssertTrue(cakra.pilgrimGuidance.contains("not the exact coordinate of every feature"))

        let manasiPlace = try XCTUnwrap(byNumber[20])
        XCTAssertEqual(.provisional, manasiPlace.coordinateStatus)
        XCTAssertEqual(.low, manasiPlace.coordinateConfidence)
        let manasi = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: manasiPlace.id))
        XCTAssertTrue(manasi.whySacred.contains("boating pastimes"))
        XCTAssertEqual([18, 19], manasi.relatedPlaceIDs.compactMap { id in places.first { $0.id == id }?.mapNumber })

        let expected: [Int: (Double, Double, CoordinateVerificationStatus, CoordinateConfidence)] = [
            21: (27.4973806, 77.4640917, .verified, .high),
            22: (27.4973694, 77.4645500, .verified, .high),
            23: (27.4968194, 77.4643333, .verified, .high),
            24: (27.4973, 77.4612, .probable, .high),
            25: (27.49419, 77.46617, .probable, .high),
            26: (27.4952417, 77.4628528, .verified, .high),
            27: (27.4949375, 77.4624375, .probable, .high),
            28: (27.4943861, 77.4636611, .verified, .high),
            29: (27.4934375, 77.4613125, .probable, .high),
            30: (27.4690625, 77.4435625, .probable, .high),
            31: (27.4919722, 77.4660000, .probable, .high),
            32: (27.4850625, 77.4558125, .probable, .high),
            33: (27.4779639, 77.4698194, .verified, .high),
            34: (27.4784009, 77.4679575, .probable, .high),
            35: (27.4680694, 77.4471028, .verified, .high),
            36: (27.47443, 77.44584, .probable, .high),
            37: (27.4735625, 77.4437344, .probable, .high),
            39: (27.4725125, 77.4441719, .probable, .high),
            40: (27.4709583, 77.4450222, .verified, .high),
            41: (27.4716875, 77.4425625, .probable, .high),
            42: (27.4686083, 77.4406417, .verified, .high),
            43: (27.4681875, 77.4423125, .probable, .high),
            45: (27.4656875, 77.4368125, .probable, .high),
            48: (27.4588972, 77.4304361, .verified, .high),
            49: (27.4592417, 77.4299333, .verified, .high),
            50: (27.4589625, 77.4286094, .probable, .high),
            51: (27.4585625, 77.4164844, .probable, .high),
            52: (27.4605375, 77.4311406, .probable, .high),
            53: (27.4603875, 77.4307344, .probable, .high),
            54: (27.4655625, 77.4362344, .probable, .high),
            55: (27.4655875, 77.4364219, .probable, .high),
            57: (27.4671250, 77.4362861, .verified, .high),
            58: (27.4746611, 77.4409917, .verified, .high),
            59: (27.4702389, 77.4386778, .verified, .high),
            61: (27.4732917, 77.4425139, .verified, .high),
            62: (27.4742625, 77.4433594, .probable, .high),
            63: (27.4745500, 77.4418800, .probable, .high),
            64: (27.4835125, 77.4311406, .probable, .high),
            65: (27.4865000, 77.4265300, .probable, .high),
            66: (27.4884375, 77.4487344, .probable, .high),
            67: (27.5075500, 77.4301000, .probable, .high),
            68: (27.5197000, 77.4536300, .probable, .high),
            69: (27.5138694, 77.4766528, .verified, .high),
            71: (27.5254125, 77.4891094, .probable, .high),
        ]
        for (number, value) in expected {
            let place = try XCTUnwrap(byNumber[number])
            XCTAssertEqual(value.0, try XCTUnwrap(place.latitude), accuracy: 0.00000001)
            XCTAssertEqual(value.1, try XCTUnwrap(place.longitude), accuracy: 0.00000001)
            XCTAssertEqual(value.2, place.coordinateStatus)
            XCTAssertEqual(value.3, place.coordinateConfidence)
        }

        let brahma = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[21]).id))
        XCTAssertTrue(brahma.summary.contains("Mahāprabhu bathed"))
        let manasiDevi = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[22]).id))
        XCTAssertTrue(manasiDevi.pilgrimGuidance.contains("Mānasī, Manasā, and Mansa"))
        let harideva = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[23]).id))
        XCTAssertTrue(harideva.lila.contains("direct Gauḍīya pilgrimage destination"))
        let townPlace = try XCTUnwrap(byNumber[24])
        XCTAssertTrue(townPlace.verificationNotes.contains("representative map marker"))
        let town = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: townPlace.id))
        XCTAssertTrue(town.pilgrimGuidance.contains("area marker"))
        let rnaPlace = try XCTUnwrap(byNumber[25])
        XCTAssertFalse(rnaPlace.alternateNames.contains { $0.localizedCaseInsensitiveContains("papa") || $0.contains("Pāpa") })
        let rna = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: rnaPlace.id))
        XCTAssertTrue(rna.references[0].explanation.contains("not a canonical śāstric source"))
        XCTAssertTrue(rna.pilgrimGuidance.contains("future #31 Pāpa-mocana-kuṇḍa"))

        let danaGhati = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[26]).id))
        XCTAssertTrue(danaGhati.whySacred.contains("Dāna-keli-cintāmaṇi"))
        let radhaFootprint = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[27]).id))
        XCTAssertTrue(radhaFootprint.whySacred.contains("not a claim that a Gosvāmī text"))
        XCTAssertTrue(try XCTUnwrap(byNumber[28]).verificationNotes.contains("separate same-name temple farther north"))
        let daniRaya = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[29]).id))
        XCTAssertFalse(daniRaya.pilgrimGuidance.localizedCaseInsensitiveContains("climb"))
        XCTAssertTrue(daniRaya.pilgrimGuidance.contains("not permission to step or scramble onto Girirāja"))
        let iskconPlace = try XCTUnwrap(byNumber[30])
        XCTAssertTrue(iskconPlace.verificationNotes.contains("Older pilgrimage literature"))
        let iskcon = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: iskconPlace.id))
        XCTAssertTrue(iskcon.whySacred.contains("not an ancient Kṛṣṇa-līlā-sthalī"))
        XCTAssertNotEqual(byNumber[25]?.id, byNumber[31]?.id)
        XCTAssertNotEqual(byNumber[25]?.coordinate?.latitude, byNumber[31]?.coordinate?.latitude)
        XCTAssertNotEqual(byNumber[26]?.id, byNumber[29]?.id)
        let papaMocana = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[31]).id))
        XCTAssertTrue(papaMocana.summary.contains("distinct from #25"))
        let danaNivartana = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[32]).id))
        XCTAssertTrue(danaNivartana.whySacred.contains("Dāna-nivartana-kuṇḍāṣṭakam"))
        let candra = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[33]).id))
        XCTAssertTrue(candra.lila.contains("separate chronological layer"))
        let parasoliPlace = try XCTUnwrap(byNumber[34])
        XCTAssertTrue(parasoliPlace.verificationNotes.contains("representative marker"))
        let parasoli = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: parasoliPlace.id))
        XCTAssertTrue(parasoli.pilgrimGuidance.contains("representative village and landscape marker"))
        let gauri = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[35]).id))
        XCTAssertEqual(
            ["Bhakti-ratnākara", "Raghunātha Dāsa Gosvāmī — Govardhanāśraya-daśakam", "Rūpa Gosvāmī — Vidagdha-mādhava"],
            gauri.references.map(\.sourceTitle)
        )
        let aniyor = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[36]).id))
        XCTAssertTrue(aniyor.summary.contains("āniaura āniaura"))
        let gopala = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[37]).id))
        XCTAssertTrue(gopala.summary.contains("not proof that the present building"))
        let sivaPlace = try XCTUnwrap(byNumber[38])
        XCTAssertEqual("Śiva Temple", sivaPlace.canonicalName)
        XCTAssertNil(sivaPlace.coordinate)
        XCTAssertEqual(37, sivaPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        let siva = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: sivaPlace.id))
        XCTAssertTrue(siva.pilgrimGuidance.contains("At navigation anchor"))
        let dauji = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[39]).id))
        XCTAssertTrue(dauji.summary.contains("not the large and famous Dauji temple at Baldeo"))
        let sankarsana = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[40]).id))
        XCTAssertTrue(sankarsana.whySacred.contains("Vraja-rīti-cintāmaṇi 3.18"))
        let prakata = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[41]).id))
        XCTAssertTrue(prakata.whySacred.contains("distinct from #37"))
        let govinda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[42]).id))
        XCTAssertTrue(govinda.whySacred.contains("does not itself name this modern water body"))
        let nipa = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[43]).id))
        XCTAssertTrue(nipa.summary.contains("two nearby but distinct physical features"))
        XCTAssertTrue(nipa.whySacred.contains("not currently approved as direct proof"))
        let stop44 = try XCTUnwrap(byNumber[44])
        XCTAssertNil(stop44.coordinate)
        XCTAssertEqual(.unverified, stop44.coordinateStatus)
        XCTAssertEqual(.unknown, stop44.coordinateConfidence)
        XCTAssertEqual(42, stop44.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        let madhavendra = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: stop44.id))
        XCTAssertTrue(madhavendra.pilgrimGuidance.contains("At navigation anchor"))
        let doka = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[45]).id))
        XCTAssertTrue(doka.lila.contains("not being presented as a direct Śrīmad-Bhāgavatam episode"))
        XCTAssertTrue(([prakata, govinda, nipa, madhavendra, doka].flatMap(\.references)).allSatisfy { $0.destination == nil })
        let crownPlace = try XCTUnwrap(byNumber[46])
        XCTAssertNil(crownPlace.coordinate)
        XCTAssertEqual(45, crownPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        let crown = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: crownPlace.id))
        XCTAssertTrue(crown.whySacred.contains("Kṛṣṇa mauli-śilā"))
        XCTAssertTrue(crown.pilgrimGuidance.contains("At navigation anchor"))
        let nrsimhaPlace = try XCTUnwrap(byNumber[47])
        XCTAssertNil(nrsimhaPlace.coordinate)
        XCTAssertEqual(48, nrsimhaPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        let nrsimha = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: nrsimhaPlace.id))
        XCTAssertTrue(nrsimha.whySacred.contains("not this particular Pūñcharī location"))
        XCTAssertFalse(nrsimha.summary.contains("1000 years old"))
        let navaPlace = try XCTUnwrap(byNumber[48])
        XCTAssertEqual("Nava-kuṇḍa", navaPlace.canonicalName)
        XCTAssertTrue(navaPlace.alternateNames.contains("Naval Kund"))
        XCTAssertTrue(navaPlace.alternateNames.contains("Puccha-kuṇḍa"))
        let nava = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: navaPlace.id))
        XCTAssertTrue(nava.references.contains { $0.locus == "BDP_Gvdn_104" })
        let apsara = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[49]).id))
        XCTAssertTrue(apsara.whySacred.contains("Bhakti-ratnākara 5.651"))
        XCTAssertNotEqual(byNumber[48]?.id, byNumber[49]?.id)
        XCTAssertNotEqual(byNumber[48]?.longitude, byNumber[49]?.longitude)
        let lautha = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[50]).id))
        XCTAssertTrue(lautha.whySacred.contains("does not name Lauṭhā Bābā"))
        XCTAssertTrue(([crown, nrsimha, nava, apsara, lautha].flatMap(\.references)).allSatisfy { $0.destination == nil })
        let syamaDhaka = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[51]).id))
        XCTAssertTrue(syamaDhaka.whySacred.contains("Bhakti-ratnākara 5.652"))
        XCTAssertTrue(syamaDhaka.pilgrimGuidance.contains("representative landscape marker"))
        let cave = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[52]).id))
        XCTAssertTrue(cave.summary.contains("later received localization"))
        XCTAssertTrue(cave.pilgrimGuidance.contains("Do not enter a sealed cave"))
        let nathji = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[53]).id))
        XCTAssertTrue(nathji.summary.contains("not the historical Jatipura"))
        let airavata = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[54]).id))
        XCTAssertTrue(airavata.whySacred.contains("Garga-saṁhitā 3.8.10"))
        let indra = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[55]).id))
        XCTAssertTrue(indra.summary.contains("Indra worshiping and surrendering to Kṛṣṇa"))
        XCTAssertNotEqual(byNumber[54]?.id, byNumber[55]?.id)
        XCTAssertNotEqual(byNumber[54]?.coordinate?.latitude, byNumber[55]?.coordinate?.latitude)
        XCTAssertNotEqual(byNumber[54]?.coordinate?.longitude, byNumber[55]?.coordinate?.longitude)
        XCTAssertTrue(([syamaDhaka, cave, nathji, airavata, indra].flatMap(\.references)).allSatisfy { $0.destination == nil })
        let indraKundaPlace = try XCTUnwrap(byNumber[56])
        XCTAssertNil(indraKundaPlace.coordinate)
        XCTAssertEqual(55, indraKundaPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        let indraKunda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: indraKundaPlace.id))
        XCTAssertTrue(indraKunda.whySacred.contains("exact identity with #56 remains unresolved"))
        XCTAssertTrue(indraKunda.pilgrimGuidance.contains("At navigation anchor"))
        let surabhi = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[57]).id))
        XCTAssertTrue(surabhi.references.contains { $0.locus == "BDP_Gvdn_107" })
        XCTAssertTrue(surabhi.pilgrimGuidance.contains("Parmanand Dāsa’s samādhi remains a feature here"))
        let rudraHariju = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[58]).id))
        XCTAssertTrue(rudraHariju.summary.contains("two related but distinct physical water bodies"))
        XCTAssertTrue(rudraHariju.whatToSee.contains { $0.contains("27.4714222, 77.4380889") })
        let airavataKunda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[59]).id))
        XCTAssertTrue(airavataKunda.whySacred.contains("Bhāgavatam names Airāvata-kuṇḍa"))
        let samadhisPlace = try XCTUnwrap(byNumber[60])
        XCTAssertNil(samadhisPlace.coordinate)
        XCTAssertEqual(59, samadhisPlace.navigationAnchorPlaceID.flatMap { id in places.first { $0.id == id } }?.mapNumber)
        let samadhis = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: samadhisPlace.id))
        XCTAssertTrue(samadhis.summary.contains("not one tomb but a memorial landscape"))
        XCTAssertTrue(samadhis.whySacred.contains("Parmanand Dāsa’s samādhi remains at #57"))
        XCTAssertTrue(samadhis.whySacred.contains("future #61"))
        XCTAssertTrue(samadhis.pilgrimGuidance.contains("At navigation anchor"))
        XCTAssertTrue(([indraKunda, surabhi, rudraHariju, airavataKunda, samadhis].flatMap(\.references)).allSatisfy { $0.destination == nil })
        let jatipuraMukharavinda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[61]).id))
        XCTAssertTrue(jatipuraMukharavinda.whatToSee.contains { $0.contains("27.4734125, 77.4425156") })
        XCTAssertTrue(jatipuraMukharavinda.pilgrimGuidance.contains("not #18"))
        XCTAssertTrue(jatipuraMukharavinda.pilgrimGuidance.contains("Do not climb"))
        let dandavat = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[62]).id))
        XCTAssertTrue(dandavat.whySacred.contains("not a scriptural or automatic guarantee"))
        let jatipura = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[63]).id))
        XCTAssertTrue(jatipura.pilgrimGuidance.contains("representative village/area marker"))
        let gulala = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[64]).id))
        XCTAssertTrue(gulala.whySacred.contains("living tradition"))
        let gantholi = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[65]).id))
        XCTAssertTrue(gantholi.summary.contains("temporarily"))
        let gulalaPlace = try XCTUnwrap(byNumber[64])
        XCTAssertTrue(gantholi.relatedPlaceIDs.contains(gulalaPlace.id))
        XCTAssertTrue(([jatipuraMukharavinda, dandavat, jatipura, gulala, gantholi].flatMap(\.references)).allSatisfy { $0.destination == nil })
        let cluster = [61, 62, 63].compactMap { byNumber[$0] }
        XCTAssertEqual(3, Set(cluster.map(\.id)).count)
        let model = PilgrimageMapModel(places: places)
        for number in [61, 62, 63] {
            let place = try XCTUnwrap(byNumber[number])
            model.navigate(to: place)
            XCTAssertEqual(place.id, model.activeDestination.id)
            XCTAssertEqual(place.coordinate?.latitude, model.requestedCenter?.latitude)
            XCTAssertEqual(place.id, GeoMath.nearest(to: try XCTUnwrap(place.coordinate), places: places)?.id)
        }
        XCTAssertNotEqual(byNumber[64]?.id, byNumber[65]?.id)
        let vilachu = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[66]).id))
        XCTAssertTrue(vilachu.pilgrimGuidance.contains("practical arrival point"))
        XCTAssertTrue(vilachu.pilgrimGuidance.contains("not the exact Vilachu-kuṇḍa centroid"))
        XCTAssertTrue(vilachu.lila.contains("living pilgrimage tradition"))
        XCTAssertNotEqual(byNumber[66]?.id, byNumber[23]?.id)
        let sakhi = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[67]).id))
        XCTAssertTrue(sakhi.summary.contains("Bhakti-ratnākara 5.748–752"))
        XCTAssertTrue(sakhi.summary.contains("Candrāvalī"))
        XCTAssertTrue(sakhi.pilgrimGuidance.contains("not direct proof"))
        let nima = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[68]).id))
        XCTAssertTrue(nima.summary.contains("5.778"))
        XCTAssertTrue(nima.whySacred.contains("1841"))
        XCTAssertTrue(nima.whySacred.contains("sectarian tradition"))
        let uddhavaKunda = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[69]).id))
        XCTAssertTrue(uddhavaKunda.summary.contains("10.47.61"))
        XCTAssertTrue(uddhavaKunda.summary.contains("does not name the modern water body"))
        XCTAssertTrue(uddhavaKunda.references.contains { $0.locus == "BDP_Gvdn_123a" })
        XCTAssertNotEqual(byNumber[69]?.id, byNumber[6]?.id)
        let sivaKhariPlace = try XCTUnwrap(byNumber[70])
        XCTAssertNil(sivaKhariPlace.coordinate)
        XCTAssertEqual(.unverified, sivaKhariPlace.coordinateStatus)
        XCTAssertEqual(.unknown, sivaKhariPlace.coordinateConfidence)
        XCTAssertEqual(byNumber[71]?.id, sivaKhariPlace.navigationAnchorPlaceID)
        XCTAssertTrue(sivaKhariPlace.alternateNames.contains("Śivakhora"))
        let sivaKhari = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: sivaKhariPlace.id))
        XCTAssertTrue(sivaKhari.summary.contains("Bhakti-ratnākara 5.587"))
        XCTAssertTrue(sivaKhari.summary.contains("variant"))
        XCTAssertTrue(sivaKhari.pilgrimGuidance.contains("At navigation anchor"))
        let matha = try XCTUnwrap(try repository.pilgrimagePlaceContent(placeID: XCTUnwrap(byNumber[71]).id))
        XCTAssertTrue(matha.summary.contains("Rādhā-kuṇḍa, not Govardhan town"))
        XCTAssertTrue(matha.summary.contains("1934"))
        XCTAssertTrue(matha.summary.contains("04-11-1935"))
        XCTAssertTrue(matha.summary.contains("Śrīman Mahāprabhu"))
        XCTAssertTrue(matha.whySacred.contains("final numbered landmark"))
        XCTAssertTrue(([vilachu, sakhi, nima, uddhavaKunda, sivaKhari, matha].flatMap(\.references)).allSatisfy { $0.destination == nil })
        model.navigate(to: sivaKhariPlace)
        XCTAssertEqual(70, model.activeDestination.mapNumber)
        XCTAssertEqual(71, model.activeNavigationAnchor?.mapNumber)
        XCTAssertEqual(byNumber[71]?.coordinate?.latitude, model.navigationCoordinate?.latitude)
        model.sample = .init(coordinate: try XCTUnwrap(byNumber[71]?.coordinate), horizontalAccuracy: 1,
                             timestamp: Date(timeIntervalSince1970: 123), course: 0, speed: 0)
        XCTAssertEqual(.navigationAnchorArrival, model.arrivalPresentationState)
    }
    private func bundledContentURL() throws -> URL {
        try XCTUnwrap(Bundle.main.url(forResource: "radhakunda-content", withExtension: "sqlite"))
    }

    func testContentDatabaseInitializesAndReadsRealSliceMetadata() throws {
        let content = try ContentDatabase(url: bundledContentURL())
        let repository = SQLiteContentRepository(database: content)

        XCTAssertEqual(
            [StorySummary(id: StoryID(rawValue: "story.radhakunda"), title: "The Story of Śrī Rādhā-kuṇḍa", status: "DEVELOPMENT")],
            try repository.stories()
        )
        let works = try repository.works()
        XCTAssertEqual(8, works.count)
        XCTAssertEqual(
            Set(["work.radha-kundastaka", "work.mathura-mahatmya", "work.radhakunda-manifestation-puranic-unit", "work.srimad-bhagavatam", "work.dana-keli-cintamani", "work.radha-krsna-ganoddesa-dipika", "work.govinda-lilamrta", "work.krishna-bhavanamrita"]),
            Set(works.map(\.id.rawValue))
        )
        XCTAssertFalse(works.contains { $0.id.rawValue == "work.stavavali" })
    }

    func testKrishnaBhavanamritaCompleteEnglishReaderMetadataSearchAndAnchors() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let workID = SourceWorkID(rawValue: "work.krishna-bhavanamrita")
        let targetID = SourcePassageID(rawValue: "passage.krishna-bhavanamrita.kba.ch09.p001")
        let content = try repository.sourceReaderContent(targetPassageID: targetID)

        XCTAssertEqual("Kṛṣṇa-bhāvanāmṛta-mahākāvya", content.work.title)
        XCTAssertEqual("Śrī Viśvanātha Cakravartī Ṭhākura", content.work.author)
        XCTAssertEqual("Translator not identified in supplied file", content.work.preferredEdition.translator)
        XCTAssertEqual(784, content.passages.count)
        XCTAssertEqual(712, content.passages.filter { $0.sectionKind == "CHAPTER" }.count)
        let target = try XCTUnwrap(content.passages.first { $0.id == targetID })
        XCTAssertEqual(9, target.chapterNumber)
        XCTAssertEqual("Flowerplays and Loveplays", target.chapterTitle)
        XCTAssertEqual("10:48 a.m.–3:36 p.m.", target.timeRange)
        XCTAssertNil(target.originalText)
        XCTAssertNil(target.transliteration)
        XCTAssertNotNil(target.translation)
        XCTAssertFalse(content.passages.contains { $0.translation?.contains("sri krishna caitanya ghanam prapadye") == true })
        XCTAssertFalse(try repository.search("Radha", in: workID).isEmpty)
        XCTAssertFalse(try repository.search("Rādhā", in: workID).isEmpty)
    }

    func testNeutralFixtureWitnessMappingOpensExactPDFPageAndPreservesPrintedLabel() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        guard try repository.stories().first?.id == StoryID(rawValue: "story.fixture") else {
            throw XCTSkip("Neutral witness architecture test runs against the fixture database build")
        }
        let mapping = try XCTUnwrap(
            try repository.originalWitnessMapping(passageID: SourcePassageID(rawValue: "passage.fixture.2"))
        )
        XCTAssertEqual(2, mapping.pdfPageIndex)
        XCTAssertEqual("1", mapping.printedPageLabel)
        XCTAssertNotEqual(String(mapping.pdfPageIndex), mapping.printedPageLabel)
        XCTAssertNil(
            try repository.originalWitnessMapping(passageID: SourcePassageID(rawValue: "passage.fixture.1"))
        )
        let url = try XCTUnwrap(Bundle.main.url(forResource: "task012-neutral-witness", withExtension: "pdf"))
        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(3, document.pageCount)
        XCTAssertTrue(try XCTUnwrap(document.page(at: mapping.pdfPageIndex)?.string).contains("Neutral Witness Mapped Page"))
    }

    func testBundledContentDatabaseIsReadOnly() throws {
        let content = try ContentDatabase(url: bundledContentURL())
        XCTAssertThrowsError(
            try content.reader.write { database in
                try database.execute(sql: "INSERT INTO stories(id, title, status) VALUES ('story.write-test', 'Write Test', 'fixture')")
            }
        )
        let repository = SQLiteContentRepository(database: content)
        XCTAssertEqual([StoryID(rawValue: "story.radhakunda")], try repository.stories().map(\.id))
    }

    func testUserStateDatabaseIsSeparateAndWritable() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let userState = try UserStateDatabase(url: directory.appending(path: "user-state.sqlite"))
        try userState.setSetting(key: "fixture.setting", value: "enabled")

        XCTAssertEqual("enabled", try userState.setting(key: "fixture.setting"))
        XCTAssertNotEqual(try bundledContentURL().standardizedFileURL, userState.url.standardizedFileURL)
    }

    func testTypedIdentifiersAndRoutesRemainDistinctAndHashable() {
        let story = StoryID(rawValue: "shared.raw-value")
        let work = SourceWorkID(rawValue: "shared.raw-value")
        XCTAssertEqual("shared.raw-value", story.rawValue)
        XCTAssertEqual("shared.raw-value", work.rawValue)

        let routes: Set<AppRoute> = [.storyTOC(story), .library, .search, .bookmarks]
        XCTAssertEqual(4, routes.count)
    }

    func testStoryReaderLoadsOrderedRealProseBlocksFromDatabase() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let storyID = try XCTUnwrap(try repository.stories().first?.id)
        let section = try XCTUnwrap(try repository.storySections(storyID: storyID).first)
        let blocks = try repository.storyBlocks(sectionID: section.id)

        XCTAssertEqual(
            [
                "rk-manifestation-block-01-dharma-challenge", "rk-manifestation-block-02-krsna-manifests-pond",
                "rk-manifestation-block-03-radha-manifests-pond", "rk-manifestation-block-04-tirthas-petition",
                "rk-manifestation-block-05-waters-join", "rk-manifestation-block-06-krsna-declaration",
                "rk-manifestation-block-07-radha-declaration", "rk-manifestation-block-08-rasa-night"
            ],
            blocks.map(\.id.rawValue)
        )
        XCTAssertEqual(Array(repeating: .paragraph, count: 8), blocks.map(\.type))
        XCTAssertTrue(blocks[0].text.contains("narma-dharmokti-raṅgaiḥ"))
        XCTAssertTrue(blocks[1].text.contains("Bhogavatī"))
    }

    func testStoryCitationRowIsStructuredDatabaseContent() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let rows = try repository.storyCitations(blockID: StoryBlockID(rawValue: "rk-manifestation-block-01-dharma-challenge"))
        XCTAssertEqual(3, rows.count)
        XCTAssertEqual(
            .range(
                start: SourcePassageID(rawValue: "passage.radhakunda-manifestation-puranic-unit.1"),
                end: SourcePassageID(rawValue: "passage.radhakunda-manifestation-puranic-unit.2")
            ),
            rows.first?.target
        )
        XCTAssertEqual("Twenty-Verse Rādhā-kuṇḍa Manifestation Account Verses 1–2", rows.first?.label)
        let singleton = try XCTUnwrap(rows.first { $0.id.rawValue == "citation.rk.manifestation.rka.1.challenge" })
        XCTAssertEqual(.singleton(SourcePassageID(rawValue: "passage.radha-kundastaka.1")), singleton.target)
        XCTAssertEqual("Śrī Rādhā-kuṇḍāṣṭakam Verse 1", singleton.label)
        XCTAssertEqual(SourcePassageID(rawValue: "passage.radha-kundastaka.1"), singleton.passageID)
        let background = try XCTUnwrap(rows.first { $0.id.rawValue == "citation.rk.manifestation.sb.10.36.1-15" })
        XCTAssertEqual(
            .range(
                start: SourcePassageID(rawValue: "passage.srimad-bhagavatam.10.36.1"),
                end: SourcePassageID(rawValue: "passage.srimad-bhagavatam.10.36.15")
            ),
            background.target
        )
        XCTAssertEqual("Śrīmad-Bhāgavatam Verses 1–15", background.label)
        XCTAssertEqual(SourcePassageID(rawValue: "passage.srimad-bhagavatam.10.36.1"), background.passageID)
    }

    func testAllAuthoredRKMARangesSurviveRepositoryWithCompleteLabels() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let expectations: [(String, String, String, String)] = [
            ("rk-manifestation-block-01-dharma-challenge", "1", "2", "Verses 1–2"),
            ("rk-manifestation-block-02-krsna-manifests-pond", "3", "6", "Verses 3–6"),
            ("rk-manifestation-block-03-radha-manifests-pond", "7", "10", "Verses 7–10"),
            ("rk-manifestation-block-04-tirthas-petition", "11", "16", "Verses 11–16"),
        ]
        for (blockID, start, end, label) in expectations {
            let rows = try repository.storyCitations(blockID: StoryBlockID(rawValue: blockID))
            let range = try XCTUnwrap(rows.first { if case .range = $0.target { return true }; return false })
            XCTAssertEqual(
                .range(
                    start: SourcePassageID(rawValue: "passage.radhakunda-manifestation-puranic-unit.\(start)"),
                    end: SourcePassageID(rawValue: "passage.radhakunda-manifestation-puranic-unit.\(end)")
                ),
                range.target
            )
            XCTAssertTrue(range.label.hasSuffix(label))
            XCTAssertEqual(SourcePassageID(rawValue: "passage.radhakunda-manifestation-puranic-unit.\(start)"), range.passageID)
        }
    }

    func testCitationResolverTargetsExactCanonicalPassage() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        XCTAssertEqual(
            SourcePassageID(rawValue: "passage.radha-kundastaka.1"),
            try repository.resolveCitation(citationID: CitationID(rawValue: "citation.rk.manifestation.rka.1.challenge"))
        )
    }

    func testSourceReaderUsesPreferredEditionAndLoadsAdjacentPassages() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let targetID = SourcePassageID(rawValue: "passage.radha-kundastaka.1")
        let content = try repository.sourceReaderContent(targetPassageID: targetID)

        XCTAssertEqual(targetID, content.targetPassageID)
        XCTAssertEqual("Śrī Rādhā-kuṇḍāṣṭakam", content.work.title)
        XCTAssertEqual("Govardhana Pilgrimage Project Reading Edition", content.work.preferredEdition.title)
        XCTAssertEqual(8, content.passages.count)
        XCTAssertTrue(content.passages[0].transliteration?.contains("narma-dharmokti-raṅgair") == true)
        XCTAssertTrue(content.passages[0].translation?.contains("Queen of Vṛndāvana") == true)
        XCTAssertNil(try repository.originalWitnessMapping(passageID: targetID))
    }

    func testTranslationProvenanceIsAvailableInSourceDetails() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let content = try repository.sourceReaderContent(
            targetPassageID: SourcePassageID(rawValue: "passage.radha-kundastaka.1")
        )
        XCTAssertEqual("Govardhana Pilgrimage Project", content.work.preferredEdition.translator)
        XCTAssertTrue(content.work.preferredEdition.translationProvenance?.contains("APPROVED_PROJECT") == true)
    }

    func testWorkingTranslationStatusAndAuthorizedVerse14ReadingNoteAreSurfaced() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let content = try repository.sourceReaderContent(
            targetPassageID: SourcePassageID(rawValue: "passage.radhakunda-manifestation-puranic-unit.14")
        )
        let passage = try XCTUnwrap(content.passages.first { $0.id.rawValue.hasSuffix(".14") })
        XCTAssertEqual("VERIFIED", passage.verificationStatus)
        XCTAssertEqual("WORKING_PROJECT", passage.translationStatus)
        XCTAssertTrue(passage.readingNote?.contains("tat-pārṣṇi-ghāṭa-kṛta") == true)
        XCTAssertTrue(passage.readingNote?.contains("tat-pārṣṇi-ghāta-kṛta") == true)
        XCTAssertTrue(passage.readingNote?.contains("APP_READY") == true)
    }

    func testLibraryLoadsCanonicalWorkFromBeginningWithPassageTOC() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let workID = SourceWorkID(rawValue: "work.radha-kundastaka")
        let content = try repository.sourceReaderContent(workID: workID)

        XCTAssertEqual("Śrī Raghunātha dāsa Gosvāmī", content.work.author)
        XCTAssertEqual("A_PRIMARY_GOSVAMI", content.work.sourceLayer)
        XCTAssertEqual(SourcePassageID(rawValue: "passage.radha-kundastaka.1"), content.targetPassageID)
        XCTAssertEqual((1...8).map { "Verse \($0)" }, content.passages.map(\.displayLocus))
    }

    func testSrimadBhagavatamReaderProvidesNativeScriptAndSixteenOrderedPassages() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let content = try repository.sourceReaderContent(workID: SourceWorkID(rawValue: "work.srimad-bhagavatam"))
        XCTAssertEqual("Śrīmad-Bhāgavatam", content.work.title)
        XCTAssertEqual(16, content.passages.count)
        XCTAssertEqual((1...16).map { "10.36.\($0)" }, content.passages.map(\.displayLocus))
        XCTAssertTrue(content.passages[0].originalText?.contains("श्री बादरायणिरुवाच") == true)
        XCTAssertTrue(content.passages[0].transliteration?.contains("atha tarhy āgato goṣṭham") == true)
        XCTAssertEqual("WORKING_PROJECT", content.passages[0].translationStatus)
    }

    func testDanaKeliCintamaniUsesGenericLibraryReaderAndSearchForAll175Verses() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let workID = SourceWorkID(rawValue: "work.dana-keli-cintamani")
        let matchingWorks = try repository.works().filter { $0.id == workID }
        XCTAssertEqual(1, matchingWorks.count)

        let content = try repository.sourceReaderContent(workID: workID)
        XCTAssertEqual("Śrī Dāna-keli-cintāmaṇi", content.work.title)
        XCTAssertEqual("Śrī Raghunātha dāsa Gosvāmī", content.work.author)
        XCTAssertEqual("A_PRIMARY_GOSVAMI", content.work.sourceLayer)
        XCTAssertEqual("Govardhana Pilgrimage Project Reading Edition", content.work.preferredEdition.title)
        XCTAssertEqual(175, content.passages.count)
        XCTAssertEqual((1...175).map { "Verse \($0)" }, content.passages.map(\.displayLocus))
        XCTAssertEqual(SourcePassageID(rawValue: "passage.dana-keli-cintamani.1"), content.targetPassageID)
        XCTAssertEqual(SourcePassageID(rawValue: "passage.dana-keli-cintamani.175"), content.passages.last?.id)
        XCTAssertTrue(content.passages.allSatisfy { $0.transliteration?.isEmpty == false })
        XCTAssertTrue(content.passages.allSatisfy { $0.translation?.isEmpty == false })
        XCTAssertTrue(content.passages.allSatisfy { $0.translationStatus == "WORKING_PROJECT" })

        let sanskritResults = try repository.search("uddāma", in: workID)
        let englishResults = try repository.search("pollen", in: workID)
        XCTAssertTrue(sanskritResults.contains { result in
            if case let .source(_, resultWorkID) = result.target { return resultWorkID == workID }
            return false
        })
        XCTAssertTrue(englishResults.contains { result in
            if case let .source(_, resultWorkID) = result.target { return resultWorkID == workID }
            return false
        })
    }

    func testGlobalFTSSearchReturnsTypedStoryAndSourceResultsWithSnippets() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let results = try repository.search("narma-dharmokti", in: nil)

        XCTAssertEqual(2, results.count)
        XCTAssertTrue(results.allSatisfy { $0.snippet.contains("‹narma-dharmokti›") })
        XCTAssertTrue(results.contains {
            $0.target == .story(
                storyID: StoryID(rawValue: "story.radhakunda"),
                sectionID: StorySectionID(rawValue: "story.radhakunda.manifestation"),
                blockID: StoryBlockID(rawValue: "rk-manifestation-block-01-dharma-challenge")
            )
        })
        XCTAssertTrue(results.contains {
            $0.target == .source(
                passageID: SourcePassageID(rawValue: "passage.radha-kundastaka.1"),
                workID: SourceWorkID(rawValue: "work.radha-kundastaka")
            )
        })
    }

    func testWorkScopedFTSSearchExcludesStoryResults() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let workID = SourceWorkID(rawValue: "work.radha-kundastaka")
        let results = try repository.search("rādhā-kuṇḍam", in: workID)

        XCTAssertEqual(8, results.count)
        XCTAssertTrue(results.allSatisfy {
            if case let .source(_, resultWorkID) = $0.target { return resultWorkID == workID }
            return false
        })
    }

    func testFTSUsesCompiledUnicodeTokenizerWithoutRuntimeNormalization() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let results = try repository.search("Rādhā", in: nil)

        XCTAssertTrue(results.contains { if case .story = $0.target { return true }; return false })
        XCTAssertTrue(results.contains { if case .source = $0.target { return true }; return false })
    }

    func testMissingCitationAndPassageFailSafely() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        XCTAssertThrowsError(
            try repository.resolveCitation(citationID: CitationID(rawValue: "citation.fixture.missing"))
        )
        XCTAssertThrowsError(
            try repository.sourceReaderContent(targetPassageID: SourcePassageID(rawValue: "passage.fixture.missing"))
        )
    }

    @MainActor
    func testSourceExcursionTracksCurrentPassageAndReturnsTypedPathToExactOrigin() throws {
        let model = AppModel()
        let origin = StoryOrigin(
            storyID: StoryID(rawValue: "story.fixture"),
            sectionID: StorySectionID(rawValue: "section.fixture.opening"),
            blockID: StoryBlockID(rawValue: "block.fixture.opening"),
            citationID: CitationID(rawValue: "citation.fixture.opening")
        )
        let excursion = SourceExcursion(
            origin: origin,
            citedPassageID: SourcePassageID(rawValue: "passage.fixture.2"),
            currentPassageID: SourcePassageID(rawValue: "passage.fixture.2")
        )
        model.navigationPath = [
            .storyTOC(origin.storyID),
            .storySection(storyID: origin.storyID, sectionID: origin.sectionID, blockID: origin.blockID),
            .sourcePassage(excursion),
        ]

        model.beginSourceExcursion(excursion)
        model.updateSourceExcursion(currentPassageID: SourcePassageID(rawValue: "passage.fixture.3"))
        XCTAssertEqual(SourcePassageID(rawValue: "passage.fixture.3"), model.sourceExcursion?.currentPassageID)
        XCTAssertEqual(origin.citationID, model.sourceExcursion?.origin.citationID)

        model.returnToStory(from: excursion)
        XCTAssertNil(model.sourceExcursion)
        XCTAssertEqual(
            [
                .storyTOC(origin.storyID),
                .storySection(storyID: origin.storyID, sectionID: origin.sectionID, blockID: origin.blockID),
            ],
            model.navigationPath
        )
        XCTAssertEqual(
            StoryReadingPosition(storyID: origin.storyID, sectionID: origin.sectionID, blockID: origin.blockID),
            model.storyPosition
        )
    }

    func testSemanticStoryPositionSurvivesDatabaseRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "user-state.sqlite")
        let expected = StoryReadingPosition(
            storyID: StoryID(rawValue: "story.fixture"),
            sectionID: StorySectionID(rawValue: "section.fixture.opening"),
            blockID: StoryBlockID(rawValue: "block.fixture.verse")
        )

        try UserStateDatabase(url: url).saveStoryPosition(expected)
        XCTAssertEqual(expected, try UserStateDatabase(url: url).storyPosition(storyID: expected.storyID))
    }

    func testIndependentWorkPositionSurvivesDatabaseRelaunchAndDoesNotReplaceStoryState() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "user-state.sqlite")
        let workPosition = WorkReadingPosition(
            workID: SourceWorkID(rawValue: "work.fixture"),
            passageID: SourcePassageID(rawValue: "passage.fixture.3")
        )
        let storyPosition = StoryReadingPosition(
            storyID: StoryID(rawValue: "story.fixture"),
            sectionID: StorySectionID(rawValue: "section.fixture.opening"),
            blockID: StoryBlockID(rawValue: "block.fixture.opening")
        )

        let firstSession = try UserStateDatabase(url: url)
        try firstSession.saveStoryPosition(storyPosition)
        try firstSession.saveWorkPosition(workPosition)

        let reopened = try UserStateDatabase(url: url)
        XCTAssertEqual(workPosition, try reopened.workPosition(workID: workPosition.workID))
        XCTAssertEqual(storyPosition, try reopened.storyPosition(storyID: storyPosition.storyID))
    }

    func testStoryAndSourceBookmarksCreateRemoveAndSurviveDatabaseRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "user-state.sqlite")
        let storyTarget = BookmarkTarget.story(
            StoryReadingPosition(
                storyID: StoryID(rawValue: "story.fixture"),
                sectionID: StorySectionID(rawValue: "section.fixture.opening"),
                blockID: StoryBlockID(rawValue: "block.fixture.following")
            )
        )
        let sourceTarget = BookmarkTarget.source(SourcePassageID(rawValue: "passage.fixture.3"))

        let firstSession = try UserStateDatabase(url: url)
        try firstSession.saveBookmark(storyTarget)
        try firstSession.saveBookmark(sourceTarget)
        try firstSession.saveBookmark(storyTarget)

        let reopened = try UserStateDatabase(url: url)
        XCTAssertEqual(Set([storyTarget, sourceTarget]), Set(try reopened.bookmarks().map(\.target)))
        XCTAssertEqual(2, try reopened.bookmarks().count)

        try reopened.removeBookmark(storyTarget)
        XCTAssertEqual([sourceTarget], try UserStateDatabase(url: url).bookmarks().map(\.target))
        try reopened.removeBookmark(sourceTarget)
        XCTAssertTrue(try reopened.bookmarks().isEmpty)
    }

    func testPeopleRepositoryUsesOneCanonicalPersonAndExactSourceTargets() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        let people = try repository.people()
        XCTAssertEqual(1, people.count)
        let person = try XCTUnwrap(people.first)
        XCTAssertEqual("person.lalita-sakhi", person.id.rawValue)
        XCTAssertEqual(.vrajaAssociate, person.kind)
        let sections = try repository.personSections(personID: person.id)
        XCTAssertEqual(9, sections.count)
        for section in sections {
            XCTAssertFalse(try repository.personBlocks(sectionID: section.id).isEmpty)
        }
        let blocks = try sections.flatMap { try repository.personBlocks(sectionID: $0.id) }
        XCTAssertEqual(14, blocks.count)
        XCTAssertEqual(22, blocks.flatMap(\.citations).count)
        XCTAssertTrue(try repository.personPlaceRelationships(personID: person.id).isEmpty)
        let first = try XCTUnwrap(blocks.first)
        XCTAssertEqual(
            .range(start: SourcePassageID(rawValue: "passage.radha-krsna-ganoddesa-dipika.79"),
                   end: SourcePassageID(rawValue: "passage.radha-krsna-ganoddesa-dipika.80")),
            first.citations.first?.target
        )
        let source = try repository.sourceReaderContent(targetPassageID: SourcePassageID(rawValue: "passage.radha-krsna-ganoddesa-dipika.79"))
        XCTAssertEqual(16, source.passages.count)
        XCTAssertNotNil(source.passages.first?.translation)
        XCTAssertTrue(source.work.preferredEdition.translationProvenance?.contains("Gauḍīya Vedānta Publications") == true)
        let episode = try repository.sourceReaderContent(targetPassageID: SourcePassageID(rawValue: "passage.govinda-lilamrta.5.78"))
        XCTAssertEqual(1, episode.passages.count)
        XCTAssertEqual("WORKING_PROJECT", episode.passages.first?.translationStatus)
    }

    func testPeopleAliasesSearchAsOneCanonicalResultAndWorkScopeExcludesPeople() throws {
        let repository = SQLiteContentRepository(database: try ContentDatabase(url: bundledContentURL()))
        for alias in ["Lalita", "Lalitā", "Lalitā-devī", "Anurādhā"] {
            let people = try repository.search(alias, in: nil).filter {
                if case .person = $0.target { return true }
                return false
            }
            XCTAssertEqual(1, people.count, "Alias \(alias) should yield one Person result")
            XCTAssertEqual(.person(PersonID(rawValue: "person.lalita-sakhi")), people.first?.target)
        }
        let scoped = try repository.search("Lalitā", in: SourceWorkID(rawValue: "work.radha-krsna-ganoddesa-dipika"))
        XCTAssertFalse(scoped.contains { if case .person = $0.target { return true }; return false })
    }

    @MainActor
    func testPersonSourceExcursionReturnsToExactSemanticBlock() throws {
        let model = AppModel()
        let position = PersonReadingPosition(personID: PersonID(rawValue: "person.lalita-sakhi"),
                                             sectionID: PersonSectionID(rawValue: "person-section.lalita.names"),
                                             blockID: PersonBlockID(rawValue: "person-block.lalita.technical-terms"))
        let passage = SourcePassageID(rawValue: "passage.radha-krsna-ganoddesa-dipika.81")
        let excursion = PersonSourceExcursion(origin: position,
                                              citationID: CitationID(rawValue: "citation.person.lalita.technical-terms"),
                                              citedPassageID: passage, currentPassageID: passage)
        model.navigationPath = [.people, .person(personID: position.personID, blockID: position.blockID),
                                .personSource(excursion)]
        model.beginPersonSourceExcursion(excursion)
        model.updatePersonSourceExcursion(currentPassageID: SourcePassageID(rawValue: "passage.radha-krsna-ganoddesa-dipika.82"))
        XCTAssertEqual("passage.radha-krsna-ganoddesa-dipika.82", model.personSourceExcursion?.currentPassageID.rawValue)
        model.returnToPerson(from: excursion)
        XCTAssertEqual(position, model.personPositions[position.personID])
        XCTAssertEqual([.people, .person(personID: position.personID, blockID: position.blockID)], model.navigationPath)
    }

    func testPersonPositionAndBookmarkSurviveColdUserStateRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "user-state.sqlite")
        let position = PersonReadingPosition(personID: PersonID(rawValue: "person.lalita-sakhi"),
                                             sectionID: PersonSectionID(rawValue: "person-section.lalita.services"),
                                             blockID: PersonBlockID(rawValue: "person-block.lalita.supervision"))
        let first = try UserStateDatabase(url: url)
        try first.savePersonPosition(position)
        try first.saveBookmark(.person(position))
        let reopened = try UserStateDatabase(url: url)
        XCTAssertEqual(position, try reopened.personPosition(personID: position.personID))
        XCTAssertEqual([.person(position)], try reopened.bookmarks().map(\.target))
        try reopened.removeBookmark(.person(position))
        XCTAssertTrue(try UserStateDatabase(url: url).bookmarks().isEmpty)
    }

    func testVedabasePageBookmarksSurviveRelaunchAndStaySeparateFromContent() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let databaseURL = directory.appending(path: "user-state.sqlite")
        let pageURL = try XCTUnwrap(URL(string: "https://vedabase.io/en/library/bg/10/17/"))
        let unsafeURL = try XCTUnwrap(URL(string: "https://example.com/en/library/bg/10/17/"))
        XCTAssertTrue(VedabaseBookmarkRecord.isBookmarkable(pageURL))
        XCTAssertTrue(VedabaseBookmarkRecord.isBookmarkable(URL(string: "https://vedabase.io/en/library/")!))
        XCTAssertFalse(VedabaseBookmarkRecord.isBookmarkable(unsafeURL))

        let firstSession = try UserStateDatabase(url: databaseURL)
        try firstSession.saveVedabaseBookmark(url: pageURL, title: "Bg. 10.17")
        try firstSession.saveVedabaseBookmark(url: pageURL, title: "Bhagavad-gītā 10.17")
        XCTAssertThrowsError(try firstSession.saveVedabaseBookmark(url: unsafeURL, title: "Not Vedabase"))

        let reopened = try UserStateDatabase(url: databaseURL)
        let records = try reopened.vedabaseBookmarks()
        XCTAssertEqual(1, records.count)
        XCTAssertEqual(pageURL, records.first?.url)
        XCTAssertEqual("Bhagavad-gītā 10.17", records.first?.title)
        XCTAssertTrue(try reopened.bookmarks().isEmpty)
        try reopened.removeVedabaseBookmark(url: pageURL)
        XCTAssertTrue(try UserStateDatabase(url: databaseURL).vedabaseBookmarks().isEmpty)
    }

    func testUserStateOperationsDoNotMutateGeneratedContentDatabase() throws {
        let contentURL = try bundledContentURL()
        let contentBefore = try Data(contentsOf: contentURL)
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let userState = try UserStateDatabase(url: directory.appending(path: "user-state.sqlite"))

        try userState.saveBookmark(.source(SourcePassageID(rawValue: "passage.fixture.2")))
        try userState.saveVedabaseBookmark(
            url: try XCTUnwrap(URL(string: "https://vedabase.io/en/library/bg/10/17/")),
            title: "Bg. 10.17"
        )
        try userState.saveWorkPosition(
            WorkReadingPosition(
                workID: SourceWorkID(rawValue: "work.fixture"),
                passageID: SourcePassageID(rawValue: "passage.fixture.3")
            )
        )

        XCTAssertEqual(contentBefore, try Data(contentsOf: contentURL))
        XCTAssertNotEqual(contentURL.standardizedFileURL, userState.url.standardizedFileURL)
    }

    @MainActor
    func testLiveAppContainerInitializes() throws {
        let container = try AppContainer.live()
        XCTAssertEqual("The Story of Śrī Rādhā-kuṇḍa", try container.contentRepository.stories().first?.title)
        XCTAssertEqual(8, try container.contentRepository.works().count)
        XCTAssertTrue(container.userStateDatabase.url.lastPathComponent == "user-state.sqlite")
    }
}
