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
                        .inset(by: 9)
                        .fill(Color.blue)
                        .frame(height: 297)
                    Text("Graph of Progress in Each Series")
                }
                List {  //FIXME: ListStyle looks weird here
                    SeriesCell()
                    Text("Prog Yoga B")
                    Text("Prog Yoga C")
                    Text("Prog Yoga D")
                    Text("Prog Yoga E")
                }
                Spacer()
            }
            .navigationTitle("Prog Yog")
        }
    }
}

struct SeriesCell: View {
    var body: some View {
        NavigationLink(destination: SeriesUI()){
            HStack(alignment: .center) {
//TODO: Get Color for Graph Working
//                Rectangle()
//                    .size(width: 18, height: 18)
//                    .fill(Color.blue)
                Text("Prog Yoga A")
                    .multilineTextAlignment(.leading)
                Spacer()
                Text("86%")
            }
        }
    }
}
