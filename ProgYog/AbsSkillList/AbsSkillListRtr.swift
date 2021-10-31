//
//  AbsSkillListRtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class AbsSkillListRtr: Rtr
{
    let srvcs: W3rkSrvcs
    let vm: AbsSkillListVm
    
    init(srvcs: W3rkSrvcs) {
        self.srvcs = srvcs
        self.vm = AbsSkillListVm(cdSrvc: srvcs.coreDataSrvc)
    }
    
    func rootView() -> some View {
        AbsSkillList(rtr: self, vm: self.vm)
    }
}
