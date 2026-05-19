import Foundation

public enum UkrailyDateFormatter {

    public static let hmm: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_GB")
        return f
    }()

    public static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Parses a Darwin time string like "14:32" relative to a reference date.
    public static func parseTime(_ timeStr: String, on referenceDate: Date = .now) -> Date? {
        let calendar = Calendar.current
        let components = timeStr.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        var dc = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        dc.hour = components[0]
        dc.minute = components[1]
        dc.second = 0
        return calendar.date(from: dc)
    }
}
