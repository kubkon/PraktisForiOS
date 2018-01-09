//
//  ViewController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 26/12/2017.
//  Copyright © 2017 Jakub Konka. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var playlistsList: UITableView!
    @IBOutlet weak var tracksList: UITableView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var timerDuration: UITextField!
    @IBOutlet weak var timerDurationPicker: UIPickerView!
    @IBOutlet weak var trackArtwork: UIImageView!
    @IBOutlet weak var trackName: UILabel!
    
    var spotifyController: SpotifyController!
    var playlistsViewDelegate: PlaylistsViewDelegate!
    var tracksViewDelegate: TracksViewDelegate!
    var timerDurationViewDelegate: TimerDurationViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set default timerDuration
        timerDurationViewDelegate = TimerDurationViewDelegate()
        timerDurationViewDelegate.mainView = self
        timerDuration.text = String(timerDurationViewDelegate.timerDurations[0]);
        timerDurationPicker.isHidden = true;
        timerDurationPicker.dataSource = timerDurationViewDelegate
        timerDurationPicker.delegate = timerDurationViewDelegate
        timerDuration.delegate = timerDurationViewDelegate
        
        // set up Spotify
        spotifyController = SpotifyController.setUp(with: self)
        
        // set up playlistsViewDelegate, tracksViewDelegate
        playlistsViewDelegate = PlaylistsViewDelegate()
        playlistsViewDelegate.mainView = self
        tracksViewDelegate = TracksViewDelegate()
        tracksViewDelegate.mainView = self
        
        playlistsList.dataSource = playlistsViewDelegate
        playlistsList.delegate = playlistsViewDelegate
        tracksList.dataSource = tracksViewDelegate
        tracksList.delegate = tracksViewDelegate
        
        // ensure playback is continued in the background
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        if let loginURL = spotifyController.loginURL {
            UIApplication.shared.open(loginURL, options: [:], completionHandler: {
                (success) in
                    if self.spotifyController.auth.canHandle(self.spotifyController.auth.redirectURL) {}
            })
        }
    }
}
