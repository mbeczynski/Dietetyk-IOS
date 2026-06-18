import Foundation

// MARK: - Żądania

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct TwoFactorCodeRequest: Encodable {
    let tempToken: String
    let code: String
}

struct ChangePasswordForcedRequest: Encodable {
    let tempToken: String
    let newPassword: String
}

// MARK: - Odpowiedzi

/// Surowa odpowiedź `/api/login`. Backend zwraca albo `token` (sukces), albo
/// `status` + `tempToken` opisujące kolejny wymagany krok (2FA, pierwsza
/// konfiguracja 2FA, wymuszona zmiana hasła) - patrz `backend/routes/auth.js`.
struct LoginResponse: Decodable {
    let token: String?
    let status: String?
    let tempToken: String?
    let qrCode: String?
    let secret: String?
}

struct TokenResponse: Decodable {
    let token: String
}

/// Wynik próby logowania, znormalizowany do postaci wygodnej dla
/// `AuthViewModel` - bez konieczności sprawdzania stringów `status` w UI.
enum LoginOutcome {
    case authenticated(token: String)
    case requiresTwoFactor(tempToken: String)
    case requiresTwoFactorSetup(tempToken: String, qrCode: String, secret: String)
    case requiresPasswordChange(tempToken: String)
}

extension LoginResponse {
    /// Mapuje surową odpowiedź backendu na `LoginOutcome`. Zwraca `nil`,
    /// jeśli odpowiedź nie ma rozpoznanego kształtu (nieoczekiwany format -
    /// traktowane przez wołającego jako błąd).
    func toOutcome() -> LoginOutcome? {
        if let token {
            return .authenticated(token: token)
        }
        guard let status, let tempToken else { return nil }
        switch status {
        case "require_2fa":
            return .requiresTwoFactor(tempToken: tempToken)
        case "setup_2fa":
            guard let qrCode, let secret else { return nil }
            return .requiresTwoFactorSetup(tempToken: tempToken, qrCode: qrCode, secret: secret)
        case "force_password_change":
            return .requiresPasswordChange(tempToken: tempToken)
        default:
            return nil
        }
    }
}
