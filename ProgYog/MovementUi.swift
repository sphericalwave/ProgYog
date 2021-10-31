//
//  MovementUi.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-30.
//

import SwiftUI

struct MovementUi: View
{
    var body: some View {
        VStack{
            ZStack() {
                Rectangle()
                    .inset(by: 9)
                    .fill(Color.yellow)
                    .frame(height: 300)
                Text("Movement Data RPE RT RD")
            }
            
            List{
                NavigationLink(destination: WorkoutUi()) {
                    Text("5 x BodyWeight")
                }
                Text("RPE = 10")
                Text("RT = 10")
                Text("RD = 5")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("Shinbox"))
        //.navigationBarItems(trailing: TrainBtn(showModal: self.$showModal) )
        //.sheet(isPresented: $showModal) { TrainUI() }
        
    }
}

struct MovementUi_Previews: PreviewProvider {
    static var previews: some View {
        MovementUi()
    }
}
