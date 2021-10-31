//
//  TrainRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class TrainRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: TrainVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = TrainVm()
    }
    
    func rootView() -> some View {
        TrainUi(rtr: self, vm: self.vm)
    }
}
