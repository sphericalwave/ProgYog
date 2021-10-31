//
//  TrainVm.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class TrainVm: ObservableObject
{
    @Published var skillFamily: String = "Dolphin Bomber"
    @Published var skill: String = "Hollow Body Pushup"
    @Published var skillLevel: Int = 1
    @Published var skillTime: Double = 30
    @Published var showingAlert = false
    @Published var inputText = """
    While laying in a prone position with your forearms tight to your ribs, lock your knees and rest on the balls of your feet.
    
    Exhale through the mouth and push up from your palms until your elbows can move inwards toward one another.
    
    Push no higher than your elbows remain in contact with your ribs.
    
    Slightly round your midback, and allow your shoulders to waterfall lower toward your elbows so that your upper arms are as parallel to the ground as possible.
    
    Squeeze your knees locked and your heels together. Tuck your tailbone.
    
    Release this hollow body position and lower yourself belly down to the floor with an inhale through the nose.
    """
}
