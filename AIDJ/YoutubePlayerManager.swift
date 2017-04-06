//
//  YoutubePlayerManager.swift
//  AIDJ
//
//  Created by Akihiro Aida on 2017/03/28.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import youtube_ios_player_helper

class YoutubePlayerManager: NSObject, YTPlayerViewDelegate {
    var youtubeView: YTPlayerView!
    let playerParam = [
        "playsinline": 1,
        "showinfo": 0,
        "autoplay": 1,
        "rel": 0,
        "controls": 1,
        "origin": "https://www.example.com",
        "modestbranding": 1,
        "vq": "medium", // smallだと音質も明らかに下がる.
        ] as [String : Any]
    
    var isHardPlay = false
    var isPlaying = false {
        didSet {
            if isPlaying {
                delegate?.playStateChange(playing: true)
            } else {
                delegate?.playStateChange(playing: false)
            }
        }
    }
    var delegate: YoutubePlayerManageDelegate?
    
    convenience init(containerView: UIView) {
        // view Element
        let playerView = YTPlayerView(frame: CGRect.zero)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        // addsubview
        containerView.addSubview(playerView)
        
        let consTop = NSLayoutConstraint(item: playerView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1.0, constant: 0.0)
        let consBottom = NSLayoutConstraint(item: playerView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        let consLeft = NSLayoutConstraint(item: playerView, attribute: .left, relatedBy: .equal, toItem: containerView, attribute: .left, multiplier: 1.0, constant: 0.0)
        let consRight = NSLayoutConstraint(item: playerView, attribute: .right, relatedBy: .equal, toItem: containerView, attribute: .right, multiplier: 1.0, constant: 0.0)
        containerView.addConstraints([consTop, consBottom, consLeft, consRight])
        
        // PureLayoutで書けばこれくらいシンプルになるらしい。
//        playerView.autoPinEdgeToSuperviewEdge(.Top)
//        playerView.autoPinEdgeToSuperviewEdge(.Left)
//        playerView.autoPinEdgeToSuperviewEdge(.Right)
//        playerView.autoSetDimension(.Height, toSize: 380)
        self.init(playerView: playerView)
    }
    
    init(playerView: YTPlayerView) {
        super.init()
        
        youtubeView = playerView
        youtubeView.delegate = self
        
        let defaultCenter = NotificationCenter.default
        
        defaultCenter.addObserver(self, selector: #selector(applicationDidEnterBackground(application:)), name: .UIApplicationDidEnterBackground, object: nil)
        defaultCenter.addObserver(self, selector: #selector(applicationWillEnterForeground(application:)), name: .UIApplicationWillEnterForeground, object: nil)
        defaultCenter.addObserver(self, selector: #selector(applicationWillResignActive(application:)), name: .UIApplicationWillResignActive, object: nil)
        
        isHardPlay = false; // 強制再生はまだ不必要なので
    }
    
    func playSong() {
        if youtubeView.playerState() == YTPlayerState.playing {
            youtubeView.pauseVideo()
            isPlaying = false
        } else {
            youtubeView.playVideo()
            isPlaying = true
        }
    }
    
    
    func setVideo(identifier: String){
        youtubeView.load(withVideoId: identifier, playerVars: playerParam)
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        
        switch (state) {
        case YTPlayerState.paused:
            NSLog("didChangeTo paused")
            if isHardPlay { // 一時停止ボタンが効かなくなるので判定する
                playerView.playVideo()
                isHardPlay = false
            }
        case YTPlayerState.buffering:
            NSLog("didChangeTo buffering")
        case YTPlayerState.ended:
            NSLog("didChangeTo ended")
            if isPlaying {
                delegate?.playEnded()
            }
        case YTPlayerState.playing:
            NSLog("didChangeTo playing")
            isPlaying = true
        case YTPlayerState.queued:
            NSLog("didChangeTo queued")
        case YTPlayerState.unknown:
            NSLog("didChangeTo unknown")
        case YTPlayerState.unstarted:
            NSLog("didChangeTo unstarted")
        }
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        NSLog("playerViewDidBecomeReady")
        if isPlaying {
            playerView.playVideo()
        }
    }
    
    // バックグラウンド移行直前に実行(didChangeToStateより先に動きます)
    func applicationWillResignActive(application: UIApplication) -> Void {
        NSLog("applicationWillResignActive")
        isHardPlay = true; // didChangeToStateで再生してもらう為にフラグ書き換え
    }
    
    // バックグラウンド移行後に実行(didChangeToStateより後に動きます)
    func applicationDidEnterBackground(application: UIApplication) -> Void {
        NSLog("applicationDidEnterBackground")
        // バックグラウンド再生したい気持ちを伝えます
        if isPlaying {
            youtubeView.playVideo()
        }
    }
    
    // フォアグラウンドに戻ってきた際に実行
    func applicationWillEnterForeground(application: UIApplication) -> Void {
        NSLog("applicationWillEnterForeground")
    }
}

protocol YoutubePlayerManageDelegate {
    func playStateChange(playing: Bool)
    func playEnded()
}
