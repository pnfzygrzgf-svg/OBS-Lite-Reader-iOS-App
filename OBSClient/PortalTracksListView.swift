import SwiftUI

/// PortalTracksListView
///
/// Warum diese Variante (List) flüssig läuft:
/// - `List` ist intern stark optimiert (Cell-Reuse/Virtualisierung/Prefetching)
/// - Im Gegensatz zu `ScrollView + VStack` muss SwiftUI nicht alles sofort layouten
/// - Gerade mit „Card“-Styles (Shadow/Background/Overlay) ist `List` meist deutlich performanter
struct PortalTracksListView: View {

    // Portal-Base-URL (kommt aus AppStorage; wird in den Portal-Einstellungen gesetzt)
    @AppStorage("obsBaseUrl") private var obsBaseUrl: String = ""

    // Datenquelle: geladene Track-Summaries
    @State private var tracks: [PortalTrackSummary] = []

    // UI-States
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingLogin = false

    var body: some View {
        // ✅ List: performant für lange/komplexe Listen
        List {

            // MARK: - Einleitung
            Section {
                Text("Im Portal gespeicherte Fahrten ansehen. Sortiert nach Fahrtdatum (neueste zuerst).")
                    .font(.obsFootnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)   // verhindert unschöne Abschneideeffekte
                    .listRowBackground(Color.clear)                 // damit Hintergrund „grouped“ wirkt
            }

            // MARK: - Actions (Reload)
            Section {
                HStack {
                    Spacer()

                    Button {
                        // Reload bewusst in Task, weil load() async ist
                        Task { await load() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Neu laden")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading || obsBaseUrl.isEmpty) // nicht spammen, und ohne URL sinnlos

                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // MARK: - Inhalt je nach Zustand
            //
            // Zustände:
            // 1) keine Portal-URL
            // 2) lädt und noch keine Daten
            // 3) leer (keine Tracks)
            // 4) Liste mit Tracks (+ optional Loading-Row beim Refresh)
            if obsBaseUrl.isEmpty {
                noBaseUrlCard
                    .listRowSeparator(.hidden) // Card-Look: keine Trennlinie

            } else if isLoading && tracks.isEmpty {
                loadingCard
                    .listRowSeparator(.hidden)

            } else if tracks.isEmpty {
                emptyTracksCard
                    .listRowSeparator(.hidden)

            } else {
                // Hinweis-Card oben
                loginHintInline
                    .listRowSeparator(.hidden)

                // Optional: „Aktualisiere…“ nur sichtbar, wenn schon Daten da sind
                if isLoading {
                    loadingInlineRow
                        .listRowSeparator(.hidden)
                }

                // ✅ ForEach in List:
                // - List kümmert sich um Performance (Recycling etc.)
                // - NavigationLink pro Row ist der „Standardweg“
                ForEach(tracks) { track in
                    NavigationLink {
                        // Detailansicht
                        PortalTrackDetailView(baseUrl: obsBaseUrl, track: track)
                    } label: {
                        // Row-Content bewusst „leicht“ halten:
                        // - keine schweren Effekte in der Row selbst (Blur, riesige Shadows etc.)
                        // - Styling macht obsCardStyleV2() außen
                        PortalTrackRowContent(track: track)
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        // MARK: - List Styling
        .listStyle(.insetGrouped)                  // optisch wie Settings
        .scrollContentBackground(.hidden)          // wir setzen den Hintergrund selbst
        .background(Color(.systemGroupedBackground))

        // MARK: - Navigation
        .navigationTitle("Fahrten im OBS-Portal")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Toolbar (Login)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Login") { showingLogin = true }
                    .disabled(obsBaseUrl.isEmpty) // ohne Portal-URL kein Login
            }
        }

        // MARK: - Initial Load
        // Lädt beim ersten Anzeigen.
        // Hinweis: Wenn die View oft neu erscheint (z.B. Tabwechsel), kann das mehrfach feuern.
        // Falls das störend ist: mit zusätzlichem Flag „didLoadOnce“ absichern.
        .task { await load() }

        // MARK: - Login Sheet
        .sheet(isPresented: $showingLogin) {
            if !obsBaseUrl.isEmpty {
                // PortalLoginView ruft Callback nach erfolgreichem Login
                PortalLoginView(baseUrl: obsBaseUrl) {
                    // danach direkt neu laden
                    Task { await load() }
                }
            } else {
                // Fallback: sollte wegen disabled kaum vorkommen
                Text("Keine Portal-URL gesetzt.\nBitte in den Portal-Einstellungen konfigurieren.")
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }

        // MARK: - Fehler Alert
        .alert(
            "Fehler",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Cards / Content
    //
    // Diese Cards bekommen alle obsCardStyleV2()
    // Wichtig für Performance:
    // - Vermeide in obsCardStyleV2() teure Effekte (Material/Blur, große Shadows, Masking)
    // - Gerade in Listen kann das Scrollen sonst wieder ruckeln

    private var noBaseUrlCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            OBSSectionHeaderV2(
                "Keine Portal-URL eingetragen",
                subtitle: "Bitte in den Portal-Einstellungen konfigurieren."
            )

            Text("Ohne Portal-URL können keine Tracks geladen werden.")
                .font(.obsFootnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .obsCardStyleV2()
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Lade Tracks…")
                .font(.obsBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .obsCardStyleV2()
    }

    private var emptyTracksCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "bicycle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            OBSSectionHeaderV2(
                "Keine Tracks gefunden",
                subtitle: "Entweder sind keine Fahrten im Portal gespeichert oder du bist nicht eingeloggt."
            )

            Text("Wenn du sicher bist, dass Tracks existieren: Tippe oben auf „Login“ und lade danach neu.")
                .font(.obsFootnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .obsCardStyleV2()
    }

    private var loginHintInline: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Login-Hinweis")
                    .font(.obsSectionTitle)
            }

            Text("Falls keine oder nur wenige Fahrten angezeigt werden, prüfe, ob du oben rechts über „Login“ im OBS-Portal angemeldet bist.")
                .font(.obsFootnote)
                .foregroundStyle(.secondary)
        }
        .obsCardStyleV2()
    }

    private var loadingInlineRow: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Aktualisiere Liste…")
                .font(.obsFootnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .obsCardStyleV2()
    }

    // MARK: - Datum Parsing
    //
    // Portal liefert recordedAt im ISO-Format, teils mit Fractional Seconds.
    // DateFormatter ist teuer -> deshalb statisch gecached.
    private enum PortalDate {
        private static let dfWithFraction: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            return df
        }()

        private static let dfNoFraction: DateFormatter = {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return df
        }()

        static func parse(_ s: String) -> Date {
            if let d = dfWithFraction.date(from: s) { return d }
            if let d = dfNoFraction.date(from: s) { return d }
            return .distantPast
        }
    }

    // MARK: - Load
    //
    // Lädt Tracks aus dem Portal.
    // Wichtig:
    // - isLoading schützt vor parallelen Requests
    // - tracks werden sortiert (neueste zuerst)
    // - tracks update erfolgt ohne Animation (reduziert Jank)
    private func load() async {
        guard !obsBaseUrl.isEmpty else {
            errorMessage = "Portal-URL ist leer. Bitte in den Portal-Einstellungen eintragen."
            tracks = []
            return
        }

        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let client = PortalApiClient(baseUrl: obsBaseUrl)
            let result = try await client.fetchMyTracks(limit: 20)

            // Sortierung nach recordedAt, neueste zuerst
            let sorted = result.tracks.sorted {
                PortalDate.parse($0.recordedAt) > PortalDate.parse($1.recordedAt)
            }

            // ✅ Update ohne Animation:
            // verhindert unnötige „Diff“-Animationen beim Re-Rendern der List Rows
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                tracks = sorted
            }

            errorMessage = nil

        } catch let PortalApiError.httpError(status, body) where status == 401 {
            errorMessage = "Nicht im Portal eingeloggt.\nBitte oben auf „Login“ tippen und dich anmelden.\n\nAntwort:\n\(body)"
            tracks = []

        } catch PortalApiError.invalidBaseUrl {
            errorMessage = """
            Portal-URL ist ungültig:

            \(obsBaseUrl)

            Bitte in den Portal-Einstellungen inkl. https:// eintragen.
            """
            tracks = []

        } catch PortalApiError.invalidURL {
            errorMessage = "Interne URL konnte nicht gebaut werden.\nBitte Portal-URL prüfen."
            tracks = []

        } catch PortalApiError.noHTTPResponse {
            errorMessage = "Keine gültige HTTP-Antwort vom Portal erhalten.\nIst das Portal erreichbar?"
            tracks = []

        } catch let PortalApiError.httpError(status, body) {
            errorMessage = "Serverfehler \(status).\nAntwort:\n\(body)"
            tracks = []

        } catch {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
            tracks = []
        }
    }
}

// MARK: - Row Content
//
// Absichtlich ohne obsCardStyleV2 hier drin,
// damit die Row selbst günstig bleibt. Der Card-Look wird außen angewendet.
private struct PortalTrackRowContent: View {
    let track: PortalTrackSummary

    var body: some View {
        // Titel robust bestimmen (ohne obsDisplayText Extension)
        let title = (track.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? track.title!
            : "(ohne Titel)"

        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.obsSectionTitle)
                .lineLimit(1)
                .truncationMode(.tail)

            Text("Portal-ID: \(track.slug)")
                .font(.obsCaption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text(String(format: "Länge: %.2f km", track.length / 1000.0))
                Text("Dauer: \(formattedDuration(track.duration))")
                Text("Events: \(track.numEvents)")
            }
            .font(.obsCaption)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    /// Formatiert Sekunden als „X h Y min“ bzw. „Y min“.
    private func formattedDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        return hours > 0 ? "\(hours) h \(minutes) min" : "\(minutes) min"
    }
}

#Preview {
    NavigationStack {
        PortalTracksListView()
    }
}
