# Lokus — App Store Connect & RevenueCat Kurulum Rehberi

Bu rehber, Premium aboneliği canlıya almak için gereken adımları sırayla listeler.

## Ön koşullar

- [Apple Developer Program](https://developer.apple.com/programs/) üyeliği (99 USD/yıl)
- [App Store Connect](https://appstoreconnect.apple.com) erişimi
- [RevenueCat](https://app.revenuecat.com) hesabı (ücretsiz başlangıç planı yeterli)

---

## BÖLÜM 1 — App Store Connect

### 1.1 Uygulama kaydı

1. App Store Connect → **My Apps** → **+** → **New App**
2. Alanlar:

| Alan | Değer |
|------|-------|
| Platform | iOS |
| Name | Lokus |
| Primary Language | Turkish |
| Bundle ID | `com.sinannergiz.lokus` |
| SKU | `lokus-ios-001` |
| User Access | Full Access |

### 1.2 Abonelik grubu

1. Uygulama → **Subscriptions** → **+** (Subscription Group)
2. **Reference Name:** `Lokus Premium`
3. Grup içinde **+** ile abonelik oluştur:

| Alan | Değer |
|------|-------|
| Reference Name | Lokus Premium Yıllık |
| Product ID | `lokus_premium_annual` |
| Subscription Duration | 1 Year |

4. **Subscription Prices** → Türkiye fiyatı belirleyin (ör. ₺499,99)
5. **Localization (Turkish):**
   - Display Name: `Lokus Premium Yıllık`
   - Description: `Sınırsız bölge analizi, PDF belgeler ve reklamsız deneyim.`

### 1.3 Sözleşmeler

1. App Store Connect → **Agreements, Tax, and Banking**
2. **Paid Applications** sözleşmesini imzalayın
3. Banka ve vergi bilgilerini tamamlayın (abonelik geliri için zorunlu)

### 1.4 App Store bilgileri (TestFlight öncesi)

- **Privacy Policy URL** (zorunlu — kendi sitenizde yayınlayın)
- **Category:** Navigation veya Lifestyle
- **Age Rating** anketi doldurun
- Ekran görüntüleri (6.7" ve 6.5" iPhone)

---

## BÖLÜM 2 — RevenueCat

### 2.1 Proje oluşturma

1. [RevenueCat Dashboard](https://app.revenuecat.com) → **+ New Project**
2. Proje adı: `Lokus`

### 2.2 iOS uygulaması ekleme

1. **Project Settings** → **Apps** → **+ New**
2. **App name:** Lokus iOS
3. **Bundle ID:** `com.sinannergiz.lokus`
4. **App Store Connect Shared Secret** (isteğe bağlı, abonelik doğrulama için önerilir):
   - App Store Connect → Uygulama → **General** → **App Information** → **App-Specific Shared Secret**

### 2.3 API anahtarı

1. **Project Settings** → **API keys**
2. **Public API key** (iOS) kopyalayın — `appl_` ile başlar
3. Projede `Lokus/Config/Secrets.plist` dosyasını güncelleyin:

```xml
<key>REVENUECAT_API_KEY</key>
<string>appl_XXXXXXXXXXXXXXXXXXXX</string>
```

### 2.4 Entitlement

1. **Product catalog** → **Entitlements** → **+ New**
2. **Identifier:** `premium` (kodda `Constants.premiumEntitlementID` ile eşleşmeli)
3. **Display name:** Lokus Premium

### 2.5 Ürün bağlama

1. **Products** → **+ New** → **App Store**
2. **Product identifier:** `lokus_premium_annual`
3. Entitlement olarak `premium` seçin

### 2.6 Offering

1. **Offerings** → **+ New Offering**
2. **Identifier:** `default` (RevenueCat varsayılan offering)
3. **Packages** → **+** → **Annual**
4. Ürün: `lokus_premium_annual`
5. **Make Current** ile aktif offering yapın

---

## BÖLÜM 3 — Xcode

### 3.1 Signing

1. Xcode → Lokus target → **Signing & Capabilities**
2. **Team:** Apple Developer hesabınız
3. **Bundle Identifier:** `com.sinannergiz.lokus`

### 3.2 StoreKit test (Simulator)

Scheme → **Run** → **Options** → **StoreKit Configuration:** `Lokus/Config/Products.storekit`

Simulator'da Profil → **Lokus Premium Satın Al** ile test edin.

### 3.3 Sandbox test (gerçek cihaz)

1. App Store Connect → **Users and Access** → **Sandbox** → Test hesabı oluşturun
2. iPhone → **Ayarlar → App Store → Sandbox Hesabı** ile giriş yapın
3. Xcode'dan cihaza yükleyip satın alma test edin

### 3.4 Kurulum doğrulama

```bash
./Scripts/verify_app_store_setup.sh
```

---

## BÖLÜM 4 — Kontrol listesi

| # | Görev | Durum |
|---|-------|-------|
| 1 | App Store Connect'te uygulama oluşturuldu | ☐ |
| 2 | `lokus_premium_annual` aboneliği tanımlandı | ☐ |
| 3 | Paid Apps sözleşmesi imzalandı | ☐ |
| 4 | RevenueCat projesi + iOS app eklendi | ☐ |
| 5 | `premium` entitlement oluşturuldu | ☐ |
| 6 | Offering `default` current yapıldı | ☐ |
| 7 | `Secrets.plist` → `appl_` API key yazıldı | ☐ |
| 8 | StoreKit / Sandbox satın alma testi geçti | ☐ |
| 9 | Privacy Policy URL hazır | ☐ |

---

## Kimlik özeti (kopyala-yapıştır)

```
Bundle ID:        com.sinannergiz.lokus
Product ID:       lokus_premium_annual
Entitlement ID:   premium
Offering ID:      default
Subscription:     1 Year (Auto-Renewable)
```

---

## Sıradaki adım

Kurulum tamamlandıktan sonra:
1. Gerçek ilçe/mahalle verisiyle fiyat kalibrasyonu
2. TestFlight build yükleme
3. App Store inceleme gönderimi
