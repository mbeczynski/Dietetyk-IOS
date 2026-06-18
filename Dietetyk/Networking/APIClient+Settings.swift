import Foundation

extension APIClient {
    func fetchSettings() async throws -> UserSettings {
        try await get("/api/settings")
    }

    /// `POST /api/settings` zwraca tylko `{success, message}` (NIE odsyła
    /// zaktualizowanych ustawień) - jeśli UI potrzebuje świeżych wartości po
    /// zapisie, woła `fetchSettings()` ponownie.
    @discardableResult
    func updateSettings(_ settings: UpdateSettingsRequest) async throws -> SuccessResponse {
        try await send("/api/settings", body: settings)
    }

    func fetchProfile() async throws -> UserProfile {
        try await get("/api/user/profile")
    }
}
