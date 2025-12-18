// PortalTrackMapView.swift
import SwiftUI
import MapKit

struct OvertakeEvent: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let distance: Double?
}

struct PortalTrackMapView: UIViewRepresentable {
    let route: [CLLocationCoordinate2D]
    let events: [OvertakeEvent]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator

        map.mapType = .mutedStandard
        map.pointOfInterestFilter = .excludingAll

        map.isRotateEnabled = false
        map.showsCompass = false
        map.showsUserLocation = false
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)

        if !route.isEmpty {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            map.addOverlay(polyline)

            var rect = polyline.boundingMapRect

            if !events.isEmpty {
                let points = events.map { MKMapPoint($0.coordinate) }
                let eventRect = points.reduce(MKMapRect.null) { partial, point in
                    let r = MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0))
                    return partial.isNull ? r : partial.union(r)
                }
                rect = rect.union(eventRect)
            }

            let padding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
            map.setVisibleMapRect(rect, edgePadding: padding, animated: false)
        }

        for event in events {
            let annotation = OvertakeAnnotation(event: event)
            map.addAnnotation(annotation)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3.0
            renderer.strokeColor = UIColor.systemPink
            renderer.lineDashPattern = [4, 2]
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let ann = annotation as? OvertakeAnnotation else { return nil }

            let identifier = "overtake"
            let view: MKMarkerAnnotationView

            if let reused = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = reused
                view.annotation = ann
            } else {
                view = MKMarkerAnnotationView(annotation: ann, reuseIdentifier: identifier)
                view.canShowCallout = true
            }

            if let distance = ann.event.distance {
                if distance <= 1.10 {
                    view.markerTintColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
                } else if distance <= 1.30 {
                    view.markerTintColor = .systemRed
                } else if distance <= 1.50 {
                    view.markerTintColor = .systemYellow
                } else if distance <= 1.70 {
                    view.markerTintColor = .systemGreen
                } else {
                    view.markerTintColor = UIColor(red: 0.0, green: 0.4, blue: 0.0, alpha: 1.0)
                }

                view.glyphText = String(format: "%.2f", distance)
            } else {
                view.markerTintColor = .systemGray
                view.glyphText = "–"
            }

            return view
        }
    }
}

final class OvertakeAnnotation: NSObject, MKAnnotation {
    let event: OvertakeEvent
    dynamic var coordinate: CLLocationCoordinate2D

    init(event: OvertakeEvent) {
        self.event = event
        self.coordinate = event.coordinate
        super.init()
    }

    var title: String? {
        if let d = event.distance {
            return String(format: "Überholung: %.2f m", d)
        }
        return "Überholung"
    }
}
