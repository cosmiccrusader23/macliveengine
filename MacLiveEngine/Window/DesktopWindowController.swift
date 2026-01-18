//
//  DesktopWindowController.swift
//  MacLiveEngine
//
//  Controller managing a desktop window and its renderer
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa

final class DesktopWindowController {
    
    private let window: DesktopWindow
    private var renderer: WallpaperRenderer?
    private var targetFPS: Int = 60
    private var isInteractive: Bool = false
    
    var screenID: UInt32 {
        return window.screenID
    }
    
    init(screen: NSScreen) {
        window = DesktopWindow(screen: screen)
    }
    
    func show() {
        window.orderFront(nil)
        Logger.log("Desktop window shown for screen \(screenID)")
    }
    
    func hide() {
        window.orderOut(nil)
    }
    
    func loadWallpaper(from url: URL) {
        // Clean up existing renderer
        renderer?.cleanup()
        
        // Create new renderer
        guard let newRenderer = RendererFactory.createRenderer(for: url) else {
            Logger.log("Could not create renderer for: \(url.lastPathComponent)")
            return
        }
        
        renderer = newRenderer
        
        // Setup view
        if let contentView = window.contentView {
            let rendererView = newRenderer.view
            rendererView.frame = contentView.bounds
            rendererView.autoresizingMask = [.width, .height]
            contentView.addSubview(rendererView)
        }
        
        // Load and play
        newRenderer.load(from: url) { [weak self] success in
            if success {
                self?.renderer?.setTargetFPS(self?.targetFPS ?? 60)
                self?.renderer?.play()
                Logger.log("Wallpaper loaded and playing: \(url.lastPathComponent)")
            } else {
                Logger.log("Failed to load wallpaper: \(url.lastPathComponent)")
            }
        }
    }
    
    func play() {
        renderer?.play()
    }
    
    func pause() {
        renderer?.pause()
    }
    
    func resume() {
        renderer?.play()
    }
    
    func stop() {
        renderer?.stop()
    }
    
    func cleanup() {
        renderer?.cleanup()
        renderer = nil
        window.orderOut(nil)
    }
    
    func setTargetFPS(_ fps: Int) {
        targetFPS = fps
        renderer?.setTargetFPS(fps)
    }
    
    func setInteractiveMode(_ interactive: Bool) {
        isInteractive = interactive
        if interactive {
            window.enableInteractiveMode()
        } else {
            window.disableInteractiveMode()
        }
    }
    
    func updateFrame(_ frame: NSRect) {
        window.setFrame(frame, display: true)
    }
}
