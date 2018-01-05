//
//  ViewController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 26/12/2017.
//  Copyright © 2017 Jakub Konka. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    @IBOutlet weak var playlistsList: UITableView!
    @IBOutlet weak var loginButton: UIButton!
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var playlists: SPTPlaylistList!
    var player: SPTAudioStreamingController?
    var loginURL: URL?
    var songsForPlayback = [SPTPlaylistTrack]()
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        playlistsList.dataSource = self
        playlistsList.delegate = self
        
        setUp()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
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
        self.songsForPlayback.removeAll(keepingCapacity: false)
        
        let playlist = playlists.items[indexPath.item] as! SPTPartialPlaylist
        SPTPlaylistSnapshot.playlist(withURI: playlist.playableUri, accessToken: self.session.accessToken, callback:
            {(error, data) in
                if error != nil {
                    print("Something went wrong: " + error.debugDescription)
                    return
                }
                
                if let snap = data as? SPTPlaylistSnapshot {
                    let page = snap.firstTrackPage!
                    for tr in page.items {
                        if let track = tr as? SPTPlaylistTrack {
                            self.songsForPlayback.append(track)
                        }
                    }
                    print("Loaded \(self.songsForPlayback.count) songs")
                    
                    // TODO shuffle
                    // start playback
                    print("Starting playback...")
                    let first = self.songsForPlayback[0]
                    self.songsForPlayback.remove(at: 0)
                    self.player?.playSpotifyURI(first.playableUri.absoluteString, startingWith: 0, startingWithPosition: 0, callback:
                        {(error) in
                            if error != nil {
                                print("Couldn't play a track!")
                            }
                    })
                    self.timer.invalidate()
                    self.timer = Timer.scheduledTimer(
                        timeInterval: 20.0,
                        target: self,
                        selector: #selector(self.timerAction),
                        userInfo: nil,
                        repeats: true
                    )
                    
                    // if more songs available, load in the background while already playing
                    if page.hasNextPage {
                        page.requestNextPage(withAccessToken: self.session.accessToken, callback: self.extractTracksFromPlaylistPage)
                    }
                }
        })
    }
    
    func extractTracksFromPlaylistPage(error: Error?, response: Any?) {
        print("More songs available, loading...")
        if error != nil {
            print("Something went wrong: " + error.debugDescription)
            return
        }
        
        let page = response as! SPTListPage
        for tr in page.items {
            if let track = tr as? SPTPlaylistTrack {
                self.songsForPlayback.append(track)
            }
        }
        print("Loaded \(self.songsForPlayback.count) songs")
        
        if page.hasNextPage {
            page.requestNextPage(withAccessToken: self.session.accessToken, callback: self.extractTracksFromPlaylistPage)
        }
    }
    
    @objc func timerAction() {
        print("Timer expired!")
        self.player?.setIsPlaying(false, callback: {(error) in
            if error != nil {
                print("Couldn't stop the playback!")
            }
        })
    }

    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        // TODO get info about current track such as volume level and auto-adjust
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if (isPlaying) {
            return
        }
        if (self.songsForPlayback.isEmpty) {
            self.timer.invalidate()
            return
        }
        let next = self.songsForPlayback[0]
        self.songsForPlayback.remove(at: 0)
        self.player?.playSpotifyURI(next.playableUri.absoluteString, startingWith: 0, startingWithPosition: 0, callback:
            {(error) in
                if error != nil {
                    print("Couldn't enqueue a track!")
                }
        })
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
                    self.playlists = data as! SPTPlaylistList
                    self.playlistsList.reloadData()
            })
            
            initialisePlayer(authSession: session)
        }
    }
    
    func initialisePlayer(authSession: SPTSession) {
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
        }
    }

    func setUp() {
        SPTAuth.defaultInstance().clientID = Credentials.ClientID
        SPTAuth.defaultInstance().redirectURL = Credentials.RedirectURL
        SPTAuth.defaultInstance().requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadPrivateScope,
            SPTAuthPlaylistModifyPublicScope,
            SPTAuthPlaylistModifyPrivateScope
        ]
        loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        UIApplication.shared.open(loginURL!, options: [:], completionHandler: {
            (success) in
                if self.auth.canHandle(self.auth.redirectURL) {
                }
        })
    }
}

