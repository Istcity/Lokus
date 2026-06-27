// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import MapKit

/// Backend MVT karoları için MapKit tile overlay.
final class GeoVectorTileOverlay: MKTileOverlay {
    init(layerName: String, backendURL: URL) {
        let template = backendURL
            .appendingPathComponent(layerName)
            .absoluteString + "/{z}/{x}/{y}.mvt"
        super.init(urlTemplate: template)
        tileSize = CGSize(width: 512, height: 512)
        minimumZ = 10
        maximumZ = 18
        canReplaceMapContent = false
    }
}
