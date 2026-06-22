import Foundation

/// Modele odpowiadające 1:1 formatowi payloadu webhooka "Health Auto Export"
/// (`backend/routes/appleHealth.js` w repo Dietetyk-AI), żeby ta apka mogła
/// wysyłać dane odczytane natywnie z HealthKit DOKŁADNIE w tym samym
/// kształcie, bez ŻADNYCH zmian po stronie backendu - patrz `HealthSyncService`,
/// który faktycznie buduje i wysyła ten payload, zastępując webhook
/// "Health Auto Export" (apka ta sama, ale teraz jako natywny klient, nie
/// pośrednik trzeciej firmy).
///
///   { "data": { "metrics": [ { "name": "step_count", "units": "count",
///       "data": [ { "date": "2026-06-18 12:00:00 +0200", "qty": 1234 } ] } ],
///       "workouts": [ { "id": "...", "name": "Running", "start": "...",
///       "end": "...", "duration": 1234.5,
///       "activeEnergyBurned": { "qty": 250.0, "units": "kcal" } } ] } }
struct HealthExportPayload: Encodable {
    let data: HealthExportData
}

struct HealthExportData: Encodable {
    var metrics: [HealthExportMetric] = []
    var workouts: [HealthExportWorkout] = []
}

struct HealthExportMetric: Encodable {
    let name: String
    let units: String
    let data: [HealthExportMetricPoint]
}

struct HealthExportMetricPoint: Encodable {
    /// Format "yyyy-MM-dd HH:mm:ss Z", zgodny z `parseHealthAutoExportDate`
    /// w `backend/utils/dates.js`.
    let date: String
    let qty: Double
}

struct HealthExportWorkout: Encodable {
    let id: String
    let name: String?
    let start: String
    let end: String
    /// Sekundy - `appleHealth.js` sam dzieli przez 60, żeby dostać minuty.
    let duration: Double
    let activeEnergyBurned: HealthExportQuantity?
}

struct HealthExportQuantity: Encodable {
    let qty: Double
    let units: String
}

/// Odpowiedź `POST /api/integrations/apple-health/:syncToken`
/// (`res.json({ status: 'ok', saved_dates: [...], workouts_received: N })`).
struct AppleHealthSyncResponse: Decodable {
    let status: String?
    let savedDates: [String]?
    let workoutsReceived: Int?
}
