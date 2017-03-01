//
//  ViewController.swift
//  AIDJ
//
//  Created by AidaAkihiro on 2017/02/23.
//  Copyright © 2017年 another sensy. All rights reserved.
//

import UIKit
import MediaPlayer
import NotificationCenter
import XCDYouTubeKit
import Firebase

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var videoContainerView: UIView!
    var videoPlayerViewController: XCDYouTubeVideoPlayerViewController?
    let videos = ["9bZkp7q19f0", "nfWlot6h_JM"]
    var databaseRef:FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch let error as NSError {
            NSLog("Failed to set audio session category.  Error: \(error)")
        }
        
        databaseRef = FIRDatabase.database().reference()
        setVideo(identifier: videos[0])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func playButton(_ sender: Any) {
        if let player = videoPlayerViewController {
            player.moviePlayer.play()
        }
    }
    @IBAction func nextButton(_ sender: Any) {
    }
    
    func setVideo(identifier: String){
        if videoPlayerViewController?.videoIdentifier == identifier {
            return
        }
        videoPlayerViewController = XCDYouTubeVideoPlayerViewController.init(videoIdentifier: identifier)
        videoPlayerViewController?.present(in: self.videoContainerView)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        
        let songCell: SongCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! SongCell
        let text = "aaa \(indexPath): \(videos[indexPath.row])"
        songCell.label.text = text
        
        //選択時の背景
        let selectedBGView = UIView(frame: songCell.bounds)
        selectedBGView.backgroundColor = UIColor.red
        songCell.selectedBackgroundView = selectedBGView
        
        return songCell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        setVideo(identifier: videos[indexPath.row])
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: true)
        }else{
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition.bottom)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.darkGray
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.clear
    }
}

