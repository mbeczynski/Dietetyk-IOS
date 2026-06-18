import SwiftUI

/// Główna nawigacja po zalogowaniu. Dashboard ma już pełną treść (#59);
/// Posiłki i Ustawienia dostaną swoją w kolejnych krokach (#60/#61) - do
/// tego czasu zakładka Ustawienia ma już działający przycisk wylogowania,
/// żeby cały cykl logowanie -> sesja -> wylogowanie był od razu testowalny.
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            DashboardView(appState: appState)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            placeholder(title: "Posiłki", systemImage: "fork.knife", note: "Lista posiłków i dodawanie nowych (tekst/zdjęcie). (W budowie)")
                .tabItem { Label("Posiłki", systemImage: "fork.knife") }

            SettingsPlaceholderView()
                .tabItem { Label("Ustawienia", systemImage: "gearshape.fill") }
        }
    }

    private func placeholder(title: String, systemImage: String, note: String) -> some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .navigationTitle(title)
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
