//
//  WallpaperConfiguration.swift
//  MacLiveEngine
//
//  Persistent configuration and settings management
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Foundation
import Combine

final class WallpaperConfiguration: ObservableObject, Codable {
    
    private static let defaultsKey = "com.macliveengine.configuration"
    
    @Published var launchAtLogin: Bool = false
    @Published var loopVideos: Bool = true
    @Published var muteAudio: Bool = true
    @Published var videoScaling: VideoScaling = .fill
    @Published var allowInteractive: Bool = true
    
    @Published var targetFPS: Int = 60
    @Published var pauseWhenHidden: Bool = true
    @Published var pauseInFullScreen: Bool = true
    @Published var terminateWebProcesses: Bool = true
    @Published var videoBufferSize: Int = 100
    
    @Published var batteryMode: BatteryMode = .balanced
    @Published var respectLowPowerMode: Bool = true
    @Published var pauseOnCriticalBattery: Bool = true
    @Published var pauseBelowBattery: Int = 10
    
    var wallpapers: [UInt32: WallpaperEntry] = [:]
    var lastWallpaperDirectory: URL?
    var recentWallpapers: [URL] = []
    private let maxRecentWallpapers = 10
    
    enum CodingKeys: String, CodingKey {
        case launchAtLogin, loopVideos, muteAudio, videoScaling, allowInteractive
        case targetFPS, pauseWhenHidden, pauseInFullScreen, terminateWebProcesses, videoBufferSize
        case batteryMode, respectLowPowerMode, pauseOnCriticalBattery, pauseBelowBattery
        case wallpapers, lastWallpaperDirectory, recentWallpapers
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        loopVideos = try container.decodeIfPresent(Bool.self, forKey: .loopVideos) ?? true
        muteAudio = try container.decodeIfPresent(Bool.self, forKey: .muteAudio) ?? true
        videoScaling = try container.decodeIfPresent(VideoScaling.self, forKey: .videoScaling) ?? .fill
        allowInteractive = try container.decodeIfPresent(Bool.self, forKey: .allowInteractive) ?? true
        
        targetFPS = try container.decodeIfPresent(Int.self, forKey: .targetFPS) ?? 60
        pauseWhenHidden = try container.decodeIfPresent(Bool.self, forKey: .pauseWhenHidden) ?? true
        pauseInFullScreen = try container.decodeIfPresent(Bool.self, forKey: .pauseInFullScreen) ?? true
        terminateWebProcesses = try container.decodeIfPresent(Bool.self, forKey: .terminateWebProcesses) ?? true
        videoBufferSize = try container.decodeIfPresent(Int.self, forKey: .videoBufferSize) ?? 100
        
        batteryMode = try container.decodeIfPresent(BatteryMode.self, forKey: .batteryMode) ?? .balanced
        respectLowPowerMode = try container.decodeIfPresent(Bool.self, forKey: .respectLowPowerMode) ?? true
        pauseOnCriticalBattery = try container.decodeIfPresent(Bool.self, forKey: .pauseOnCriticalBattery) ?? true
        pauseBelowBattery = try container.decodeIfPresent(Int.self, forKey: .pauseBelowBattery) ?? 10
        
        if let wallpapersData = try container.decodeIfPresent([String: WallpaperEntry].self, forKey: .wallpapers) {
            wallpapers = Dictionary(uniqueKeysWithValues: wallpapersData.compactMap { key, value in
                guard let screenID = UInt32(key) else { return nil }
                return (screenID, value)
            })
        }
        
        lastWallpaperDirectory = try container.decodeIfPresent(URL.self, forKey: .lastWallpaperDirectory)
        recentWallpapers = try container.decodeIfPresent([URL].self, forKey: .recentWallpapers) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(loopVideos, forKey: .loopVideos)
        try container.encode(muteAudio, forKey: .muteAudio)
        try container.encode(videoScaling, forKey: .videoScaling)
        try container.encode(allowInteractive, forKey: .allowInteractive)
        
        try container.encode(targetFPS, forKey: .targetFPS)
        try container.encode(pauseWhenHidden, forKey: .pauseWhenHidden)
        try container.encode(pauseInFullScreen, forKey: .pauseInFullScreen)
        try container.encode(terminateWebProcesses, forKey: .terminateWebProcesses)
        try container.encode(videoBufferSize, forKey: .videoBufferSize)
        
        try container.encode(batteryMode, forKey: .batteryMode)
        try container.encode(respectLowPowerMode, forKey: .respectLowPowerMode)
        try container.encode(pauseOnCriticalBattery, forKey: .pauseOnCriticalBattery)
        try container.encode(pauseBelowBattery, forKey: .pauseBelowBattery)
        
        let wallpapersStringKeyed = Dictionary(uniqueKeysWithValues: wallpapers.map { (String($0.key), $0.value) })
        try container.encode(wallpapersStringKeyed, forKey: .wallpapers)
        
        try container.encodeIfPresent(lastWallpaperDirectory, forKey: .lastWallpaperDirectory)
        try container.encode(recentWallpapers, forKey: .recentWallpapers)
    }
    
    static func load() -> WallpaperConfiguration {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            Logger.log("No saved configuration found, using defaults")
            return WallpaperConfiguration()
        }
        
        do {
            let config = try JSONDecoder().decode(WallpaperConfiguration.self, from: data)
            Logger.log("Configuration loaded successfully")
            return config
        } catch {
            Logger.log("Failed to decode configuration: \(error)")
            return WallpaperConfiguration()
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
            Logger.log("Configuration saved")
        } catch {
            Logger.log("Failed to save configuration: \(error)")
        }
    }
    
    func addRecentWallpaper(_ url: URL) {
        recentWallpapers.removeAll { $0 == url }
        recentWallpapers.insert(url, at: 0)
        if recentWallpapers.count > maxRecentWallpapers {
            recentWallpapers = Array(recentWallpapers.prefix(maxRecentWallpapers))
        }
    }
}

struct WallpaperEntry: Codable {
    let url: URL
    let screenID: UInt32
    var lastModified: Date
    
    init(url: URL, screenID: UInt32) {
        self.url = url
        self.screenID = screenID
        self.lastModified = Date()
    }
}
