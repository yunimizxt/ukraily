import Foundation

final class DarwinSOAPResponseParser: NSObject, XMLParserDelegate {

    // MARK: - State

    private enum ParseMode {
        case idle
        case departureBoardServices
        case serviceDetails
    }

    private var mode: ParseMode = .idle
    private var currentElement = ""
    private var currentText = ""

    // Shared fields during parse
    private var generatedAt = ""
    private var locationName = ""
    private var locationCRS = ""

    // Departure board accumulation
    private var services: [GetDepartureBoardResponse.ServiceSummary] = []
    private var serviceID = ""
    private var serviceType = ""
    private var operatorName = ""
    private var scheduledDep = ""
    private var estimatedDep: String? = nil
    private var platform: String? = nil
    private var isCancelled = false
    private var originName = ""
    private var destinationName = ""
    private var destinationCRS: String? = nil
    private var inServiceList = false
    private var inService = false
    private var inDestination = false

    // Service detail accumulation
    private var callingPoints: [GetServiceDetailsResponse.CallingPointDetail] = []
    private var cpStationName = ""
    private var cpCRS: String? = nil
    private var cpScheduled = ""
    private var cpEstimated: String? = nil
    private var cpActual: String? = nil
    private var cpPlatform: String? = nil
    private var cpCancelled = false
    private var inCallingPoint = false
    private var inCallingPointList = false

    // MARK: - Results

    private(set) var departureBoardResult: GetDepartureBoardResponse?
    private(set) var serviceDetailsResult: GetServiceDetailsResponse?
    private(set) var parseError: Error?

    // MARK: - Parse entry points

    func parseDepartureBoard(data: Data) throws -> GetDepartureBoardResponse {
        mode = .departureBoardServices
        try runParser(data: data)
        guard let result = departureBoardResult else {
            throw DarwinParseError.missingElement("GetDepartureBoardResult")
        }
        return result
    }

    func parseServiceDetails(data: Data) throws -> GetServiceDetailsResponse {
        mode = .serviceDetails
        try runParser(data: data)
        guard let result = serviceDetailsResult else {
            throw DarwinParseError.missingElement("GetServiceDetailsResult")
        }
        return result
    }

    private func runParser(data: Data) throws {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let error = parseError { throw error }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "lt8:trainServices", "lt7:trainServices":
            inServiceList = true
        case "lt8:service", "lt7:service":
            guard inServiceList else { break }
            inService = true
            resetServiceAccumulators()
        case "lt8:destination", "lt7:destination":
            inDestination = true
        case "lt8:callingPoints", "lt7:callingPoints":
            inCallingPointList = true
        case "lt8:callingPoint", "lt7:callingPoint":
            guard inCallingPointList else { break }
            inCallingPoint = true
            resetCallingPointAccumulators()
        default:
            break
        }

        if let sid = attributeDict["serviceID"] {
            serviceID = sid
        }
        if let st = attributeDict["serviceType"] {
            serviceType = st
        }
        if let cancelled = attributeDict["isCancelled"], cancelled == "true" {
            if inCallingPoint { cpCancelled = true } else { isCancelled = true }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {

        // --- Shared ---
        case "lt8:generatedAt", "lt7:generatedAt":
            generatedAt = text
        case "lt8:locationName", "lt7:locationName":
            if !inService && !inCallingPoint { locationName = text }
        case "lt8:crs", "lt7:crs":
            if !inService && !inCallingPoint { locationCRS = text }

        // --- Service summary fields ---
        case "lt8:std", "lt7:std":
            scheduledDep = text
        case "lt8:etd", "lt7:etd":
            estimatedDep = text
        case "lt8:platform", "lt7:platform":
            if inCallingPoint { cpPlatform = text.isEmpty ? nil : text }
            else { platform = text.isEmpty ? nil : text }
        case "lt8:operator", "lt7:operator":
            operatorName = text
        case "lt8:locationName", "lt7:locationName":
            if inDestination { destinationName = text }
            else if inService { originName = text }
        case "lt8:via", "lt7:via":
            break  // ignored for now
        case "lt8:destination", "lt7:destination":
            inDestination = false
        case "lt8:service", "lt7:service":
            guard inService else { break }
            inService = false
            inDestination = false
            services.append(GetDepartureBoardResponse.ServiceSummary(
                serviceID: serviceID,
                serviceType: serviceType,
                operatorName: operatorName,
                scheduledDeparture: scheduledDep,
                estimatedDeparture: estimatedDep,
                platform: platform,
                isCancelled: isCancelled,
                originName: originName,
                destinationName: destinationName,
                destinationCRS: destinationCRS
            ))
        case "lt8:trainServices", "lt7:trainServices":
            inServiceList = false
            departureBoardResult = GetDepartureBoardResponse(
                generatedAt: ISO8601DateFormatter().date(from: generatedAt) ?? .now,
                locationName: locationName,
                crs: locationCRS,
                services: services
            )

        // --- Service details calling points ---
        case "lt8:st", "lt7:st":
            cpScheduled = text
        case "lt8:et", "lt7:et":
            cpEstimated = text
        case "lt8:at", "lt7:at":
            cpActual = text
        case "lt8:callingPoint", "lt7:callingPoint":
            guard inCallingPoint else { break }
            inCallingPoint = false
            callingPoints.append(GetServiceDetailsResponse.CallingPointDetail(
                stationName: cpStationName,
                crs: cpCRS,
                scheduledTime: cpScheduled,
                estimatedTime: cpEstimated,
                actualTime: cpActual,
                platform: cpPlatform,
                isCancelled: cpCancelled
            ))
        case "lt8:callingPoints", "lt7:callingPoints":
            inCallingPointList = false
        case "lt8:GetServiceDetailsResult", "lt7:GetServiceDetailsResult":
            serviceDetailsResult = GetServiceDetailsResponse(
                generatedAt: ISO8601DateFormatter().date(from: generatedAt) ?? .now,
                serviceID: serviceID,
                operatorName: operatorName,
                platform: platform,
                isCancelled: isCancelled,
                callingPoints: callingPoints
            )

        default:
            // Capture station name for calling points
            if inCallingPoint && elementName == "lt8:locationName" || elementName == "lt7:locationName" {
                cpStationName = text
            }
            if inCallingPoint && elementName == "lt8:crs" || elementName == "lt7:crs" {
                cpCRS = text
            }
        }

        currentText = ""
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    // MARK: - Helpers

    private func resetServiceAccumulators() {
        serviceID = ""; serviceType = ""; operatorName = ""
        scheduledDep = ""; estimatedDep = nil; platform = nil
        isCancelled = false; originName = ""; destinationName = ""; destinationCRS = nil
    }

    private func resetCallingPointAccumulators() {
        cpStationName = ""; cpCRS = nil; cpScheduled = ""
        cpEstimated = nil; cpActual = nil; cpPlatform = nil; cpCancelled = false
    }
}

enum DarwinParseError: Error {
    case missingElement(String)
    case malformedDate(String)
}
