import SwiftUI

/// Korzeń hierarchii widoków - przełącza między ekranem logowania i resztą
/// apki w zależności od `AppState.isAuthenticated`.
struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView(appState: appState)
            }
        }
        // Animacja przy przełączeniu (np. po wylogowaniu albo wygaśnięciu
        // sesji) wygląda naturalniej niż nagła zamiana widoku.
        .animation(.default, value: appState.isAuthenticated)
    }
}
