import Foundation

/// Globalny stan autoryzacji, współdzielony przez całą apkę przez
/// `@EnvironmentObject`. Token sesji żyje w Keychain (patrz `KeychainStore`)
/// - ten obiekt tylko odzwierciedla, czy token istnieje, żeby `RootView`
/// mógł przełączać się między ekranem logowania i resztą apki.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var isAuthenticated: Bool

    init() {
        // Auto-login: jeśli w Keychain jest token z poprzedniej sesji,
        // zakładamy że jest wciąż ważny - dopiero pierwsze żądanie do
        // backendu faktycznie to zweryfikuje. 401 wywoła `requireReauth()`
        // i wróci do ekranu logowania.
        self.isAuthenticated = KeychainStore.hasToken
    }

    func markAuthenticated(token: String) {
        KeychainStore.saveToken(token)
        isAuthenticated = true
    }

    /// Świadome wylogowanie przez użytkownika (przycisk w Ustawieniach).
    func logout() {
        Task {
            try? await APIClient.shared.logout()
        }
        KeychainStore.deleteToken()
        isAuthenticated = false
    }

    /// Wołane przez ViewModel-e, gdy żądanie zwróci `APIError.unauthorized`
    /// (token wygasł/został unieważniony po stronie backendu) - czyści
    /// lokalny token i wraca do ekranu logowania bez dodatkowego wołania
    /// `/api/logout` (token i tak już nie działa).
    func requireReauth() {
        KeychainStore.deleteToken()
        isAuthenticated = false
    }
}
