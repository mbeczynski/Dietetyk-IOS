import Foundation

/// Jeden, prosty klient HTTP nad `URLSession` - bez zewnętrznych zależności
/// (Alamofire itd. są niepotrzebne przy tej skali apki). Token sesji
/// wysyłany jako `Authorization: Bearer <token>`, zgodnie z
/// `backend/middleware/auth.js` w repo Dietetyk-AI (backend NIE używa
/// cookies, tylko nagłówka Bearer).
///
/// `actor`, bo `URLSession`/`JSONDecoder`/`JSONEncoder` są tu współdzielone
/// między wywołaniami z wielu ekranów naraz (Dashboard, Meals, Settings
/// mogą odpytywać równolegle) - actor daje bezpieczny dostęp bez ręcznych
/// blokad, a same metody sieciowe i tak są `async` więc nie blokują UI.
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)

        // Odpowiedzi backendu są w większości snake_case (kolumny SQL zwracane
        // bezpośrednio jako JSON - patrz routes/dashboard.js, routes/meals.js),
        // ale kilka miejsc (auth.js: tempToken/qrCode, meals.js: count) używa
        // już camelCase - .convertFromSnakeCase nie psuje tych kluczy, bo
        // działa tylko na stringach faktycznie zawierających "_".
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        // UWAGA: brak globalnej strategii .convertToSnakeCase na encoderze.
        // Backend jest tu NIEKONSEKWENTNY - ciała żądań w auth.js/meals.js
        // oczekują camelCase ("rawText", "tempToken"), a w health.js/account.js
        // snake_case ("amount_ml", "target_calories"). Każdy model żądania
        // (Encodable) sam definiuje swoje CodingKeys tam, gdzie nazwa pola w
        // JSON różni się od nazwy property w Swift - patrz np. WaterAddRequest.
        let encoder = JSONEncoder()
        self.encoder = encoder
    }

    // MARK: - Core

    /// GET/DELETE bez ciała żądania, z zdekodowaną odpowiedzią typu `T`.
    func get<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let (data, _) = try await perform(
            path: path,
            method: method,
            bodyData: nil,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
        return try decode(data)
    }

    /// POST/PUT z zakodowanym ciałem `body`, ze zdekodowaną odpowiedzią typu `T`.
    func send<B: Encodable, T: Decodable>(
        _ path: String,
        method: String = "POST",
        body: B,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw APIError.decoding(error)
        }
        let (data, _) = try await perform(
            path: path,
            method: method,
            bodyData: bodyData,
            queryItems: queryItems,
            requiresAuth: requiresAuth
        )
        return try decode(data)
    }

    /// POST/DELETE, gdzie interesuje nas tylko sukces/błąd (np. logout) -
    /// odpowiedź jest ignorowana, walidowany jest tylko status HTTP.
    func sendVoid<B: Encodable>(
        _ path: String,
        method: String = "POST",
        body: B,
        requiresAuth: Bool = true
    ) async throws {
        let bodyData: Data
        do {
            bodyData = try encoder.encode(body)
        } catch {
            throw APIError.decoding(error)
        }
        _ = try await perform(path: path, method: method, bodyData: bodyData, queryItems: nil, requiresAuth: requiresAuth)
    }

    /// GET/DELETE/POST bez ciała żądania, gdzie interesuje nas tylko sukces/błąd.
    func performVoid(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws {
        _ = try await perform(path: path, method: method, bodyData: nil, queryItems: queryItems, requiresAuth: requiresAuth)
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func perform(
        path: String,
        method: String,
        bodyData: Data?,
        queryItems: [URLQueryItem]?,
        requiresAuth: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        var url = APIConfig.baseURL.appendingPathComponent(path)

        if let queryItems, !queryItems.isEmpty {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw APIError.invalidURL
            }
            components.queryItems = queryItems
            guard let composed = components.url else { throw APIError.invalidURL }
            url = composed
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainStore.loadToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let bodyData {
            urlRequest.httpBody = bodyData
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? decoder.decode(ServerErrorMessage.self, from: data))?.error
                ?? "Błąd serwera (\(httpResponse.statusCode))."
            throw APIError.server(message: message, statusCode: httpResponse.statusCode)
        }

        return (data, httpResponse)
    }
}
