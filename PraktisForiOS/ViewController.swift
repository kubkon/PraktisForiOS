//
//  ViewController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 26/12/2017.
//  Copyright © 2017 Jakub Konka. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    @IBOutlet weak var playlistsList: UITableView!
    @IBOutlet weak var loginButton: UIButton!
    
    var auth = SPTAuth.defaultInstance()!
    var session: SPTSession!
    var playlists: SPTPlaylistList!
    var player: SPTAudioStreamingController?
    var loginURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        playlistsList.dataSource = self
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
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
//        self.player?.playSpotifyURI("spotify:track:58s6EuEYJdlb0kO7awm3Vp", startingWith: 0, startingWithPosition: 0, callback: {(error) in
//            if error != nil {
//                print("playing...")
//            }
//        })
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

