import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var bt: BluetoothManager

    @State private var showSaveConfirmation = false
    @State private var showSideDistances = false

    // (1) cancelbarer Toast-Timer
    @State private var toastTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(.vertical) {
                    VStack(spacing: 24) {
                        LogoView()

                        DeviceTypeSelectionCard()

                        ConnectionStatusCard()

                        if !bt.isPoweredOn || !bt.hasBluetoothPermission {
                            BluetoothPermissionHintView()
                        }

                        MeasurementsCardView(showSideDistances: $showSideDistances)

                        HandlebarWidthView(handlebarWidthCm: $bt.handlebarWidthCm)

                        if !bt.isLocationEnabled || !bt.hasLocationAlwaysPermission {
                            LocationPermissionHintView()
                        }

                        // (10) kein Spacer nötig – ScrollView endet sauber über padding
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 80) // Platz für Record-Button
                    .font(.obsBody)
                }
                // (10) kleine SwiftUI-Details
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)

                if showSaveConfirmation {
                    SaveConfirmationToast(
                        overtakeCount: bt.currentOvertakeCount,
                        // (3) lokalisiert
                        distanceText: DistanceFormatter.kmString(fromMeters: bt.currentDistanceMeters)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("OBS Recorder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        InfoView()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                RecordButtonView(
                    isConnected: bt.isConnected,
                    isRecording: bt.isRecording,
                    onTap: handleRecordTap
                )
            }
            .onDisappear {
                toastTask?.cancel()
                toastTask = nil
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func handleRecordTap() {
        // (2) nur bei erfolgreicher Aktion
        guard bt.isConnected else {
            Haptics.shared.warning()
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if bt.isRecording {
                bt.stopRecording()
                showSaveToastForTwoSeconds()
            } else {
                bt.startRecording()
            }
        }

        Haptics.shared.success()
    }

    private func showSaveToastForTwoSeconds() {
        toastTask?.cancel()
        showSaveConfirmation = true

        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation { showSaveConfirmation = false }
            }
        }
    }
}

// MARK: - Logo

