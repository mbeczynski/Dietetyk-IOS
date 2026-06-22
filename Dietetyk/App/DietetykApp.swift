import SwiftUI

@main
struct DietetykApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task {
                    // Rejestruje HKObserverQuery, jeśli użytkownik wcześniej
                    // włączył synchronizację Apple Health w Ustawieniach -
                    // dzięki temu HealthKit sam wzbudza synchronizację, gdy
                    // przybędą nowe dane, nawet gdy apka jest w tle.
                    await HealthSyncService.shared.startObservingIfEnabled()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                await HealthSyncService.shared.syncIfEnabled()
            }
        }
    }
}
