//
//  WebRenderer.swift
//  MacLiveEngine
//
//  Web wallpaper renderer using WKWebView
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import WebKit

final class WebRenderer: NSObject, WallpaperRenderer {
    
    let contentType: WallpaperContentType = .web
    
    var view: NSView {
        return containerView
    }
    
    var isPlaying: Bool {
        return state == .playing
    }
    
    private let containerView: BaseRendererView
    private var webView: WKWebView?
    private var state: RendererLifecycleState = .unloaded
    private var targetFPS: Int = 60
    private var loadedURL: URL?
    
    override init() {
        containerView = BaseRendererView(frame: .zero)
        super.init()
    }
    
    deinit {
        cleanup()
    }
    
    func load(from url: URL, completion: @escaping (Bool) -> Void) {
        cleanup()
        state = .loading
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "acceleratedDrawingEnabled")
        
        webView = WKWebView(frame: containerView.bounds, configuration: config)
        webView?.navigationDelegate = self
        webView?.autoresizingMask = [.width, .height]
        webView?.setValue(false, forKey: "drawsBackground")
        
        if let webView = webView {
            containerView.addSubview(webView)
        }
        
        var loadURL = url
        if url.hasDirectoryPath {
            loadURL = url.appendingPathComponent("index.html")
        }
        
        loadedURL = loadURL
        
        if loadURL.isFileURL {
            webView?.loadFileURL(loadURL, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView?.load(URLRequest(url: loadURL))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.state == .loading {
                self?.state = .ready
                completion(true)
            }
        }
    }
    
    func play() {
        guard state.canPlay else { return }
        webView?.evaluateJavaScript("if(window.resumeWallpaper) window.resumeWallpaper();", completionHandler: nil)
        state = .playing
        Logger.log("Web wallpaper playing")
    }
    
    func pause() {
        webView?.evaluateJavaScript("if(window.pauseWallpaper) window.pauseWallpaper();", completionHandler: nil)
        state = .paused
        Logger.log("Web wallpaper paused")
    }
    
    func stop() {
        webView?.evaluateJavaScript("if(window.stopWallpaper) window.stopWallpaper();", completionHandler: nil)
        state = .stopped
        Logger.log("Web wallpaper stopped")
    }
    
    func cleanup() {
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
        loadedURL = nil
        state = .unloaded
        Logger.log("Web renderer cleaned up")
    }
    
    func setTargetFPS(_ fps: Int) {
        targetFPS = fps
        let js = "(function(){ window.__targetFPS = \(fps); if(window.setTargetFPS) window.setTargetFPS(\(fps)); })();"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func setVolume(_ volume: Float) {
        let js = "if(window.setVolume) window.setVolume(\(volume));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
}

extension WebRenderer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        state = .ready
        Logger.log("Web content loaded: \(loadedURL?.lastPathComponent ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        state = .error(error.localizedDescription)
        Logger.log("Web content failed to load: \(error.localizedDescription)")
    }
}
