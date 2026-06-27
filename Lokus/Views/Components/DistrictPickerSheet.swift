// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import SwiftUI

/// İl ve ilçe seçimi — fizibilite için bölge belirleme.
struct DistrictPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var provinces: [ProvinceIndex] = []
    @State private var selectedProvince: ProvinceIndex?
    @State private var searchText = ""

    let onSelect: (ProvinceIndex, DistrictIndex) -> Void

    var body: some View {
        NavigationStack {
            List {
                if selectedProvince == nil {
                    Section("İl Seçin") {
                        ForEach(filteredProvinces) { province in
                            Button {
                                selectedProvince = province
                            } label: {
                                HStack {
                                    Text(province.name)
                                    Spacer()
                                    Text("\(province.districts.count) ilçe")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(Color("TextPrimary"))
                        }
                    }
                } else if let province = selectedProvince {
                    Section {
                        Button("← \(province.name) iline dön") {
                            selectedProvince = nil
                        }
                        .font(.footnote)
                    }

                    Section("İlçe Seçin") {
                        ForEach(filteredDistricts(in: province)) { district in
                            Button(district.name) {
                                onSelect(province, district)
                                dismiss()
                            }
                            .foregroundStyle(Color("TextPrimary"))
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Ara…")
            .navigationTitle("Bölge Seç")
            .navigationBarTitleDisplayMode(.inline)
            .lokusNavigationBarLogo()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .task {
                provinces = (try? AdministrativeDataStore.shared.loadIndex())?.provinces ?? []
            }
        }
    }

    private var filteredProvinces: [ProvinceIndex] {
        guard !searchText.isEmpty else { return provinces }
        return provinces.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func filteredDistricts(in province: ProvinceIndex) -> [DistrictIndex] {
        guard !searchText.isEmpty else { return province.districts }
        return province.districts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}