struct LogoView: View {
    var body: some View {
        Image("OBSLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Device Type Selection

struct DeviceTypeSelectionCard: View {
    @EnvironmentObject var bt: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gerätetyp")
                .font(.obsSectionTitle)

            Picker("Gerätetyp", selection: $bt.deviceType) {
                ForEach(ObsDeviceType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Text(bt.deviceType.description)
                .font(.obsFootnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .obsCardStyle()
    }
}

// MARK: - Connection Status (Presentation Model) (7)

struct ConnectionStatusPresentation {
    let title: String
    let subtitle: String
    let color: Color

    init(bt: BluetoothManager) {
        if bt.isConnected {
            title = "Mit OBS verbunden"
            color = .green

            // (4) nil-safety
            let detected = bt.detectedDeviceType?.displayName ?? "unbekannt"
            let mfg = bt.manufacturerName.nonEmptyOrDash
            let fw  = bt.firmwareRevision.nonEmptyOrDash

            subtitle = """
            Name: \(bt.connectedName)
            LocalName: \(bt.connectedLocalName)
            Detected: \(detected) · Quelle: \(bt.lastBleSource)
            Hersteller: \(mfg) · Firmware: \(fw)
            ID: \(bt.connectedId)
            """
            return
        }

        if !bt.isPoweredOn {
            title = "Bluetooth deaktiviert"
            subtitle = "Aktiviere Bluetooth, um den Sensor zu verbinden."
            color = .red
            return
        }

        if !bt.hasBluetoothPermission {
            title = "Bluetooth-Zugriff erforderlich"
            subtitle = "Erlaube Bluetooth-Zugriff in den iOS-Einstellungen."
            color = .red
            return
        }

        title = "Nicht verbunden"
        subtitle = "Warten auf Sensorverbindung."
        color = .orange
    }
}

struct ConnectionStatusCard: View {
    @EnvironmentObject var bt: BluetoothManager

    var body: some View {
        let p = ConnectionStatusPresentation(bt: bt)

        HStack(spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .symbolVariant(.fill)
                .foregroundStyle(p.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(p.title)
                    .font(.obsSectionTitle)

                Text(p.subtitle)
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .obsCardStyle()
    }
}

// MARK: - Permission Hints

struct LocationPermissionHintView: View {
    @EnvironmentObject var bt: BluetoothManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.obsSectionTitle)

                Text(message)
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Einstellungen öffnen")
                        .font(.obsFootnote.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }

            Spacer()
        }
        .obsCardStyle()
    }

    private var title: String {
        if !bt.isLocationEnabled { return "Standortdienste deaktiviert" }
        if !bt.hasLocationAlwaysPermission { return "Hintergrund-Standort deaktiviert" }
        return "Standortzugriff erforderlich"
    }

    private var message: String {
        if !bt.isLocationEnabled {
            return """
Damit deine Fahrten vollständig aufgezeichnet werden können, müssen die Standortdienste (GPS) aktiviert sein.
Aktiviere sie in den iOS-Einstellungen unter „Datenschutz & Sicherheit > Ortungsdienste“.
"""
        }

        return """
Damit deine Fahrten auch bei ausgeschaltetem Bildschirm und im Hintergrund aufgezeichnet werden können, braucht diese App „Immer“ Zugriff auf deinen Standort.

Tippe unten auf „Einstellungen öffnen“ und stelle unter
„Ortungsdienste > OBS Recorder > Zugriff auf Standort“
die Option auf „Immer“.
"""
    }
}

struct BluetoothPermissionHintView: View {
    @EnvironmentObject var bt: BluetoothManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.obsSectionTitle)

                Text(message)
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Einstellungen öffnen")
                        .font(.obsFootnote.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }

            Spacer()
        }
        .obsCardStyle()
    }

    private var title: String {
        bt.isPoweredOn ? "Bluetooth-Zugriff erforderlich" : "Bluetooth deaktiviert"
    }

    private var message: String {
        if !bt.isPoweredOn {
            return "Aktiviere Bluetooth in den Systemeinstellungen, damit sich dein OBS-Gerät verbinden und Messwerte senden kann."
        }
        return "Damit sich dein OBS-Gerät verbinden kann, benötigt diese App Zugriff auf Bluetooth. Erlaube den Zugriff in den iOS-Einstellungen."
    }
}

// MARK: - Measurements Card (6)

struct MeasurementsCardView: View {
    @EnvironmentObject var bt: BluetoothManager
    @Binding var showSideDistances: Bool

    private var isWaitingForSideValues: Bool {
        showSideDistances
        && bt.isConnected
        && bt.leftRawCm == nil
        && bt.rightRawCm == nil
        && bt.leftCorrectedCm == nil
        && bt.rightCorrectedCm == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Sensorwerte")
                    .font(.obsSectionTitle)

                Spacer()

                Toggle("Abstände anzeigen", isOn: $showSideDistances)
                    .labelsHidden()
                    .accessibilityLabel("Abstände links und rechts anzeigen")
            }

            // Skeleton: nicht verbunden ODER verbunden aber noch keine Werte
            if showSideDistances && (!bt.isConnected || isWaitingForSideValues) {
                SensorValuesSkeletonView()
                    .transition(.opacity)
            }

            if showSideDistances {
                HStack(alignment: .top, spacing: 32) {
                    SensorValueView(
                        title: "Abstand links",
                        corrected: bt.leftCorrectedCm,
                        raw: bt.leftRawCm
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: isWaitingForSideValues ? .placeholder : [])

                    SensorValueView(
                        title: "Abstand rechts",
                        corrected: bt.rightCorrectedCm,
                        raw: bt.rightRawCm
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .redacted(reason: isWaitingForSideValues ? .placeholder : [])
                }
            }

            OvertakeDistanceView(distance: bt.overtakeDistanceCm)
        }
        .obsCardStyle()
    }
}

