import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bt: BluetoothManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // MARK: - Logo im Inhalt zentriert
                Image("OBSLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .frame(maxWidth: .infinity, alignment: .center)

                // MARK: - Verbindungsstatus
                HStack(spacing: 8) {
                    Circle()
                        .fill(bt.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(bt.isConnected ? "Verbunden mit OBS" : "Nicht verbunden")
                            .font(.obsSectionTitle)

                        Text(bt.isPoweredOn ? "Bluetooth an" : "Bluetooth AUS")
                            .font(.obsFootnote)
                            .foregroundStyle(bt.isPoweredOn ? .secondary : Color.red)
                    }

                    Spacer()
                }

                // MARK: - Messwerte-Sektion (als „Karte“)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Messwerte")
                        .font(.obsScreenTitle)

                    // Sensoren nebeneinander
                    HStack(alignment: .top, spacing: 32) {

                        // Sensor LINKS
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sensor links")
                                .font(.obsSectionTitle)

                            Text(rawText(for: bt.leftRawCm))
                                .font(.obsBody)
                                .monospacedDigit()

                            Text(correctedText(for: bt.leftCorrectedCm))
                                .font(.obsValue)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Sensor RECHTS
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sensor rechts")
                                .font(.obsSectionTitle)

                            Text(rawText(for: bt.rightRawCm))
                                .font(.obsBody)
                                .monospacedDigit()

                            Text(correctedText(for: bt.rightCorrectedCm))
                                .font(.obsValue)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Überholabstand
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Überholabstand")
                            .font(.obsSectionTitle)

                        Text(bt.overtakeDistanceText)
                            .font(.obsValue)
                            .monospacedDigit()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                // MARK: - Lenkerbreite
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lenkerbreite")
                        .font(.obsSectionTitle)

                    Stepper(
                        value: $bt.handlebarWidthCm,
                        in: 30...120,
                        step: 1
                    ) {
                        Text("\(bt.handlebarWidthCm) cm")
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // MARK: - Aufnahme-Button
                Button(action: {
                    if bt.isRecording {
                        bt.stopRecording()
                    } else {
                        bt.startRecording()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: bt.isRecording ? "stop.circle.fill" : "record.circle.fill")
                        Text(bt.isRecording ? "Aufnahme stoppen" : "Aufnahme starten")
                    }
                    .font(.obsSectionTitle)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        bt.isRecording
                        ? Color.red.opacity(0.2)
                        : Color.green.opacity(0.2)
                    )
                    .clipShape(Capsule())
                }

            }
            .padding()
            .font(.obsBody) // Basis-Font für alles in dieser View
            .navigationTitle("OBS Lite Recorder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        DataExportView()
                    } label: {
                        Image(systemName: "folder")
                    }

                    NavigationLink {
                        InfoView()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
    }

    // MARK: - Hilfsfunktionen

    private func rawText(for value: Int?) -> String {
        if let v = value {
            return "Roh: \(v) cm"
        } else {
            return "Roh: –"
        }
    }

    private func correctedText(for value: Int?) -> String {
        if let v = value {
            return "Korrigiert: \(v) cm"
        } else {
            return "Korrigiert: –"
        }
    }
}

// 👉 Preview-Bereich, außerhalb der struct
#Preview {
    ContentView()
        .environmentObject(BluetoothManager())
}
