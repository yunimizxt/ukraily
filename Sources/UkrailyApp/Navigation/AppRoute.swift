import Foundation
import UkrailyCore

enum AppRoute: Hashable {
    case departureBoard(crs: String, name: String)
    case journeySearch(originCRS: String, destinationCRS: String)
    case trainCard(serviceID: String)
    case trackedJourneys
    case settings
}
