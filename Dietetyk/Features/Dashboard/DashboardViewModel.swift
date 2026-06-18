import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published private(set) var response: DashboardResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdatingWater = false
    @Published var errorMessage: String?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var summary: DashboardSummary? { response?.summary }
    var meals: [Meal] { response?.meals ?? [] }
    var aiAdvice: String? { response?.aiAdvice }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task { await load() }
    }

    func goToNextDay() {
        guard !isToday else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task { await load() }
    }

    func goToToday() {
        guard !isToday else { return }
        selectedDate = Date()
        Task { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            response = try await APIClient.shared.fetchDashboard(date: APIDateFormat.string(from: selectedDate))
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Szybkie dodanie wody (przyciski np. +250ml na ekranie). Aktualizuje
    /// lokalnie tylko `summary.waterMl` z odpowiedzi endpointu - bez
    /// ponownego odpytywania całego `/api/dashboard`.
    func addWater(amountMl: Int) async {
        guard response != nil else { return }
        isUpdatingWater = true
        defer { isUpdatingWater = false }
        do {
            let result = try await APIClient.shared.addWater(
                date: APIDateFormat.string(from: selectedDate),
                amountMl: amountMl
            )
            if let newWaterMl = result.waterMl {
                response?.summary.waterMl = newWaterMl
            }
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetWater() async {
        guard response != nil else { return }
        isUpdatingWater = true
        defer { isUpdatingWater = false }
        do {
            let result = try await APIClient.shared.resetWater(date: APIDateFormat.string(from: selectedDate))
            response?.summary.waterMl = result.waterMl ?? 0
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
