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
                    .inset(by: 10)
                    .fill(Color.blue)
                    .frame(height: 300)
                Text("Series Graph")
            }
            
            List{
                NavigationLink(destination: Text("FIXME")) {
                    Text("Mon, Feb 17, 2021")
                }
                Text("Mon, Feb 17, 2021")
                Text("Mon, Feb 17, 2021")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Text("Yog A"))
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
