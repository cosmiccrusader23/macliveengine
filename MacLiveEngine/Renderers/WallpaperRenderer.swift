//
//  WallpaperRenderer.swift
//  MacLiveEngine
//
//  Protocol and base classes for wallpaper rendering
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa

// MARK: - Wallpaper Renderer Protocol

protocol WallpaperRenderer: AnyObject {
    var contentType: WallpaperContentType { get }
    var view: NSView { get }
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    
    func load(from url: URL, completion: @escaping (Bool) -> Void)
    func play()
    func pause()
    func stop()
    func cleanup()
    func setTargetFPS(_ fps: Int)
    func setVolume(_ volume: Float)
}

extension WallpaperRenderer {
    var currentTime: TimeInterval { return 0 }
    var duration: TimeInterval { return 0 }
    
    func setVolume(_ volume: Float) {
        // Default: no-op for renderers without audio
    }
}

// MARK: - Content Type

enum WallpaperContentType: String, CaseIterable {
    case video = "video"
    case web = "web"
    case scene = "scene"
    case image = "image"
    
    var fileExtensions: [String] {
        switch self {
        case .video:
            return ["mp4", "mov", "m4v", "webm", "avi"]
        case .web:
            return ["html", "htm"]
        case .scene:
            return ["scene", "json"]
        case .image:
            return ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff"]
        }
    }
    
    static func from(url: URL) -> WallpaperContentType? {
        let ext = url.pathExtension.lowercased()
        
        for type in WallpaperContentType.allCases {
            if type.fileExtensions.contains(ext) {
                return type
            }
        }
        
        if url.hasDirectoryPath {
            let indexPath = url.appendingPathComponent("index.html")
            if FileManager.default.fileExists(atPath: indexPath.path) {
                return .web
            }
        }
        
        return nil
    }
}

// MARK: - Renderer State Machine

enum RendererLifecycleState: Equatable {
    case unloaded
    case loading
    case ready
    case playing
    case paused
    case stopped
    case error(String)
    
    var canPlay: Bool {
        switch self {
        case .ready, .paused, .stopped:
            return true
        default:
            return false
        }
    }
    
    var canPause: Bool {
        return self == .playing
    }
    
    static func == (lhs: RendererLifecycleState, rhs: RendererLifecycleState) -> Bool {
        switch (lhs, rhs) {
        case (.unloaded, .unloaded),
             (.loading, .loading),
             (.ready, .ready),
             (.playing, .playing),
             (.paused, .paused),
             (.stopped, .stopped):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Renderer Errors

enum RendererError: LocalizedError {
    case unsupportedFormat(String)
    case loadFailed(String)
    case playbackFailed(String)
    case resourceUnavailable
    case systemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .loadFailed(let reason):
            return "Failed to load: \(reason)"
        case .playbackFailed(let reason):
            return "Playback failed: \(reason)"
        case .resourceUnavailable:
            return "Required resource is unavailable"
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Base Renderer View

class BaseRendererView: NSView {
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = .black
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        canDrawConcurrently = true
    }
    
    override var isFlipped: Bool {
        return true
    }
    
    func fillSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }
}
