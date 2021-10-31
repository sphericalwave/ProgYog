//
//  SeriesRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class SeriesRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: SeriesVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = SeriesVm()
    }
    
    func rootView() -> some View {
        SeriesUI(rtr: self, vm: self.vm)
    }
    
    func trainUi() -> some View {
        TrainRtr(srvcs: srvcs).rootView()
    }
    
    func workoutUi() -> some View {
        WorkoutRtr(srvcs: srvcs).rootView()
    }
}