private struct SensorValuesSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(height: 8)
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Sensor Value Views

struct SensorValueView: View {
    let title: String
    let corrected: Int?
    let raw: Int?

    @State private var showMeasuredInfo = false
    @State private var showCalculatedInfo = false

    private let maxDistance = 200.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.obsSectionTitle)

            if let corrected {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(corrected)")
                            .font(.obsValue)
                            .monospacedDigit()
                        Text("cm")
                            .font(.obsBody)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(
                        value: min(Double(corrected), maxDistance),
                        total: maxDistance
                    )
                    .tint(Color.overtakeColor(for: corrected))

                    HStack(spacing: 4) {
                        Text("Berechnet")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)

                        Button { showCalculatedInfo = true } label: {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Info: Berechneter Abstand")
                    }
                    .alert("Berechneter Abstand", isPresented: $showCalculatedInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("„Berechnet“ berücksichtigt die Lenkerbreite: gemessener Abstand minus halbe Lenkerbreite.")
                    }
                }
            } else {
                Text("Noch kein berechneter Wert.")
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)
            }

            if let raw {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Gemessen (Rohwert)")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)

                        Button { showMeasuredInfo = true } label: {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Info: Gemessener Rohwert")
                    }

                    HStack(spacing: 4) {
                        Text("\(raw)")
                            .font(.obsFootnote)
                            .monospacedDigit()
                        Text("cm")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .alert("Gemessener Rohwert", isPresented: $showMeasuredInfo) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("„Gemessen (Rohwert)“ ist der Abstand, den der Sensor erfasst – ohne Korrektur um die Lenkerbreite.")
                }
            } else {
                Text("Noch kein Rohwert gemessen.")
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct OvertakeDistanceView: View {
    let distance: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Überholabstand")
                .font(.obsScreenTitle)

            if let distance {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.overtakeColor(for: distance))
                        .frame(width: 12, height: 12)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(distance)")
                            .font(.obsValue)
                            .monospacedDigit()
                        Text("cm")
                            .font(.obsBody)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityValue("\(distance) Zentimeter")
                }
            } else {
                Text("Noch kein Überholabstand berechnet.")
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lenkerbreite

struct HandlebarWidthView: View {
    @Binding var handlebarWidthCm: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lenkerbreite")
                .font(.obsSectionTitle)

            HStack {
                Text("\(handlebarWidthCm)")
                    .monospacedDigit()
                    .font(.obsBody)

                Text("cm")
                    .font(.obsBody)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Stepper(value: $handlebarWidthCm, in: 30...120, step: 1) {
                EmptyView()
            }
            .labelsHidden()

            Text("Wird zur Berechnung des Überholabstands verwendet.")
                .font(.obsFootnote)
                .foregroundStyle(.secondary)
        }
        .obsCardStyle()
    }
}

// MARK: - Record Button

struct RecordButtonView: View {
    let isConnected: Bool
    let isRecording: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isRecording ? "stop.fill" : "record.circle.fill")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isRecording ? "Aufnahme stoppen" : "Aufnahme starten")
                        .font(.obsSectionTitle)
                        .fontWeight(.semibold)

                    if !isConnected {
                        Text("Sensor nicht verbunden")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: isRecording
                        ? [Color.red.opacity(0.9), Color.red]
                        : [Color.green.opacity(0.9), Color.green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: isConnected ? 4 : 0)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .scaleEffect(isRecording ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isRecording)
        }
        .disabled(!isConnected)
        .opacity(isConnected ? 1.0 : 0.5)
    }
}

// MARK: - Save Confirmation Toast

struct SaveConfirmationToast: View {
    let overtakeCount: Int
    let distanceText: String

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 4) {
                Text("Aufnahme gespeichert.")
                    .font(.obsFootnote.weight(.semibold))

                Text("\(overtakeCount) Überholvorgänge · \(distanceText) km")
                    .font(.obsFootnote)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding(.bottom, 120)
        }
    }
}
