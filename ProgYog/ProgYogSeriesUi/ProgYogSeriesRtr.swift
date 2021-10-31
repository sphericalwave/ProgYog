//
//  ProgYogSeriesRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class ProgYogSeriesRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: ProgYogSeriesVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = ProgYogSeriesVm()
    }
    
    func rootView() -> some View {
        ProgYogSeriesUi(rtr: self, vm: self.vm)
    }
    
    func cell(color: Color, text: String, percent: Int) -> some View {
        SeriesCellRtr(srvcs: srvcs, color: color, text: text, percent: percent).rootView()
    }
}
