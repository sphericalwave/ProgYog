//
//  Rtr.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-10-31.
//

//import Foundation
import SwiftUI

public protocol Rtr: ObservableObject
{
    associatedtype ViewOutput: View
    
    func rootView() -> ViewOutput
}
