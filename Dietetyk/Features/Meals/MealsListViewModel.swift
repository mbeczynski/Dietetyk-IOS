import Foundation

@MainActor
final class MealsListViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published private(set) var meals: [Meal] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var totalCalories: Double {
        meals.reduce(0) { $0 + ($1.calories ?? 0) }
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
            meals = try await APIClient.shared.fetchMeals(date: APIDateFormat.string(from: selectedDate))
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ meal: Meal) async {
        do {
            try await APIClient.shared.deleteMeal(id: meal.id)
            meals.removeAll { $0.id == meal.id }
        } catch APIError.unauthorized {
            appState.requireReauth()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
