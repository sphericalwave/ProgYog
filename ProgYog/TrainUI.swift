//
//  TrainUI.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI
import AVKit

struct TrainUI: View {
    @State var skillFamily: String = "Dolphin Bomber"
    @State var skill: String = "Hollow Body Pushup"
    @State var skillLevel: Int = 1
    @State private var skillTime: Double = 30
    @State private var showingAlert = false
    @State private var inputText = """
    While laying in a prone position with your forearms tight to your ribs, lock your knees and rest on the balls of your feet.

    Exhale through the mouth and push up from your palms until your elbows can move inwards toward one another.

    Push no higher than your elbows remain in contact with your ribs.

    Slightly round your midback, and allow your shoulders to waterfall lower toward your elbows so that your upper arms are as parallel to the ground as possible.

    Squeeze your knees locked and your heels together. Tuck your tailbone.

    Release this hollow body position and lower yourself belly down to the floor with an inhale through the nose.
    """
    
    var body: some View {
        VStack {
            Text("\(skillFamily) \(skillLevel)")
                .font(.headline)
            Text("\(skill)")
                .font(.subheadline)
            
            ZStack() {
                Rectangle()
                    //.inset(by: 10)
                    .fill(Color.blue)
                    .frame(height: 198)
                Text("Graph of Current Skill Score")
            }
            
            ProgressView(value: skillTime, total: 60)
            
            TextEditor(text: $inputText)
                .disabled(true)
            
            Text("Session: 18:55")
            ProgressView(value: skillTime, total: 60)
            
            Button("Test Show Alert") {
                        showingAlert = true
                    }
                    .alert(isPresented:$showingAlert) {
                        Alert(
                            title: Text("Range of Motion") ,
                            message: Text("\(skillFamily) \(skillLevel) \(skill)"),
                            primaryButton: .default(Text("Free to Move")) { print("Free to Move") },
                            secondaryButton: .destructive(Text("Movement Constrained")) { print("Movement Constrained") }
                        )
                    }
        }
        .padding()
    }
}

//
//struct ContentView: View {
//    @State private var downloadAmount = 0.0
//    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
//
//    var body: some View {
//        VStack {
//            ProgressView("Downloading…", value: downloadAmount, total: 100)
//        }
//        .onReceive(timer) { _ in
//            if downloadAmount < 100 {
//                downloadAmount += 2
//            }
//        }
//    }
//}
