import SwiftUI

/// Główna nawigacja po zalogowaniu. Dashboard (#59) i Posiłki (#60) mają już
/// pełną treść; Ustawienia dostaną swoją w kolejnym kroku (#61) - do tego
/// czasu zakładka Ustawienia ma już działający przycisk wylogowania, żeby
/// cały cykl logowanie -> sesja -> wylogowanie był od razu testowalny.
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            DashboardView(appState: appState)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            MealsListView(appState: appState)
                .tabItem { Label("Posiłki", systemImage: "fork.knife") }

            SettingsPlaceholderView()
                .tabItem { Label("Ustawienia", systemImage: "gearshape.fill") }
        }
    }
}

/// Zalążek przyszłego ekranu Ustawień (#61) - na razie tylko wylogowanie,
/// żeby dało się zweryfikować cały przepływ `AppState`/`KeychainStore`.
private struct SettingsPlaceholderView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Cele kaloryczne, adres serwera i więcej pojawią się tutaj wkrótce.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("Wyloguj się", role: .destructive) {
                        appState.logout()
                    }
                }
            }
            .navigationTitle("Ustawienia")
        }
    }
}
