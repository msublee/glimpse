#!/bin/bash
set -euo pipefail

CONFIG=${1:-release}
PRODUCT_NAME="Glimpse"
BUNDLE_IDENTIFIER="app.glimpse.local"
VERSION="0.1.0"
BUILD="1"
PLATFORM_BUILD_DIR=$(swift build -c "$CONFIG" --show-bin-path)

if [ ! -d "$PLATFORM_BUILD_DIR" ]; then
  echo "Failed to locate build directory" >&2
  exit 1
fi

EXECUTABLE_PATH="$PLATFORM_BUILD_DIR/$PRODUCT_NAME"
RESOURCES_BUNDLE="$PLATFORM_BUILD_DIR/${PRODUCT_NAME}_${PRODUCT_NAME}.bundle"

if [ ! -f "$EXECUTABLE_PATH" ]; then
  echo "Executable not found at $EXECUTABLE_PATH" >&2
  exit 1
fi

APP_DIR="$PWD/.build/$CONFIG/Glimpse.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>
    <key>CFBundleExecutable</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>GlimpseIcon</string>
</dict>
</plist>
PLIST

cp "$EXECUTABLE_PATH" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"

if [ -d "$RESOURCES_BUNDLE" ]; then
  cp -R "$RESOURCES_BUNDLE" "$APP_DIR/Contents/Resources/"
fi

ICONSET_DIR=$(mktemp -d)/Glimpse.iconset
mkdir -p "$ICONSET_DIR"
ASSET_DIR="$PWD/Sources/Glimpse/Resources/Assets.xcassets/AppIcon.appiconset"

cp "$ASSET_DIR/GlimpseIcon-16.png"  "$ICONSET_DIR/icon_16x16.png"
cp "$ASSET_DIR/GlimpseIcon-32.png"  "$ICONSET_DIR/icon_16x16@2x.png"
cp "$ASSET_DIR/GlimpseIcon-32.png"  "$ICONSET_DIR/icon_32x32.png"
cp "$ASSET_DIR/GlimpseIcon-64.png"  "$ICONSET_DIR/icon_32x32@2x.png"
cp "$ASSET_DIR/GlimpseIcon-128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$ASSET_DIR/GlimpseIcon-256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$ASSET_DIR/GlimpseIcon-256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$ASSET_DIR/GlimpseIcon-512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$ASSET_DIR/GlimpseIcon-512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$ASSET_DIR/GlimpseIcon-1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/GlimpseIcon.icns"

rm -rf "${ICONSET_DIR%/*}"

codesign --force --sign - "$APP_DIR"

echo "Created $APP_DIR"
echo "Copy it to /Applications with:"
echo "  cp -R '$APP_DIR' /Applications"
