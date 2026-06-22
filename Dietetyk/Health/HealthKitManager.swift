import Foundation
import HealthKit

/// Cienka warstwa nad HealthKit - apka TYLKO CZYTA dane (nigdy nie zapisuje
/// do Zdrowia). Zakres metryk dobrany 1:1 do tego, co już obsługuje webhook
/// "Health Auto Export" po stronie backendu (`METRIC_FIELD_MAP` w
/// `backend/routes/appleHealth.js`) - patrz `HealthSyncService`, który
/// faktycznie wysyła te dane, replikując ten webhook 1:1, więc backend nie
/// wymaga żadnych zmian.
///
/// Celowo NIE jest `@MainActor` - `HKHealthStore` jest bezpieczny do
/// wywoływania z dowolnego wątku/aktora (dokumentacja Apple), a
/// `HealthSyncService` (osobny `actor`) korzysta z tej klasy bez
/// dodatkowego przeskakiwania między aktorami.
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    var store: HKHealthStore { healthStore }

    /// `false` na urządzeniach bez wsparcia dla Zdrowia (np. niektóre iPady) -
    /// sekcja synchronizacji w Ustawieniach się wtedy chowa.
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Identyfikatory metryk kumulatywnych/dyskretnych, które realnie
    /// synchronizujemy - patrz `HealthSyncService.metricSpecs` po
    /// szczegóły konwersji jednostek.
    let quantityIdentifiers: [HKQuantityTypeIdentifier] = {
        var ids: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .appleExerciseTime,
            .distanceWalkingRunning
        ]
        if #available(iOS 16.0, *) {
            // Wymaga Apple Watch Series 8+/Ultra - jeśli niedostępna, zapytania
            // o nią po prostu nie zwrócą żadnych próbek (nie jest to błąd).
            ids.append(.appleSleepingWristTemperature)
        }
        return ids
    }()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        for identifier in quantityIdentifiers {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }
        types.insert(HKObjectType.workoutType())
        return types
    }

    /// Pyta o zgodę na odczyt. HealthKit z założeń prywatności NIE pozwala
    /// jednoznacznie odróżnić "użytkownik odmówił" od "brak danych" dla
    /// uprawnień tylko-do-odczytu - jeśli to się nie powiedzie (np. Zdrowie
    /// niedostępne), poszczególne zapytania po prostu nie zwrócą próbek,
    /// zamiast zgłaszać błąd.
    func requestAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw HealthSyncError.unavailable
        }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func quantityType(_ identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: identifier)
    }
}

enum HealthSyncError: LocalizedError {
    case unavailable
    case missingSyncToken

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Zdrowie nie jest dostępne na tym urządzeniu."
        case .missingSyncToken:
            return "Brak tokenu synchronizacji w Ustawieniach - odśwież ekran Ustawień i spróbuj ponownie."
        }
    }
}
