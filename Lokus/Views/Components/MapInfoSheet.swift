// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Harita bilgi kartı — kısmi yükseklik, sürüklenebilir, içerik kaydırılabilir.
enum MapInfoSheetDetents {
    static let peek = PresentationDetent.fraction(0.34)
    static let half = PresentationDetent.fraction(0.52)
    static let expanded = PresentationDetent.medium

    static var all: [PresentationDetent] { [peek, half, expanded] }
}

extension View {
    func mapInfoSheetStyle(detent: Binding<PresentationDetent>) -> some View {
        presentationDetents(Set(MapInfoSheetDetents.all), selection: detent)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: MapInfoSheetDetents.peek))
            .presentationCornerRadius(22)
    }
}

/// Kart kapalıyken seçili konumu tekrar açmak için mini çubuk.
struct MapInfoPeekBar: View {
    let title: String
    let subtitle: String?
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.up")
                        .font(.caption.bold())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        if let subtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                    Text("Detay")
                        .font(.caption.bold())
                        .foregroundStyle(Color("AccentOrange"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Seçimi kapat")
        }
        .padding(.horizontal, 12)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }
}
