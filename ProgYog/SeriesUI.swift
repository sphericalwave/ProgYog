//
//  SeriesUI.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

struct SeriesUI: View {
    
    @State var showModal = false
    
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
                NavigationLink(destination: WorkoutUi()) {
                    HStack(alignment: .center) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Yoga A")
                                Text("feb 17, 2021")

                            }
                        } icon: {
                            Image(systemName: "square.fill")
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                }
                NavigationLink(destination: WorkoutUi()) {
                    HStack(alignment: .center) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Yoga A")
                                Text("oct 31, 2021")
                            }
                        } icon: {
                            Image(systemName: "square.fill")
                                .foregroundColor(.red)
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("Feb 17, 2021"))
        .navigationBarItems(trailing: TrainBtn(showModal: self.$showModal) )
        .sheet(isPresented: $showModal) { TrainUI() }
        
    }
}

struct TrainBtn: View
{
    @Binding var showModal: Bool
    
    var body: some View {
        Button(action: { self.showModal.toggle() }) {
            Image(systemName: "play.circle")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}
