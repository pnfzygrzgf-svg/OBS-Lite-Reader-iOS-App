// PortalHomeView.swift

import SwiftUI

/// Einstiegsseite für den Tab „Aufzeichnungen“.
/// - Navigation zu:
///   - Fahrtaufzeichnungen & Upload
///   - Meine Portal-Tracks
///   - Portal-Einstellungen (Portal-URL, API-Key, Login-Hilfe)
struct PortalHomeView: View {

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    navigationSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("OBS-Portal")
    }

    /// Navigation zu den Bereichen:
    /// - Fahrtaufzeichnungen & Upload
    /// - Meine Portal-Tracks
    /// - Portal-Einstellungen
    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. Fahrtaufzeichnungen & Upload
            NavigationLink {
                DataExportView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fahrten ins OBS-Portal hochladen")
                            .font(.obsSectionTitle)
                        Text("Aufgezeichnete Fahrten verwalten und hochladen.")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .obsCardStyle()

            // 2. Meine Portal-Tracks
            NavigationLink {
                PortalTracksListView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fahrten im OBS-Portal")
                            .font(.obsSectionTitle)
                        Text("Im Portal gespeicherte Fahrten ansehen und öffnen.")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .obsCardStyle()

            // 3. Portal-Einstellungen
            NavigationLink {
                PortalSettingsView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Portal-Einstellungen")
                            .font(.obsSectionTitle)
                        Text("Portal-URL, API-Key und Login-Hinweise verwalten.")
                            .font(.obsFootnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .obsCardStyle()
        }
    }
}

#Preview {
    NavigationStack {
        PortalHomeView()
    }
}
