//
//  Logger.swift
//  MacLiveEngine
//
//  Simple logging utility for debugging and diagnostics
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Foundation
import os.log

enum Logger {
    private static let subsystem = "com.macliveengine"
    private static let logger = os.Logger(subsystem: subsystem, category: "general")
    
    static func log(_ message: String) {
        logger.info("\(message)")
        print("[MacLiveEngine] \(message)")
    }
    
    static func error(_ message: String) {
        logger.error("\(message)")
        print("[MacLiveEngine ERROR] \(message)")
    }
    
    static func debug(_ message: String) {
        logger.debug("\(message)")
        print("[MacLiveEngine DEBUG] \(message)")
    }
    
    static func warning(_ message: String) {
        logger.warning("\(message)")
        print("[MacLiveEngine WARNING] \(message)")
    }
}
