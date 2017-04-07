//
//  ViewController.swift
//  AIDJ
//
//  Created by AidaAkihiro on 2017/02/23.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import UIKit
import Firebase

import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var volumeBar: UIProgressView!
    @IBOutlet weak var volumeBar2: UIProgressView!
    
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
    var tapProcessor: MYAudioTapProcessor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.shared.beginReceivingRemoteControlEvents()
        navBar.delegate = self
        navItem.titleView = UIImageView(image: R.image.header())
        playerManager = YoutubePlayerManager(containerView: containerView)
        playerManager?.delegate = self
        
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("settings")
        if FileManager().fileExists(atPath: path) {
            settings = NSDictionary(contentsOfFile: path) as! [String: Any]
        } else {
            _ = (self.settings as NSDictionary).write(toFile: path, atomically: true)
        }
//        NSLog("path \(path)")
        NSLog("settings \(settings)")
        
        databaseRef = FIRDatabase.database().reference()
        registerDatabase()
        
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self, selector: #selector(itemDidPlayToEndTime(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        defaultCenter.addObserver(self, selector: #selector(itemBecameCurrentNotification(notification:)), name: Notification.Name(rawValue: "AVPlayerItemBecameCurrentNotification"), object: nil)

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
//            NSLog("songs: \(values)")
            self.songs = values as! [String : [String: AnyObject]]
            self.songsKey = Array(self.songs.keys).sorted(by: {$0 < $1})
//            NSLog("songs: \(self.songs)")
            // listの更新
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.setSong(index: self.songIndex)
        })
        let roomHandle = databaseRef.child("rooms/\(settings["roomId"]!)").observe(FIRDataEventType.value, with: { (snapshot) -> Void in
            var index: Int = 0
            if snapshot.value is NSNull {
                index = 0
            } else if let values = snapshot.value {
                let room = values as! [String : AnyObject]
//                NSLog("room \(room)")
                index = room["playing"] as! Int
            }
            self.setSong(index: index)
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
        
        databaseRef.child("rooms").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value is NSNull {
                return
            }
            guard let values: Any = snapshot.value else {
                return
            }
            NSLog("rooms: \(values)")
            let rooms = values as! [String : [String: AnyObject]]
            NSLog("rooms: \(rooms.count, rooms)")
            self.showRoomSelect(rooms: rooms)
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func showRoomSelect(rooms: [String : [String: AnyObject]]) {
        let currentRoom = rooms[settings["roomId"] as! String]?["name"] as? String ?? "unknown"
        let alert = UIAlertController(title: "Room Id", message: "current \n \(currentRoom)", preferredStyle: .actionSheet)
        let roomKeys = Array(rooms.keys).sorted(by: {$0 < $1})
        
        let closure = { (action: UIAlertAction!) -> Void in
            guard let index = alert.actions.index(of: action) else {
                return
            }
            NSLog("Index: \(index, roomKeys[index])")
            self.settings["roomId"] = roomKeys[index]
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("settings")
            _ = (self.settings as NSDictionary).write(toFile: path, atomically: true)

            self.unregisterDatabase()
            self.registerDatabase()
        }
        for key in roomKeys {
            alert.addAction(UIAlertAction(title: rooms[key]?["name"] as? String, style: .default, handler: closure))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func setSong(index: Int) {
        if self.songIndex != index && index < self.songs.count {
            self.selectSong(row: index)
        }
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
    
    func itemDidPlayToEndTime(notification: NSNotification) {
        NSLog("itemDidPlayToEndTime")
//        NSLog("itemDidPlayToEndTime: \(notification)")
        let playerItem: AVPlayerItem? = notification.object as? AVPlayerItem
        let _: AVPlayer? = playerItem?.value(forKey: "player") as? AVPlayer
    }
    
    func itemBecameCurrentNotification(notification: NSNotification) {
        NSLog("itemBecameCurrentNotification")
//        NSLog("itemBecameCurrentNotification: \(notification)")
        
        guard let playerItem = notification.object as? AVPlayerItem else {
            return
        }
        //        AudioTap.setAudioTap(playerItem: playerItem!)
        if let _ = playerItem.asset.tracks as? [AVAssetTrack] {
            tapProcessor = MYAudioTapProcessor(avPlayerItem: playerItem)
            playerItem.audioMix = tapProcessor.audioMix
            tapProcessor.delegate = self
        }
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

extension ViewController: MYAudioTabProcessorDelegate {
    
    func audioTabProcessor(_ audioTabProcessor: MYAudioTapProcessor!, hasNewLeftChannelValue leftChannelValue: Float, rightChannelValue: Float) {
//        print("volume: \(leftChannelValue) : \(rightChannelValue)")
//        volumeSlider.value = leftChannelValue
        volumeBar.setProgress(leftChannelValue, animated: true)
        volumeBar2.setProgress(rightChannelValue, animated: true)
    }
}
