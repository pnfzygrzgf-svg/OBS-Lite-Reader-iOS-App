import Foundation
import CoreLocation

/// Recorder für OBS Classic, der direkt eine CSV-Datei im OBS-Format schreibt.
/// - Eine Session = eine CSV-Datei
/// - Pro Messung eine Zeile (Measurements = 1)
/// - Für Lus/Rus wird distance(cm) * 58 als Flugzeit in µs verwendet
final class ClassicCsvRecorder {

    // MARK: - Public

    /// URL der aktuell offenen CSV-Datei (falls vorhanden)
    private(set) var fileURL: URL?

    // MARK: - Private

    private let queue = DispatchQueue(label: "obs.classic.csv.writer")

    private var handle: FileHandle?

    private let handlebarOffsetCm: Int       // Abstand Lenkerende → Radmitte (z.B. 30 cm)
    private let firmwareVersion: String?
    private let appVersion: String
    private let deviceId: String
    private let factor: Double = 58.0        // wie in der Spezifikation / Flutter-App
    private let maxMeasurementsPerLine = 1   // wir schreiben eine Messung pro Zeile

    // MARK: - Init

    /// - Parameters:
    ///   - handlebarOffsetCm: Abstand je Lenkerseite zur Radmitte (z.B. 30 cm)
    ///   - appVersion: App-Version (z.B. "1.0.0")
    ///   - firmwareVersion: Firmware des OBS Classic (optional)
    init(handlebarOffsetCm: Int, appVersion: String, firmwareVersion: String?) {
        self.handlebarOffsetCm = handlebarOffsetCm
        self.appVersion = appVersion
        self.firmwareVersion = firmwareVersion
        self.deviceId = "obs-ios-\(appVersion)"
    }

    // MARK: - Lifecycle

    /// Startet eine neue CSV-Session: legt Datei an, schreibt Metadaten & Header.
    func startSession() {
        queue.sync {
            do {
                let fm = FileManager.default

                // Documents/OBS
                let docs = try fm.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
                let dir = docs.appendingPathComponent("OBS", isDirectory: true)

                if !fm.fileExists(atPath: dir.path) {
                    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                }

                // Dateiname: fahrt_YYYYMMDD_HHmmss.csv
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let stamp = formatter.string(from: Date())

                let file = dir.appendingPathComponent("fahrt_\(stamp).csv")

                fm.createFile(atPath: file.path, contents: nil)
                let fh = try FileHandle(forWritingTo: file)
                self.handle = fh
                self.fileURL = file

                // Metadaten + Header schreiben
                let metadataLine = genMetadataLine()
                let headerLine = genCSVHeader(maxMeasurements: maxMeasurementsPerLine)

                try fh.write(contentsOf: (metadataLine + "\n").data(using: .utf8)!)
                try fh.write(contentsOf: (headerLine + "\n").data(using: .utf8)!)

                print("ClassicCsvRecorder: startSession -> \(file.path)")
            } catch {
                print("ClassicCsvRecorder: startSession error: \(error)")
                self.handle = nil
                self.fileURL = nil
            }
        }
    }

    /// Beendet die Session und schließt die Datei.
    func finishSession() {
        queue.sync {
            guard let handle = self.handle else { return }

            do {
                try handle.synchronize()
            } catch {
                print("ClassicCsvRecorder: synchronize error: \(error)")
            }

            do {
                try handle.close()
            } catch {
                print("ClassicCsvRecorder: close error: \(error)")
            }

            self.handle = nil
            print("ClassicCsvRecorder: finishSession -> \(fileURL?.lastPathComponent ?? "-")")
        }
    }

    // MARK: - Schreiben von Messungen

    /// Schreibt eine einzelne Messung als CSV-Zeile.
    ///
    /// - Parameters:
    ///   - leftCm:   linker Abstand in Zentimetern (raw Sensorwert, ohne Lenkerkorrektur), oder nil
    ///   - rightCm:  rechter Abstand in Zentimetern, oder nil
    ///   - confirmed: true, wenn diese Messung per Button als „Überholvorgang“ bestätigt wurde
    ///   - location: letzte bekannte Position (optional)
    ///   - batteryVoltage: Batteriespannung in Volt (optional, kann nil sein → Spalte bleibt leer)
    func recordMeasurement(
        leftCm: UInt16?,
        rightCm: UInt16?,
        confirmed: Bool,
        location: CLLocation?,
        batteryVoltage: Double?
    ) {
        queue.async {
            guard let handle = self.handle else {
                print("ClassicCsvRecorder: recordMeasurement ohne offene Session")
                return
            }

            let now = Date()
            let line = self.genCSVRow(
                date: now,
                location: location,
                batteryVoltage: batteryVoltage,
                leftCm: leftCm,
                rightCm: rightCm,
                confirmed: confirmed
            )

            if let data = (line + "\n").data(using: .utf8) {
                do {
                    try handle.write(contentsOf: data)
                } catch {
                    print("ClassicCsvRecorder: write error: \(error)")
                }
            }
        }
    }

    // MARK: - Metadata / Header

