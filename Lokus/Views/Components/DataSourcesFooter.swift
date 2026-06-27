// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Veri kaynağı şeffaflık footer'ı.
struct DataSourcesFooter: View {
    let sources: [GeoDataSource]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Veri Kaynakları")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(sources) { source in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(source.katman.capitalized): \(source.kaynak)")
                            .font(.caption2)
                        Text("Güncelleme: \(source.guncellemeTarihi)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        if let lisans = source.lisans {
                            Text("Lisans: \(lisans)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Text(AppConfiguration.geoAttributionText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(12)
        .background(Color("WarningAmber").opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
