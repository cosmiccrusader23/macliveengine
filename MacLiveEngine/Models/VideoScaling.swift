//
//  VideoScaling.swift
//  MacLiveEngine
//
//  Video scaling mode enumeration
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Foundation
import AVFoundation

/// Video scaling modes for wallpaper rendering
enum VideoScaling: String, CaseIterable, Codable {
    case fill = "Fill"           // Scale to fill, may crop
    case fit = "Fit"             // Scale to fit, may letterbox
    case stretch = "Stretch"     // Stretch to fill exactly
    case center = "Center"       // Center at original size
    
    /// Convert to AVLayerVideoGravity
    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .fill:
            return .resizeAspectFill
        case .fit:
            return .resizeAspect
        case .stretch:
            return .resize
        case .center:
            return .resizeAspect  // Will be handled separately
        }
    }
    
    /// Human-readable description
    var description: String {
        switch self {
        case .fill:
            return "Fill (may crop)"
        case .fit:
            return "Fit (may letterbox)"
        case .stretch:
            return "Stretch to fill"
        case .center:
            return "Center (original size)"
        }
    }
}
