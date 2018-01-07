//
//  AudioController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 07/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class SpotifyController : NSObject, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate, UITableViewDataSource {
    var auth = SPTAuth.defaultInstance()!
    var loginURL: URL?
    var session: SPTSession!
    
    var player: SPTAudioStreamingController?
    
    var playlists: SPTPlaylistList?
    var viewController: ViewController?
    
    var tracksForPlayback = [SPTPlaylistTrack]()
    
    class func setUp(with viewController: ViewController!) -> SpotifyController {
        SPTAuth.defaultInstance().clientID = Credentials.ClientID
        SPTAuth.defaultInstance().redirectURL = Credentials.RedirectURL
        SPTAuth.defaultInstance().requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadPrivateScope,
            SPTAuthPlaylistModifyPublicScope,
            SPTAuthPlaylistModifyPrivateScope
        ]
        let spotifyController = SpotifyController()
        spotifyController.loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        spotifyController.viewController = viewController
        NotificationCenter.default.addObserver(spotifyController, selector: #selector(SpotifyController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessful"), object: nil)
        
        return spotifyController
    }
    
    @objc func updateAfterFirstLogin() {
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            session = firstTimeSession
            
            SPTPlaylistList.playlists(
                forUser: self.session.canonicalUsername,
                withAccessToken: self.session.accessToken,
                callback: {(error, data) in
                    if let data = data as? SPTPlaylistList {
                        self.playlists = data
                        self.viewController?.playlistsList.reloadData()
                    }
            })
            
            if player == nil {
                player = SPTAudioStreamingController.sharedInstance()
                player!.playbackDelegate = self
                player!.delegate = self
                try! player!.start(withClientId: auth.clientID)
                player!.login(withAccessToken: session.accessToken)
            }
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let playlists = playlists {
            return playlists.items.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let playlists = playlists {
            let playlist = playlists.items[indexPath.item] as! SPTPartialPlaylist
            let cell = UITableViewCell()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
            label.text = playlist.name + " (\(playlist.trackCount))"
            cell.addSubview(label)
            return cell
        }
        return UITableViewCell()
    }
}
