//
//  PreferencesWindow.swift
//  MacLiveEngine
//
//  Preferences window using SwiftUI
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import SwiftUI
import ServiceManagement

final class PreferencesWindowController: NSWindowController {
    
    private let configuration: WallpaperConfiguration
    private let powerManager: PowerManager
    
    init(configuration: WallpaperConfiguration, powerManager: PowerManager) {
        self.configuration = configuration
        self.powerManager = powerManager
        
        let preferencesView = PreferencesView(
            configuration: configuration,
            powerManager: powerManager
        )
        
        let hostingView = NSHostingView(rootView: preferencesView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacLiveEngine Preferences"
        window.center()
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PreferencesView: View {
    @ObservedObject var configuration: WallpaperConfiguration
    let powerManager: PowerManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView(configuration: configuration)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            PerformancePreferencesView(configuration: configuration)
                .tabItem {
                    Label("Performance", systemImage: "speedometer")
                }
                .tag(1)
            
            BatteryPreferencesView(configuration: configuration, powerManager: powerManager)
                .tabItem {
                    Label("Battery", systemImage: "battery.100")
                }
                .tag(2)
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(3)
        }
        .padding()
        .frame(width: 500, height: 380)
    }
}

struct GeneralPreferencesView: View {
    @ObservedObject var configuration: WallpaperConfiguration
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $configuration.launchAtLogin)
                    .onChange(of: configuration.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            } header: {
                Text("Startup")
            }
            
            Section {
                Picker("Default Video Scaling", selection: $configuration.videoScaling) {
                    ForEach(VideoScaling.allCases, id: \.self) { scaling in
                        Text(scaling.rawValue).tag(scaling)
                    }
                }
                
                Toggle("Loop Videos", isOn: $configuration.loopVideos)
                Toggle("Mute Audio by Default", isOn: $configuration.muteAudio)
            } header: {
                Text("Playback")
            }
            
            Section {
                Toggle("Allow Interactive Wallpapers", isOn: $configuration.allowInteractive)
            } header: {
                Text("Interactivity")
            }
        }
        .formStyle(.grouped)
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Logger.log("Failed to set launch at login: \(error)")
            }
        }
    }
}

struct PerformancePreferencesView: View {
    @ObservedObject var configuration: WallpaperConfiguration
    
    var body: some View {
        Form {
            Section {
                Picker("Target Frame Rate", selection: $configuration.targetFPS) {
                    Text("60 FPS").tag(60)
                    Text("30 FPS").tag(30)
                    Text("24 FPS").tag(24)
                    Text("15 FPS").tag(15)
                }
                
                Toggle("Pause When Desktop Hidden", isOn: $configuration.pauseWhenHidden)
                Toggle("Pause in Full Screen Apps", isOn: $configuration.pauseInFullScreen)
            } header: {
                Text("Rendering")
            }
            
            Section {
                Toggle("Terminate Web Processes When Inactive", isOn: $configuration.terminateWebProcesses)
            } header: {
                Text("Memory")
            }
        }
        .formStyle(.grouped)
    }
}

struct BatteryPreferencesView: View {
    @ObservedObject var configuration: WallpaperConfiguration
    let powerManager: PowerManager
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: powerManager.isOnBattery ? "battery.50" : "bolt.fill")
                        .foregroundColor(powerManager.isOnBattery ? .orange : .green)
                    Text(powerManager.isOnBattery ? "On Battery (\(powerManager.batteryLevel)%)" : "Connected to Power")
                }
            } header: {
                Text("Current Status")
            }
            
            Section {
                Picker("When on Battery", selection: $configuration.batteryMode) {
                    ForEach(BatteryMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                
                Toggle("Respect System Low Power Mode", isOn: $configuration.respectLowPowerMode)
            } header: {
                Text("Battery Optimization")
            }
            
            Section {
                Toggle("Pause on Critical Battery (<10%)", isOn: $configuration.pauseOnCriticalBattery)
            } header: {
                Text("Auto-Pause")
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("MacLiveEngine")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .foregroundColor(.secondary)
            
            Text("Dynamic wallpaper engine for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
