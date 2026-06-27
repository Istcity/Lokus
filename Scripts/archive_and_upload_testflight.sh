#!/bin/bash
# Lokus — Archive + TestFlight yükleme
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Lokus"
PROJECT="$ROOT/Lokus.xcodeproj"
ARCHIVE_PATH="$ROOT/build/Lokus.xcarchive"
EXPORT_PATH="$ROOT/build/export"
EXPORT_OPTIONS="$ROOT/Lokus/Config/ExportOptions.plist"
TEAM_ID="R9VURFRPRC"

cd "$ROOT"
mkdir -p build

echo "=== 1/3 — Release Archive ==="
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates

echo ""
echo "=== 2/3 — App Store Connect'e Yükleme ==="
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates

echo ""
echo "=== 3/3 — Tamamlandı ==="
echo "App Store Connect → TestFlight sekmesinden build işlenmesini bekleyin (5–30 dk)."
echo "https://appstoreconnect.apple.com"
