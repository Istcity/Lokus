#!/bin/bash
# Lokus — App Store / RevenueCat kurulum doğrulayıcı

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$ROOT/Lokus/Config/Secrets.plist"
ERRORS=0

warn() { echo "⚠️  $1"; }
ok()   { echo "✅ $1"; }
fail() { echo "❌ $1"; ERRORS=$((ERRORS + 1)); }

echo "=== Lokus App Store Kurulum Kontrolü ==="
echo ""

# Xcode project
if [ -f "$ROOT/Lokus.xcodeproj/project.pbxproj" ]; then
    ok "Xcode projesi mevcut"
else
    fail "Lokus.xcodeproj bulunamadı"
fi

# Bundle ID
if grep -q "com.sinannergiz.lokus" "$ROOT/Lokus.xcodeproj/project.pbxproj" 2>/dev/null; then
    ok "Bundle ID: com.sinannergiz.lokus"
else
    fail "Bundle ID project.pbxproj içinde bulunamadı"
fi

# StoreKit config
if [ -f "$ROOT/Lokus/Config/Products.storekit" ]; then
    ok "Products.storekit mevcut"
    if grep -q "lokus_premium_annual" "$ROOT/Lokus/Config/Products.storekit"; then
        ok "Product ID: lokus_premium_annual"
    else
        fail "Products.storekit içinde lokus_premium_annual yok"
    fi
else
    fail "Products.storekit bulunamadı"
fi

# Privacy manifest
if [ -f "$ROOT/Lokus/PrivacyInfo.xcprivacy" ]; then
    ok "PrivacyInfo.xcprivacy mevcut"
else
    warn "PrivacyInfo.xcprivacy eksik (App Store için önerilir)"
fi

# Secrets.plist
if [ -f "$SECRETS" ]; then
    ok "Secrets.plist mevcut"
    if grep -q "YOUR_REVENUECAT" "$SECRETS" 2>/dev/null; then
        warn "REVENUECAT_API_KEY henüz yapılandırılmamış (appl_... yazın)"
    elif grep -q "appl_" "$SECRETS" 2>/dev/null; then
        ok "RevenueCat API anahtarı yapılandırılmış"
    else
        warn "RevenueCat API anahtarı formatı beklenmiyor (appl_ ile başlamalı)"
    fi
else
    fail "Secrets.plist bulunamadı — cp Lokus/Config/Secrets.plist.example Lokus/Config/Secrets.plist"
fi

# Administrative index
if [ -f "$ROOT/Lokus/Data/administrative_index.json" ]; then
    DISTRICTS=$(python3 -c "import json; d=json.load(open('$ROOT/Lokus/Data/administrative_index.json')); print(d['districtCount'])" 2>/dev/null || echo "?")
    ok "administrative_index.json — $DISTRICTS ilçe"
else
    fail "administrative_index.json eksik — python3 Scripts/build_admin_index.py çalıştırın"
fi

# App icon
if [ -f "$ROOT/Lokus/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" ]; then
    ok "App Icon mevcut"
else
    warn "App Icon 1024x1024 eksik"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "=== Sonuç: Hazırlık tamam (uyarılar olabilir) ==="
    echo "Detaylı adımlar: Lokus/Config/APP_STORE_SETUP.md"
    exit 0
else
    echo "=== Sonuç: $ERRORS kritik eksik ==="
    exit 1
fi
