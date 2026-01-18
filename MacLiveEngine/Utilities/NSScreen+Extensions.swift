//
//  NSScreen+Extensions.swift
//  MacLiveEngine
//
//  Extensions for NSScreen to provide convenient access to screen identifiers
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa

extension NSScreen {
    
    /// Unique identifier for this screen (display ID)
    var screenID: UInt32 {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return 0
        }
        return screenNumber.uint32Value
    }
    
    /// Human-readable name for the screen
    var displayName: String {
        return localizedName
    }
    
    /// Check if this is the main/primary screen
    var isPrimary: Bool {
        return self == NSScreen.main
    }
    
    /// Get screen by ID
    static func screen(withID id: UInt32) -> NSScreen? {
        return screens.first { $0.screenID == id }
    }
}
