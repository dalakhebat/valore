#!/bin/zsh
# Build Release lalu pasang ke iPhone yang tersambung (kabel atau Wi-Fi).
# Dengan Apple ID gratis, app kedaluwarsa tiap 7 hari: jalankan skrip ini lagi. Data di iPhone tetap aman.
#
# Pakai: scripts/install-iphone.sh [UDID]
# Tanpa UDID, dipakai iPhone fisik pertama yang terdeteksi.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f Config/Local.xcconfig ]]; then
  echo "Config/Local.xcconfig belum ada. Isi dengan: DEVELOPMENT_TEAM = <Team ID kamu>" >&2
  exit 1
fi

device="${1:-}"
if [[ -z "$device" ]]; then
  device=$(xcrun devicectl list devices 2>/dev/null | awk '/physical/ && /iPhone/ && /connected|available/ { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9A-F]{8}-[0-9A-F]{16}$/) { print $i; exit } }')
fi
if [[ -z "$device" ]]; then
  echo "iPhone tidak terdeteksi. Colok kabel, buka kunci iPhone, lalu coba lagi." >&2
  exit 1
fi

derived="${TMPDIR:-/tmp}/valore-device-build"

echo "→ Generate project"
xcodegen generate --quiet

echo "→ Build Release untuk $device"
xcodebuild build \
  -project Valore.xcodeproj -scheme Valore -configuration Release \
  -destination "id=$device" -derivedDataPath "$derived" \
  -allowProvisioningUpdates -quiet

echo "→ Pasang ke iPhone"
xcrun devicectl device install app --device "$device" "$derived/Build/Products/Release-iphoneos/Valore.app" >/dev/null

echo "✓ VALORE terpasang. Berlaku 7 hari dengan Apple ID gratis."
