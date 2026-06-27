# Lokus – Gayrimenkul Konum Radarı

iOS 17+ SwiftUI uygulaması. MVVM mimarisi, sıfır sunucu maliyeti (ücretli API yok).

## Veri Mimarisi (Hibrit)

Türkiye'de **32.000+ mahalle** ve **18.000+ köy** olduğu için tüm yerleşimleri statik JSON'da tutmak pratik değildir. Lokus üç katmanlı bir yapı kullanır:

```
┌─────────────────────────────────────────────────────────┐
│  KATMAN 1 — Yerel (çevrimdışı, ~200 KB)                 │
│  administrative_index.json → 81 il + 973 ilçe           │
│  Kaynak: TurkiyeAPI 2025 veri seti (TÜİK MEDAS)        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  KATMAN 2 — Geocoder (ücretsiz, Apple)                  │
│  CLGeocoder → il / ilçe / mahalle adı                   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  KATMAN 3 — Çevrimiçi (ücretsiz, TurkiyeAPI)            │
│  Mahalle/köy doğrulama + resmi nüfus                    │
│  api.turkiyeapi.dev — API anahtarı gerekmez             │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  KATMAN 4 — Tahmin modeli (on-device)                   │
│  RegionEstimator → fiyat, imar, altyapı tahmini         │
│  İl ortalaması × ilçe çarpanı × kentsel/rural profil    │
└─────────────────────────────────────────────────────────┘
```

**Önemli:** Fiyat ve imar verileri **tahmindir**; resmi çap belgesi yerine geçmez.

### Neden ücretli yapay zeka yok?

Master prompt kuralı gereği OpenAI/Gemini gibi ücretli LLM API'leri kullanılmaz. Bunun yerine:

- **TurkiyeAPI** — ücretsiz, resmi idari veri (mahalle/köy adı + nüfus)
- **CLGeocoder** — ücretsiz konum çözümleme
- **RegionEstimator** — deterministik fiyat modeli (kalibrasyon yapılabilir)

## Veri Güncelleme

```bash
# 81 il + 973 ilçe indeksini TurkiyeAPI'den yeniden üret
python3 Scripts/build_admin_index.py
```

## Kurulum

1. `Lokus.xcodeproj` dosyasını Xcode ile açın
2. **Signing & Capabilities** altında Development Team seçin
3. Simulator veya cihazda çalıştırın

## Yapılandırma

```bash
cp Lokus/Config/Secrets.plist.example Lokus/Config/Secrets.plist
```

`Secrets.plist` içinde RevenueCat public API anahtarınızı girin.

### StoreKit Test

Xcode → **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration** → `Lokus/Config/Products.storekit`

## Sonraki Adımlar (planlanan)

- [ ] App Store Connect + RevenueCat entitlement kurulumu
- [ ] Gerçek ilçe/mahalle verisiyle fiyat kalibrasyonu
- [ ] TestFlight / App Store gönderim hazırlığı

## Bundle ID

`com.sinannergiz.lokus`

## Lisans

MIT — Copyright (c) 2025 Sinan Nergiz
