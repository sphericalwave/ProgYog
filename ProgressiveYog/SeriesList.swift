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
                        .inset(by: 10)
                        .fill(Color.blue)
                        .frame(height: 300)
                    Text("General Graph")
                }
                List {
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
            Text("Prog Yoga A")
        }
    }
}
