#!/usr/bin/env bash
# Build and package macOS application as .app bundle and DMG
set -euo pipefail

# Configuration
APP_NAME=${1:-MinTik}
VERSION=${2:-1.0}
OUT_DIR=${3:-dist}
BUNDLE_ID_PREFIX=${BUNDLE_ID_PREFIX:-com.example}
CODESIGN_IDENTITY=${CODESIGN_IDENTITY:-}
NOTARY_PROFILE=${NOTARY_PROFILE:-}
TEAM_ID=${TEAM_ID:-}

echo "🏗️  Building ${APP_NAME}..."

# Build in release mode
echo "  → Compiling release build..."
BUNDLE_ID_SUFFIX=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
BUNDLE_ID="${BUNDLE_ID_PREFIX}.${BUNDLE_ID_SUFFIX}"
# Explicitly build first to ensure we have latest code
swift build -c release

BIN_DIR=$(swift build -c release --show-bin-path)

# Create app bundle structure
APP_DIR=build/"${APP_NAME}.app"
echo "  → Creating app bundle structure..."
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/"{MacOS,Resources}

# Copy executable
echo "  → Copying executable..."
cp "${BIN_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Make executable
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Add launcher script for debug logging
cat >"${APP_DIR}/Contents/MacOS/start.sh" <<'LAUNCH'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$HOME/Library/Logs/MinTik"
mkdir -p "$LOG_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/run-$STAMP.log"
{
  echo "==== MinTik launch $STAMP ===="
  echo "Executable: $DIR/MinTik"
  echo "PWD: $(pwd)"
} >>"$LOG_FILE"
exec "$DIR/MinTik" "$@" >>"$LOG_FILE" 2>&1
LAUNCH

chmod +x "${APP_DIR}/Contents/MacOS/start.sh"

# Create Info.plist
echo "  → Generating Info.plist..."
cat >"${APP_DIR}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSUIElement</key>
  <false/>
  <key>NSUserNotificationsUsageDescription</key>
  <string>RestApp 需要通知权限来提醒你休息。</string>
</dict>
</plist>
EOF

# Copy resources if they exist
if [ -d "Sources/RestApp/Resources" ]; then
    echo "  → Copying app resources..."
    cp -R Sources/RestApp/Resources/* "${APP_DIR}/Contents/Resources/" 2>/dev/null || true
fi

# Ensure app icon is copied and referenced
ICON_SOURCE="Sources/RestApp/Resources/AppIcon.icns"
if [ -f "$ICON_SOURCE" ]; then
    echo "  → Adding app icon..."
    cp "$ICON_SOURCE" "${APP_DIR}/Contents/Resources/AppIcon.icns"
    # Add icon reference to Info.plist
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "${APP_DIR}/Contents/Info.plist" 2>/dev/null || true
else
    echo "  ⚠️  Warning: AppIcon.icns not found at $ICON_SOURCE"
fi

# Copy SwiftPM resource bundles (e.g., RestApp_RestApp.bundle)
echo "  → Checking for SwiftPM resource bundles..."
mkdir -p "${APP_DIR}/Contents/Resources"
for BUNDLE_PATH in "${BIN_DIR}"/*_*.bundle; do
    if [ -d "$BUNDLE_PATH" ]; then
        BUNDLE_NAME=$(basename "$BUNDLE_PATH")
        echo "     • Found bundle: $BUNDLE_NAME"
        cp -R "$BUNDLE_PATH" "${APP_DIR}/Contents/Resources/$BUNDLE_NAME"
    fi
done

# Sign the app bundle
echo "  → Signing app bundle..."
if [ -n "${CODESIGN_IDENTITY}" ]; then
    codesign --force --deep --options runtime --timestamp --sign "${CODESIGN_IDENTITY}" "${APP_DIR}"
else
    echo "  ⚠️  未提供 CODESIGN_IDENTITY，执行临时签名（ad-hoc）。"
    codesign --force --deep --sign - "${APP_DIR}"
fi

echo "✅ App bundle created: ${APP_DIR}"
echo ""

# Optional: notarize app before DMG
if [ -n "${NOTARY_PROFILE}" ] && [ -n "${CODESIGN_IDENTITY}" ]; then
    echo "🧾 Submitting for notarization..."
    ZIP_PATH="${OUT_DIR}/${APP_NAME}.zip"
    mkdir -p "${OUT_DIR}"
    rm -f "${ZIP_PATH}"
    /usr/bin/ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${ZIP_PATH}"
    xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
    echo "📎 Stapling notarization ticket to app..."
    xcrun stapler staple "${APP_DIR}" || true
else
    echo "  ℹ️  跳过公证：未配置 NOTARY_PROFILE 或未提供 CODESIGN_IDENTITY。"
fi

# Create DMG
echo "📀 Creating DMG installer..."

# Install appdmg if not present (optional, npx handles it but good to check)
# Using npx to run appdmg
mkdir -p "${OUT_DIR}"
rm -f "${OUT_DIR}/${APP_NAME}.dmg"
if command -v npm &> /dev/null; then
    npx --yes appdmg scripts/dmg.json "${OUT_DIR}/${APP_NAME}.dmg"
else
    echo "  ℹ️  npm 未安装，使用 hdiutil 生成基础 DMG"
    TMP_DIR=$(mktemp -d)
    mkdir -p "$TMP_DIR"
    cp -R "${APP_DIR}" "$TMP_DIR/${APP_NAME}.app"
    ln -s /Applications "$TMP_DIR/Applications"
    hdiutil create -volname "${APP_NAME}" -srcfolder "$TMP_DIR" -ov -format UDZO "${OUT_DIR}/${APP_NAME}.dmg"
    rm -rf "$TMP_DIR"
fi

# Staple DMG if notarization was used
if [ -n "${NOTARY_PROFILE}" ] && [ -f "${OUT_DIR}/${APP_NAME}.dmg" ]; then
    echo "📎 Stapling notarization ticket to DMG..."
    xcrun stapler staple "${OUT_DIR}/${APP_NAME}.dmg" || true
fi

echo "✅ DMG created successfully: ${OUT_DIR}/${APP_NAME}.dmg"
