// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import SwiftUI

/// Açılış yasal uyarı ekranı.
struct DisclaimerView: View {
    @AppStorage("disclaimerAccepted") private var accepted = false

    var body: some View {
        if !accepted {
            VStack(spacing: 24) {
                LokusBrandView(style: .hero)

                Text("Önemli Uyarı")
                    .font(.title2.bold())

                Text("Lokus tarafından sunulan veriler bölgesel tahminlere ve geçmiş endekslere dayanmaktadır. Resmi imar durumu yerine geçmez. Yatırım kararı vermeden önce ilgili belediyelerden resmi imar durumu (çap) belgesi talep edilmelidir. Lokus, yatırım kararlarının sonuçlarından sorumlu tutulamaz.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Anladım, Devam Et") {
                    accepted = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentOrange"))
            }
            .padding(30)
        }
    }
}

#Preview {
    DisclaimerView()
}
