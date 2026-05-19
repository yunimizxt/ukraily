import Foundation

struct GetDepartureBoardResponse {
    let generatedAt: Date
    let locationName: String
    let crs: String
    let services: [ServiceSummary]

    struct ServiceSummary {
        let serviceID: String
        let serviceType: String
        let operatorName: String
        let scheduledDeparture: String    // "HH:mm"
        let estimatedDeparture: String?   // "HH:mm" or "On time" or "Delayed" or "Cancelled"
        let platform: String?
        let isCancelled: Bool
        let originName: String
        let destinationName: String
        let destinationCRS: String?
    }
}

struct GetServiceDetailsResponse {
    let generatedAt: Date
    let serviceID: String
    let operatorName: String
    let platform: String?
    let isCancelled: Bool
    let callingPoints: [CallingPointDetail]

    struct CallingPointDetail {
        let stationName: String
        let crs: String?
        let scheduledTime: String   // "HH:mm"
        let estimatedTime: String?
        let actualTime: String?
        let platform: String?
        let isCancelled: Bool
    }
}
