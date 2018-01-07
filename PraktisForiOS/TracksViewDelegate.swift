//
//  TracksViewDelegate.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 07/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class TracksViewDelegate : NSObject, UITableViewDelegate, UITableViewDataSource {
    var spotifyController: SpotifyController?
    var tracks = [SPTPlaylistTrack]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tracks.isEmpty {
            return 0
        }
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tracks.isEmpty {
            return UITableViewCell()
        }
        let track = tracks[indexPath.item] as SPTPlaylistTrack
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 550, height: 50))
        label.text = track.name
        cell.addSubview(label)
        return cell
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
}
