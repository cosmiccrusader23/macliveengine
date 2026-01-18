//
//  DisplayManager.swift
//  MacLiveEngine
//
//  Manages multi-monitor wallpaper configurations
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa

struct DisplayInfo {
    let screenID: UInt32
    let name: String
    let resolution: String
    let hasWallpaper: Bool
    let isInteractive: Bool
}

final class DisplayManager {
    
    private var windowControllers: [UInt32: DesktopWindowController] = [:]
    private let configuration: WallpaperConfiguration
    private let powerManager: PowerManager
    private let visibilityObserver: VisibilityObserver
    private var interactiveMode: [UInt32: Bool] = [:]
    private(set) var isRunning: Bool = false
    
    init(configuration: WallpaperConfiguration,
         powerManager: PowerManager,
         visibilityObserver: VisibilityObserver) {
        self.configuration = configuration
        self.powerManager = powerManager
        self.visibilityObserver = visibilityObserver
        
        setupScreenChangeObserver()
    }
    
    deinit {
        stopEngine()
        NotificationCenter.default.removeObserver(self)
    }
    
    func startEngine() {
        guard !isRunning else { return }
        isRunning = true
        
        for screen in NSScreen.screens {
            createWindowController(for: screen)
        }
        
        loadSavedWallpapers()
        
        Logger.log("Display manager started with \(windowControllers.count) display(s)")
    }
    
    func stopEngine() {
        guard isRunning else { return }
        isRunning = false
        
        for (_, controller) in windowControllers {
            controller.cleanup()
        }
        windowControllers.removeAll()
        
        Logger.log("Display manager stopped")
    }
    
    func setWallpaper(_ url: URL, forScreen screenID: UInt32) {
        guard let controller = windowControllers[screenID] else {
            Logger.log("No window controller for screen \(screenID)")
            return
        }
        
        controller.loadWallpaper(from: url)
        
        let entry = WallpaperEntry(url: url, screenID: screenID)
        configuration.wallpapers[screenID] = entry
        configuration.addRecentWallpaper(url)
        configuration.save()
        
        Logger.log("Set wallpaper for screen \(screenID): \(url.lastPathComponent)")
    }
    
    func setWallpaperForAllScreens(_ url: URL) {
        for screenID in windowControllers.keys {
            setWallpaper(url, forScreen: screenID)
        }
    }
    
    func clearWallpaper(forScreen screenID: UInt32) {
        guard let controller = windowControllers[screenID] else { return }
        
        controller.stop()
        configuration.wallpapers.removeValue(forKey: screenID)
        configuration.save()
        
        Logger.log("Cleared wallpaper for screen \(screenID)")
    }
    
    func pauseAllRenderers() {
        for (_, controller) in windowControllers {
            controller.pause()
        }
    }
    
    func resumeAllRenderers() {
        for (screenID, controller) in windowControllers {
            if visibilityObserver.isDesktopVisible(forScreen: screenID) {
                controller.resume()
            }
        }
    }
    
    func pauseRenderer(forScreen screenID: UInt32) {
        windowControllers[screenID]?.pause()
    }
    
    func resumeRenderer(forScreen screenID: UInt32) {
        windowControllers[screenID]?.resume()
    }
    
    func applyBatteryOptimizations(mode: BatteryMode) {
        let targetFPS = mode.targetFPS
        
        for (_, controller) in windowControllers {
            if targetFPS == 0 {
                controller.pause()
            } else {
                controller.setTargetFPS(targetFPS)
            }
        }
        
        Logger.log("Applied battery mode: \(mode.rawValue)")
    }
    
    func removeBatteryOptimizations() {
        let targetFPS = configuration.targetFPS
        
        for (_, controller) in windowControllers {
            controller.setTargetFPS(targetFPS)
            controller.resume()
        }
        
        Logger.log("Removed battery optimizations")
    }
    
    @discardableResult
    func toggleInteractiveMode(forScreen screenID: UInt32) -> Bool {
        let current = interactiveMode[screenID] ?? false
        let newValue = !current
        interactiveMode[screenID] = newValue
        
        windowControllers[screenID]?.setInteractiveMode(newValue)
        
        return newValue
    }
    
    var displayInfo: [DisplayInfo] {
        return NSScreen.screens.map { screen in
            let screenID = screen.screenID
            let hasWallpaper = configuration.wallpapers[screenID] != nil
            let isInteractive = interactiveMode[screenID] ?? false
            
            return DisplayInfo(
                screenID: screenID,
                name: screen.localizedName,
                resolution: "\(Int(screen.frame.width))x\(Int(screen.frame.height))",
                hasWallpaper: hasWallpaper,
                isInteractive: isInteractive
            )
        }
    }
    
    private func setupScreenChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func handleScreenChange() {
        guard isRunning else { return }
        
        let currentScreenIDs = Set(NSScreen.screens.map { $0.screenID })
        let existingIDs = Set(windowControllers.keys)
        
        for screen in NSScreen.screens where !existingIDs.contains(screen.screenID) {
            createWindowController(for: screen)
            Logger.log("Added window for new screen: \(screen.localizedName)")
        }
        
        for screenID in existingIDs.subtracting(currentScreenIDs) {
            windowControllers[screenID]?.cleanup()
            windowControllers.removeValue(forKey: screenID)
            Logger.log("Removed window for disconnected screen: \(screenID)")
        }
        
        for screen in NSScreen.screens {
            windowControllers[screen.screenID]?.updateFrame(screen.frame)
        }
    }
    
    private func createWindowController(for screen: NSScreen) {
        let controller = DesktopWindowController(screen: screen)
        windowControllers[screen.screenID] = controller
        
        if powerManager.isOnBattery {
            let fps = powerManager.recommendedFPS(forMode: configuration.batteryMode)
            controller.setTargetFPS(fps)
        } else {
            controller.setTargetFPS(configuration.targetFPS)
        }
        
        controller.show()
    }
    
    private func loadSavedWallpapers() {
        for (screenID, entry) in configuration.wallpapers {
            guard FileManager.default.fileExists(atPath: entry.url.path) else {
                Logger.log("Saved wallpaper file not found: \(entry.url.path)")
                continue
            }
            
            windowControllers[screenID]?.loadWallpaper(from: entry.url)
        }
    }
}
