import Foundation
import CoreLocation

class ConcreteEventRepository: EventRepository {
    private let geocoder: CLGeocoder
    private let urlProvider: URLProvider
    private let jsonClient: JSONClient
    private let eventDeserializer: EventDeserializer
    private let operationQueue: NSOperationQueue

    init(
        geocoder: CLGeocoder,
        urlProvider: URLProvider,
        jsonClient: JSONClient,
        eventDeserializer: EventDeserializer,
        operationQueue: NSOperationQueue) {
            self.geocoder = geocoder
            self.urlProvider = urlProvider
            self.jsonClient = jsonClient
            self.eventDeserializer = eventDeserializer
            self.operationQueue = operationQueue
    }


    func fetchEventsWithZipCode(zipCode: String, radiusMiles: Float, completion: (EventSearchResult) -> Void, error: (NSError) -> Void) {
        self.geocoder.geocodeAddressString(zipCode, completionHandler: { (placemarks, geocodingError) -> Void in
            if geocodingError != nil {
                error(geocodingError!)
                return
            }

            let placemark = placemarks!.first!
            let location = placemark.location!

            let url = self.urlProvider.eventsURL()

            let HTTPBodyDictionary = self.HTTPBodyDictionaryWithLatitude(
                location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radiusMiles: radiusMiles)

            let eventsFuture = self.jsonClient.JSONPromiseWithURL(url, method: "POST", bodyDictionary: HTTPBodyDictionary)

            eventsFuture.onSuccess(callback: { (deserializedObject) -> Void in
                guard let jsonDictionary = deserializedObject as? NSDictionary else {
                    let incorrectObjectTypeError = NSError(domain: "ConcreteEventRepository", code: -1, userInfo: nil)

                    self.operationQueue.addOperationWithBlock({ () -> Void in error(incorrectObjectTypeError) })
                    return
                }

                let parsedEvents = self.eventDeserializer.deserializeEvents(jsonDictionary)
                let eventSearchResult = EventSearchResult(searchCentroid: location, events: parsedEvents)
                self.operationQueue.addOperationWithBlock({ () -> Void in completion(eventSearchResult) })
            }).onFailure(callback: { (receivedError) -> Void in
                self.operationQueue.addOperationWithBlock({ () -> Void in error(receivedError) })
            })
        })
    }

    // MARK: Private

    func HTTPBodyDictionaryWithLatitude(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radiusMiles: Float) -> NSDictionary {
        return [
            "sort": [

                [
                "event_date" : [
                    "order" : "asc"
                ]],

                ["_geo_distance": [
                    "location": [
                        "lat":  latitude,
                        "lon": longitude
                    ],
                    "order":         "asc",
                    "unit":          "mi",
                    "distance_type": "plane"
                ]
                    ]
            ],

            "from": 0, "size": 30,
            "_source": ["venue", "name", "timezone", "start_time", "url", "capacity", "attendee_count", "event_type_name", "description", "url"],
            "query": [
                "filtered": [
                    "query": [
                        "match_all": []
                    ],
                    "filter": [
                        "bool": [
                            "must": self.filterConditions(latitude, longitude: longitude, radiusMiles: radiusMiles)
                        ]
                    ]
                ]
            ]

        ]
    }

    func filterConditions(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radiusMiles: Float) -> Array<AnyObject> {
        return [
            [
                "range": [
                    "event_date": [
                        "lte": "now+6M/d",
                        "gte": "now"
                    ]
                ]
            ],
            [
                "geo_distance": [
                    "distance": "\(radiusMiles)mi",
                    "location": [
                        "lat": latitude,
                        "lon": longitude
                    ]
                ]
            ]
        ]
    }
}
