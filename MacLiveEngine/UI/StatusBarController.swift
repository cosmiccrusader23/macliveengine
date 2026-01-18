//
//  StatusBarController.swift
//  MacLiveEngine
//
//  Menu bar icon and dropdown menu management
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import UniformTypeIdentifiers

protocol StatusBarControllerDelegate: AnyObject {
    func statusBarDidRequestPreferences()
    func statusBarDidRequestQuit()
    func statusBarDidSelectWallpaper(_ url: URL, forScreen screenID: UInt32?)
    func statusBarDidTogglePause(_ isPaused: Bool)
}

final class StatusBarController: NSObject {
    
    weak var delegate: StatusBarControllerDelegate?
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private let configuration: WallpaperConfiguration
    private let displayManager: DisplayManager
    private let powerManager: PowerManager
    private var isPaused: Bool = false
    
    init(configuration: WallpaperConfiguration,
         displayManager: DisplayManager,
         powerManager: PowerManager) {
        self.configuration = configuration
        self.displayManager = displayManager
        self.powerManager = powerManager
        
        super.init()
        
        print(">>> StatusBarController: init complete, setting up status item")
        setupStatusItem()
        print(">>> StatusBarController: setup complete")
    }
    
    private func setupStatusItem() {
        print(">>> StatusBarController: Creating status item")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print(">>> StatusBarController: Status item created: \(String(describing: statusItem))")
        
        if let button = statusItem.button {
            print(">>> StatusBarController: Got button, setting up image")
            // Use simpler text-based approach for guaranteed visibility
            button.title = " 🎬 "
            button.toolTip = "MacLiveEngine - Dynamic Wallpaper - Click me!"
            print(">>> StatusBarController: Set emoji title")
        } else {
            print(">>> StatusBarController: ERROR - No button!")
        }
        
        menu = buildMenu()
        statusItem.menu = menu
        print(">>> StatusBarController: Menu assigned")
    }
    
    @discardableResult
    private func buildMenu() -> NSMenu {
        menu = NSMenu()
        menu.delegate = self
        
        let titleItem = NSMenuItem(title: "MacLiveEngine", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let pauseItem = NSMenuItem(
            title: isPaused ? "Resume Playback" : "Pause Playback",
            action: #selector(togglePause),
            keyEquivalent: "p"
        )
        pauseItem.target = self
        menu.addItem(pauseItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let browseItem = NSMenuItem(
            title: "Browse Wallpapers…",
            action: #selector(browseWallpapers),
            keyEquivalent: "o"
        )
        browseItem.target = self
        menu.addItem(browseItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit MacLiveEngine",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        return menu
    }
    
    @objc private func togglePause(_ sender: NSMenuItem) {
        isPaused.toggle()
        delegate?.statusBarDidTogglePause(isPaused)
        sender.title = isPaused ? "Resume Playback" : "Pause Playback"
    }
    
    @objc private func browseWallpapers(_ sender: NSMenuItem) {
        showOpenPanel { [weak self] url in
            self?.delegate?.statusBarDidSelectWallpaper(url, forScreen: nil)
        }
    }
    
    @objc private func openPreferences(_ sender: NSMenuItem) {
        delegate?.statusBarDidRequestPreferences()
    }
    
    @objc private func quit(_ sender: NSMenuItem) {
        delegate?.statusBarDidRequestQuit()
    }
    
    private func showOpenPanel(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select Wallpaper"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie, .video, .html, .png, .jpeg, .gif, .json]
        
        if let lastDir = configuration.lastWallpaperDirectory {
            panel.directoryURL = lastDir
        }
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.configuration.lastWallpaperDirectory = url.deletingLastPathComponent()
                completion(url)
            }
        }
    }
    
    func refreshMenu() {
        buildMenu()
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        buildMenu()
    }
}
