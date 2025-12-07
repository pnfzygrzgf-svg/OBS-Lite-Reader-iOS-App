import SwiftUI

@main
struct OBSClientApp: App {
    // deine bisherigen StateObjects bleiben wie sie sind
    @StateObject private var bluetoothManager: BluetoothManager
    @StateObject private var locationManager: LocationManager

    // neu: steuert, ob der Splash sichtbar ist
    @State private var showSplash = true

    init() {
        let bt = BluetoothManager()
        _bluetoothManager = StateObject(wrappedValue: bt)
        _locationManager = StateObject(wrappedValue: LocationManager(bluetoothManager: bt))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // deine eigentliche App
                ContentView()
                    .environmentObject(bluetoothManager)

                // SplashScreen liegt oben drüber, solange showSplash == true
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Dauer des Splashscreens (hier 2 Sekunden)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
