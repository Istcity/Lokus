// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import SwiftUI

/// Hedef değere animasyonlu sayaç gösterimi.
struct NumberTickerView: View {
    let targetValue: Double
    let prefix: String
    let suffix: String
    let duration: Double

    @State private var displayValue: Double = 0

    var body: some View {
        Text("\(prefix)\(displayValue.formatted(.number.precision(.fractionLength(0))))\(suffix)")
            .font(.title.bold())
            .foregroundStyle(Color("AccentOrange"))
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = targetValue
                }
            }
            .onChange(of: targetValue) { _, newValue in
                displayValue = 0
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = newValue
                }
            }
    }
}

#Preview {
    NumberTickerView(targetValue: 85_000, prefix: "", suffix: " ₺", duration: 1.2)
        .padding()
}
