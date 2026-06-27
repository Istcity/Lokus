// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// PDF belge şablon türleri.
enum DocumentType: String, CaseIterable, Identifiable {
    case imarDurumu = "İmar Durumu Talep Dilekçesi"
    case tapuBilgisi = "Tapu Bilgisi Talep Dilekçesi"
    case ruhsatEvrak = "Ruhsat Başvuru Evrak Listesi"
    case kiraSozlesmesi = "Kira Sözleşmesi Taslağı"

    var id: String { rawValue }

    var recipient: String {
        switch self {
        case .imarDurumu: return "İlgili Belediye Başkanlığı"
        case .tapuBilgisi: return "İlgili Tapu Müdürlüğü"
        case .ruhsatEvrak: return "İlgili Belediye İmar ve Şehircilik Müdürlüğü"
        case .kiraSozlesmesi: return "Taraflar Arası"
        }
    }
}

/// Kullanıcının belgeye yazılacak kişisel bilgileri.
struct DocumentUserInfo {
    var fullName: String
    var address: String
    var parcelInfo: String
    var date: Date

    var formattedDate: String {
        date.formatted(date: .long, time: .omitted)
    }
}

/// Belge şablonu metin üreticisi.
struct DocumentTemplate {
    let type: DocumentType

    /// Kullanıcı bilgileriyle doldurulmuş belge metnini üretir.
    func renderedText(userInfo: DocumentUserInfo) -> String {
        switch type {
        case .imarDurumu:
            return """
            \(userInfo.formattedDate)

            \(type.recipient)'na

            Konu: İmar Durumu (Çap) Belgesi Talebi

            Sayın Yetkili,

            \(userInfo.address) adresinde bulunan, \(userInfo.parcelInfo) parselinde kayıtlı taşınmazımın güncel imar durumu belgesinin (çap) tarafıma verilmesini arz ederim.

            Gereğini saygılarımla arz ederim.

            Ad Soyad: \(userInfo.fullName)
            Adres: \(userInfo.address)
            Tarih: \(userInfo.formattedDate)
            """
        case .tapuBilgisi:
            return """
            \(userInfo.formattedDate)

            \(type.recipient)'ne

            Konu: Tapu Kayıt Örneği Talebi

            Sayın Yetkili,

            \(userInfo.parcelInfo) parseline ait güncel tapu kayıt örneğinin tarafıma verilmesini talep ederim.

            Ad Soyad: \(userInfo.fullName)
            Adres: \(userInfo.address)
            Tarih: \(userInfo.formattedDate)
            """
        case .ruhsatEvrak:
            return """
            \(type.recipient)
            Tarih: \(userInfo.formattedDate)

            RUHSAT BAŞVURUSU EVRAK LİSTESİ
            Başvuru Sahibi: \(userInfo.fullName)
            Parsel: \(userInfo.parcelInfo)
            Adres: \(userInfo.address)

            1. Tapu senedi veya tapu kayıt örneği
            2. Güncel imar durumu belgesi (çap)
            3. Mimari proje (onaylı)
            4. Statik proje raporu
            5. Elektrik ve mekanik projeler
            6. Zemin etüt raporu
            7. Yapı denetim sözleşmesi
            8. Sigorta poliçesi
            9. İnşaat ruhsatı harç makbuzu
            10. Kimlik fotokopisi

            Not: Belediye mevzuatına göre ek evrak istenebilir.
            """
        case .kiraSozlesmesi:
            return """
            KİRA SÖZLEŞMESİ TASLAĞI
            Tarih: \(userInfo.formattedDate)

            KİRAYA VEREN: \(userInfo.fullName)
            ADRES: \(userInfo.address)
            TAŞINMAZ: \(userInfo.parcelInfo)

            MADDE 1 — KONU
            İşbu sözleşme, yukarıda belirtilen taşınmazın kiralanmasına ilişkindir.

            MADDE 2 — SÜRE
            Kira süresi 1 (bir) yıldır. Süre bitiminde tarafların anlaşması halinde yenilenir.

            MADDE 3 — KİRA BEDELİ
            Aylık kira bedeli taraflarca kararlaştırılacak olup, her ayın 1-5'i arasında ödenir.

            MADDE 4 — DEPOZİTO
            Bir aylık kira bedeli tutarında depozito alınır.

            MADDE 5 — GENEL HÜKÜMLER
            Kiracı, taşınmazı özenle kullanmayı; kiraya veren, mevzuata uygun kullanımı sağlamayı kabul eder.

            KİRAYA VEREN: ___________________
            KİRACI: ___________________
            """
        }
    }
}
