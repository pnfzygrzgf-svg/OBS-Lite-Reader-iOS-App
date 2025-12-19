// OBSUIV2.swift

import SwiftUI
import Foundation

// =====================================================
// MARK: - Card Style V2
// =====================================================

/// Einheitlicher "Card"-Look (V2) – absichtlich neu benannt,
/// damit es keine Kollisionen mit vorhandenen Styles gibt.
struct OBSCardStyleV2: ViewModifier {

    /// OPTIK:
    /// - iOS "Inset Grouped" Look
    /// - Dezenter Stroke + sehr leichter Shadow
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

extension View {
    /// V2-Variante, damit es nicht mit `obsCardStyle()` kollidiert.
    func obsCardStyleV2() -> some View {
        modifier(OBSCardStyleV2())
    }
}

// =====================================================
// MARK: - Grouped Scroll Screen V2
// =====================================================

/// Wrapper im iOS-"Grouped" Look (V2), neu benannt gegen Kollisionen.
struct GroupedScrollScreenV2<Content: View>: View {

    /// Der Inhalt, der innerhalb des ScrollView gerendert wird.
    private let content: Content

    /// Initializer mit ViewBuilder.
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                content
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

// =====================================================
// MARK: - Components V2
// =====================================================

/// Section-Header (V2), neu benannt gegen Kollisionen.
/// Wichtig: nur EIN init -> keine "ambiguous init" Fehler.
struct OBSSectionHeaderV2: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.obsScreenTitle)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Status-Chip (V2) – neu benannt gegen Kollisionen.
struct OBSStatusChipV2: View {
    enum Style {
        case success
        case warning
        case neutral

        var foreground: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .neutral: return .secondary
            }
        }

        var background: Color {
            switch self {
            case .success: return Color.green.opacity(0.15)
            case .warning: return Color.orange.opacity(0.15)
            case .neutral: return Color.secondary.opacity(0.12)
            }
        }
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(.obsCaption.weight(.semibold))
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(style.background)
            )
    }
}

/// Navigations-Kachel/Row (V2) – neu benannt gegen Kollisionen.
struct OBSRowCardV2: View {
    let icon: String
    let title: String
    let subtitle: String?

    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.obsSectionTitle)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.obsFootnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

// =====================================================
// MARK: - Distance Formatter V2
// =====================================================

/// DistanceFormatter (V2) – neu benannt gegen Kollisionen.
enum OBSDistanceFormatterV2 {
    static func kmString(fromMeters meters: Double) -> String {
        let km = meters / 1000.0
        return km.formatted(.number.precision(.fractionLength(2)))
    }
}

// =====================================================
// MARK: - Optional String helpers V2
// =====================================================

extension Optional where Wrapped == String {

    /// V2-Variante gegen Kollisionen mit evtl. vorhandenen Helpers.
    var obsNonEmptyOrDashV2: String {
        guard let s = self,
              !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return "-" }
        return s
    }
}

// =====================================================
// MARK: - Colors V2
// =====================================================

extension Color {

    /// V2-Variante gegen Kollisionen mit evtl. vorhandenen Color-Extensions.
    static func obsOvertakeColorV2(for distance: Int) -> Color {
        switch distance {
        case ..<100:      return .red
        case 100..<150:   return .orange
        default:          return .green
        }
    }
}
