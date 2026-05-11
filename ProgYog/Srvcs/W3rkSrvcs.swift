//
//  W3rkSrvcs.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import Foundation

import Foundation

class W3rkSrvcs
{
    //var crtFdSrvc: CrtFdSrvc
    let coreDataSrvc: CoreDataSrvc
    //let newFdSrvc: NewFdSrvc
    
    init() {
        _ = SwTheme()       //fixme: put in services
        let cd = CoreDataSrvc()
        cd.launch()                 //not sure about this
        self.coreDataSrvc = cd
        //self.crtFdSrvc = CrtFdSrvc(cdSrvc: cd)
        //self.newFdSrvc = NewFdSrvc()
    }
}
