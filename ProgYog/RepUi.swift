//
//  RepUi.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

struct RepUi: View {
    var body: some View {
        VStack{
            ZStack() {
                Rectangle()
                    .inset(by: 9)
                    .fill(Color.purple)
                    .frame(height: 300)
                Text("Series Graph Families")
            }
            List{
                Text("Reps")
                Text("Duration")
                Text("Discomfort")
                Text("Form")
                Text("Exertion")
                Text("HR")
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct RepUi_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RepUi()
        }
    }
}
