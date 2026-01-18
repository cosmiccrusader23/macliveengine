#!/bin/bash

# Quick build script for MacLiveEngine
# Compiles directly using swiftc without Xcode

set -e

APP_NAME="MacLiveEngine"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building $APP_NAME..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Find all Swift files
SWIFT_FILES=$(find MacLiveEngine -name "*.swift" -type f | grep -v ".build" | sort)

echo "📁 Found Swift files:"
echo "$SWIFT_FILES" | while read f; do echo "   $f"; done

# Compile
echo "🔧 Compiling..."
swiftc \
    -target arm64-apple-macos14.0 \
    -sdk $(xcrun --sdk macosx --show-sdk-path) \
    -O \
    -whole-module-optimization \
    -import-objc-header /dev/null \
    -framework Cocoa \
    -framework AVFoundation \
    -framework AVKit \
    -framework WebKit \
    -framework IOKit \
    -framework CoreGraphics \
    -framework Metal \
    -framework MetalKit \
    -framework QuartzCore \
    -framework ServiceManagement \
    -o "$MACOS/$APP_NAME" \
    $SWIFT_FILES

# Create Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MacLiveEngine</string>
    <key>CFBundleDisplayName</key>
    <string>MacLiveEngine</string>
    <key>CFBundleIdentifier</key>
    <string>com.macliveengine.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>MacLiveEngine</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPL????" > "$CONTENTS/PkgInfo"

echo "✅ Build complete!"
echo "📦 App bundle: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
