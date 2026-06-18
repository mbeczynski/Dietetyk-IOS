import SwiftUI

/// Główna nawigacja po zalogowaniu. Dashboard (#59), Posiłki (#60) i
/// Ustawienia (#61) mają już pełną treść.
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            DashboardView(appState: appState)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            MealsListView(appState: appState)
                .tabItem { Label("Posiłki", systemImage: "fork.knife") }

            SettingsView(appState: appState)
                .tabItem { Label("Ustawienia", systemImage: "gearshape.fill") }
        }
    }
}