    /// Generiert die erste Metadatenzeile (URL-encoded Key-Value-Paare, durch & getrennt).
    private func genMetadataLine() -> String {
        // Angelehnt an die Flutter-App / UploadManager.dart (_genMetadataHeader)
        let fields = [
            "OBSFirmwareVersion=\(firmwareVersion ?? "unknown")",
            "OBSDataFormat=2",
            "DataPerMeasurement=3",
            "MaximumMeasurementsPerLine=\(maxMeasurementsPerLine)",
            "OffsetLeft=\(handlebarOffsetCm)",
            "OffsetRight=\(handlebarOffsetCm)",
            "NumberOfDefinedPrivacyAreas=0",
            "PrivacyLevelApplied=AbsolutePrivacy",
            "MaximumValidFlightTimeMicroseconds=18560",
            "DistanceSensorsUsed=HC-SR04/JSN-SR04T",
            "DeviceId=\(deviceId)",
            "TimeZone=UTC"
        ]
        return fields.joined(separator: "&")
    }

    /// CSV-Headerzeile, entspricht im Wesentlichen der Spezifikation.
    private func genCSVHeader(maxMeasurements: Int) -> String {
        var fields: [String] = [
            "Date",
            "Time",
            "Millis",
            "Comment",
            "Latitude",
            "Longitude",
            "Altitude",
            "Course",
            "Speed",
            "HDOP",
            "Satellites",
            "BatteryLevel",
            "Left",
            "Right",
            "Confirmed",
            "Marked",
            "Invalid",
            "InsidePrivacyArea",
            "Factor",
            "Measurements"
        ]

        // Für jede Messung Tms, Lus, Rus
        for i in 1...maxMeasurements {
            fields.append("Tms\(i)")
            fields.append("Lus\(i)")
            fields.append("Rus\(i)")
        }

        return fields.joined(separator: ";")
    }

    // MARK: - CSV-Zeile für eine Messung

    private func genCSVRow(
        date: Date,
        location: CLLocation?,
        batteryVoltage: Double?,
        leftCm: UInt16?,
        rightCm: UInt16?,
        confirmed: Bool
    ) -> String {
        // Datum/Zeit als UTC, Format wie in der Spezifikation
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        timeFormatter.locale = Locale(identifier: "de_DE")
        timeFormatter.dateFormat = "HH:mm:ss"

        let dateStr = dateFormatter.string(from: date)
        let timeStr = timeFormatter.string(from: date)

        let millis = Int64(date.timeIntervalSince1970 * 1000.0)

        // GPS / Bewegung
        let latStr: String
        let lonStr: String
        let altStr: String
        let courseStr: String
        let speedStr: String
        let hdopStr: String
        let satsStr: String

        if let loc = location {
            latStr = String(loc.coordinate.latitude)
            lonStr = String(loc.coordinate.longitude)
            altStr = String(loc.altitude)
            // In CoreLocation: course = Richtung über Grund (Grad)
            courseStr = loc.course >= 0 ? String(loc.course) : ""
            // Spezifikation sagt km/h, aber wie in Flutter-App verwenden wir m/s
            speedStr = loc.speed >= 0 ? String(loc.speed) : ""
            hdopStr = String(loc.horizontalAccuracy)
            satsStr = ""   // iOS liefert uns das nicht direkt → leer lassen
        } else {
            latStr = ""
            lonStr = ""
            altStr = ""
            courseStr = ""
            speedStr = ""
            hdopStr = ""
            satsStr = ""
        }

        let batteryStr: String = batteryVoltage.map { String($0) } ?? ""

        // Korrigierte Abstände: Sensorwert - HandlebarOffset, nicht < 0
        let leftCorrected: Int? = leftCm.map { max(Int($0) - handlebarOffsetCm, 0) }
        let rightCorrected: Int? = rightCm.map { max(Int($0) - handlebarOffsetCm, 0) }

        let leftCorrectedStr = leftCorrected.map { String($0) } ?? ""
        let rightCorrectedStr = rightCorrected.map { String($0) } ?? ""

        let confirmedStr = confirmed ? "1" : "0"
        let markedStr = confirmed ? "OVERTAKING" : ""

        let invalidStr = "0"
        let insidePrivacyAreaStr = "0"
        let factorStr = String(factor)
        let measurementsStr = "1" // wir schreiben eine Messung pro Zeile

        // Tms1: Offset innerhalb dieser Serie – wir nutzen 0
        let tms1Str = "0"

        // Lus1 / Rus1: Flugzeit in µs = distance(cm) * factor
        let lus1Str: String
        if let leftCm {
            let us = Int(Double(leftCm) * factor)
            lus1Str = String(us)
        } else {
            lus1Str = ""
        }

        let rus1Str: String
        if let rightCm {
            let us = Int(Double(rightCm) * factor)
            rus1Str = String(us)
        } else {
            rus1Str = ""
        }

        let commentStr = "Recorded via OBS iOS Classic"

        var fields: [String] = [
            dateStr,
            timeStr,
            String(millis),
            commentStr,
            latStr,
            lonStr,
            altStr,
            courseStr,
            speedStr,
            hdopStr,
            satsStr,
            batteryStr,
            leftCorrectedStr,
            rightCorrectedStr,
            confirmedStr,
            markedStr,
            invalidStr,
            insidePrivacyAreaStr,
            factorStr,
            measurementsStr,
            tms1Str,
            lus1Str,
            rus1Str
        ]

        return fields.joined(separator: ";")
    }
}
