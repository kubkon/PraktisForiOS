//
//  PlaylistsViewDelegate.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 07/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class PlaylistsViewDelegate : NSObject, UITableViewDelegate, UITableViewDataSource {
    var spotifyController: SpotifyController?
    var playlists: SPTPlaylistList?
    
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let playlists = playlists {
            if let playlist = playlists.items[indexPath.item] as? SPTPartialPlaylist {
                spotifyController?.getTracksForPlaylist(playlist.uri)
            }
        }
    }
}
