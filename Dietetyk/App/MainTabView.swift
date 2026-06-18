import SwiftUI

/// Tymczasowy szkielet głównej nawigacji - zakładki Dashboard/Posiłki
/// dostaną pełną treść w kolejnych krokach (patrz lista zadań: #59, #60).
/// Zakładka Ustawienia ma już teraz działający przycisk wylogowania, żeby
/// cały cykl logowanie -> sesja -> wylogowanie był od razu testowalny.
struct MainTabView: View {
    var body: some View {
        TabView {
            placeholder(title: "Dashboard", systemImage: "chart.bar.fill", note: "Podsumowanie dnia - kalorie, makro, zdrowie. (W budowie)")
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
