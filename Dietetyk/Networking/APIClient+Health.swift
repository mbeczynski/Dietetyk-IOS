import Foundation

/// Woda i historia metryk zdrowotnych (`backend/routes/health.js`). Historia
/// nie ma jeszcze ekranu w UI (patrz README - Trends odłożone na później),
/// ale metoda jest gotowa do użycia, gdy ten ekran powstanie.
extension APIClient {
    /// Zwraca nowy stan licznika wody (po dodaniu) - pozwala UI zaktualizować
    /// się natychmiast, bez dodatkowego zapytania o `/api/dashboard`.
    @discardableResult
    func addWater(date: String, amountMl: Int) async throws -> WaterResponse {
        try await send("/api/water/add", body: WaterAddRequest(date: date, amountMl: amountMl))
    }

    @discardableResult
    func resetWater(date: String) async throws -> WaterResponse {
        try await send("/api/water/reset", body: WaterResetRequest(date: date))
    }

    func fetchHealthHistory() async throws -> [HealthHistoryEntry] {
        try await get("/api/health/history")
    }
}
