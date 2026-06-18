import SwiftUI

struct MealsListView: View {
    @StateObject private var viewModel: MealsListViewModel
    @State private var showAddMeal = false
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: MealsListViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                DayNavigatorView(
                    dateText: APIDateFormat.displayFormatter.string(from: viewModel.selectedDate),
                    isToday: viewModel.isToday,
                    onPrevious: { viewModel.goToPreviousDay() },
                    onToday: { viewModel.goToToday() },
                    onNext: { viewModel.goToNextDay() }
                )
                .padding(.horizontal)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                if !viewModel.meals.isEmpty {
                    HStack {
                        Text("Razem")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(viewModel.totalCalories)) kcal")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal)
                }

                List {
                    if viewModel.meals.isEmpty && !viewModel.isLoading {
                        Text("Brak zapisanych posiłków tego dnia.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.meals) { meal in
                        NavigationLink(value: meal) {
                            mealRow(meal)
                        }
                        .swipeActions {
                            Button("Usuń", role: .destructive) {
                                Task { await viewModel.delete(meal) }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable { await viewModel.load() }
                .overlay {
                    if viewModel.isLoading && viewModel.meals.isEmpty {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Posiłki")
            .navigationDestination(for: Meal.self) { meal in
                MealDetailView(meal: meal)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView(appState: appState, date: viewModel.selectedDate) {
                    Task { await viewModel.load() }
                }
            }
            .task { await viewModel.load() }
        }
    }

    private func mealRow(_ meal: Meal) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name ?? meal.rawText ?? "Posiłek")
                    .font(.subheadline)
                    .lineLimit(1)
                if let timestamp = meal.timestamp {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let calories = meal.calories {
                Text("\(Int(calories)) kcal")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
