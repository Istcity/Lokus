// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import MapKit
import SwiftUI

/// Harita üzerinde çizilecek GeoJSON özelliği.
struct GeoLayerFeature: Identifiable, Equatable {
    enum Geometry {
        case polygon([CLLocationCoordinate2D])
        case polyline([CLLocationCoordinate2D])
    }

    let id: String
    let layer: MapOverlayType
    let geometry: Geometry
    let label: String

    static func == (lhs: GeoLayerFeature, rhs: GeoLayerFeature) -> Bool {
        lhs.id == rhs.id
    }

    var strokeColor: Color {
        switch layer {
        case .zoning: Color("AccentOrange")
        case .parcels: Color.blue
        case .infrastructure: Color.green
        case .faultLines: Color("DangerRed")
        }
    }

    var fillColor: Color {
        strokeColor.opacity(layer == .infrastructure ? 0 : 0.15)
    }
}

enum GeoLayerParser {
    static func parse(data: Data, layer: MapOverlayType) -> [GeoLayerFeature] {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = root["features"] as? [[String: Any]] else {
            return []
        }

        var results: [GeoLayerFeature] = []
        for (index, feature) in features.enumerated() {
            guard let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String,
                  let coords = geometry["coordinates"] else { continue }

            let label = label(from: feature["properties"] as? [String: Any], layer: layer)

            switch type {
            case "Polygon":
                guard let rings = coords as? [[[Double]]] else { continue }
                for (ringIndex, ring) in rings.enumerated() {
                    let points = coordinates(from: ring)
                    guard points.count >= 3 else { continue }
                    results.append(
                        GeoLayerFeature(
                            id: "\(layer.rawValue)-\(index)-\(ringIndex)",
                            layer: layer,
                            geometry: .polygon(points),
                            label: label
                        )
                    )
                }
            case "MultiPolygon":
                guard let polys = coords as? [[[[Double]]]] else { continue }
                var polyIndex = 0
                for poly in polys {
                    for ring in poly {
                        let points = coordinates(from: ring)
                        guard points.count >= 3 else { continue }
                        results.append(
                            GeoLayerFeature(
                                id: "\(layer.rawValue)-\(index)-\(polyIndex)",
                                layer: layer,
                                geometry: .polygon(points),
                                label: label
                            )
                        )
                        polyIndex += 1
                    }
                }
            case "LineString":
                guard let line = coords as? [[Double]] else { continue }
                let points = coordinates(from: line)
                guard points.count >= 2 else { continue }
                results.append(
                    GeoLayerFeature(
                        id: "\(layer.rawValue)-\(index)",
                        layer: layer,
                        geometry: .polyline(points),
                        label: label
                    )
                )
            default:
                continue
            }
        }
        return results
    }

    private static func coordinates(from pairs: [[Double]]) -> [CLLocationCoordinate2D] {
        pairs.compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }
    }

    private static func label(from props: [String: Any]?, layer: MapOverlayType) -> String {
        guard let props else { return layer.title }
        switch layer {
        case .zoning:
            return props["plan_notu"] as? String ?? layer.title
        case .parcels:
            let ada = props["ada"] as? String ?? "?"
            let parsel = props["parsel"] as? String ?? "?"
            return "Ada \(ada) / Parsel \(parsel)"
        case .infrastructure:
            return props["tur"] as? String ?? layer.title
        case .faultLines:
            return layer.title
        }
    }
}
