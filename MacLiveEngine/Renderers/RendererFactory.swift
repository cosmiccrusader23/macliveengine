//
//  RendererFactory.swift
//  MacLiveEngine
//
//  Factory for creating appropriate renderers based on content type
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa

/// Factory for creating wallpaper renderers based on content type
struct RendererFactory {
    
    static func createRenderer(for url: URL) -> WallpaperRenderer? {
        guard let contentType = WallpaperContentType.from(url: url) else {
            Logger.log("Unknown content type for: \(url.lastPathComponent)")
            return nil
        }
        
        return createRenderer(for: contentType)
    }
    
    static func createRenderer(for contentType: WallpaperContentType) -> WallpaperRenderer {
        switch contentType {
        case .video:
            Logger.log("Creating video renderer")
            return VideoRenderer()
        case .web:
            Logger.log("Creating web renderer")
            return WebRenderer()
        case .scene:
            Logger.log("Creating scene renderer (using web)")
            return WebRenderer()
        case .image:
            Logger.log("Creating image renderer")
            return ImageRenderer()
        }
    }
}

/// Simple image renderer for static wallpapers
final class ImageRenderer: WallpaperRenderer {
    
    let contentType: WallpaperContentType = .image
    
    var view: NSView {
        return imageView
    }
    
    var isPlaying: Bool {
        return state == .playing
    }
    
    private let imageView: NSImageView
    private var state: RendererLifecycleState = .unloaded
    
    init() {
        imageView = NSImageView(frame: .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
    }
    
    func load(from url: URL, completion: @escaping (Bool) -> Void) {
        state = .loading
        
        if let image = NSImage(contentsOf: url) {
            imageView.image = image
            state = .ready
            Logger.log("Image loaded: \(url.lastPathComponent)")
            completion(true)
        } else {
            state = .error("Failed to load image")
            Logger.log("Failed to load image: \(url.lastPathComponent)")
            completion(false)
        }
    }
    
    func play() {
        state = .playing
    }
    
    func pause() {
        state = .paused
    }
    
    func stop() {
        state = .stopped
    }
    
    func cleanup() {
        imageView.image = nil
        state = .unloaded
    }
    
    func setTargetFPS(_ fps: Int) {
        // No-op for static images
    }
}
