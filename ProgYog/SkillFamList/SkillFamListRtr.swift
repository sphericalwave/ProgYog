//
//  SkillFamListRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class SkillFamListRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: SkillFamListVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = SkillFamListVm(cdSrvc: srvcs.coreDataSrvc)
    }
    
    func rootView() -> some View {
        SkillFamList(rtr: self, vm: self.vm)
    }
}
