import XCTest
import HealthKit
@testable import Dietetyk

/// Testuje czystą logikę `HealthSyncService` (formatowanie dat, mapowanie
/// nazw treningów) - bez dotykania żywego HealthKit/sieci, więc nie wymaga
/// uprawnień ani danych na symulatorze.
final class HealthSyncServiceLogicTests: XCTestCase {
    /// Synchronizacja zapisuje znacznik czasu zawsze w POŁUDNIE danego dnia
    /// (lokalnie urządzenia) - to chroni dzień kalendarzowy po stronie
    /// backendu od przesunięcia przez różnicę stref czasowych. Dwie różne
    /// godziny tego samego dnia muszą więc dać IDENTYCZNY wynik.
    func testExportDateStringAnchorsToNoonRegardlessOfTimeOfDay() {
        let calendar = Calendar.current
        let startOfDay = calendar.date(from: DateComponents(year: 2026, month: 6, day: 18))!
        let earlyMorning = calendar.date(byAdding: .minute, value: 30, to: startOfDay)!
        let lateEvening = calendar.date(byAdding: .hour, value: 23, to: startOfDay)!

        let earlyResult = HealthSyncService.exportDateString(forDay: earlyMorning)
        let lateResult = HealthSyncService.exportDateString(forDay: lateEvening)

        XCTAssertEqual(earlyResult, lateResult)
    }

    func testExportDateStringMatchesExpectedFormat() {
        let calendar = Calendar.current
        let day = calendar.date(from: DateComponents(year: 2026, month: 6, day: 18, hour: 9))!

        let result = HealthSyncService.exportDateString(forDay: day)

        // "yyyy-MM-dd HH:mm:ss Z" z czasem zawsze "12:00:00".
        let pattern = #"^\d{4}-\d{2}-\d{2} 12:00:00 [+-]\d{4}$"#
        XCTAssertNotNil(result.range(of: pattern, options: .regularExpression), "Nieoczekiwany format: \(result)")
        XCTAssertTrue(result.hasPrefix("2026-06-18"))
    }

    func testWorkoutActivityNameKnownCases() {
        XCTAssertEqual(HealthSyncService.workoutActivityName(.running), "Running")
        XCTAssertEqual(HealthSyncService.workoutActivityName(.walking), "Walking")
        XCTAssertEqual(HealthSyncService.workoutActivityName(.cycling), "Cycling")
        XCTAssertEqual(HealthSyncService.workoutActivityName(.yoga), "Yoga")
        XCTAssertEqual(HealthSyncService.workoutActivityName(.highIntensityIntervalTraining), "High Intensity Interval Training")
    }

    /// Typy treningu nieobsłużone explicite w `switch` muszą trafić w
    /// `default` ("Workout"), a nie np. wywalić aplikację - backend i tak
    /// traktuje ten string tylko jako etykietę do wyświetlenia.
    func testWorkoutActivityNameFallsBackToWorkoutForUnhandledTypes() {
        XCTAssertEqual(HealthSyncService.workoutActivityName(.other), "Workout")
        XCTAssertEqual(HealthSyncService.workoutActivityName(.archery), "Workout")
    }
}
