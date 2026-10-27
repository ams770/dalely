import Foundation
import MapKit

@Observable
final class PlaceSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()

    var query: String = "" {
        didSet {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                results = []
                completer.queryFragment = ""
            } else {
                completer.queryFragment = query
            }
        }
    }

    var results: [MKLocalSearchCompletion] = []
    var isSearching = false

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
        self.isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.isSearching = false
    }

    func resolveCoordinate(for completion: MKLocalSearchCompletion) async -> CLLocationCoordinate2D? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            return nil
        }
    }
}
