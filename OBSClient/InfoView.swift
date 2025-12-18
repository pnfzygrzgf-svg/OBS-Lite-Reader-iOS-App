// InfoView.swift
import SwiftUI

struct InfoView: View {
    var body: some View {
        GroupedScrollScreen {
            VStack(alignment: .leading, spacing: 24) {
                aboutAppCard
                creditsCard
                licenseCard
            }
            .font(.obsBody)
        }
        .navigationTitle("Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var aboutAppCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Über diese App")
                .font(.obsScreenTitle)

            Text("""
Diese App zeichnet deine Fahrten und Überholabstände mit einem OpenBikeSensor auf.
Sie hilft dabei, kritische Überholmanöver sichtbar zu machen und die Daten auszuwerten.
""")

            if let url = URL(string: "https://www.openbikesensor.org/device/") {
                Link("Mehr zum OpenBikeSensor", destination: url)
                    .font(.obsFootnote.weight(.semibold))
            } else {
                // Sollte nie passieren, verhindert aber Crashes bei kaputten URLs.
                Text("Mehr zum OpenBikeSensor (Link ungültig)")
                    .font(.obsFootnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .obsCardStyle()
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danksagungen & verwendete Projekte")
                .font(.obsScreenTitle)

            VStack(alignment: .leading, spacing: 8) {
                Text("OpenBikeSensor")
                    .font(.obsBody.weight(.bold))

                if let url = URL(string: "https://github.com/openbikesensor") {
                    Link("Github-Organisation", destination: url)
                } else {
                    Text("Github-Organisation (Link ungültig)")
                        .foregroundStyle(.secondary)
                }

                Text("""
In dieser App wird Code aus dem OpenBikeSensor-Projekt verwendet. \
Die Originalsoftware wird unter der GNU Lesser General Public License (LGPL-3.0) veröffentlicht.
""")
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("OpenBikeSensor-Logo")
                    .font(.obsBody.weight(.bold))

                if let url = URL(string: "https://github.com/turbo-distortion/OpenBikeSensor-Logo") {
                    Link("Repository des Logos", destination: url)
                } else {
                    Text("Repository des Logos (Link ungültig)")
                        .foregroundStyle(.secondary)
                }

                Text("""
Das in dieser App verwendete OpenBikeSensor-Logo wurde von Lukas Betzler \
als Beitrag zum OpenBikeSensor-Projekt erstellt. Das Logo steht unter der \
Creative-Commons-Lizenz CC BY-SA 4.0. Bei Weitergabe oder Anpassungen sind \
eine Namensnennung und das Teilen unter derselben Lizenz erforderlich.
""")
            }

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("SimRa Android App")
                    .font(.obsBody.weight(.bold))

                if let url = URL(string: "https://github.com/simra-project/simra-android") {
                    Link("Projekt auf GitHub", destination: url)
                } else {
                    Text("Projekt auf GitHub (Link ungültig)")
                        .foregroundStyle(.secondary)
                }

                Text("""
Teile des Quellcodes – insbesondere zur Fahrtenaufzeichnung – basieren auf Code aus der \
SimRa Android App. Diese steht unter der Apache License 2.0.
""")
            }
        }
        .obsCardStyle()
    }

    private var licenseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lizenz dieser App")
                .font(.obsScreenTitle)

            Text("""
Diese App wird als Open-Source-Software bereitgestellt.
Die genaue Lizenz und alle Drittanbieter-Lizenzen findest du im Quellcode-Repository \
(in den Dateien LICENSE bzw. THIRD_PARTY_LICENSES).

Bitte beachte, dass für die oben genannten Projekte weiterhin deren eigenen \
Lizenzen gelten (LGPL-3.0, CC BY-SA 4.0, Apache-2.0).
""")
        }
        .obsCardStyle()
    }
}

#Preview {
    NavigationStack {
        InfoView()
    }
}
