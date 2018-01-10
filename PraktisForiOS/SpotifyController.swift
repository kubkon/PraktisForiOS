//
//  AudioController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 07/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation
import AVFoundation

class SpotifyController : NSObject, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    var auth = SPTAuth.defaultInstance()!
    var loginURL: URL?
    var session: SPTSession!
    var player: SPTAudioStreamingController?
    var viewController: ViewController!
    var timer: Timer?
    var wasTimerAction = false
    var timeElapsed = 0.0
    var currentTrackIndex: Int?
    let avPlayer = AVQueuePlayer()
    var isPlaying = false
    
    class func setUp(with viewController: ViewController!) -> SpotifyController {
        SPTAuth.defaultInstance().clientID = Credentials.ClientID
        SPTAuth.defaultInstance().redirectURL = Credentials.RedirectURL
        SPTAuth.defaultInstance().requestedScopes = [
            SPTAuthStreamingScope,
            SPTAuthPlaylistReadPrivateScope,
            SPTAuthPlaylistModifyPublicScope,
            SPTAuthPlaylistModifyPrivateScope,
            SPTAuthPlaylistReadCollaborativeScope
        ]
        let spotifyController = SpotifyController()
        spotifyController.loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        spotifyController.viewController = viewController
        NotificationCenter.default.addObserver(
            spotifyController,
            selector: #selector(SpotifyController.updateAfterFirstLogin),
            name: NSNotification.Name(rawValue: "loginSuccessful"),
            object: nil
        )
        
        return spotifyController
    }
    
    @objc func updateAfterFirstLogin() {
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            session = firstTimeSession
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(SpotifyController.avPlayerDidReachEnd),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: avPlayer.currentItem
            )
            
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
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        // get next track
        if let index = currentTrackIndex {
            // check if more tracks available for playback
            currentTrackIndex = index + 1
            if currentTrackIndex! >= viewController.tracksViewDelegate.tracks.count {
                self.invalidateTimer()
                return
            }
            let track = viewController.tracksViewDelegate.tracks[currentTrackIndex!]
            stream(track)
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.isPlaying = isPlaying
        if wasTimerAction {
            // play "Cambio de pareja"
            if let url = Bundle.main.url(forResource: "Cambio De Pareja", withExtension: "m4a") {
                avPlayer.removeAllItems()
                avPlayer.insert(AVPlayerItem(url: url), after: nil)
                avPlayer.play()
            }
            wasTimerAction = false
        }
    }
    
    func getTracksForPlaylist(_ uri: URL!) {
        SPTPlaylistSnapshot.playlist(withURI: uri, accessToken: session.accessToken, callback:
            {(error, data) in
                if error != nil {
                    print("Couldn't fetch the tracks: " + error.debugDescription)
                    return
                }
                
                var tracks = [SPTPlaylistTrack]()
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
                                    tracks.append(track)
                                }
                            }
                            print("Loaded \(page.items.count) tracks")
                            
                            if page.hasNextPage {
                                page.requestNextPage(withAccessToken: self.session.accessToken, callback: fetchTracks)
                            } else {
                                // finished loading all tracks, then refresh
                                self.viewController.tracksViewDelegate.tracks = tracks
                                self.viewController.tracksList.reloadData()
                            }
                        }
                    }
                    fetchTracks(nil, snap.firstTrackPage)
                }
        })
    }
    
    func stream(_ track: SPTPlaylistTrack!) {
        viewController.trackName.text = track.name
        if let artwork = track.album?.largestCover {
            viewController.trackArtwork.image = UIImage(data: try! Data(contentsOf: artwork.imageURL))
        }
        player?.playSpotifyURI(
            track.playableUri.absoluteString,
            startingWith: 0,
            startingWithPosition: 0,
            callback: {(error) in
                if error != nil {
                    print("Couldn't start the playback!")
                    self.timer?.invalidate()
                    return
                }
        })
    }
    
    func startPlayback(from index: Int) {
        currentTrackIndex = index
        let track = viewController.tracksViewDelegate.tracks[currentTrackIndex!]
        stream(track)
        self.setTimer()
    }
    
    func playPrevious() {
        if let index = currentTrackIndex {
            // check if more tracks available for playback
            if currentTrackIndex! - 1 < 0 {
                return
            }
            currentTrackIndex = index - 1
            let track = viewController.tracksViewDelegate.tracks[currentTrackIndex!]
            stream(track)
            self.setTimer()
        }
    }
    
    func playNext() {
        if let index = currentTrackIndex {
            // check if more tracks available for playback
            if currentTrackIndex! + 1 >= viewController.tracksViewDelegate.tracks.count {
                return
            }
            currentTrackIndex = index + 1
            let track = viewController.tracksViewDelegate.tracks[currentTrackIndex!]
            stream(track)
            self.setTimer()
        }
    }
    
    func pause() {
        if isPlaying {
            invalidateTimer()
            player?.setIsPlaying(!isPlaying, callback: {(error) in
                if error != nil {
                    print("Couldn't stop the playback!")
                    return
                }
                self.timeElapsed = self.player!.playbackState.position
            })
        }
        else {
            let track = viewController.tracksViewDelegate.tracks[currentTrackIndex!]
            player?.playSpotifyURI(
                track.playableUri.absoluteString,
                startingWith: 0,
                startingWithPosition: timeElapsed,
                callback: {(error) in
                    if error != nil {
                        print("Couldn't start the playback!")
                        self.invalidateTimer()
                        return
                    }
            })
            // TODO continue with timer where left off
            self.setTimer()
        }
    }
    
    @objc func avPlayerDidReachEnd() {
        // continue playback!
        let track = viewController.tracksViewDelegate.tracks[currentTrackIndex!]
        player?.playSpotifyURI(
            track.playableUri.absoluteString,
            startingWith: 0,
            startingWithPosition: timeElapsed,
            callback: {(error) in
                if error != nil {
                    print("Couldn't start the playback!")
                    self.invalidateTimer()
                    return
                }
        })
    }
    
    func setTimer() {
        invalidateTimer()
        if let timerDuration = viewController.timerDuration.text {
            if let duration = Int(timerDuration) {
                if duration == 0 {
                    return
                }
                timer = Timer.scheduledTimer(
                    timeInterval: Double(duration),
                    target: self,
                    selector: #selector(self.timerAction),
                    userInfo: nil,
                    repeats: true
                )
                print("Timer set!")
            }
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        print("Timer invalidated")
    }
    
    @objc func timerAction() {
        print("Timer expired!")
        player?.setIsPlaying(false, callback: {(error) in
            if error != nil {
                print("Couldn't stop the playback!")
                return
            }
            self.timeElapsed = self.player!.playbackState.position
        })
        wasTimerAction = true
    }
    
    func updateTimer() {
        print("Updating timer!")
        if !isPlaying {
            return
        }
        setTimer()
    }
}
