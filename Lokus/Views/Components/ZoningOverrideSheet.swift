// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import SwiftUI
struct ZoningOverrideSheet: View {
    @Environment(\.dismiss) private var dismiss

    let coordinate: CLLocationCoordinate2D
    let villageName: String
    let existing: ParcelZoningOverride?
    let onSave: (ParcelZoningOverride) -> Void

    @State private var taks: Double
    @State private var kaks: Double
    @State private var maxFloors: String
    @State private var status: ZoningStatus
    @State private var capReference: String
    @State private var notes: String

    init(
        coordinate: CLLocationCoordinate2D,
        villageName: String,
        zoning: ZoningInfo,
        existing: ParcelZoningOverride?,
        onSave: @escaping (ParcelZoningOverride) -> Void
    ) {
        self.coordinate = coordinate
        self.villageName = villageName
        self.existing = existing
        self.onSave = onSave
        _taks = State(initialValue: existing?.taks ?? zoning.taks)
        _kaks = State(initialValue: existing?.kaks ?? zoning.kaks)
        _maxFloors = State(initialValue: existing?.maxFloors ?? zoning.maxFloors)
        _status = State(initialValue: existing?.status ?? zoning.status)
        _capReference = State(initialValue: existing?.capReference ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Yerleşim") {
                    Text(villageName)
                    Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Çap / e-Plan Bilgisi") {
                    TextField("Çap veya e-Plan referans no", text: $capReference)
                    Picker("İmar Fonksiyonu", selection: $status) {
                        ForEach([ZoningStatus.residential, .commercial, .agricultural, .undeveloped], id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    LabeledContent("TAKS") {
                        TextField("0.30", value: $taks, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text(ZoningInfo.taksFullName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    LabeledContent("KAKS") {
                        TextField("1.20", value: $kaks, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text(ZoningInfo.kaksFullName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("Maks. kat (ör. 5 Kat)", text: $maxFloors)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Text("Resmi çap veya belediye e-Plan sorgusu sonucunu girin. Bu bilgi tahminin yerini alır.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("İmar Girişi")
            .navigationBarTitleDisplayMode(.inline)
            .lokusNavigationBarLogo()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let override = ParcelZoningOverride(
                            locationKey: ParcelZoningOverride.locationKey(
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude
                            ),
                            taks: taks,
                            kaks: kaks,
                            maxFloors: maxFloors,
                            status: status,
                            capReference: capReference,
                            notes: notes,
                            updatedAt: Date()
                        )
                        onSave(override)
                        dismiss()
                    }
                }
            }
        }
    }
}
