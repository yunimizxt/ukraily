import Foundation
import Compression

final class PushPortXMLParser: NSObject, XMLParserDelegate {

    private var tsMessages: [TSMessage] = []
    private var parseError: Error?

    // Current TS accumulation
    private var inTS = false
    private var currentRID = ""
    private var currentUID = ""
    private var currentTrainDate = ""
    private var locations: [TSMessage.TSLocation] = []

    // Current location accumulation
    private var inLocation = false
    private var locTiploc = ""
    private var locWTA: String? = nil
    private var locWTD: String? = nil
    private var locWTP: String? = nil
    private var locETA: String? = nil
    private var locETD: String? = nil
    private var locATA: String? = nil
    private var locATD: String? = nil
    private var locPlatform: String? = nil
    private var locCancelled = false

    // MARK: - Parse entry

    func parse(data: Data) throws -> [TSMessage] {
        let xmlData = try decompress(data)
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.parse()
        if let error = parseError { throw error }
        return tsMessages
    }

    // MARK: - Decompression

    private func decompress(_ data: Data) throws -> Data {
        // Darwin Push Port sends gzip-compressed XML.
        // If data starts with gzip magic bytes, decompress; otherwise pass through.
        guard data.count > 2, data[0] == 0x1f, data[1] == 0x8b else {
            return data
        }
        return try (data as NSData).decompressed(using: .zlib) as Data
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attrs: [String: String]) {
        switch elementName {
        case "TS":
            inTS = true
            currentRID = attrs["rid"] ?? ""
            currentUID = attrs["uid"] ?? ""
            currentTrainDate = attrs["ssd"] ?? ""
            locations = []
        case "ns5:Location", "Location":
            guard inTS else { break }
            inLocation = true
            locTiploc = attrs["tpl"] ?? ""
            locWTA = attrs["wta"]; locWTD = attrs["wtd"]; locWTP = attrs["wtp"]
            locETA = nil; locETD = nil; locATA = nil; locATD = nil
            locPlatform = nil; locCancelled = false
        case "ns5:arr", "arr":
            guard inLocation else { break }
            locETA = attrs["et"]
            locATA = attrs["at"]
        case "ns5:dep", "dep":
            guard inLocation else { break }
            locETD = attrs["et"]
            locATD = attrs["at"]
        case "ns5:plat", "plat":
            guard inLocation else { break }
            locPlatform = attrs["plat"]
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "ns5:Location", "Location":
            guard inLocation else { break }
            inLocation = false
            locations.append(TSMessage.TSLocation(
                tiploc: locTiploc,
                workingScheduledPassTime: locWTP,
                workingScheduledArrivalTime: locWTA,
                workingScheduledDepartureTime: locWTD,
                estimatedArrival: locETA,
                estimatedDeparture: locETD,
                actualArrival: locATA,
                actualDeparture: locATD,
                platform: locPlatform,
                isCancelled: locCancelled
            ))
        case "TS":
            guard inTS else { break }
            inTS = false
            tsMessages.append(TSMessage(
                rid: currentRID,
                uid: currentUID,
                trainDate: currentTrainDate,
                locations: locations
            ))
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}
