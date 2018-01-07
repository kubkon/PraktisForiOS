//
//  ViewController.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 26/12/2017.
//  Copyright © 2017 Jakub Konka. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var playlistsList: UITableView!
    @IBOutlet weak var tracksList: UIScrollView!
    @IBOutlet weak var loginButton: UIButton!
    
    var spotifyController: SpotifyController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up playlistView and Spotify
        spotifyController = SpotifyController.setUp(with: self)
        
        playlistsList.dataSource = spotifyController
        playlistsList.delegate = self
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        // Clean up
        //        self.tracksForPlayback.removeAll(keepingCapacity: false)
        //
        //        if let playlist = playlists.items[indexPath.item] as? SPTPartialPlaylist {
        //            SPTPlaylistSnapshot.playlist(withURI: playlist.playableUri, accessToken: self.session.accessToken, callback:
        //                {(error, data) in
        //                    if error != nil {
        //                        print("Couldn't fetch the tracks: " + error.debugDescription)
        //                        return
        //                    }
        //
        //                    if let snap = data as? SPTPlaylistSnapshot {
        //                        var fetchTracks: ((Error?, Any?) -> Void)!
        //                        fetchTracks = { (error: Error?, data: Any?) -> Void in
        //                            if error != nil {
        //                                print("Couldn't fetch the tracks: " + error.debugDescription)
        //                                return
        //                            }
        //
        //                            if let page = data as? SPTListPage {
        //                                for tr in page.items {
        //                                    if let track = tr as? SPTPlaylistTrack {
        //                                        self.tracksForPlayback.append(track)
        //                                    }
        //                                }
        //                                print("Loaded \(page.items.count) tracks")
        //
        //                                if page.hasNextPage {
        //                                    page.requestNextPage(withAccessToken: self.session.accessToken, callback: fetchTracks)
        //                                } else {
        //                                    // populate the scroll view
        //                                }
        //                            }
        //                        }
        //                        fetchTracks(nil, snap.firstTrackPage)
        //                    }
        //            })
        //        }
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
