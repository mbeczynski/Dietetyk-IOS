import SwiftUI
import UIKit

struct MealDetailView: View {
    let meal: Meal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageBase64 = meal.imageBase64, let uiImage = decodeImage(imageBase64) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Text(meal.name ?? meal.rawText ?? "Posiłek")
                    .font(.title2.weight(.semibold))

                if let healthRating = meal.healthRating {
                    HStack(spacing: 4) {
                        Text("Ocena zdrowotności:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(healthRating)/10")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                CardSection(title: "Wartości odżywcze") {
                    nutrientRow("Kalorie", meal.calories, "kcal")
                    nutrientRow("Białko", meal.protein, "g")
                    nutrientRow("Węglowodany", meal.carbs, "g")
                    nutrientRow("Tłuszcz", meal.fat, "g")
                }

                if let foodItems = meal.foodItems, !foodItems.isEmpty {
                    CardSection(title: "Składniki") {
                        ForEach(foodItems) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.name ?? "Składnik")
                                        .font(.subheadline)
                                    Spacer()
                                    if let calories = item.calories {
                                        Text("\(Int(calories)) kcal")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                if let portion = item.portion {
                                    Text(portion)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if item.id != foodItems.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                if let comment = meal.dieticianComment, !comment.isEmpty {
                    CardSection(title: "Komentarz dietetyka AI") {
                        Text(comment)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Szczegóły posiłku")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func nutrientRow(_ label: String, _ value: Double?, _ unit: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value != nil ? "\(formatted(value!)) \(unit)" : "—")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }

    /// `imageBase64` może być pełnym data URL (`data:image/jpeg;base64,...`)
    /// albo, w starszych wpisach, gołym base64 - obsługujemy obie postacie.
    private func decodeImage(_ raw: String) -> UIImage? {
        let base64String: String
        if let commaIndex = raw.firstIndex(of: ",") {
            base64String = String(raw[raw.index(after: commaIndex)...])
        } else {
            base64String = raw
        }
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: data)
    }
}
