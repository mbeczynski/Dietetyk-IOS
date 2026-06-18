import Foundation

extension APIClient {
    /// `GET /api/dashboard?date=YYYY-MM-DD`. Bez argumentu `date` backend
    /// domyślnie zwraca dzień dzisiejszy (czas lokalny serwera).
    func fetchDashboard(date: String? = nil) async throws -> DashboardResponse {
        try await get("/api/dashboard", queryItems: dateQueryItems(date))
    }
}

/// Wspólny helper dla wszystkich endpointów przyjmujących opcjonalny
/// parametr `?date=YYYY-MM-DD`.
func dateQueryItems(_ date: String?) -> [URLQueryItem]? {
    guard let date else { return nil }
    return [URLQueryItem(name: "date", value: date)]
}
