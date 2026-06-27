// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Widget

import SwiftUI
import WidgetKit
import UIKit

struct LokusEntry: TimelineEntry {
    let date: Date
    let regionName: String
    let district: String
    let housePrice: Double
    let hasData: Bool
}

struct LokusProvider: TimelineProvider {
    func placeholder(in context: Context) -> LokusEntry {
        LokusEntry(date: Date(), regionName: "Mebusevleri", district: "Çankaya", housePrice: 85_000, hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (LokusEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LokusEntry>) -> Void) {
        let entry = loadEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadEntry() -> LokusEntry {
        let defaults = UserDefaults(suiteName: "group.com.sinannergiz.shared")
        let name = defaults?.string(forKey: "lokus_last_region_name") ?? ""
        let district = defaults?.string(forKey: "lokus_last_region_district") ?? ""
        let price = defaults?.double(forKey: "lokus_last_house_price") ?? 0
        let hasData = !name.isEmpty
        return LokusEntry(
            date: Date(),
            regionName: hasData ? name : "Lokus",
            district: district,
            housePrice: price,
            hasData: hasData
        )
    }
}

struct LokusWidgetView: View {
    var entry: LokusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            widgetBrandHeader
            if entry.hasData {
                Text(entry.regionName)
                    .font(.headline)
                    .lineLimit(1)
                if !entry.district.isEmpty {
                    Text(entry.district)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(Int(entry.housePrice).formatted()) ₺/m²")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            } else {
                Text("Keşfet'te bölge seçin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private var widgetBrandHeader: some View {
        if let uiImage = UIImage(named: "LokusLogo", in: .main, compatibleWith: nil) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 18)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(.orange)
                Text("Lokus")
                    .font(.caption.bold())
                Spacer()
            }
        }
    }
}

struct LokusWidget: Widget {
    let kind = "LokusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LokusProvider()) { entry in
            LokusWidgetView(entry: entry)
        }
        .configurationDisplayName("Son Bölge")
        .description("Son baktığınız gayrimenkul bölgesini gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LokusWidgetBundle: WidgetBundle {
    var body: some Widget {
        LokusWidget()
    }
}
