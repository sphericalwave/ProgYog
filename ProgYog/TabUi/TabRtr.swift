//
//  TabRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class TabRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: TabVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = TabVm()
    }
    
    func rootView() -> some View {
        TabUi(rtr: self, vm: self.vm)
    }
    
    func progYogDash() -> some View {
        SeriesList()
    }
    
    func absProgYogSkills() -> some View {
        AbsSkillList()
    }
    
    func progYogSkillFamillies() -> some View {
        SkillFamList()
    }
}
