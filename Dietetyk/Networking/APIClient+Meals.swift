import Foundation

extension APIClient {
    func fetchMeals(date: String? = nil) async throws -> [Meal] {
        try await get("/api/meals", queryItems: dateQueryItems(date))
    }

    /// Dodaje posiłek na podstawie opisu tekstowego i/lub zdjęcia. `image`
    /// to pełny data URL base64 (np. `"data:image/jpeg;base64,..."`) -
    /// budowany przez wołającego (patrz `AddMealViewModel`, task #60) z
    /// `UIImage.jpegData`.
    ///
    /// Jedno zdjęcie może wygenerować wiele posiłków (np. zrzut ekranu z
    /// podziałem na Śniadanie/Obiad/Kolację) - stąd zwracana tablica, nawet
    /// dla wpisu czysto tekstowego.
    func addMeal(rawText: String?, date: String? = nil, image: String? = nil) async throws -> AddMealResponse {
        try await send(
            "/api/meals",
            body: AddMealRequest(rawText: rawText, date: date, image: image)
        )
    }

    func deleteMeal(id: Int) async throws {
        try await performVoid("/api/meals/\(id)", method: "DELETE")
    }
}
