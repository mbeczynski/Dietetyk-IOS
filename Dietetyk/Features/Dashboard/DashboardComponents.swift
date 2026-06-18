import SwiftUI
import UIKit

/// Karta z tytułem i zaokrąglonym tłem - wspólny kontener dla sekcji
/// Dashboardu (kalorie, makro, aktywność, sen, skład ciała...). Reużywalna
/// też w przyszłych ekranach (#60/#61), stąd osobny plik.
struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Wiersz "wartość / cel" z paskiem postępu - dla kalorii, makro, kroków itd.
struct ProgressRow: View {
    let label: String
    let value: Double
    let target: Double?
    let unit: String
    var tint: Color = .accentColor

    private var fraction: Double {
        guard let target, target > 0 else { return 0 }
        return min(value / target, 1.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                if let target {
                    Text("\(formatted(value)) / \(formatted(target)) \(unit)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(formatted(value)) \(unit)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if target != nil {
                ProgressView(value: min(fraction, 1.0))
                    .tint(fraction > 1.0 ? .orange : tint)
            }
        }
    }

    private func formatted(_ number: Double) -> String {
        number.truncatingRemainder(dividingBy: 1) == 0 && abs(number) < 100000
            ? String(Int(number.rounded()))
            : String(format: "%.1f", number)
    }
}

/// Mała "kafelka" ze statystyką (krok, sen, HRV...) - używana w gridach.
struct StatTile: View {
    let icon: String
    let title: String
    let value: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

let statTileGrid = [GridItem(.flexible()), GridItem(.flexible())]
