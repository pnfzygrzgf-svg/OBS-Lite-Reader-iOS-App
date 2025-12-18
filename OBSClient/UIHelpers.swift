import SwiftUI

/// Gemeinsamer Screen-Wrapper für den wiederholten "Settings-/Grouped"-Look.
/// Funktional identisch zu: ZStack(background) + ScrollView + Padding + hidden indicators.
struct GroupedScrollScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// Gemeinsame Dauerformatierung (entspricht exakt deiner bisherigen Logik).
enum DurationText {
    static func format(_ seconds: Double) -> String {
        let s = Int(seconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Helper für Optional<String> ohne Force-Unwrap.
extension Optional where Wrapped == String {
    func obsDisplayText(or fallback: String = "–") -> String {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines),
              !s.isEmpty else { return fallback }
        return s
    }
}
