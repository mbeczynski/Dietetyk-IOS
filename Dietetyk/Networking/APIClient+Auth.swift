import Foundation

/// Logowanie, 2FA i wymuszona zmiana hasła. Żadna z tych metod nie wymaga
/// nagłówka `Authorization` (`requiresAuth: false`) - na tym etapie klient
/// jeszcze nie ma tokenu sesji (albo ma tylko `tempToken`, przesyłany w
/// ciele żądania, nie w nagłówku).
extension APIClient {
    func login(username: String, password: String) async throws -> LoginOutcome {
        let response: LoginResponse = try await send(
            "/api/login",
            body: LoginRequest(username: username, password: password),
            requiresAuth: false
        )
        guard let outcome = response.toOutcome() else {
            throw APIError.invalidResponse
        }
        return outcome
    }

    func loginTwoFactor(tempToken: String, code: String) async throws -> String {
        let response: TokenResponse = try await send(
            "/api/login-2fa",
            body: TwoFactorCodeRequest(tempToken: tempToken, code: code),
            requiresAuth: false
        )
        return response.token
    }

    /// Pierwsza konfiguracja 2FA (po zeskanowaniu QR kodu zwróconego w
    /// `LoginOutcome.requiresTwoFactorSetup`).
    func verifyTwoFactorSetup(tempToken: String, code: String) async throws -> String {
        let response: TokenResponse = try await send(
            "/api/verify-2fa-setup",
            body: TwoFactorCodeRequest(tempToken: tempToken, code: code),
            requiresAuth: false
        )
        return response.token
    }

    /// Wymuszona zmiana hasła (np. po resecie przez admina). Backend może
    /// zwrócić token od razu albo kolejny krok 2FA - stąd `LoginOutcome`,
    /// nie gołe `String`.
    func changePasswordForced(tempToken: String, newPassword: String) async throws -> LoginOutcome {
        let response: LoginResponse = try await send(
            "/api/change-password-forced",
            body: ChangePasswordForcedRequest(tempToken: tempToken, newPassword: newPassword),
            requiresAuth: false
        )
        guard let outcome = response.toOutcome() else {
            throw APIError.invalidResponse
        }
        return outcome
    }

    /// Unieważnia token sesji po stronie backendu. Wołane "best effort" -
    /// nawet jeśli się nie powiedzie (np. brak sieci), `AuthViewModel` i tak
    /// usuwa lokalny token z Keychain i wraca do ekranu logowania.
    func logout() async throws {
        try await performVoid("/api/logout", method: "POST")
    }
}
