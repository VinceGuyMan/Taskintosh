#!/bin/bash
set -e

echo "==> Building Taskintosh (Release)..."
swift build -c release --arch arm64
swift build -c release --arch x86_64

UNIVERSAL_RELEASE_DIR=".build/universal-macosx/release"
mkdir -p "$UNIVERSAL_RELEASE_DIR"
lipo -create \
    ".build/arm64-apple-macosx/release/Taskintosh" \
    ".build/x86_64-apple-macosx/release/Taskintosh" \
    -output "$UNIVERSAL_RELEASE_DIR/Taskintosh"
echo "==> Universal executable:"
lipo -info "$UNIVERSAL_RELEASE_DIR/Taskintosh"

APP_DIR="build/Taskintosh.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "==> Creating macOS App Bundle at $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR/Eras"

# Copy universal binary
cp "$UNIVERSAL_RELEASE_DIR/Taskintosh" "$MACOS_DIR/Taskintosh"

# Copy Era packages
cp -R Sources/TaskintoshKit/Resources/Eras/* "$RESOURCES_DIR/Eras/"

# Copy Brand Assets & AppIcon
mkdir -p "$RESOURCES_DIR/Brand"
cp Sources/TaskintoshKit/Resources/Brand/* "$RESOURCES_DIR/Brand/" 2>/dev/null || true
cp Sources/Taskintosh/Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
cp Sources/Taskintosh/Resources/*.png "$RESOURCES_DIR/" 2>/dev/null || true

# Create Info.plist
cat << 'PLIST' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Taskintosh</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>org.taskintosh.Taskintosh</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Taskintosh</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Packaging complete: $APP_DIR"
