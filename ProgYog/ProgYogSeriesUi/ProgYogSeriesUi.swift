//
//  SeriesList.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

struct ProgYogSeriesUi: View
{
    @State var rtr: ProgYogSeriesRtr
    @StateObject var vm: ProgYogSeriesVm
    
    var body: some View {
        NavigationView {
            VStack {
                ZStack() {
                    Rectangle()
                        .fill(Color.blue)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .padding()
                        .overlay(Text("Graph of Progress in Each Series"))
                }
                List {
                    rtr.cell(color: .red, text: "Yog A", percent: 45)
                    rtr.cell(color: .blue, text: "Yog B", percent: 55)
                    rtr.cell(color: .green, text: "Yog C", percent: 35)
                    rtr.cell(color: .purple, text: "Yog D", percent: 40)
                    rtr.cell(color: .orange, text: "Yog E", percent: 33)
                }.listStyle(PlainListStyle())
            }
            .navigationTitle("Prog Yog") //<- Causes "Unable to simultaneously satisfy constraints."
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


