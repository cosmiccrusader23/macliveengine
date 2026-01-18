//
//  DesktopWindow.swift
//  MacLiveEngine
//
//  Custom NSWindow subclass that renders behind desktop icons
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import CoreGraphics

final class DesktopWindow: NSWindow {
    
    private(set) var targetScreen: NSScreen
    
    var screenID: UInt32 {
        return targetScreen.screenID
    }
    
    var allowsMousePassthrough: Bool = true {
        didSet {
            ignoresMouseEvents = allowsMousePassthrough
        }
    }
    
    init(screen: NSScreen) {
        self.targetScreen = screen
        
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        configureWindow()
    }
    
    private func configureWindow() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        
        isMovable = false
        isMovableByWindowBackground = false
        
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenNone
        ]
        
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = true
        isExcludedFromWindowsMenu = true
        
        setFrame(targetScreen.frame, display: true)
        
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = .clear
        
        Logger.log("DesktopWindow created for screen: \(targetScreen.localizedName) at \(targetScreen.frame)")
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    func updateForScreen(_ screen: NSScreen) {
        targetScreen = screen
        setFrame(screen.frame, display: true, animate: false)
        Logger.log("DesktopWindow updated for screen change: \(screen.frame)")
    }
    
    func enableInteractiveMode() {
        allowsMousePassthrough = false
        Logger.log("Interactive mode enabled for screen \(screenID)")
    }
    
    func disableInteractiveMode() {
        allowsMousePassthrough = true
        Logger.log("Interactive mode disabled for screen \(screenID)")
    }
    
    override func mouseDown(with event: NSEvent) {
        if !allowsMousePassthrough {
            contentView?.mouseDown(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if !allowsMousePassthrough {
            contentView?.mouseUp(with: event)
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        if !allowsMousePassthrough {
            contentView?.mouseMoved(with: event)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if !allowsMousePassthrough {
            contentView?.mouseDragged(with: event)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        if !allowsMousePassthrough {
            contentView?.scrollWheel(with: event)
        }
    }
}
