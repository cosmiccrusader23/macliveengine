# MacLiveEngine

A high-performance, native macOS dynamic wallpaper engine inspired by Wallpaper Engine (Steam). Built entirely in Swift using AppKit, AVFoundation, WebKit, and Metal.

## Features

### Wallpaper Types
- **Video Wallpapers** - Hardware-accelerated playback via AVFoundation (4K/60fps)
- **Web Wallpapers** - Full HTML5/CSS3/JavaScript/WebGL support via WKWebView
- **Scene Wallpapers** - GPU-accelerated particle effects using Metal
- **Static Images** - PNG, JPEG, GIF, WebP, HEIC support

### Performance Optimizations
- **Automatic Pause** - Rendering stops when desktop is obscured by windows
- **Battery Awareness** - Reduces FPS or pauses when on battery power
- **Memory Management** - Web processes terminated when switching wallpapers
- **GPU Efficiency** - Near-zero resource usage when paused

### System Integration
- **Multi-Monitor** - Independent wallpapers per display
- **Mission Control** - Wallpapers stay behind all windows and icons
- **Spaces Support** - Persists across all virtual desktops
- **Menu Bar App** - Minimal UI, no dock icon

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ (for building)
- Apple Silicon or Intel Mac

## Building

### Using Xcode
```bash
open MacLiveEngine.xcodeproj
# Build with Cmd+B or Product > Build
```

### Using Command Line
```bash
# Full build with DMG creation
./build.sh --all

# Quick build without Xcode project
./quick_build.sh

# Options
./build.sh --release    # Release build (default)
./build.sh --debug      # Debug build
./build.sh --clean      # Clean before building
./build.sh --sign       # Code sign the app
./build.sh --dmg        # Create distributable DMG
./build.sh --notarize   # Notarize for distribution
```

## Installation

1. Download the latest DMG from Releases
2. Open the DMG and drag MacLiveEngine to Applications
3. Launch MacLiveEngine from Applications
4. Grant accessibility permissions when prompted
5. Click the menu bar icon to select wallpapers

## Usage

### Setting a Wallpaper
1. Click the MacLiveEngine icon in the menu bar
2. Select "Browse Wallpapers..." or choose from recent
3. Select a video, HTML file, or image

### Per-Display Wallpapers
1. Click the menu bar icon
2. Go to "Displays" submenu
3. Select "Set Wallpaper..." for specific display

### Interactive Wallpapers
1. Enable "Interactive Mode" for a display
2. Mouse clicks will pass through to the wallpaper
3. Useful for web wallpapers with clickable elements

### Battery Settings
1. Open Preferences (Cmd+,)
2. Go to Battery tab
3. Choose optimization level for battery power

## Project Structure

```
MacLiveEngine/
├── MacLiveEngine.xcodeproj/     # Xcode project
├── MacLiveEngine/
│   ├── main.swift               # Entry point
│   ├── AppDelegate.swift        # App lifecycle
│   ├── Window/
│   │   ├── DesktopWindow.swift         # Desktop-level window
│   │   └── DesktopWindowController.swift
│   ├── Renderers/
│   │   ├── WallpaperRenderer.swift     # Protocol
│   │   ├── VideoRenderer.swift         # AVFoundation
│   │   ├── WebRenderer.swift           # WKWebView
│   │   ├── MetalRenderer.swift         # Metal particles
│   │   ├── RendererFactory.swift       # Factory pattern
│   │   └── ParticleShaders.metal       # GPU shaders
│   ├── Managers/
│   │   ├── PowerManager.swift          # Battery detection
│   │   ├── VisibilityObserver.swift    # Window occlusion
│   │   └── DisplayManager.swift        # Multi-monitor
│   ├── UI/
│   │   ├── StatusBarController.swift   # Menu bar
│   │   └── PreferencesWindow.swift     # Settings UI
│   ├── Models/
│   │   └── WallpaperConfiguration.swift
│   └── Resources/
│       ├── Info.plist
│       ├── MacLiveEngine.entitlements
│       ├── Assets.xcassets/
│       └── MainMenu.xib
├── build.sh                     # Build script
├── quick_build.sh               # Quick build without Xcode
└── README.md
```

## Technical Details

### Window Level
The wallpaper window uses `kCGDesktopWindowLevel - 1` to render behind:
- Desktop icons
- Finder windows
- All other applications

### Visibility Detection
Uses `CGWindowListCopyWindowInfo` to detect when windows cover the desktop:
- Polls every 500ms
- Calculates screen coverage
- Pauses rendering when >95% obscured

### Power Management
Uses IOKit's power source APIs:
- Monitors battery state changes
- Tracks battery percentage
- Respects Low Power Mode

### Video Playback
AVFoundation with AVPlayerLayer:
- Hardware-accelerated decoding
- Seamless looping
- Bitrate throttling for battery

### Web Rendering
WKWebView with custom configuration:
- WebGL enabled
- JavaScript animation throttling
- Process termination on switch

### Metal Rendering
GPU compute shaders for particles:
- 10,000+ particles at 60fps
- Noise-based turbulence
- Mouse interaction support

## Creating Custom Wallpapers

### Video Wallpapers
- Use H.264 or HEVC codec
- Resolution: Match your display
- Frame rate: 30-60fps recommended
- Format: MP4 or MOV

### Web Wallpapers
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body { margin: 0; overflow: hidden; }
        canvas { width: 100vw; height: 100vh; }
    </style>
</head>
<body>
    <canvas id="canvas"></canvas>
    <script>
        // Your animation code here
        function animate() {
            requestAnimationFrame(animate);
            // Draw frame
        }
        animate();
    </script>
</body>
</html>
```

### Scene Wallpapers (JSON)
```json
{
    "particleCount": 10000,
    "backgroundColor": [0, 0, 0, 1],
    "particleColors": [[1, 1, 1, 0.8]],
    "particleSizeRange": [2, 6],
    "velocityRange": [-50, 50, -100, -20],
    "lifetimeRange": [2, 5]
}
```

## Troubleshooting

### Wallpaper not appearing
- Check System Settings > Privacy & Security > Accessibility
- Ensure MacLiveEngine has permission

### High CPU/GPU usage
- Enable "Pause When Desktop Hidden" in Preferences
- Reduce target FPS in Performance settings
- Use "Reduced" battery mode

### Video stuttering
- Use hardware-compatible codec (H.264/HEVC)
- Reduce video resolution/bitrate
- Check "Video Buffer Size" in Preferences

## License

MIT License - See LICENSE file

## Contributing

Contributions welcome! Please read CONTRIBUTING.md first.

## Acknowledgments

- Inspired by [Wallpaper Engine](https://www.wallpaperengine.io/)
- Uses Apple's AVFoundation, WebKit, and Metal frameworks
