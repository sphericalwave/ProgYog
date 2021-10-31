//
//  TrainUI.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI
import AVKit

struct TrainUi: View
{
    @State var rtr: TrainRtr
    @State var vm: TrainVm
    
    var body: some View {
        VStack {
            Text("\(vm.skillFamily) \(vm.skillLevel)")
                .font(.headline)
            Text("\(vm.skill)")
                .font(.subheadline)
            
            ZStack() {
                Rectangle()
                    //.inset(by: 10)
                    .fill(Color.blue)
                    .frame(height: 198)
                Text("Graph of Current Skill Score")
            }
            
            ProgressView(value: vm.skillTime, total: 60)
            
            TextEditor(text: $vm.inputText)
                .disabled(true)
            
            Text("Session: 18:55")
            ProgressView(value: vm.skillTime, total: 60)
            
            Button("Test Show Alert") {
                vm.showingAlert = true
                    }
            .alert(isPresented:$vm.showingAlert) {
                        Alert(
                            title: Text("Range of Motion") ,
                            message: Text("\(vm.skillFamily) \(vm.skillLevel) \(vm.skill)"),
                            primaryButton: .default(Text("Free to Move")) { print("Free to Move") },
                            secondaryButton: .destructive(Text("Movement Constrained")) { print("Movement Constrained") }
                        )
                    }
        }
        .padding()
        .navigationBarTitleDisplayMode(.large)
    }
}
