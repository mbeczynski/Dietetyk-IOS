import Foundation
import UIKit

@MainActor
final class AddMealViewModel: ObservableObject {
    @Published var rawText = ""
    @Published var selectedImage: UIImage?
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let appState: AppState
    private let date: Date

    init(appState: AppState, date: Date) {
        self.appState = appState
        self.date = date
    }

    var canSave: Bool {
        !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }

    /// Zwraca `true`, jeśli zapis się powiódł - wołający (`AddMealView`)
    /// wtedy odświeża listę i zamyka arkusz.
    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        // Backend (`backend/routes/meals.js`) oczekuje pełnego data URL
        // base64 w polu `image` ("data:image/jpeg;base64,...").
        //
        // `jpegData()` może (rzadko) zwrócić `nil` - poprzednio błąd był
        // wtedy ukrywany: posiłek zapisywał się bez zdjęcia bez żadnego
        // komunikatu. Teraz przerywamy zapis i informujemy użytkownika,
        // żeby nie stracił zdjęcia w ciszy.
        var imageDataURL: String?
        if let selectedImage {
            guard let jpegData = selectedImage.jpegData(compressionQuality: 0.7) else {
                errorMessage = "Nie udało się przygotować zdjęcia do wysłania. Spróbuj zrobić zdjęcie ponownie."
                return false
            }
            imageDataURL = "data:image/jpeg;base64,\(jpegData.base64EncodedString())"
        }

        let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await APIClient.shared.addMeal(
                rawText: trimmedText.isEmpty ? nil : trimmedText,
                date: APIDateFormat.string(from: date),
                image: imageDataURL
            )
            return true
        } catch APIError.unauthorized {
            appState.requireReauth()
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
