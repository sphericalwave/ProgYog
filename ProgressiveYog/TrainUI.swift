//
//  TrainUI.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI
import AVKit

struct TrainUI: View {
    var body: some View {
        HStack {
            Spacer()
            Button(action: { print("ROM is Limited, Deece, Complete")}){ Text("ROM +") }
            Spacer()
            Button(action: { print("Control is mediocre, great")}){ Text("Control -") }
            Spacer()
            Button(action: { print("Discomfort is mild, moderate, extreme")}){ Text("Discomfort +") }
            Spacer()
        }
        
        VideoPlayer(player: AVPlayer(url:  URL(string: "https://bit.ly/swswift")!))
        
        Text("Play First Video")
        Text("Show Feedback Interface")
        Text("Play Next Video Based on Feedback")
    }
}
