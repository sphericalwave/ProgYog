//
//  SeriesList.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

struct SeriesList: View {
    
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
                    SeriesCell(color: .red, text: "Yog A", percent: 45)
                    SeriesCell(color: .blue, text: "Yog B", percent: 55)
                    SeriesCell(color: .green, text: "Yog C", percent: 35)
                    SeriesCell(color: .purple, text: "Yog D", percent: 40)
                    SeriesCell(color: .orange, text: "Yog E", percent: 33)
                }.listStyle(PlainListStyle())
            }
            .navigationTitle("Prog Yog") //<- Causes "Unable to simultaneously satisfy constraints."
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SeriesCell: View {
    
    let color: Color
    let text: String
    let percent: Int
    
    var body: some View {
        NavigationLink(destination: SeriesUI()){
            HStack(alignment: .center) {
                Label {
                    Text(text)
                } icon: {
                    Image(systemName: "square.fill")
                        .foregroundColor(color)
                }
                Spacer()
                Text("\(percent)%")
            }
        }
    }
}
