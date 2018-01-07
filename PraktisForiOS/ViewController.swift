//
//  ViewController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 26/12/2017.
//  Copyright © 2017 Jakub Konka. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    @IBOutlet weak var playlistsList: UITableView!
    @IBOutlet weak var tracksList: UIScrollView!
    @IBOutlet weak var loginButton: UIButton!
    
    var auth = SPTAuth.defaultInstance()!
    var loginURL: URL?
    var session: SPTSession!
    
    var player: SPTAudioStreamingController?
    var playlists: SPTPlaylistList!
    var tracksForPlayback = [SPTPlaylistTrack]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        playlistsList.dataSource = self
        playlistsList.delegate = self
        
        // set up Spotify
        SPTAuth.defaultInstance().clientID = Credentials.ClientID
        SPTAuth.defaultInstance().redirectURL = Credentials.RedirectURL
        SPTAuth.defaultInstance().requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadPrivateScope,
            SPTAuthPlaylistModifyPublicScope,
            SPTAuthPlaylistModifyPrivateScope
        ]
        loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
        
        // continue playback in the background
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
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlists == nil {
            return 0
        }
        return playlists.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if playlists == nil {
            return UITableViewCell()
        }
        let playlist = playlists.items[indexPath.item] as! SPTPartialPlaylist
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        label.text = playlist.name + " (\(playlist.trackCount))"
        cell.addSubview(label)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Clean up
        self.tracksForPlayback.removeAll(keepingCapacity: false)
        
        if let playlist = playlists.items[indexPath.item] as? SPTPartialPlaylist {
            SPTPlaylistSnapshot.playlist(withURI: playlist.playableUri, accessToken: self.session.accessToken, callback:
                {(error, data) in
                    if error != nil {
                        print("Couldn't fetch the tracks: " + error.debugDescription)
                        return
                    }
                    
                    if let snap = data as? SPTPlaylistSnapshot {
                        var fetchTracks: ((Error?, Any?) -> Void)!
                        fetchTracks = { (error: Error?, data: Any?) -> Void in
                            if error != nil {
                                print("Couldn't fetch the tracks: " + error.debugDescription)
                                return
                            }
                            
                            if let page = data as? SPTListPage {
                                for tr in page.items {
                                    if let track = tr as? SPTPlaylistTrack {
                                        self.tracksForPlayback.append(track)
                                    }
                                }
                                print("Loaded \(page.items.count) tracks")
                                
                                if page.hasNextPage {
                                    page.requestNextPage(withAccessToken: self.session.accessToken, callback: fetchTracks)
                                } else {
                                    // populate the scroll view
                                }
                            }
                        }
                        fetchTracks(nil, snap.firstTrackPage)
                    }
            })
        }
    }

    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {

    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {

    }
    
    @objc func updateAfterFirstLogin() {
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            
            self.loginButton.setTitle("Logged in as " + self.session.canonicalUsername, for: .normal)
            self.loginButton.isEnabled = false
            
            SPTPlaylistList.playlists(
                forUser: self.session.canonicalUsername,
                withAccessToken: self.session.accessToken,
                callback: {(error, data) in
                    if let data = data as? SPTPlaylistList {
                        self.playlists = data
                        self.playlistsList.reloadData()
                    }
            })
            
            if self.player == nil {
                self.player = SPTAudioStreamingController.sharedInstance()
                self.player!.playbackDelegate = self
                self.player!.delegate = self
                try! player!.start(withClientId: auth.clientID)
                self.player!.login(withAccessToken: self.session.accessToken)
            }
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        if let loginURL = loginURL {
            UIApplication.shared.open(loginURL, options: [:], completionHandler: {
                (success) in if self.auth.canHandle(self.auth.redirectURL) {}
            })
        }
    }
}
