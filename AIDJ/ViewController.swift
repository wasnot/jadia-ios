//
//  ViewController.swift
//  AIDJ
//
//  Created by AidaAkihiro on 2017/02/23.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import UIKit
import NotificationCenter
import youtube_ios_player_helper
import Firebase

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationBarDelegate, YTPlayerViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var youtubeView: YTPlayerView!
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    var songs: [String: [String: AnyObject]] = [:]
    var songsKey: [String] = []
    var databaseRef:FIRDatabaseReference!
    var songIndex = -1 {
        didSet {
            NSLog("did Set \(songIndex), \(databaseRef)")
            databaseRef.child("playing").updateChildValues(["index": songIndex])
        }
    }
    var isHardPlay = false
    var isPlaying = false {
        didSet {
            if isPlaying {
                playButton.image = R.image.pause()
            } else {
                playButton.image = R.image.play()
            }
        }
    }
    
    let playerParam = [
        "playsinline": 1,
        "showinfo": 0,
        "autoplay": 1,
        "rel": 0,
        "controls": 1,
        "origin": "https://www.example.com",
        "modestbranding": 1
    ] as [String : Any]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.shared.beginReceivingRemoteControlEvents()
        navBar.delegate = self
        navItem.titleView = UIImageView(image: R.image.header())
        youtubeView.delegate = self
        
        databaseRef = FIRDatabase.database().reference()
        databaseRef.child("songs").queryOrderedByKey().observe(FIRDataEventType.value, with: { (snapshot) -> Void in
            if snapshot.value is NSNull {
                return
            }
            guard let values: Any = snapshot.value else {
                return
            }
            NSLog("songs: \(values)")
            self.songs = values as! [String : [String: AnyObject]]
            self.songsKey = Array(self.songs.keys).sorted(by: {$0 < $1})
            NSLog("songs: \(self.songs)")
            // listの更新
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        })
        databaseRef.child("playing").observe(FIRDataEventType.value, with: { (snapshot) -> Void in
            var index: Int = 0
            if snapshot.value is NSNull {
                index = 0
            } else if let values = snapshot.value {
                let playing = values as! [String : AnyObject]
                NSLog("playing \(playing)")
                index = playing["index"] as! Int
            }
            if self.songIndex != index && index < self.songs.count {
                self.selectSong(row: index)
            }
        })
        
        let defaultCenter = NotificationCenter.default
        
        defaultCenter.addObserver(self, selector: #selector(applicationDidEnterBackground(application:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        defaultCenter.addObserver(self, selector: #selector(applicationWillEnterForeground(application:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        defaultCenter.addObserver(self, selector: #selector(applicationWillResignActive(application:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        isHardPlay = false; // 強制再生はまだ不必要なので
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func playButton(_ sender: Any) {
        if youtubeView.playerState() == YTPlayerState.playing {
            youtubeView.pauseVideo()
            isPlaying = false
        } else {
            youtubeView.playVideo()
            isPlaying = true
        }
    }
    
    @IBAction func nextButton(_ sender: Any) {
        nextSong()
    }
    
    func nextSong(){
        
        self.selectSong(row: songIndex < songs.count - 1 ? songIndex + 1 : 0)
    }
    
    func selectSong(row: Int = 0, section: Int = 0){
        NSLog("selectSong \(row)")
        let index = IndexPath(row: row, section: section)
        collectionView.selectItem(at: index, animated: true, scrollPosition: UICollectionViewScrollPosition.top)
        collectionView(collectionView, didSelectItemAt: index)
    }
    
    func setVideo(identifier: String){
        youtubeView.load(withVideoId: identifier, playerVars: playerParam)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let songCell: SongCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! SongCell
        let song = songs[songsKey[indexPath.row]]
        songCell.label.text = song?["name"] as! String?
        
        //選択時の背景
        let selectedBGView = UIView(frame: songCell.bounds)
        selectedBGView.backgroundColor = UIColor.Jadia.coolCyan
        songCell.selectedBackgroundView = selectedBGView
        
        songCell.backgroundColor = indexPath.row % 2 != 0 ? UIColor.Jadia.gray : UIColor.black
        
        return songCell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return songs.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        songIndex = indexPath.row
        let song = songs[songsKey[indexPath.row]]
        setVideo(identifier: song?["id"] as! String)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        NSLog("didSelectItem \(cell.isSelected)")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 50)
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
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
                nextSong()
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
