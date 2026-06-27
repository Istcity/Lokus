// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Yakın çevre POI listesi — yarıçap filtresi.
struct POIListView: View {
    let pois: GeoPOIData
    @State private var radiusM = 500

    private let radiusOptions = [500, 1000, 5000]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Yarıçap", selection: $radiusM) {
                ForEach(radiusOptions, id: \.self) { r in
                    Text("\(r) m").tag(r)
                }
            }
            .pickerStyle(.segmented)

            poiSection("Okullar", items: filtered(pois.okullar))
            poiSection("Hastaneler", items: filtered(pois.hastaneler))
            poiSection("Marketler", items: filtered(pois.marketler))
            poiSection("Parklar", items: filtered(pois.parklar))
            poiSection("Duraklar", items: filtered(pois.duraklar))
        }
    }

    private func filtered(_ items: [GeoPOIItem]) -> [GeoPOIItem] {
        items.filter { $0.distanceM <= radiusM }.sorted { $0.distanceM < $1.distanceM }
    }

    @ViewBuilder
    private func poiSection(_ title: String, items: [GeoPOIItem]) -> some View {
        if !items.isEmpty {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(items.prefix(5)) { item in
                HStack {
                    Text(item.name)
                        .font(.footnote)
                    Spacer()
                    Text("\(item.distanceM) m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
