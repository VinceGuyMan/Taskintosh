#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

ARM64_SCRATCH=".build/scratch-arm64"
X86_SCRATCH=".build/scratch-x86_64"
UNIVERSAL_RELEASE_DIR=".build/universal-macosx/release"

mkdir -p "$UNIVERSAL_RELEASE_DIR"

echo "--> Building arm64..."
swift build -c release --arch arm64 --scratch-path "$ARM64_SCRATCH"
ARM64_BIN_DIR=$(swift build -c release --arch arm64 --scratch-path "$ARM64_SCRATCH" --show-bin-path)
ARM64_BIN="$ARM64_BIN_DIR/Taskintosh"

echo "--> Building x86_64..."
swift build -c release --arch x86_64 --scratch-path "$X86_SCRATCH"
X86_BIN_DIR=$(swift build -c release --arch x86_64 --scratch-path "$X86_SCRATCH" --show-bin-path)
X86_BIN="$X86_BIN_DIR/Taskintosh"

# Fallback lookup if show-bin-path does not point directly to the binary file
if [ ! -f "$ARM64_BIN" ]; then
    ARM64_BIN=$(find "$ARM64_SCRATCH" -type f -name "Taskintosh" -perm +111 ! -path "*.dSYM*" 2>/dev/null | head -n 1)
fi
if [ ! -f "$X86_BIN" ]; then
    X86_BIN=$(find "$X86_SCRATCH" -type f -name "Taskintosh" -perm +111 ! -path "*.dSYM*" 2>/dev/null | head -n 1)
fi

UNIVERSAL_BIN="$UNIVERSAL_RELEASE_DIR/Taskintosh"

if [ -f "$ARM64_BIN" ] && [ -f "$X86_BIN" ]; then
    echo "==> Creating universal binary from arm64 and x86_64..."
    lipo -create "$ARM64_BIN" "$X86_BIN" -output "$UNIVERSAL_BIN"
elif [ -f "$ARM64_BIN" ]; then
    echo "==> Packaging arm64 binary (x86_64 not built)..."
    cp "$ARM64_BIN" "$UNIVERSAL_BIN"
elif [ -f "$X86_BIN" ]; then
    echo "==> Packaging x86_64 binary (arm64 not built)..."
    cp "$X86_BIN" "$UNIVERSAL_BIN"
else
    echo "❌ Error: Could not find built Taskintosh executable in $ARM64_SCRATCH or $X86_SCRATCH"
    exit 1
fi

echo "==> Universal executable:"
lipo -info "$UNIVERSAL_BIN"

APP_DIR="build/Taskintosh.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "==> Creating macOS App Bundle at $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR/Eras"

# Copy universal binary
cp "$UNIVERSAL_RELEASE_DIR/Taskintosh" "$MACOS_DIR/Taskintosh"

# Copy SwiftPM generated resource bundles (required for Bundle.module)
cp -R "$ARM64_BIN_DIR"/*.bundle "$RESOURCES_DIR/" 2>/dev/null || true
if [ -d "$X86_BIN_DIR" ]; then
    cp -R "$X86_BIN_DIR"/*.bundle "$RESOURCES_DIR/" 2>/dev/null || true
fi

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
    <string>1.2.0</string>
    <key>CFBundleVersion</key>
    <string>3</string>
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

chmod -R 755 "$APP_DIR"
xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true

echo "==> Signing app bundle with designated requirement..."
codesign --force --deep --sign - --identifier org.taskintosh.Taskintosh -r='designated => identifier "org.taskintosh.Taskintosh"' "$APP_DIR"

# Also sync to scripts/build/Taskintosh.app so both locations are valid and ready to run
mkdir -p "$SCRIPT_DIR/build"
rm -rf "$SCRIPT_DIR/build/Taskintosh.app"
cp -R "$APP_DIR" "$SCRIPT_DIR/build/Taskintosh.app"
chmod -R 755 "$SCRIPT_DIR/build/Taskintosh.app"
xattr -dr com.apple.quarantine "$SCRIPT_DIR/build/Taskintosh.app" 2>/dev/null || true
codesign --force --deep --sign - --identifier org.taskintosh.Taskintosh -r='designated => identifier "org.taskintosh.Taskintosh"' "$SCRIPT_DIR/build/Taskintosh.app"

echo "==> Packaging complete: $APP_DIR and $SCRIPT_DIR/build/Taskintosh.app"

