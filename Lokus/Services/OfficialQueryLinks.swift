// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Resmi kurum web sorgu bağlantıları.
enum OfficialQueryLinks {
    static let tkgmBase = URL(string: "https://parselsorgu.tkgm.gov.tr/")!
    static let nationalEPlan = URL(string: "https://e-plan.imar.gov.tr/")!

    /// TKGM `#ara/cografi/lat/lon` veya `#ara/idari/mahalleId/ada/parsel` deep link.
    static func tkgmParcelQuery(
        coordinate: CLLocationCoordinate2D,
        tkgm: TKGMParcelResult?
    ) -> (url: URL, clipboard: String, subtitle: String) {
        let lat = formatCoord(coordinate.latitude)
        let lng = formatCoord(coordinate.longitude)

        if let tkgm {
            let path = "ara/idari/\(tkgm.mahalleId)/\(tkgm.adaNo)/\(tkgm.parselNo)"
            let url = URL(string: "https://parselsorgu.tkgm.gov.tr/#\(path)") ?? tkgmBase
            let clipboard = "\(tkgm.mahalleAd) · Ada \(tkgm.adaNo) / Parsel \(tkgm.parselNo)"
            let subtitle = "\(tkgm.ozet ?? tkgm.mahalleAd) — web'de açılıyor"
            return (url, clipboard, subtitle)
        }

        let path = "ara/cografi/\(lat)/\(lng)"
        let url = URL(string: "https://parselsorgu.tkgm.gov.tr/#\(path)") ?? tkgmBase
        let clipboard = "Enlem: \(lat)\nBoylam: \(lng)"
        return (url, clipboard, "Koordinat sorgusu · \(lat), \(lng)")
    }

    /// Kayıttan TKGM web linki — API çözümü varsa idari, yoksa coğrafi.
    static func tkgmParcelQuery(record: OfficialQueryRecord) -> URL {
        if let mahalleId = record.mahalleId,
           let ada = record.adaNo,
           let parsel = record.parselNo {
            return URL(string: "https://parselsorgu.tkgm.gov.tr/#ara/idari/\(mahalleId)/\(ada)/\(parsel)")
                ?? tkgmBase
        }
        let lat = formatCoord(record.latitude)
        let lng = formatCoord(record.longitude)
        return URL(string: "https://parselsorgu.tkgm.gov.tr/#ara/cografi/\(lat)/\(lng)")
            ?? tkgmBase
    }

    /// İl bazlı imar / e-Plan portalı.
    static func zoningPortal(
        provincePlate: Int?,
        provinceName: String?,
        coordinate: CLLocationCoordinate2D
    ) -> (url: URL, clipboard: String, subtitle: String) {
        let lat = formatCoord(coordinate.latitude)
        let lng = formatCoord(coordinate.longitude)
        let clipboard = "Enlem: \(lat)\nBoylam: \(lng)"

        if provincePlate == 34 {
            return (
                URL(string: "https://sehirharitasi.ibb.gov.tr/?lat=\(lat)&lon=\(lng)&zoom=17") ?? nationalEPlan,
                clipboard,
                "İBB Şehir Haritası · \(provinceName ?? "İstanbul")"
            )
        }
        if provincePlate == 6 {
            return (
                URL(string: "https://cbsankara.ankara.bel.tr/") ?? nationalEPlan,
                clipboard,
                "Ankara CBS · \(provinceName ?? "Ankara")"
            )
        }
        if provincePlate == 35 {
            return (
                URL(string: "https://kentrehberi.izmir.bel.tr/") ?? nationalEPlan,
                clipboard,
                "İzmir Kent Rehberi · \(provinceName ?? "İzmir")"
            )
        }

        return (
            nationalEPlan,
            clipboard,
            "Ulusal e-Plan · \(provinceName ?? "Türkiye")"
        )
    }

    static func zoningURL(record: OfficialQueryRecord) -> URL {
        zoningPortal(
            provincePlate: nil,
            provinceName: record.provinceName,
            coordinate: record.coordinate
        ).url
    }

    static func infrastructurePortal(coordinate: CLLocationCoordinate2D) -> URL {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        return URL(string: "https://www.openstreetmap.org/?mlat=\(lat)&mlon=\(lng)#map=17/\(lat)/\(lng)")
            ?? nationalEPlan
    }

    static func url(for record: OfficialQueryRecord) -> URL {
        switch record.kind {
        case .parcel: tkgmParcelQuery(record: record)
        case .zoning: zoningURL(record: record)
        case .infrastructure: infrastructurePortal(coordinate: record.coordinate)
        }
    }

    private static func formatCoord(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}
