#!/usr/bin/env bash
# Build and package macOS application as .app bundle and DMG
set -euo pipefail

# Configuration
APP_NAME=${1:-MinTik}
VERSION=${2:-1.0}
OUT_DIR=${3:-dist}

echo "🏗️  Building ${APP_NAME}..."

# Build in release mode
echo "  → Compiling release build..."
BUNDLE_ID_SUFFIX=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
# Explicitly build first to ensure we have latest code
swift build -c release

BIN_DIR=$(swift build -c release --show-bin-path)

# Create app bundle structure
APP_DIR=build/"${APP_NAME}.app"
echo "  → Creating app bundle structure..."
mkdir -p "${APP_DIR}/Contents/"{MacOS,Resources}

# Copy executable
echo "  → Copying executable..."
cp "${BIN_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Make executable
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

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
  <string>com.example.${BUNDLE_ID_SUFFIX}</string>
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
if [ -d "Sources/${APP_NAME}/Resources" ]; then
    echo "  → Copying app resources..."
    cp -R Sources/"${APP_NAME}"/Resources/* "${APP_DIR}/Contents/Resources/" 2>/dev/null || true
fi

# Copy app icon if it exists (common locations)
for icon_path in "resources/AppIcon.icns" "Sources/${APP_NAME}/Resources/AppIcon.icns" "AppIcon.icns"; do
    if [ -f "$icon_path" ]; then
        echo "  → Adding app icon..."
        cp "$icon_path" "${APP_DIR}/Contents/Resources/AppIcon.icns"
        # Add icon reference to Info.plist
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "${APP_DIR}/Contents/Info.plist" 2>/dev/null || true
        break
    fi
done

# Sign the app bundle (ad-hoc signing)
echo "  → Signing app bundle..."
codesign --force --deep --sign - "${APP_DIR}"

echo "✅ App bundle created: ${APP_DIR}"
echo ""

# Create DMG
echo "📀 Creating DMG installer..."
if ! command -v npm &> /dev/null; then
    echo "Error: npm is required to run appdmg. Please install Node.js and npm."
    exit 1
fi

# Install appdmg if not present (optional, npx handles it but good to check)
# Using npx to run appdmg
mkdir -p "${OUT_DIR}"
rm -f "${OUT_DIR}/${APP_NAME}.dmg"
npx --yes appdmg scripts/dmg.json "${OUT_DIR}/${APP_NAME}.dmg"

echo "✅ DMG created successfully: ${OUT_DIR}/${APP_NAME}.dmg"