import Foundation

/// `GET /api/settings` zwraca PŁASKI, dynamiczny obiekt - dosłownie wszystkie
/// wiersze z tabeli `settings` (key/value) tego użytkownika, plus `sync_token`
/// z tabeli `users`. Backend nie ma stałego kontraktu (klucze zależą od tego,
/// co użytkownik kiedykolwiek zapisał - może zawierać też klucze integracji
/// jak `oura_client_id`, zamaskowane sekrety jak `gemini_api_key: "********"`
/// itd.). Modelujemy tu tylko pola istotne dla tej apki (cele + token synchro
/// Apple Health) - dekodowanie po prostu ignoruje resztę kluczy.
struct UserSettings: Decodable {
    let targetCalories: Double?
    let targetProtein: Double?
    let targetCarbs: Double?
    let targetFat: Double?
    let targetWaterMl: Double?
    /// Tylko do odczytu - używany w adresie webhooka Apple Health
    /// (`backend/routes/appleHealth.js`), nigdy nie wysyłany z powrotem
    /// w żądaniu zapisu (patrz `UpdateSettingsRequest`).
    let syncToken: String?
}

/// Payload zapisu ustawień (`POST /api/settings`). Backend iteruje WSZYSTKIE
/// klucze przesłanego obiektu i nadpisuje nimi wiersze w tabeli `settings` -
/// więc wysyłamy tylko pola faktycznie zmieniane. Dzięki synteyzowanemu przez
/// kompilator `Encodable` (które dla `Optional` używa `encodeIfPresent`),
/// pola `nil` są w całości POMIJANE w wynikowym JSON-ie, a nie wysyłane jako
/// `null` - co jest kluczowe, bo backend zapisuje `null` jako literalny string
/// `"null"` (zobacz `String(val)` w `backend/routes/account.js`), co
/// skorumpowałoby ustawienie. Klucze JSON muszą być snake_case - w tym
/// jednym miejscu backend NIE używa camelCase (w przeciwieństwie do
/// auth.js/meals.js).
struct UpdateSettingsRequest: Encodable {
    var targetCalories: Int?
    var targetProtein: Double?
    var targetCarbs: Double?
    var targetFat: Double?
    var targetWaterMl: Int?

    private enum CodingKeys: String, CodingKey {
        case targetCalories = "target_calories"
        case targetProtein = "target_protein"
        case targetCarbs = "target_carbs"
        case targetFat = "target_fat"
        case targetWaterMl = "target_water_ml"
    }
}

/// Profil użytkownika z `GET /api/user/profile` (kształt jawnie zbudowany w
/// `backend/routes/account.js`, snake_case na każdym polu).
struct UserProfile: Decodable {
    let username: String
    let email: String?
    let avatarBase64: String?
    let role: String?
    let totpEnabled: Bool?
    let hasOura: Bool?
    let hasWithings: Bool?
}

/// Pojedynczy wpis z `GET /api/health/history` (90 dni metryk - na potrzeby
/// przyszłego ekranu Trends, na razie bez UI, patrz README). Kolumny 1:1 z
/// `SELECT` w `backend/routes/health.js`.
struct HealthHistoryEntry: Decodable, Identifiable {
    var id: String { date }
    let date: String
    let weight: Double?
    let fatRatio: Double?
    let muscleMass: Double?
    let sleepScore: Double?
    let sleepDuration: Double?
    let readinessScore: Double?
    let steps: Int?
    let activeCalories: Double?
    let totalCaloriesBurned: Double?
    let rhr: Double?
    let hrv: Double?
    let activeMinutes: Double?
}

/// `POST /api/water/add` - body wymaga DOKŁADNIE `amount_ml` (snake_case,
/// `backend/routes/health.js`), stąd jawne `CodingKeys`.
struct WaterAddRequest: Encodable {
    let date: String
    let amountMl: Int

    private enum CodingKeys: String, CodingKey {
        case date
        case amountMl = "amount_ml"
    }
}

struct WaterResetRequest: Encodable {
    let date: String
}

/// Odpowiedź obu endpointów wody - zawiera zaktualizowaną wartość licznika,
/// żeby UI mogło się odświeżyć bez kolejnego round-tripu do `/api/dashboard`.
struct WaterResponse: Decodable {
    let success: Bool?
    let waterMl: Int?
}

/// Generyczna odpowiedź sukcesu (`{"success": true, "message": "..."}`),
/// używana przez endpointy, gdzie nie potrzebujemy nic poza potwierdzeniem
/// (np. usunięcie posiłku).
struct SuccessResponse: Decodable {
    let success: Bool?
    let message: String?
}
