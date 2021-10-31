//
//  WorkoutUi.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-30.
//

import SwiftUI

struct WorkoutUi: View {
    
    @State var showModal = false
    
    var body: some View {
        
        VStack{
            ZStack() {
                Rectangle()
                    .inset(by: 9)
                    .fill(Color.red)
                    .frame(height: 300)
                Text("Workout Data")
            }
            
            List{
                NavigationLink(destination: MovementUi()) {
                    Text("Shinbox Switch")
                }
                Text("Table Switch")
                Text("Swipe Switch")
            }
        }
        

        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("Yog A"))
        .navigationBarItems(trailing: TrainBtn(showModal: self.$showModal) )
        .sheet(isPresented: $showModal) { TrainUI() }
        
    }
}

struct WorkoutUi_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutUi()
    }
}
