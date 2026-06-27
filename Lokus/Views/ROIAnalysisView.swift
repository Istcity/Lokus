// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import Charts
import SwiftUI

/// Gayrimenkul fizibilite analizi ekranı.
struct ROIAnalysisView: View {
    var preloadedVillage: Village?

    @StateObject private var viewModel = ROIViewModel()
    @State private var showDistrictPicker = false
    @State private var showPDFShare = false
    @State private var pdfURL: URL?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                regionHeader

                SantiyeAsistCard(
                    costs: viewModel.santiyeAsistCosts,
                    isSelected: viewModel.costSource == .santiyeAsist,
                    onRefresh: {
                        viewModel.refreshSantiyeAsistStatus()
                        if viewModel.isSantiyeAsistAvailable {
                            viewModel.applyCostSource(.santiyeAsist)
                        }
                    },
                    onSelect: {
                        viewModel.applyCostSource(.santiyeAsist)
                    }
                )

                costSourcePicker
                inputSection

                if let result = viewModel.result {
                    metricsSection(result: result)
                    projectionChart(result: result)
                    detailSection(result: result)

                    Button {
                        exportPDF(result: result)
                    } label: {
                        Label("PDF Raporu Paylaş", systemImage: "doc.richtext")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentOrange"))
                }
            }
            .padding()
        }
        .navigationTitle("Fizibilite")
        .navigationBarTitleDisplayMode(.inline)
        .lokusNavigationBarLogo()
        .task {
            await viewModel.configure(with: preloadedVillage)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.refreshSantiyeAsistStatus()
            }
        }
        .sheet(isPresented: $showDistrictPicker) {
            DistrictPickerSheet { province, district in
                viewModel.loadVillage(province: province, district: district)
            }
        }
        .sheet(isPresented: $showPDFShare) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        .lokusAdBanner()
    }

    private var regionHeader: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 10) {
                if let village = viewModel.village {
                    Text(village.name)
                        .font(.title2.bold())
                    Text("Arsa: \(village.landPricePerM2.formatted()) ₺/m² · Konut: \(village.housePricePerM2.formatted()) ₺/m²")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ZoningInfoRow(zoning: village.zoning, showDisclaimer: false)
                } else {
                    Text("Bölge seçilmedi")
                        .font(.headline)
                }

                HStack {
                    Button {
                        showDistrictPicker = true
                    } label: {
                        Label("İl / İlçe Seç", systemImage: "map")
                    }
                    .buttonStyle(.bordered)

                    if LocationViewModel.shared.selectedCoordinate != nil {
                        Button {
                            Task {
                                if let coord = LocationViewModel.shared.selectedCoordinate {
                                    await viewModel.loadVillageFromCoordinate(coord)
                                }
                            }
                        } label: {
                            Label("Keşfet Konumu", systemImage: "location.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var costSourcePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maliyet Kaynağı")
                .font(.subheadline.bold())
            Picker("Maliyet Kaynağı", selection: $viewModel.costSource) {
                ForEach(CostSource.allCases) { source in
                    Text(source.displayName).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.costSource) { _, newValue in
                viewModel.applyCostSource(newValue)
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Proje Parametreleri")
                .font(.subheadline.bold())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Arsa Alanı")
                    Spacer()
                    Text("\(Int(viewModel.landAreaM2)) m²")
                        .font(.footnote.bold())
                }
                Slider(value: $viewModel.landAreaM2, in: 100...5_000, step: 50)
                    .tint(Color("AccentOrange"))
                    .onChange(of: viewModel.landAreaM2) { _, _ in
                        viewModel.estimateMonthlyRent(force: viewModel.rentUsesAutoEstimate)
                        viewModel.calculate()
                    }
                HStack {
                    ForEach([250, 500, 1_000, 2_000], id: \.self) { preset in
                        Button("\(preset) m²") {
                            viewModel.landAreaM2 = Double(preset)
                            viewModel.estimateMonthlyRent(force: viewModel.rentUsesAutoEstimate)
                            viewModel.calculate()
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                    }
                }
            }

            numericField(
                title: "Satış Fiyatı (₺/m²)",
                value: $viewModel.salePricePerM2,
                onChange: { viewModel.calculate() }
            )

            VStack(alignment: .leading, spacing: 6) {
                numericField(
                    title: "İnşaat Maliyeti (₺/m²)",
                    value: $viewModel.constructionCostPerM2,
                    disabled: !viewModel.constructionCostIsEditable,
                    onChange: { viewModel.calculate() }
                )
                if !viewModel.constructionCostIsEditable {
                    Text("Manuel giriş için \"Manuel Giriş\" kaynağını seçin.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                numericField(
                    title: "Aylık Kira (₺)",
                    value: $viewModel.monthlyRent,
                    onChange: { viewModel.userDidEditRent() }
                )
                if viewModel.rentUsesAutoEstimate {
                    HStack {
                        Text("Otomatik tahmin")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Yeniden Tahmin Et") {
                            viewModel.estimateMonthlyRent(force: true)
                            viewModel.calculate()
                        }
                        .font(.caption2)
                    }
                }
            }

            numericField(
                title: "Yıllık Büyüme (%)",
                value: $viewModel.annualGrowthRate,
                onChange: { viewModel.calculate() }
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func numericField(
        title: String,
        value: Binding<Double>,
        disabled: Bool = false,
        onChange: @escaping () -> Void
    ) -> some View {
        LabeledContent(title) {
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .disabled(disabled)
                .opacity(disabled ? 0.5 : 1)
                .onChange(of: value.wrappedValue) { _, _ in onChange() }
        }
    }

    private func metricsSection(result: ROIResult) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Kâr Marjı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NumberTickerView(
                    targetValue: max(result.profitMargin, 0),
                    prefix: "",
                    suffix: "%",
                    duration: 1.2
                )
            }
            VStack(alignment: .leading) {
                Text("Başa Baş Fiyatı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NumberTickerView(
                    targetValue: result.breakEvenM2,
                    prefix: "",
                    suffix: " ₺/m²",
                    duration: 1.2
                )
            }
        }
    }

    private func projectionChart(result: ROIResult) -> some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("5 Yıllık Değer Projeksiyonu")
                    .font(.headline)

                Chart(Array(result.fiveYearProjection.enumerated()), id: \.offset) { item in
                    LineMark(
                        x: .value("Yıl", item.offset),
                        y: .value("Değer", item.element)
                    )
                    .foregroundStyle(Color("AccentOrange"))
                    AreaMark(
                        x: .value("Yıl", item.offset),
                        y: .value("Değer", item.element)
                    )
                    .foregroundStyle(Color("AccentOrange").opacity(0.15))
                }
                .frame(height: 180)
                .chartXAxisLabel("Yıl")
                .chartYAxisLabel("₺")
            }
        }
    }

    private func detailSection(result: ROIResult) -> some View {
        Group {
            resultRow("İnşaat Edilebilir Alan", value: buildableAreaText)
            resultRow("Arsa Maliyeti", value: "\(result.totalLandCost.formatted()) ₺")
            resultRow("İnşaat Maliyeti", value: "\(result.totalConstructionCost.formatted()) ₺")
            resultRow("Toplam Maliyet", value: "\(result.totalCost.formatted()) ₺")
            resultRow("Tahmini Gelir", value: "\(result.totalRevenue.formatted()) ₺")
            resultRow("Brüt Kâr", value: "\(result.grossProfit.formatted()) ₺")
            resultRow("Kira Getirisi", value: String(format: "%.1f%%", result.rentalYieldPercent))
            resultRow("Geri Ödeme Süresi", value: String(format: "%.1f yıl", result.paybackYears))
        }
    }

    private var buildableAreaText: String {
        guard let village = viewModel.village else { return "0 m²" }
        let area = ROIFormulas.buildableArea(landM2: viewModel.landAreaM2, kaks: village.zoning.kaks)
        let kaksText = village.zoning.kaks.formatted(.number.precision(.fractionLength(2)))
        return "\(area.formatted(.number.precision(.fractionLength(0)))) m² (KAKS \(kaksText))"
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).bold()
        }
        .font(.subheadline)
    }

    private func exportPDF(result: ROIResult) {
        guard let village = viewModel.village else { return }
        let settlement = ResolvedSettlement(
            village: village,
            provinceName: LocationViewModel.shared.provinceName,
            districtName: LocationViewModel.shared.districtName,
            settlementName: village.name,
            districtId: 0,
            provincePlate: 0,
            dataSource: .estimated,
            officialPopulation: nil,
            isNeighborhood: true
        )
        do {
            pdfURL = try RegionReportGenerator().generateRegionReport(
                village: village,
                settlement: settlement.provinceName.isEmpty ? nil : settlement,
                coordinate: LocationViewModel.shared.selectedCoordinate,
                roiResult: result,
                roiInputs: (
                    landM2: viewModel.landAreaM2,
                    salePrice: viewModel.salePricePerM2,
                    constructionCost: viewModel.constructionCostPerM2
                )
            )
            showPDFShare = true
        } catch {}
    }
}

#Preview {
    NavigationStack {
        ROIAnalysisView()
    }
}
