//
//  MovementRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class MovementRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: MovementVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = MovementVm()
    }
    
    func rootView() -> some View {
        MovementUi(rtr: self, vm: self.vm)
    }
    
    func workoutUi() -> some View {
        WorkoutRtr(srvcs: srvcs).rootView()
    }
}
