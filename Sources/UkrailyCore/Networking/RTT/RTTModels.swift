import Foundation

// MARK: - Location / Departures response

struct RTTLocationResponse: Codable {
    let location: RTTLocation
    let services: [RTTService]?
}

struct RTTLocation: Codable {
    let name: String
    let crs: String?
}

struct RTTService: Codable {
    let locationDetail: RTTLocationDetail
    let serviceUid: String
    let runDate: String
    let atocCode: String?
    let atocName: String?
    let origin: [RTTEndpoint]?
    let destination: [RTTEndpoint]?
    let isPassenger: Bool?
}

struct RTTLocationDetail: Codable {
    let gbttBookedDeparture: String?
    let realtimeDeparture: String?
    let realtimeDepartureActual: Bool?
    let gbttBookedArrival: String?
    let realtimeArrival: String?
    let platform: String?
    let platformConfirmed: Bool?
    let cancelReasonCode: String?
    let cancelReasonShortText: String?
    let displayAs: String?
}

struct RTTEndpoint: Codable {
    let tiploc: String?
    let description: String?
    let publicTime: String?
    let workingTime: String?
}

// MARK: - Service details response

struct RTTServiceResponse: Codable {
    let serviceUid: String
    let runDate: String
    let atocCode: String?
    let atocName: String?
    let origin: [RTTEndpoint]?
    let destination: [RTTEndpoint]?
    let locations: [RTTServiceLocation]?
}

struct RTTServiceLocation: Codable {
    let tiploc: String?
    let description: String?
    let crs: String?
    let gbttBookedArrival: String?
    let gbttBookedDeparture: String?
    let realtimeArrival: String?
    let realtimeDeparture: String?
    let realtimeArrivalActual: Bool?
    let realtimeDepartureActual: Bool?
    let platform: String?
    let platformConfirmed: Bool?
    let cancelReasonCode: String?
    let displayAs: String?
    let isCall: Bool?
    let isPublicCall: Bool?
}
