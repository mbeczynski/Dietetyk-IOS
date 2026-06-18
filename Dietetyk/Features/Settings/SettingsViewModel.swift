import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    // Cele - jako String, żeby dało się je swobodnie edytować w TextField
    // (puste pole = "nie zmieniaj"/"brak celu"), parsowane na liczby przy zapisie.
    @Published var targetCaloriesText = ""
    @Published var targetProteinText = ""
    @Published var targetCarbsText = ""
    @Published var targetFatText = ""
    @Published var targetWaterMlText = ""

    @Published var serverURLText = APIConfig.baseURL.absoluteString
    @Published var profile: UserProfile?

    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let settings = APIClient.shared.fetchSettings()
            async let fetchedProfile = APIClient.shared.fetchProfile()
            apply(try await settings)
            profile = try await fetchedProfile
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ settings: UserSettings) {
        targetCaloriesText = settings.targetCalories.map { String(Int($0)) } ?? ""
        targetProteinText = settings.targetProtein.map(formatted) ?? ""
        targetCarbsText = settings.targetCarbs.map(formatted) ?? ""
        targetFatText = settings.targetFat.map(formatted) ?? ""
        targetWaterMlText = settings.targetWaterMl.map { String(Int($0)) } ?? ""
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    func saveGoals() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        let request = UpdateSettingsRequest(
            targetCalories: Int(targetCaloriesText),
            targetProtein: Double(targetProteinText.replacingOccurrences(of: ",", with: ".")),
            targetCarbs: Double(targetCarbsText.replacingOccurrences(of: ",", with: ".")),
            targetFat: Double(targetFatText.replacingOccurrences(of: ",", with: ".")),
            targetWaterMl: Int(targetWaterMlText)
        )

        do {
            try await APIClient.shared.updateSettings(request)
            successMessage = "Cele zapisane."
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Zwraca `false`, jeśli wpisany adres nie jest poprawnym URL-em -
    /// widok wtedy pokazuje błąd i nie zamyka edycji.
    @discardableResult
    func saveServerURL() -> Bool {
        guard APIConfig.setBaseURLString(serverURLText) else {
            errorMessage = "Nieprawidłowy adres serwera. Podaj pełny URL, np. https://moj-serwer.pl"
            return false
        }
        successMessage = "Adres serwera zapisany."
        return true
    }

    func resetServerURL() {
        APIConfig.resetToDefault()
        serverURLText = APIConfig.baseURL.absoluteString
    }

    func logout() {
        appState.logout()
    }
}
