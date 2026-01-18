//
//  VideoRenderer.swift
//  MacLiveEngine
//
//  Video wallpaper renderer using AVFoundation
//  Copyright © 2026 MacLiveEngine. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit

final class VideoRenderer: WallpaperRenderer {
    
    let contentType: WallpaperContentType = .video
    
    var view: NSView {
        return containerView
    }
    
    var isPlaying: Bool {
        return player?.rate ?? 0 > 0
    }
    
    var currentTime: TimeInterval {
        guard let player = player else { return 0 }
        return CMTimeGetSeconds(player.currentTime())
    }
    
    var duration: TimeInterval {
        guard let duration = player?.currentItem?.duration else { return 0 }
        let seconds = CMTimeGetSeconds(duration)
        return seconds.isFinite ? seconds : 0
    }
    
    private let containerView: BaseRendererView
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loopObserver: Any?
    private var state: RendererLifecycleState = .unloaded
    private var targetFPS: Int = 60
    
    init() {
        containerView = BaseRendererView(frame: .zero)
        containerView.wantsLayer = true
    }
    
    deinit {
        cleanup()
    }
    
    func load(from url: URL, completion: @escaping (Bool) -> Void) {
        cleanup()
        state = .loading
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])
        
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = containerView.bounds
        
        if let playerLayer = playerLayer {
            containerView.layer?.addSublayer(playerLayer)
        }
        
        setupLooping()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if self.player?.currentItem?.status == .readyToPlay {
                self.state = .ready
                Logger.log("Video loaded: \(url.lastPathComponent)")
                completion(true)
            } else {
                self.state = .error("Failed to load video")
                Logger.log("Failed to load video: \(url.lastPathComponent)")
                completion(false)
            }
        }
    }
    
    func play() {
        guard state.canPlay else { return }
        player?.play()
        state = .playing
        Logger.log("Video playing")
    }
    
    func pause() {
        player?.pause()
        state = .paused
        Logger.log("Video paused")
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        state = .stopped
        Logger.log("Video stopped")
    }
    
    func cleanup() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        state = .unloaded
        Logger.log("Video renderer cleaned up")
    }
    
    func setTargetFPS(_ fps: Int) {
        targetFPS = fps
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
    
    private func setupLooping() {
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }
}
