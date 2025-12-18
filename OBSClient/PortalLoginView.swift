// PortalLoginView.swift
import SwiftUI

struct PortalLoginView: View {
    let baseUrl: String
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var loginURL: URL? {
        guard var components = URLComponents(string: baseUrl) else { return nil }
        components.path = "/login"
        return components.url
    }

    var body: some View {
        // bewusst weiterhin NavigationView (kein funktionaler Wechsel des Nav-Verhaltens)
        NavigationView {
            Group {
                if let loginURL {
                    PortalLoginWebView(url: loginURL)
                        .navigationTitle("Portal-Login")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("Ungültige Portal-URL")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        syncCookiesToURLSession {
                            onFinished()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PortalLoginView(baseUrl: "https://portal.openbikesensor.org") { }
}
