#!/bin/zsh
#
# MacLiveEngine Build & Distribution Script
# ==========================================
# This script compiles the MacLiveEngine project and creates a distributable DMG.
#
# Usage:
#   ./build.sh [options]
#
# Options:
#   --release       Build in Release configuration (default)
#   --debug         Build in Debug configuration
#   --clean         Clean build before compiling
#   --sign          Sign the application (requires Developer ID)
#   --notarize      Notarize for distribution (requires Apple Developer account)
#   --dmg           Create DMG after building
#   --all           Build, sign, and create DMG
#   --help          Show this help message
#

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================

PROJECT_NAME="MacLiveEngine"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODEPROJ="${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
APP_PATH="${BUILD_DIR}/Release/${PROJECT_NAME}.app"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_OUTPUT="${BUILD_DIR}/${PROJECT_NAME}.dmg"

# Code signing identity (change to your Developer ID)
DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
# For ad-hoc signing (no Developer ID), use: "-"
SIGNING_IDENTITY="${DEVELOPER_ID:-"-"}"

# Notarization credentials (set via environment or keychain)
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"  # App-specific password

# Configuration
CONFIGURATION="Release"
SHOULD_CLEAN=false
SHOULD_SIGN=false
SHOULD_NOTARIZE=false
SHOULD_CREATE_DMG=false

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1" >&2
}

print_info() {
    echo "ℹ️  $1"
}

print_step() {
    echo "▶️  $1"
}

show_help() {
    head -n 20 "$0" | tail -n 16
    exit 0
}

check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools not found. Install with: xcode-select --install"
        exit 1
    fi
    print_success "Xcode command line tools found"
}

check_project() {
    if [ ! -d "$XCODEPROJ" ]; then
        print_error "Xcode project not found at: $XCODEPROJ"
        exit 1
    fi
    print_success "Project found: $XCODEPROJ"
}

# ============================================================================
# Build Functions
# ============================================================================

clean_build() {
    print_step "Cleaning previous build..."
    rm -rf "$BUILD_DIR"
    xcodebuild clean -project "$XCODEPROJ" -scheme "$PROJECT_NAME" -configuration "$CONFIGURATION" 2>/dev/null || true
    print_success "Clean complete"
}

build_app() {
    print_header "Building ${PROJECT_NAME}"
    
    print_step "Building ${CONFIGURATION} configuration..."
    
    mkdir -p "$BUILD_DIR"
    
    xcodebuild build \
        -project "$XCODEPROJ" \
        -scheme "$PROJECT_NAME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        CONFIGURATION_BUILD_DIR="$BUILD_DIR/$CONFIGURATION" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        | xcpretty 2>/dev/null || xcodebuild build \
            -project "$XCODEPROJ" \
            -scheme "$PROJECT_NAME" \
            -configuration "$CONFIGURATION" \
            -derivedDataPath "$BUILD_DIR/DerivedData" \
            CONFIGURATION_BUILD_DIR="$BUILD_DIR/$CONFIGURATION" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO
    
    if [ -d "$APP_PATH" ]; then
        print_success "Build successful: $APP_PATH"
    else
        print_error "Build failed - app bundle not found"
        exit 1
    fi
}

# ============================================================================
# Code Signing
# ============================================================================

sign_app() {
    print_header "Code Signing"
    
    if [ "$SIGNING_IDENTITY" = "-" ]; then
        print_step "Performing ad-hoc signing..."
        codesign --force --deep --sign - "$APP_PATH"
    else
        print_step "Signing with Developer ID: $SIGNING_IDENTITY"
        
        # Sign frameworks and helpers first
        find "$APP_PATH/Contents/Frameworks" -name "*.framework" -o -name "*.dylib" 2>/dev/null | while read framework; do
            codesign --force --options runtime --sign "$SIGNING_IDENTITY" "$framework"
        done
        
        # Sign the main app
        codesign --force --options runtime --deep --sign "$SIGNING_IDENTITY" \
            --entitlements "${PROJECT_DIR}/${PROJECT_NAME}/Resources/${PROJECT_NAME}.entitlements" \
            "$APP_PATH"
    fi
    
    # Verify signature
    print_step "Verifying signature..."
    codesign --verify --verbose "$APP_PATH"
    print_success "Code signing complete"
}

# ============================================================================
# Notarization (requires Apple Developer account)
# ============================================================================

notarize_app() {
    print_header "Notarization"
    
    if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
        print_error "Notarization requires APPLE_ID, TEAM_ID, and APP_PASSWORD environment variables"
        exit 1
    fi
    
    # Create a ZIP for notarization
    print_step "Creating ZIP for notarization..."
    local NOTARIZE_ZIP="${BUILD_DIR}/${PROJECT_NAME}-notarize.zip"
    ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"
    
    # Submit for notarization
    print_step "Submitting for notarization..."
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_PASSWORD" \
        --wait
    
    # Staple the notarization ticket
    print_step "Stapling notarization ticket..."
    xcrun stapler staple "$APP_PATH"
    
    # Cleanup
    rm -f "$NOTARIZE_ZIP"
    
    print_success "Notarization complete"
}

# ============================================================================
# DMG Creation
# ============================================================================

