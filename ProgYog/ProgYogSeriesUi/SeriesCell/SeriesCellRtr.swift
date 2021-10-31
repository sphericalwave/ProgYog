//
//  SeriesCellRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class SeriesCellRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: SeriesCellVm
    
    init(srvcs: W3rkSrvcs, color: Color, text: String, percent: Int) {
        self.srvcs = srvcs
        self.vm = SeriesCellVm(color: color, text: text, percent: percent)
    }
    
    func rootView() -> some View {
        SeriesCell(rtr: self, vm: self.vm)
    }
    
    func seriesUi() -> some View {
        SeriesRtr(srvcs: srvcs).rootView()
    }
}
