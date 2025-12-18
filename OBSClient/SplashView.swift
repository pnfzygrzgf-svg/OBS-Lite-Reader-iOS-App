// SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var overallOpacity: Double = 0.0
    @State private var text1Scale: CGFloat = 0.7
    @State private var showText2 = false
    @State private var text2Offset: CGFloat = 10

    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("#Bürger*innenforschung")
                    .font(.system(size: 30, weight: .bold))
                    .tracking(1)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .scaleEffect(text1Scale)
                    .opacity(overallOpacity)

                Text("für Verkehrssicherheit")
                    .font(.headline)
                    .opacity(showText2 ? 1.0 : 0.0)
                    .offset(y: showText2 ? 0 : text2Offset)
            }
        }
        .task {
            await runAnimation()
        }
    }

    @MainActor
    private func runAnimation() async {
        withAnimation(.easeOut(duration: 0.4)) {
            overallOpacity = 1.0
            text1Scale = 1.15
        }

        try? await Task.sleep(nanoseconds: 400_000_000)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            text1Scale = 1.0
        }

        try? await Task.sleep(nanoseconds: 450_000_000)

        withAnimation(.easeOut(duration: 0.4)) {
            showText2 = true
            text2Offset = 0
        }
    }
}
