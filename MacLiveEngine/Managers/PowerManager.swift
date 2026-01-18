//
//  PowerManager.swift
//  MacLiveEngine
//
//  Battery awareness and power management using IOKit
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Foundation
import IOKit.ps

protocol PowerManagerDelegate: AnyObject {
    func powerSourceDidChange(isOnBattery: Bool)
    func batteryLevelDidChange(level: Int)
}

enum BatteryMode: String, CaseIterable, Identifiable, Codable {
    case normal = "Normal"
    case balanced = "Balanced"
    case lowPower = "Low Power"
    case pauseOnBattery = "Pause on Battery"
    
    var id: String { rawValue }
    
    var targetFPS: Int {
        switch self {
        case .normal: return 60
        case .balanced: return 30
        case .lowPower: return 15
        case .pauseOnBattery: return 0
        }
    }
    
    var description: String {
        switch self {
        case .normal: return "Full quality"
        case .balanced: return "30 FPS"
        case .lowPower: return "15 FPS"
        case .pauseOnBattery: return "Paused"
        }
    }
}

final class PowerManager {
    
    weak var delegate: PowerManagerDelegate?
    
    private(set) var isOnBattery: Bool = false
    private(set) var batteryLevel: Int = -1
    private(set) var hasBattery: Bool = false
    private(set) var isLowPowerModeEnabled: Bool = false
    
    private var runLoopSource: CFRunLoopSource?
    private var batteryCheckTimer: Timer?
    private var lastPowerState: Bool = false
    private var lastBatteryLevel: Int = -1
    
    init() {
        updatePowerState()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        setupPowerSourceNotifications()
        
        batteryCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkBatteryLevel()
        }
        
        setupLowPowerModeObserver()
        
        Logger.log("Power monitoring started")
    }
    
    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
        
        batteryCheckTimer?.invalidate()
        batteryCheckTimer = nil
        
        NotificationCenter.default.removeObserver(self)
        
        Logger.log("Power monitoring stopped")
    }
    
    func recommendedFPS(forMode mode: BatteryMode) -> Int {
        if !isOnBattery {
            return 60
        }
        return mode.targetFPS
    }
    
    func recommendedQuality() -> Double {
        if !isOnBattery {
            return 1.0
        }
        
        if batteryLevel > 50 {
            return 0.8
        } else if batteryLevel > 20 {
            return 0.6
        } else {
            return 0.4
        }
    }
    
    private func setupPowerSourceNotifications() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: IOPowerSourceCallbackType = { context in
            guard let ctx = context else { return }
            let manager = Unmanaged<PowerManager>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async {
                manager.updatePowerState()
            }
        }
        
        if let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = source
            Logger.log("IOKit power source notifications registered")
        }
    }
    
    private func updatePowerState() {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        
        hasBattery = (sources?.count ?? 0) > 0
        
        if !hasBattery {
            isOnBattery = false
            batteryLevel = -1
            return
        }
        
        for source in sources ?? [] {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let type = info[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType {
                    if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                        isOnBattery = (powerSource == kIOPSBatteryPowerValue)
                    }
                    
                    if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                        batteryLevel = capacity
                    }
                    
                    break
                }
            }
        }
        
        if isOnBattery != lastPowerState {
            lastPowerState = isOnBattery
            delegate?.powerSourceDidChange(isOnBattery: isOnBattery)
            Logger.log("Power source changed: \(isOnBattery ? "Battery" : "AC")")
        }
    }
    
    private func checkBatteryLevel() {
        updatePowerState()
        
        if batteryLevel != lastBatteryLevel {
            lastBatteryLevel = batteryLevel
            delegate?.batteryLevelDidChange(level: batteryLevel)
        }
    }
    
    private func setupLowPowerModeObserver() {
        if #available(macOS 12.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(lowPowerModeChanged),
                name: Notification.Name.NSProcessInfoPowerStateDidChange,
                object: nil
            )
            
            isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
    
    @objc private func lowPowerModeChanged() {
        if #available(macOS 12.0, *) {
            isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
            Logger.log("Low Power Mode: \(isLowPowerModeEnabled ? "enabled" : "disabled")")
        }
    }
}
