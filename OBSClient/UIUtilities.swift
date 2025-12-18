import SwiftUI
import Foundation

// MARK: - Card Style (8)

struct ObsCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}

extension View {
    func obsCardStyle() -> some View {
        modifier(ObsCardStyle())
    }
}

// MARK: - Distance formatting (3)

enum DistanceFormatter {
    /// Lokalisierte km-Ausgabe mit genau 2 Nachkommastellen (z.B. "1,23" im DE-Locale)
    static func kmString(fromMeters meters: Double) -> String {
        let km = meters / 1000.0
        return km.formatted(.number.precision(.fractionLength(2)))
    }
}

// MARK: - Optional String helpers (4)

extension Optional where Wrapped == String {
    /// Gibt "-" zurück, wenn nil/leer/whitespace, sonst den String.
    var nonEmptyOrDash: String {
        guard let s = self, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "-" }
        return s
    }
}

// MARK: - Colors

extension Color {
    static func overtakeColor(for distance: Int) -> Color {
        switch distance {
        case ..<100:      return .red
        case 100..<150:   return .orange
        default:          return .green
        }
    }
}
