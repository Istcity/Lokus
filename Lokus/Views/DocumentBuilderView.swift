// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import SwiftUI

/// Premium PDF belge oluşturucu ekranı.
struct DocumentBuilderView: View {
    @StateObject private var viewModel = DocumentViewModel()
    @ObservedObject private var revenueCat = RevenueCatService.shared
    @State private var showShareSheet = false

    var body: some View {
        Group {
            if revenueCat.hasPremiumAccess {
                formContent
            } else {
                premiumGate
            }
        }
        .navigationTitle("Belgeler")
        .navigationBarTitleDisplayMode(.inline)
        .lokusNavigationBarLogo()
        .onAppear {
            viewModel.prefillFromLocation()
            Task { await revenueCat.checkPremiumStatus() }
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = viewModel.generatedPDFURL {
                ShareSheet(items: [url])
            }
        }
        .lokusAdBanner()
    }

    private var premiumGate: some View {
        VStack(spacing: 20) {
            LokusBrandView(style: .header)
            Text("Lokus Premium")
                .font(.title2.bold())
            Text("PDF dilekçe ve sözleşme şablonları Premium abonelikle kullanılabilir.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            NavigationLink {
                ProfileView()
            } label: {
                Text("Premium'a Geç →")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentOrange"))
            .padding(.horizontal)
        }
        .padding()
    }

    private var formContent: some View {
        Form {
            Section("Belge Türü") {
                Picker("Şablon", selection: $viewModel.selectedType) {
                    ForEach(DocumentType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }

            Section("Bilgileriniz") {
                TextField("Ad Soyad", text: $viewModel.fullName)
                TextField("Adres", text: $viewModel.address, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Parsel / Taşınmaz Bilgisi", text: $viewModel.parcelInfo, axis: .vertical)
                    .lineLimit(2...3)
            }

            Section {
                Button("PDF Oluştur") {
                    viewModel.generatePDF()
                    if viewModel.generatedPDFURL != nil {
                        showShareSheet = true
                    }
                }
                .disabled(!viewModel.isFormValid)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DocumentBuilderView()
    }
}
