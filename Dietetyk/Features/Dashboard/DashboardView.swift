import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: DashboardViewModel(appState: appState))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dateNavigator

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let summary = viewModel.summary {
                        caloriesCard(summary)
                        macrosCard(summary)
                        activityCard(summary)
                        waterCard(summary)
                        if hasHealthData(summary) {
                            healthCard(summary)
                        }
                        if hasBodyData(summary) {
                            bodyCompositionCard(summary)
                        }
                        if let advice = viewModel.aiAdvice, !advice.isEmpty {
                            adviceCard(advice)
                        }
                        mealsCard
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    } else {
                        Text("Brak danych do wyświetlenia.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 60)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
        }
    }

    // MARK: - Nawigacja po dniach

    private var dateNavigator: some View {
        DayNavigatorView(
            dateText: APIDateFormat.displayFormatter.string(from: viewModel.selectedDate),
            isToday: viewModel.isToday,
            onPrevious: { viewModel.goToPreviousDay() },
            onToday: { viewModel.goToToday() },
            onNext: { viewModel.goToNextDay() }
        )
    }

    // MARK: - Kalorie

    private func caloriesCard(_ summary: DashboardSummary) -> some View {
        CardSection(title: "Kalorie") {
            ProgressRow(label: "Zjedzone", value: summary.caloriesEaten, target: summary.targetCalories, unit: "kcal")
            HStack {
                StatTile(icon: "flame.fill", title: "Spalone (aktywność)", value: format(summary.caloriesBurnedActive), subtitle: "kcal")
                StatTile(icon: "flame", title: "Spalone razem", value: format(summary.caloriesBurnedTotal), subtitle: "kcal (z BMR \(format(summary.bmr)))")
            }
            StatTile(icon: "equal.circle", title: "Bilans netto", value: format(summary.netCalories), subtitle: "kcal")
        }
    }

    // MARK: - Makro

    private func macrosCard(_ summary: DashboardSummary) -> some View {
        CardSection(title: "Makroskładniki") {
            ProgressRow(label: "Białko", value: summary.eatenProtein, target: summary.targetProtein, unit: "g", tint: .blue)
            ProgressRow(label: "Węglowodany", value: summary.eatenCarbs, target: summary.targetCarbs, unit: "g", tint: .orange)
            ProgressRow(label: "Tłuszcz", value: summary.eatenFat, target: summary.targetFat, unit: "g", tint: .pink)
        }
    }

    // MARK: - Aktywność

    private func activityCard(_ summary: DashboardSummary) -> some View {
        CardSection(title: "Aktywność") {
            ProgressRow(label: "Kroki", value: Double(summary.steps), target: Double(summary.targetSteps), unit: "")
            ProgressRow(label: "Minuty aktywności", value: summary.activeMinutes, target: summary.targetActiveMinutes, unit: "min")
            if let lastSync = summary.lastSync {
                Text("Ostatnia synchronizacja: \(lastSync)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Woda

    private func waterCard(_ summary: DashboardSummary) -> some View {
        CardSection(title: "Nawodnienie") {
            ProgressRow(label: "Woda", value: Double(summary.waterMl), target: Double(summary.targetWaterMl), unit: "ml", tint: .cyan)
            HStack(spacing: 10) {
                ForEach([200, 330, 500], id: \.self) { amount in
                    Button("+\(amount) ml") {
                        Task { await viewModel.addWater(amountMl: amount) }
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                Button("Wyzeruj") {
                    Task { await viewModel.resetWater() }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .disabled(viewModel.isUpdatingWater)
        }
    }

    // MARK: - Sen i gotowość (Oura)

    private func hasHealthData(_ summary: DashboardSummary) -> Bool {
        summary.sleepScore != nil || summary.readinessScore != nil || summary.hrv != nil || summary.rhr != nil
    }

    private func healthCard(_ summary: DashboardSummary) -> some View {
        CardSection(title: "Sen i gotowość") {
            LazyVGrid(columns: statTileGrid, spacing: 10) {
                if let sleepScore = summary.sleepScore {
                    StatTile(icon: "bed.double.fill", title: "Sen", value: format(sleepScore), subtitle: sleepDurationSubtitle(summary))
                }
                if let readinessScore = summary.readinessScore {
                    StatTile(icon: "bolt.heart.fill", title: "Gotowość", value: format(readinessScore))
                }
                if let hrv = summary.hrv {
                    StatTile(icon: "waveform.path.ecg", title: "HRV", value: format(hrv), subtitle: "ms")
                }
                if let rhr = summary.rhr {
                    StatTile(icon: "heart.fill", title: "Tętno spoczynkowe", value: format(rhr), subtitle: "bpm")
                }
            }
        }
    }

    private func sleepDurationSubtitle(_ summary: DashboardSummary) -> String? {
        guard let duration = summary.sleepDuration else { return nil }
        let hours = Int(duration)
        let minutes = Int((duration - Double(hours)) * 60)
        return String(format: "%dh %02dmin", hours, minutes)
    }

    // MARK: - Skład ciała (Withings/Apple Health)

    private func hasBodyData(_ summary: DashboardSummary) -> Bool {
        summary.weight != nil || summary.fatRatio != nil || summary.muscleMass != nil
    }

    private func bodyCompositionCard(_ summary: DashboardSummary) -> some View {
        CardSection(title: "Skład ciała") {
            LazyVGrid(columns: statTileGrid, spacing: 10) {
                if let weight = summary.weight {
                    StatTile(icon: "scalemass.fill", title: "Waga", value: format(weight), subtitle: "kg")
                }
                if let fatRatio = summary.fatRatio {
                    StatTile(icon: "percent", title: "Tkanka tłuszczowa", value: format(fatRatio), subtitle: "%")
                }
                if let muscleMass = summary.muscleMass {
                    StatTile(icon: "figure.strengthtraining.traditional", title: "Masa mięśniowa", value: format(muscleMass), subtitle: "kg")
                }
            }
        }
    }

    // MARK: - Porada AI

    private func adviceCard(_ advice: String) -> some View {
        CardSection(title: "Porada dietetyka AI") {
            Text(advice)
                .font(.subheadline)
        }
    }

    // MARK: - Posiłki dnia

    private var mealsCard: some View {
        CardSection(title: "Posiłki dnia") {
            if viewModel.meals.isEmpty {
                Text("Brak zapisanych posiłków tego dnia.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.meals) { meal in
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
                            Text("\(format(calories)) kcal")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    if meal.id != viewModel.meals.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}
