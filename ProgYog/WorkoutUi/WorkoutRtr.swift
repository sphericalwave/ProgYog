//
//  WorkoutRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class WorkoutRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: WorkoutVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = WorkoutVm()
    }
    
    func rootView() -> some View {
        WorkoutUi(rtr: self, vm: self.vm)
    }
    
    func trainUi() -> some View {
        TrainRtr(srvcs: srvcs).rootView()
    }
    
    func movementUi() -> some View {
        MovementRtr(srvcs: srvcs).rootView()
    }
}
