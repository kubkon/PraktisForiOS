//
//  AudioController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 07/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class SpotifyController : NSObject, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    var auth = SPTAuth.defaultInstance()!
    var loginURL: URL?
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    
    var viewController: ViewController!
    
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
                        self.viewController?.playlistsViewDelegate.playlists = data
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
    
    func getTracksForPlaylist(_ uri: URL!) {
        SPTPlaylistSnapshot.playlist(withURI: uri, accessToken: session.accessToken, callback:
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
                                    self.viewController.tracksViewDelegate.tracks.append(track)
                                }
                            }
                            print("Loaded \(page.items.count) tracks")
                            
                            if page.hasNextPage {
                                page.requestNextPage(withAccessToken: self.session.accessToken, callback: fetchTracks)
                            } else {
                                // finished loading all tracks, then refresh
                                self.viewController.tracksList.reloadData()
                            }
                        }
                    }
                    fetchTracks(nil, snap.firstTrackPage)
                }
        })
    }
}
