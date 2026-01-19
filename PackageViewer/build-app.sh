#!/bin/bash
# Build script for PackageViewer.app

set -e

echo "Building PackageViewer..."

# Build release version
swift build -c release

# Create .icns icon file first
echo "Creating app icon..."
rm -rf /tmp/AppIcon.iconset
mkdir -p /tmp/AppIcon.iconset

ICONSET_DIR="Sources/PackageViewer/Resources/Assets.xcassets/AppIcon.appiconset"
cp "$ICONSET_DIR/icon_16x16.png" /tmp/AppIcon.iconset/icon_16x16.png
cp "$ICONSET_DIR/icon_32x32.png" /tmp/AppIcon.iconset/icon_16x16@2x.png
cp "$ICONSET_DIR/icon_32x32.png" /tmp/AppIcon.iconset/icon_32x32.png
cp "$ICONSET_DIR/icon_64x64.png" /tmp/AppIcon.iconset/icon_32x32@2x.png
cp "$ICONSET_DIR/icon_128x128.png" /tmp/AppIcon.iconset/icon_128x128.png
cp "$ICONSET_DIR/icon_256x256.png" /tmp/AppIcon.iconset/icon_128x128@2x.png
cp "$ICONSET_DIR/icon_256x256.png" /tmp/AppIcon.iconset/icon_256x256.png
cp "$ICONSET_DIR/icon_512x512.png" /tmp/AppIcon.iconset/icon_256x256@2x.png
cp "$ICONSET_DIR/icon_512x512.png" /tmp/AppIcon.iconset/icon_512x512.png
cp "$ICONSET_DIR/icon_1024x1024.png" /tmp/AppIcon.iconset/icon_512x512@2x.png

iconutil -c icns /tmp/AppIcon.iconset -o /tmp/AppIcon.icns

# App bundle paths
APP_BUNDLE=".build/arm64-apple-macosx/release/PackageViewer.app"
DEST_APP="/Users/fengxiaodong/Desktop/PackageViewer.app"

# Create app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp ".build/arm64-apple-macosx/release/PackageViewer" "$APP_BUNDLE/Contents/MacOS/"
chmod +x "$APP_BUNDLE/Contents/MacOS/PackageViewer"

# Copy .icns file (standard macOS icon format)
cp /tmp/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Create Info.plist with CFBundleIconFile
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PackageViewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.packageviewer</string>
    <key>CFBundleName</key>
    <string>PackageViewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Copy to Desktop
rm -rf "$DEST_APP"
cp -R "$APP_BUNDLE" "$DEST_APP"

# Remove extended attributes and code sign (required for icon display)
xattr -cr "$DEST_APP"
codesign --force --deep --sign - "$DEST_APP" > /dev/null 2>&1

# Update modification time to trigger icon refresh
touch "$DEST_APP"

# Clear icon cache and restart Dock
killall Dock 2>/dev/null || true
sleep 2

echo "✅ PackageViewer.app built successfully at: $DEST_APP"
echo ""
echo "To install, drag PackageViewer.app to /Applications"
