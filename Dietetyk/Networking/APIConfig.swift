import Foundation

/// Konfiguracja klienta API - adres backendu.
///
/// To dane NIE-sekretne (w przeciwieństwie do tokenu sesji, patrz `KeychainStore`),
/// więc żyją w `UserDefaults`. Użytkownik może je zmienić w Ustawieniach bez
/// przebudowania apki - przydatne np. przy testowaniu przeciw self-hosted
/// backendowi albo `localhost` podczas developmentu.
enum APIConfig {
    private static let baseURLDefaultsKey = "api.baseURL"

    /// Domyślny, produkcyjny adres backendu Dietetyk-AI.
    static let defaultBaseURLString = "https://dietetyk.renacode.com"

    static var baseURL: URL {
        get {
            if let stored = UserDefaults.standard.string(forKey: baseURLDefaultsKey),
               let url = URL(string: stored) {
                return url
            }
            return URL(string: defaultBaseURLString)!
        }
        set {
            UserDefaults.standard.set(newValue.absoluteString, forKey: baseURLDefaultsKey)
        }
    }

    /// Waliduje i zapisuje nowy adres backendu podany przez użytkownika w Ustawieniach.
    /// Zwraca `false` (i nie zapisuje nic), jeśli string nie jest poprawnym URL-em
    /// ze schematem i hostem (np. "https://moj-serwer.pl").
    @discardableResult
    static func setBaseURLString(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil, url.host != nil else {
            return false
        }
        baseURL = url
        return true
    }

    /// Przywraca domyślny, produkcyjny adres backendu.
    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: baseURLDefaultsKey)
    }
}
