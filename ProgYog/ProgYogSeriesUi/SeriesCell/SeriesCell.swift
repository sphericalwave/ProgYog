//
//  SeriesCell.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

struct SeriesCell: View {
    
    @State var rtr: SeriesCellRtr
    @State var vm: SeriesCellVm
    
    var body: some View {
        NavigationLink(destination: rtr.seriesUi()){
            HStack(alignment: .center) {
                Label {
                    Text(vm.text)
                } icon: {
                    Image(systemName: "square.fill")
                        .foregroundColor(vm.color)
                }
                Spacer()
                Text("\(vm.percent)%")
            }
        }
    }
}
