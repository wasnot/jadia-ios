//
//  ViewController.swift
//  AIDJ
//
//  Created by AidaAkihiro on 2017/02/23.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import UIKit
import youtube_ios_player_helper
import Firebase

import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var youtubeView: YTPlayerView!
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    var settings: [String: Any] = ["roomId": "-KfA3ThcnZwJhcX0OIzA"]
    var songs: [String: [String: AnyObject]] = [:]
    var songsKey: [String] = []
    var databaseRef: FIRDatabaseReference!
    var databaseHandles: [UInt]?
    var songIndex = -1 {
        didSet {
            NSLog("did Set \(songIndex), \(databaseRef)")
            databaseRef.child("rooms/\(settings["roomId"]!)").updateChildValues(["playing": songIndex])
        }
    }
    var playerManager: YoutubePlayerManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.shared.beginReceivingRemoteControlEvents()
        navBar.delegate = self
        navItem.titleView = UIImageView(image: R.image.header())
        playerManager = YoutubePlayerManager(playerView: youtubeView)
        playerManager?.delegate = self
        
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("settings")
        if FileManager().fileExists(atPath: path) {
            settings = NSDictionary(contentsOfFile: path) as! [String: Any]
        } else {
            _ = (self.settings as NSDictionary).write(toFile: path, atomically: true)
        }
        NSLog("path \(path)")
        NSLog("settings \(settings)")
        
        databaseRef = FIRDatabase.database().reference()
        registerDatabase()
        
        
        
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self, selector: #selector(test1(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        defaultCenter.addObserver(self, selector: #selector(test2(notification:)), name: Notification.Name.AVPlayerItemPlaybackStalled, object: nil)
        defaultCenter.addObserver(self, selector: #selector(test3(notification:)), name: Notification.Name.MPMoviePlayerLoadStateDidChange, object: nil)
        defaultCenter.addObserver(self, selector: #selector(test4(notification:)), name: Notification.Name.MPMoviePlayerDidExitFullscreen, object: nil)
        defaultCenter.addObserver(self, selector: #selector(test4(notification:)), name: Notification.Name.MPMusicPlayerControllerVolumeDidChange, object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerDatabase() {
        NSLog("registerDatabase songs/\(settings["roomId"]!)")
        let songHandle = databaseRef.child("songs/\(settings["roomId"]!)").queryOrderedByKey().observe(FIRDataEventType.value, with: { (snapshot) -> Void in
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
        let roomHandle = databaseRef.child("rooms/\(settings["roomId"]!)").observe(FIRDataEventType.value, with: { (snapshot) -> Void in
            var index: Int = 0
            if snapshot.value is NSNull {
                index = 0
            } else if let values = snapshot.value {
                let room = values as! [String : AnyObject]
                NSLog("room \(room)")
                index = room["playing"] as! Int
            }
            if self.songIndex != index && index < self.songs.count {
                self.selectSong(row: index)
            }
        })
        databaseHandles = [songHandle, roomHandle]
    }
    
    func unregisterDatabase(){
        guard databaseHandles == nil else {
            return
        }
        for handle in databaseHandles! {
            databaseRef.removeObserver(withHandle: handle)
        }
        databaseHandles = nil
    }

    @IBAction func playButton(_ sender: Any) {
        playerManager?.playSong()
    }
    
    @IBAction func nextButton(_ sender: Any) {
        let isOtherAudioPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying
        NSLog("playing \(isOtherAudioPlaying)")
        
        let alert = UIAlertController(title: "Room Id", message: "Input text", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Done", style: .default) { (action:UIAlertAction!) -> Void in
            
            let textField = alert.textFields![0] as UITextField
            
            self.settings["roomId"] = textField.text!
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("settings")
            _ = (self.settings as NSDictionary).write(toFile: path, atomically: true)
            
            self.unregisterDatabase()
            self.registerDatabase()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        // UIAlertControllerにtextFieldを追加
        alert.addTextField(configurationHandler: {(textField: UITextField) -> Void in
            textField.text = self.settings["roomId"] as? String
        })
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
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
    
    func test1(notification: NSNotification) {
        NSLog("test1: \(notification)")
        let _: AVPlayerItem? = notification.object as! AVPlayerItem
        
    }
    
    func test2(notification: NSNotification) {
        NSLog("test2: \(notification)")
    }
    
    func test3(notification: NSNotification) {
        NSLog("test3: \(notification)")
    }
    
    func test4(notification: NSNotification) {
        NSLog("test4: \(notification)")
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UINavigationBarDelegate{
    
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
        playerManager?.setVideo(identifier: song?["id"] as! String)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        NSLog("didSelectItem \(cell.isSelected)")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 50)
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.topAttached
    }
}

extension ViewController: YoutubePlayerManageDelegate {
    func playStateChange(playing: Bool) {
        if playing {
            playButton.image = R.image.pause()
        } else {
            playButton.image = R.image.play()
        }
    }
    func playEnded() {
        nextSong()
    }
}
