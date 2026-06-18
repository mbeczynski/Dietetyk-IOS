import SwiftUI

/// Wspólny pasek nawigacji "poprzedni dzień / dzisiaj / następny dzień" -
/// używany na Dashboardzie i liście posiłków (oba ekrany operują na tym
/// samym konkretnym dniu, tak jak `GET /api/dashboard`/`GET /api/meals`).
struct DayNavigatorView: View {
    let dateText: String
    let isToday: Bool
    let onPrevious: () -> Void
    let onToday: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Button(action: onToday) {
                Text(dateText)
                    .font(.subheadline.weight(.medium))
            }
            .disabled(isToday)
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
            .disabled(isToday)
        }
        .buttonStyle(.plain)
    }
}
