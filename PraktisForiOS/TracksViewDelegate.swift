//
//  TracksViewDelegate.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 07/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class TracksViewDelegate : NSObject, UITableViewDelegate, UITableViewDataSource {
    var mainView: ViewController!
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
        if tracks.isEmpty {
            return
        }
        mainView.spotifyController.startPlayback(from: indexPath.item)
    }
}
