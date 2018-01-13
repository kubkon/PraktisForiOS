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
    var volume = 1.0
    let volumeReductionFactor = 0.5
    var currentTrackIndex: IndexPath!
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
        // check if more tracks available for playback
        currentTrackIndex.item += 1
        if currentTrackIndex.item >= viewController.tracksViewDelegate.tracks.count {
            self.invalidateTimer()
            return
        }
        let track = viewController.tracksViewDelegate.tracks[currentTrackIndex.item]
        stream(track)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangeVolume volume: SPTVolume) {
        if wasTimerAction {
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
        // update title and artwork placeholders
        viewController.trackName.text = track.name
        if let artwork = track.album?.largestCover {
            viewController.trackArtwork.image = UIImage(data: try! Data(contentsOf: artwork.imageURL))
        }
        // highlight currently played track in the TrackView
        viewController.tracksList.selectRow(at: currentTrackIndex, animated: false, scrollPosition: UITableViewScrollPosition.none)
        // start streaming
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
    
    func startPlayback(from index: IndexPath) {
        currentTrackIndex = index
        let track = viewController.tracksViewDelegate.tracks[currentTrackIndex.item]
        stream(track)
        self.setTimer()
    }
    
    func playPrevious() {
        // check if more tracks available for playback
        if currentTrackIndex.item - 1 < 0 {
            return
        }
        currentTrackIndex.item -= 1
        let track = viewController.tracksViewDelegate.tracks[currentTrackIndex.item]
        stream(track)
        self.setTimer()
    }
    
    func playNext() {
        // check if more tracks available for playback
        if currentTrackIndex.item + 1 >= viewController.tracksViewDelegate.tracks.count {
            return
        }
        currentTrackIndex.item += 1
        let track = viewController.tracksViewDelegate.tracks[currentTrackIndex.item]
        stream(track)
        self.setTimer()
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
            let track = viewController.tracksViewDelegate.tracks[currentTrackIndex.item]
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
        player?.setVolume(volume, callback: {(error) in
            if error != nil {
                print("Couldn't change volume!")
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
        if let v = player?.volume {
            volume = v
        }
        player?.setVolume(volume * volumeReductionFactor, callback: {(error) in
            if error != nil {
                print("Couldn't change volume!")
            }
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
