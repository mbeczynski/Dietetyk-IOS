import Foundation

/// Backend (kolumny `DATE` w Postgresie - patrz `routes/dashboard.js`,
/// `routes/meals.js`, `routes/health.js`) oczekuje i zwraca daty jako
/// czyste `YYYY-MM-DD`, bez strefy czasowej - traktujemy to jako "dzień
/// kalendarzowy", nie jako punkt w czasie UTC.
enum APIDateFormat {
    static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Format do wyświetlenia w UI (np. "18 cze 2026"), w lokalizacji urządzenia.
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Data + godzina (np. "18 cze 2026, 14:32") - używane do pokazania
    /// "ostatniej synchronizacji" Apple Health w Ustawieniach.
    static let displayDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func string(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        isoFormatter.date(from: string)
    }
}