create_dmg() {
    print_header "Creating DMG"
    
    # Clean up previous DMG
    rm -rf "$DMG_DIR"
    rm -f "$DMG_OUTPUT"
    
    # Create DMG directory structure
    print_step "Creating DMG structure..."
    mkdir -p "$DMG_DIR"
    cp -R "$APP_PATH" "$DMG_DIR/"
    
    # Create Applications symlink
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Create a background instructions file
    cat > "$DMG_DIR/.background_instructions.txt" << 'EOF'
Drag MacLiveEngine to the Applications folder to install.

After installation:
1. Open MacLiveEngine from Applications
2. Grant accessibility permissions if prompted
3. Select a wallpaper from the menu bar icon

Enjoy your dynamic wallpaper!
EOF
    
    # Create README
    cat > "$DMG_DIR/README.txt" << 'EOF'
MacLiveEngine - Dynamic Wallpaper Engine for macOS
==================================================

Installation:
1. Drag MacLiveEngine.app to the Applications folder
2. Launch from Applications or Spotlight

First Run:
- The app will appear in your menu bar (no dock icon)
- Click the menu bar icon to select wallpapers
- Grant permissions when prompted for full functionality

Supported Formats:
- Video: MP4, MOV, M4V, WebM
- Web: HTML (with CSS/JS/WebGL support)
- Scenes: JSON-based particle effects
- Images: PNG, JPG, GIF, WebP, HEIC

Tips:
- Wallpapers automatically pause when desktop is hidden
- Battery optimization reduces FPS when unplugged
- Use Preferences to customize behavior

For help: https://github.com/macliveengine

EOF
    
    # Calculate DMG size (app size + 50MB buffer)
    local APP_SIZE=$(du -sm "$DMG_DIR" | cut -f1)
    local DMG_SIZE=$((APP_SIZE + 50))
    
    # Create the DMG
    print_step "Creating DMG image..."
    hdiutil create \
        -volname "$PROJECT_NAME" \
        -srcfolder "$DMG_DIR" \
        -ov \
        -format UDZO \
        -imagekey zlib-level=9 \
        "$DMG_OUTPUT"
    
    # Clean up
    rm -rf "$DMG_DIR"
    
    if [ -f "$DMG_OUTPUT" ]; then
        local DMG_SIZE_MB=$(du -h "$DMG_OUTPUT" | cut -f1)
        print_success "DMG created: $DMG_OUTPUT ($DMG_SIZE_MB)"
    else
        print_error "DMG creation failed"
        exit 1
    fi
}

# ============================================================================
# Create Fancy DMG with background (optional)
# ============================================================================

create_fancy_dmg() {
    print_header "Creating Fancy DMG"
    
    local TEMP_DMG="${BUILD_DIR}/${PROJECT_NAME}-temp.dmg"
    local VOLUME_NAME="$PROJECT_NAME"
    
    # Create a temporary read-write DMG
    print_step "Creating temporary DMG..."
    rm -f "$TEMP_DMG" "$DMG_OUTPUT"
    hdiutil create -size 200m -fs HFS+ -volname "$VOLUME_NAME" "$TEMP_DMG"
    
    # Mount the DMG
    print_step "Mounting DMG..."
    local MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | grep "/Volumes/" | sed 's/.*\(\/Volumes\/.*\)/\1/' | head -1)
    
    if [ -z "$MOUNT_POINT" ]; then
        print_error "Failed to mount DMG"
        exit 1
    fi
    
    print_info "Mounted at: $MOUNT_POINT"
    
    # Copy app
    print_step "Copying application..."
    cp -R "$APP_PATH" "$MOUNT_POINT/"
    
    # Create Applications symlink
    ln -s /Applications "$MOUNT_POINT/Applications"
    
    # Set up the DMG window appearance using AppleScript
    print_step "Configuring DMG appearance..."
    osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 450}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "${PROJECT_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {350, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
    
    # Sync and unmount
    print_step "Finalizing DMG..."
    sync
    hdiutil detach "$MOUNT_POINT" -force
    
    # Convert to compressed read-only DMG
    print_step "Compressing DMG..."
    hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUTPUT"
    
    # Clean up
    rm -f "$TEMP_DMG"
    
    if [ -f "$DMG_OUTPUT" ]; then
        local DMG_SIZE_MB=$(du -h "$DMG_OUTPUT" | cut -f1)
        print_success "Fancy DMG created: $DMG_OUTPUT ($DMG_SIZE_MB)"
    else
        print_error "DMG creation failed"
        exit 1
    fi
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    print_header "MacLiveEngine Build System"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --release)
                CONFIGURATION="Release"
                shift
                ;;
            --debug)
                CONFIGURATION="Debug"
                shift
                ;;
            --clean)
                SHOULD_CLEAN=true
                shift
                ;;
            --sign)
                SHOULD_SIGN=true
                shift
                ;;
            --notarize)
                SHOULD_NOTARIZE=true
                SHOULD_SIGN=true
                shift
                ;;
            --dmg)
                SHOULD_CREATE_DMG=true
                shift
                ;;
            --all)
                SHOULD_CLEAN=true
                SHOULD_SIGN=true
                SHOULD_CREATE_DMG=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
    
    # Check prerequisites
    check_xcode
    check_project
    
    # Build process
    if $SHOULD_CLEAN; then
        clean_build
    fi
    
    build_app
    
    if $SHOULD_SIGN; then
        sign_app
    fi
    
    if $SHOULD_NOTARIZE; then
        notarize_app
    fi
    
    if $SHOULD_CREATE_DMG; then
        create_fancy_dmg
    fi
    
    # Summary
    print_header "Build Complete"
    echo "Configuration: $CONFIGURATION"
    echo "App Bundle:    $APP_PATH"
    [ -f "$DMG_OUTPUT" ] && echo "DMG File:      $DMG_OUTPUT"
    echo ""
    print_success "All tasks completed successfully!"
}

# Run main function
main "$@"
