import XCTest
@testable import Dietetyk

/// Pilnuje kontraktu JSON-a, który `HealthSyncService` wysyła do
/// `POST /api/integrations/apple-health/:syncToken` (`backend/routes/appleHealth.js`
/// w repo Dietetyk-AI). Backend nie zmienia się pod tę integrację - liczy się
/// WYŁĄCZNIE kształt tego JSON-a, więc to jest najważniejszy test w całym
/// projekcie: jeśli ktoś przypadkiem zmieni nazwę pola w `HealthExportModels`
/// (np. doda CodingKeys albo `keyEncodingStrategy`), backend zacznie po cichu
/// gubić dane, bez żadnego błędu w apce.
///
/// Encoder użyty tu jest identyczny jak w `APIClient` (zwykły `JSONEncoder()`,
/// bez `.convertToSnakeCase`) - patrz komentarz w `APIClient.swift`.
final class HealthExportPayloadEncodingTests: XCTestCase {
    private func encodeToJSONObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    func testPayloadShapeMatchesWebhookContract() throws {
        let payload = HealthExportPayload(
            data: HealthExportData(
                metrics: [
                    HealthExportMetric(
                        name: "step_count",
                        units: "count",
                        data: [HealthExportMetricPoint(date: "2026-06-18 12:00:00 +0200", qty: 1234)]
                    )
                ],
                workouts: [
                    HealthExportWorkout(
                        id: "ABC-123",
                        name: "Running",
                        start: "2026-06-18 07:00:00 +0200",
                        end: "2026-06-18 07:30:00 +0200",
                        duration: 1800,
                        activeEnergyBurned: HealthExportQuantity(qty: 250, units: "kcal")
                    )
                ]
            )
        )

        let json = try encodeToJSONObject(payload)

        let data = try XCTUnwrap(json["data"] as? [String: Any], "brak klucza najwyższego poziomu \"data\"")

        let metrics = try XCTUnwrap(data["metrics"] as? [[String: Any]])
        XCTAssertEqual(metrics.count, 1)
        XCTAssertEqual(metrics[0]["name"] as? String, "step_count")
        XCTAssertEqual(metrics[0]["units"] as? String, "count")
        let metricPoints = try XCTUnwrap(metrics[0]["data"] as? [[String: Any]])
        XCTAssertEqual(metricPoints.count, 1)
        XCTAssertEqual(metricPoints[0]["date"] as? String, "2026-06-18 12:00:00 +0200")
        XCTAssertEqual(metricPoints[0]["qty"] as? Double, 1234)

        let workouts = try XCTUnwrap(data["workouts"] as? [[String: Any]])
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts[0]["id"] as? String, "ABC-123")
        XCTAssertEqual(workouts[0]["name"] as? String, "Running")
        XCTAssertEqual(workouts[0]["start"] as? String, "2026-06-18 07:00:00 +0200")
        XCTAssertEqual(workouts[0]["end"] as? String, "2026-06-18 07:30:00 +0200")
        XCTAssertEqual(workouts[0]["duration"] as? Double, 1800)
        let energy = try XCTUnwrap(workouts[0]["activeEnergyBurned"] as? [String: Any])
        XCTAssertEqual(energy["qty"] as? Double, 250)
        XCTAssertEqual(energy["units"] as? String, "kcal")
    }

    /// Pusta tablica metryk/treningów nie powinna sama z siebie zniknąć z
    /// JSON-a (np. przez `JSONEncoder` opcjonalnie pomijający puste kolekcje) -
    /// `appleHealth.js` zawsze oczekuje obu kluczy w `data`.
    func testEmptyDataStillProducesBothKeys() throws {
        let payload = HealthExportPayload(data: HealthExportData())
        let json = try encodeToJSONObject(payload)
        let data = try XCTUnwrap(json["data"] as? [String: Any])
        XCTAssertNotNil(data["metrics"])
        XCTAssertNotNil(data["workouts"])
        XCTAssertEqual((data["metrics"] as? [Any])?.count, 0)
        XCTAssertEqual((data["workouts"] as? [Any])?.count, 0)
    }

    /// Odpowiedź backendu (`res.json({ status, saved_dates, workouts_received })`)
    /// dekodowana tym samym decoderem co `APIClient`
    /// (`keyDecodingStrategy = .convertFromSnakeCase`).
    func testResponseDecodingMatchesSnakeCaseBackendKeys() throws {
        let json = """
        {"status":"ok","saved_dates":["2026-06-17","2026-06-18"],"workouts_received":2}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(AppleHealthSyncResponse.self, from: json)

        XCTAssertEqual(response.status, "ok")
        XCTAssertEqual(response.savedDates, ["2026-06-17", "2026-06-18"])
        XCTAssertEqual(response.workoutsReceived, 2)
    }
}
