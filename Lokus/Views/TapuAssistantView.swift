// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import SwiftUI

/// Tapu ve hukuk interaktif rehber ekranı.
struct TapuAssistantView: View {
    @StateObject private var viewModel = TapuViewModel()

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stepContent
                }
                .padding()
            }
            navigationButtons
        }
        .navigationTitle("Tapu & Hukuk")
        .navigationBarTitleDisplayMode(.inline)
        .lokusNavigationBarLogo()
        .onAppear {
            viewModel.loadData()
        }
        .lokusAdBanner()
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(TapuStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                          ? Color("AccentOrange") : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .deedType:
            deedTypeStep
        case .annotation:
            annotationStep
        case .zoning:
            zoningStep
        case .earthquake:
            earthquakeStep
        case .summary:
            summaryStep
        }
    }

    private var deedTypeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tapu türünüz nedir?")
                .font(.title2.bold())

            ForEach(DeedType.allCases) { type in
                Button {
                    viewModel.selectedDeedType = type
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.rawValue)
                                .font(.headline)
                                .foregroundStyle(Color("TextPrimary"))
                            Text(type.explanation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        if viewModel.selectedDeedType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color("AccentOrange"))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var annotationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Şerh var mı?")
                .font(.title2.bold())

            Toggle("Tapuda şerh/beyan var", isOn: $viewModel.hasAnnotation)
                .tint(Color("AccentOrange"))

            if viewModel.hasAnnotation {
                ForEach(AnnotationType.allCases.filter { $0 != .none }) { annotation in
                    Button {
                        viewModel.selectedAnnotation = annotation
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(annotation.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(Color("TextPrimary"))
                                Text(annotation.explanation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if viewModel.selectedAnnotation == annotation {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color("AccentOrange"))
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(AnnotationType.none.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var zoningStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("İmar Durumu Sorgulama")
                .font(.title2.bold())

            Text(viewModel.zoningGuideText)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var earthquakeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deprem Riski Analizi")
                .font(.title2.bold())

            GlassCardView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Risk Seviyesi")
                            .font(.headline)
                        Spacer()
                        RiskBadgeView(level: viewModel.riskLevel)
                    }

                    if !viewModel.nearestFaultName.isEmpty {
                        Label(viewModel.nearestFaultName, systemImage: "waveform.path.ecg")
                        Text(String(format: "En yakın fay mesafesi: %.1f km", viewModel.faultDistanceKm))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Konum izni vererek haritadan konum seçin; fay analizi otomatik yapılır.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Özet Değerlendirme")
                .font(.title2.bold())

            GlassCardView {
                VStack(alignment: .leading, spacing: 12) {
                    summaryRow("Tapu Türü", viewModel.selectedDeedType?.rawValue ?? "Seçilmedi")
                    summaryRow("Şerh Durumu", viewModel.hasAnnotation ? viewModel.selectedAnnotation.rawValue : "Yok")
                    HStack {
                        Text("Genel Risk")
                        Spacer()
                        RiskBadgeView(level: viewModel.overallRiskScore)
                    }
                    HStack {
                        Text("Deprem Riski")
                        Spacer()
                        RiskBadgeView(level: viewModel.riskLevel)
                    }
                }
            }

            Text("Bu değerlendirme bilgilendirme amaçlıdır. Resmi tapu ve imar sorgulaması için ilgili kurumlara başvurun.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }

    private var navigationButtons: some View {
        HStack {
            if viewModel.currentStep != .deedType {
                Button("Geri") {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if viewModel.currentStep != .summary {
                Button("İleri") {
                    viewModel.nextStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentOrange"))
                .disabled(!canProceed)
            }
        }
        .padding()
    }

    private var canProceed: Bool {
        switch viewModel.currentStep {
        case .deedType: return viewModel.selectedDeedType != nil
        default: return true
        }
    }
}

#Preview {
    NavigationStack {
        TapuAssistantView()
    }
}
