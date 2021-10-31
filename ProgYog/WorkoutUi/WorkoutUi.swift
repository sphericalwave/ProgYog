//
//  WorkoutUi.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-30.
//

import SwiftUI

struct WorkoutUi: View {
    
    @State var rtr: WorkoutRtr
    @StateObject var vm: WorkoutVm
    
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
                NavigationLink(destination: rtr.movementUi()) {
                    Text("Shinbox Switch")
                }
                Text("Table Switch")
                Text("Swipe Switch")
            }
        }
        

        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(Text("Yog A"))
        .navigationBarItems(trailing: TrainBtn(showModal: $vm.showModal) )
        .sheet(isPresented: $vm.showModal) { rtr.trainUi() }
        
    }
}

//struct WorkoutUi_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutUi()
//    }
//}
