import SwiftUI

extension Font {
    /// Rounded-Systemfont für einen TextStyle (headline, body, caption, …)
    static func obs(_ style: TextStyle, weight: Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    /// Rounded-Systemfont mit fester Größe
    static func obs(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// App-eigene Typo-Rollen
extension Font {
    /// Titel oben im Screen (z.B. „Messwerte“)
    static var obsScreenTitle: Font {
        .obs(size: 24, weight: .bold)
    }

    /// Abschnittsüberschrift (z.B. „Sensor links“, „Aufnahmen“)
    static var obsSectionTitle: Font {
        .obs(.headline, weight: .semibold)
    }

    /// Standard-Text
    static var obsBody: Font {
        .obs(.body)
    }

    /// Kleinere Zusatzinfos
    static var obsFootnote: Font {
        .obs(.footnote)
    }

    /// Kleine Meta-Infos (Dateigröße, Datum, Hinweise)
    static var obsCaption: Font {
        .obs(.caption)
    }

    /// Werte-Anzeige (Sensorwerte, Distanzen)
    static var obsValue: Font {
        .obs(size: 18, weight: .semibold)
    }
}
