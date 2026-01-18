#!/bin/bash

# Create DMG installer for MacLiveEngine
# This script creates a professional DMG with drag-to-Applications functionality

set -e

APP_NAME="MacLiveEngine"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR="./build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_FILE="${BUILD_DIR}/${DMG_NAME}.dmg"

echo "📦 Creating DMG for ${APP_NAME} v${VERSION}..."

# Check if app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at ${APP_BUNDLE}"
    echo "   Run ./quick_build.sh first to build the app."
    exit 1
fi

# Clean up any previous DMG build
rm -rf "$DMG_DIR"
rm -f "$DMG_FILE"
rm -f "${BUILD_DIR}/${DMG_NAME}-temp.dmg"

# Create DMG directory structure
mkdir -p "$DMG_DIR"

# Copy the app bundle
echo "📁 Copying app bundle..."
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create a symbolic link to Applications folder
echo "🔗 Creating Applications symlink..."
ln -s /Applications "$DMG_DIR/Applications"

# Create a background image with instructions (optional - using text file instead)
cat > "$DMG_DIR/.background_info.txt" << 'EOF'
Drag MacLiveEngine to Applications to install
EOF

# Create a README file
cat > "$DMG_DIR/README.txt" << 'EOF'
MacLiveEngine - Dynamic Wallpaper Engine for macOS
===================================================

Installation:
1. Drag "MacLiveEngine.app" to the "Applications" folder
2. Open MacLiveEngine from Applications
3. You'll see a 🎬 icon in your menu bar

Usage:
- Click the menu bar icon to access controls
- Select "Browse Wallpapers..." to choose videos, images, or HTML5 content
- Use Preferences to configure behavior

Supported formats:
- Video: MP4, MOV, M4V, WebM, AVI
- Image: PNG, JPG, JPEG, GIF, WebP, HEIC, TIFF
- Web: HTML5/CSS3/JavaScript (folder with index.html)

Requirements:
- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3) Mac

For issues or feedback, visit:
https://github.com/yourusername/MacLiveEngine

Enjoy your dynamic wallpapers! 🎬
EOF

# Create the DMG
echo "💿 Creating DMG image..."

# Calculate size needed (app size + 10MB buffer)
APP_SIZE=$(du -sm "$DMG_DIR" | cut -f1)
DMG_SIZE=$((APP_SIZE + 20))

# Create temporary DMG
hdiutil create -srcfolder "$DMG_DIR" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${DMG_SIZE}m \
    "${BUILD_DIR}/${DMG_NAME}-temp.dmg"

# Mount the temporary DMG
echo "🔧 Configuring DMG..."
MOUNT_DIR="/Volumes/${APP_NAME}"

# Unmount if already mounted
hdiutil detach "$MOUNT_DIR" 2>/dev/null || true

hdiutil attach "${BUILD_DIR}/${DMG_NAME}-temp.dmg" -readwrite -noverify -noautoopen

# Wait for mount
sleep 2

# Set custom icon positions using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 200, 900, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${APP_NAME}.app" of container window to {125, 150}
        set position of item "Applications" of container window to {375, 150}
        set position of item "README.txt" of container window to {250, 280}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Make sure writes are flushed
sync

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to compressed final DMG
echo "🗜️  Compressing DMG..."
hdiutil convert "${BUILD_DIR}/${DMG_NAME}-temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_FILE"

# Clean up
rm -f "${BUILD_DIR}/${DMG_NAME}-temp.dmg"
rm -rf "$DMG_DIR"

# Get final size
FINAL_SIZE=$(du -h "$DMG_FILE" | cut -f1)

echo ""
echo "✅ DMG created successfully!"
echo "📍 Location: $DMG_FILE"
echo "📊 Size: $FINAL_SIZE"
echo ""
echo "Share this DMG file with your friends!"
echo "They can install by:"
echo "  1. Double-click the DMG to open it"
echo "  2. Drag MacLiveEngine to Applications"
echo "  3. Eject the DMG"
echo "  4. Launch MacLiveEngine from Applications"
