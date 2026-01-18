//
//  VisibilityObserver.swift
//  MacLiveEngine
//
//  Window occlusion detection using CGWindowList
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import CoreGraphics

protocol VisibilityObserverDelegate: AnyObject {
    func desktopVisibilityChanged(forScreen screenID: UInt32, isVisible: Bool)
}

final class VisibilityObserver {
    
    weak var delegate: VisibilityObserverDelegate?
    
    private var checkTimer: Timer?
    private var visibilityState: [UInt32: Bool] = [:]
    private var checkInterval: TimeInterval = 1.0
    private var isMonitoring: Bool = false
    
    init() {
        for screen in NSScreen.screens {
            visibilityState[screen.screenID] = true
        }
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkVisibility()
        }
        
        setupScreenObserver()
        
        Logger.log("Visibility monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        checkTimer?.invalidate()
        checkTimer = nil
        
        NotificationCenter.default.removeObserver(self)
        
        Logger.log("Visibility monitoring stopped")
    }
    
    func isDesktopVisible(forScreen screenID: UInt32) -> Bool {
        return visibilityState[screenID] ?? true
    }
    
    func setCheckInterval(_ interval: TimeInterval) {
        checkInterval = max(0.1, min(5.0, interval))
        
        if isMonitoring {
            checkTimer?.invalidate()
            checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
                self?.checkVisibility()
            }
        }
    }
    
    func forceCheck() {
        checkVisibility()
    }
    
    private func setupScreenObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func handleScreenChange() {
        let currentScreenIDs = Set(NSScreen.screens.map { $0.screenID })
        let existingIDs = Set(visibilityState.keys)
        
        for screen in NSScreen.screens where !existingIDs.contains(screen.screenID) {
            visibilityState[screen.screenID] = true
        }
        
        for screenID in existingIDs.subtracting(currentScreenIDs) {
            visibilityState.removeValue(forKey: screenID)
        }
    }
    
    private func checkVisibility() {
        for screen in NSScreen.screens {
            let isVisible = checkDesktopVisibility(for: screen)
            let screenID = screen.screenID
            let previousState = visibilityState[screenID] ?? true
            
            if isVisible != previousState {
                visibilityState[screenID] = isVisible
                delegate?.desktopVisibilityChanged(forScreen: screenID, isVisible: isVisible)
                Logger.log("Screen \(screenID) visibility: \(isVisible ? "visible" : "occluded")")
            }
        }
    }
    
    private func checkDesktopVisibility(for screen: NSScreen) -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return true
        }
        
        let screenFrame = screen.frame
        var totalOccludedArea: CGFloat = 0
        let screenArea = screenFrame.width * screenFrame.height
        
        for windowInfo in windowList {
            guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer >= 0,
                  let alpha = windowInfo[kCGWindowAlpha as String] as? CGFloat,
                  alpha > 0.5 else {
                continue
            }
            
            let windowFrame = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            
            let intersection = screenFrame.intersection(windowFrame)
            if !intersection.isNull {
                totalOccludedArea += intersection.width * intersection.height
            }
        }
        
        let occlusionRatio = totalOccludedArea / screenArea
        return occlusionRatio < 0.9
    }
    
    func getScreenOcclusionInfo() -> [UInt32: CGFloat] {
        var info: [UInt32: CGFloat] = [:]
        
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return info
        }
        
        for screen in NSScreen.screens {
            let screenFrame = screen.frame
            let screenArea = screenFrame.width * screenFrame.height
            var totalOccludedArea: CGFloat = 0
            
            for windowInfo in windowList {
                guard let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                      let layer = windowInfo[kCGWindowLayer as String] as? Int,
                      layer >= 0 else {
                    continue
                }
                
                let windowFrame = CGRect(
                    x: boundsDict["X"] ?? 0,
                    y: boundsDict["Y"] ?? 0,
                    width: boundsDict["Width"] ?? 0,
                    height: boundsDict["Height"] ?? 0
                )
                
                let intersection = screenFrame.intersection(windowFrame)
                if !intersection.isNull {
                    totalOccludedArea += intersection.width * intersection.height
                }
            }
            
            info[screen.screenID] = totalOccludedArea / screenArea
        }
        
        return info
    }
}
