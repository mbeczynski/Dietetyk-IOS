import Foundation
import Security

/// Przechowuje token sesji w Keychain - to jedyny sekret, jaki ta apka trzyma
/// na urządzeniu (adres serwera i cele kaloryczne to dane nie-sekretne, patrz
/// `APIConfig` / `UserDefaults`).
enum KeychainStore {
    private static let service = "com.renacode.dietetyk.session"
    private static let account = "sessionToken"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func saveToken(_ token: String) {
        let data = Data(token.utf8)

        // Usuń istniejący wpis przed zapisem nowego - prościej i bardziej
        // przewidywalne niż SecItemUpdate przy zmianie atrybutów.
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        // Dostępny po pierwszym odblokowaniu urządzenia, nawet w tle - potrzebne,
        // żeby ewentualna synchronizacja w tle (np. przyszłe powiadomienia) mogła
        // odczytać token bez wymogu, by urządzenie było aktualnie odblokowane.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    static func deleteToken() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    static var hasToken: Bool {
        loadToken() != nil
    }
}
