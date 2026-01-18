//
//  AppDelegate.swift
//  MacLiveEngine
//
//  Main application delegate handling lifecycle and core services
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController!
    private var displayManager: DisplayManager!
    private var powerManager: PowerManager!
    private var visibilityObserver: VisibilityObserver!
    private var configuration: WallpaperConfiguration!
    private var preferencesWindowController: PreferencesWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print(">>> AppDelegate: applicationDidFinishLaunching started")
        NSApp.setActivationPolicy(.accessory)
        print(">>> AppDelegate: setActivationPolicy done")
        
        configuration = WallpaperConfiguration.load()
        print(">>> AppDelegate: configuration loaded")
        
        initializeManagers()
        
        statusBarController = StatusBarController(
            configuration: configuration,
            displayManager: displayManager,
            powerManager: powerManager
        )
        statusBarController.delegate = self
        
        displayManager.startEngine()
        
        Logger.log("MacLiveEngine started successfully")
        Logger.log("Detected \(NSScreen.screens.count) display(s)")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        displayManager.stopEngine()
        visibilityObserver.stopMonitoring()
        powerManager.stopMonitoring()
        configuration.save()
        
        Logger.log("MacLiveEngine shutdown complete")
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func initializeManagers() {
        powerManager = PowerManager()
        powerManager.delegate = self
        powerManager.startMonitoring()
        
        visibilityObserver = VisibilityObserver()
        visibilityObserver.delegate = self
        
        displayManager = DisplayManager(
            configuration: configuration,
            powerManager: powerManager,
            visibilityObserver: visibilityObserver
        )
        
        visibilityObserver.startMonitoring()
    }
}

extension AppDelegate: StatusBarControllerDelegate {
    func statusBarDidRequestPreferences() {
        showPreferencesWindow()
    }
    
    func statusBarDidRequestQuit() {
        NSApp.terminate(nil)
    }
    
    func statusBarDidSelectWallpaper(_ url: URL, forScreen screenID: UInt32?) {
        if let screenID = screenID {
            displayManager.setWallpaper(url, forScreen: screenID)
        } else {
            displayManager.setWallpaperForAllScreens(url)
        }
        configuration.save()
    }
    
    func statusBarDidTogglePause(_ isPaused: Bool) {
        if isPaused {
            displayManager.pauseAllRenderers()
        } else {
            displayManager.resumeAllRenderers()
        }
    }
    
    private func showPreferencesWindow() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(
                configuration: configuration,
                powerManager: powerManager
            )
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: PowerManagerDelegate {
    func powerSourceDidChange(isOnBattery: Bool) {
        Logger.log("Power source changed: \(isOnBattery ? "Battery" : "AC Power")")
        
        if isOnBattery && configuration.batteryMode != .normal {
            displayManager.applyBatteryOptimizations(mode: configuration.batteryMode)
        } else {
            displayManager.removeBatteryOptimizations()
        }
    }
    
    func batteryLevelDidChange(level: Int) {
        Logger.log("Battery level: \(level)%")
        
        if level <= 10 && configuration.pauseOnCriticalBattery {
            displayManager.pauseAllRenderers()
            Logger.log("Paused rendering due to critical battery level")
        }
    }
}

extension AppDelegate: VisibilityObserverDelegate {
    func desktopVisibilityChanged(forScreen screenID: UInt32, isVisible: Bool) {
        if isVisible {
            displayManager.resumeRenderer(forScreen: screenID)
        } else {
            displayManager.pauseRenderer(forScreen: screenID)
        }
    }
}
