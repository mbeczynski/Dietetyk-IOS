import XCTest
@testable import Dietetyk

/// Backend przechowuje daty jako czyste "YYYY-MM-DD" (kolumny `DATE` w
/// Postgresie, bez strefy czasowej) - jeśli `APIDateFormat` zacznie
/// produkować inny format (np. przez przypadkową zmianę `dateFormat` albo
/// usunięcie `Locale(identifier: "en_US_POSIX")`, co uzależniłoby format od
/// języka urządzenia), zapisy/odczyty dat w całej apce zaczną się rozjeżdżać
/// z backendem w sposób trudny do zauważenia lokalnie.
final class APIDateFormatTests: XCTestCase {
    func testStringFromDateProducesPlainISODate() {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .current
        components.year = 2026
        components.month = 6
        components.day = 18
        components.hour = 15
        components.minute = 30
        let date = components.date!

        XCTAssertEqual(APIDateFormat.string(from: date), "2026-06-18")
    }

    func testDateFromStringRoundTrips() {
        let original = "2026-06-18"
        let date = try! XCTUnwrap(APIDateFormat.date(from: original))
        XCTAssertEqual(APIDateFormat.string(from: date), original)
    }

    func testDateFromInvalidStringReturnsNil() {
        XCTAssertNil(APIDateFormat.date(from: "nie-data"))
        XCTAssertNil(APIDateFormat.date(from: "2026-13-40"))
    }

    /// Godzina w obrębie tego samego dnia kalendarzowego nie powinna zmienić
    /// wyniku - to jest "data", nie znacznik czasu.
    func testTimeOfDayDoesNotAffectFormattedDate() {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.date(from: DateComponents(year: 2026, month: 6, day: 18))!
        let lateInDay = calendar.date(byAdding: .hour, value: 23, to: startOfDay)!

        XCTAssertEqual(APIDateFormat.string(from: startOfDay), APIDateFormat.string(from: lateInDay))
    }
}
