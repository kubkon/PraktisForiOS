//
//  SPTAudioAnalysis.swift
//  PraktisForiOS
//
//  Created by Jakub Konka on 06/01/2018.
//  Copyright © 2018 Jakub Konka. All rights reserved.
//

import Foundation

class SPTAudioAnalysis {
    var tempo: Double?
    
    class func forTrack(with url: URL, accessToken: String!, callback: @escaping (Error?, Any?) -> Void) {
        let bits = url.absoluteString.components(separatedBy: ":")
        let url = URL(string: "https://api.spotify.com/v1/audio-analysis/" + bits[2])
        var request = URLRequest(url: url!)
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            let decoded = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
            var result: SPTAudioAnalysis?
            if let decoded = decoded {
                result = SPTAudioAnalysis()
                let trackInfo = decoded["track"] as? [String: Any]
                if let trackInfo = trackInfo {
                    result!.tempo = trackInfo["tempo"] as? Double
                }
            }
            
            callback(error, result)
        })
        task.resume()
    }
}
