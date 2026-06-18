import Foundation

/// Błędy warstwy sieciowej, ujednolicone tak, żeby ViewModel mógł je
/// bezpośrednio pokazać użytkownikowi (po polsku, przez `errorDescription`)
/// bez dodatkowego mapowania w UI.
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(message: String, statusCode: Int)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Nieprawidłowy adres backendu. Sprawdź adres serwera w Ustawieniach."
        case .invalidResponse:
            return "Serwer zwrócił nieprawidłową odpowiedź."
        case .unauthorized:
            return "Sesja wygasła. Zaloguj się ponownie."
        case .server(let message, _):
            return message
        case .decoding:
            return "Nie udało się odczytać odpowiedzi serwera."
        case .network(let error):
            return error.localizedDescription
        }
    }
}

/// Kształt komunikatów błędów zwracanych przez backend Express, np.
/// `{"error": "Nieprawidłowe żądanie."}` (patrz centralny handler błędów
/// w `backend/server.js`).
struct ServerErrorMessage: Codable {
    let error: String?
}
