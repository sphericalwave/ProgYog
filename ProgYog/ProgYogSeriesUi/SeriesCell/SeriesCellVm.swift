//
//  SeriesCellVm.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

import SwiftUI

class SeriesCellVm: ObservableObject
{
    @Published var color: Color
    @Published var text: String
    @Published var percent: Int
    
    init(color: Color, text: String, percent: Int) {
        self.color = color
        self.text = text
        self.percent = percent
    }
}
