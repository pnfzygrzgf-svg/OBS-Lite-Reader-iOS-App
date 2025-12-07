import SwiftUI

struct SplashView: View {
    // Sichtbarkeit insgesamt
    @State private var overallOpacity: Double = 0.0

    // Scale für "#velowende"
    @State private var text1Scale: CGFloat = 0.5   // kleiner Start

    // Steuert, ob "jetzt!" sichtbar wird
    @State private var showText2 = false

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("#Bürger*innenforschung")
                    .font(.system(size: 30, weight: .bold)) // Basisgröße
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .scaleEffect(text1Scale)
                    .opacity(overallOpacity)

                Text("für Verkehrssicherheit")
                    .font(.headline)
                    .opacity(showText2 ? 1.0 : 0.0)
            }
        }
        .onAppear {
            // 1) Einblenden + schnell auf dich zukommen (deutlich größer als Screen)
            withAnimation(.easeOut(duration: 0.4)) {
                overallOpacity = 1.0
                text1Scale = 8.0      // sehr groß, aber nicht völlig weg
            }

            // 2) Wieder auf "ruhig" (normale Größe) zurück
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    text1Scale = 1.0
                }

                // 3) Wenn ruhig, "jetzt!" einblenden
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showText2 = true
                    }
                }
            }
        }
    }
}
