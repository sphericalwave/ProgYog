//
//  PillText.swift
//  ContractorPortal
//
//  Created by Aaron Anthony on 2021-06-10.
//

import SwiftUI

struct PillText: View {
    
    let text: String
    let clr: Color
    
    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .padding(.horizontal, 9)
            .padding(.vertical,4)
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .foregroundColor(clr)
            .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(clr, style: StrokeStyle(lineWidth: 2) ) )
    }
}

struct PillBorderModifier: ViewModifier
{
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 9)
            .padding(.vertical,4)
            .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(color, style: StrokeStyle(lineWidth: 2) ) )
    }
}

extension View {
    func pillBorder(color: Color) -> some View {
        self.modifier(PillBorderModifier(color: color))
    }
}

enum AvenirType {
    case regular, bold, demiBold
}

struct AvenirModifier: ViewModifier
{
    var size: CGFloat
    var color: Color
    var type: AvenirType
    
    func body(content: Content) -> some View {
        content
            .font(Font.custom(font, size: size))
            .foregroundColor(color)
    }
    
    var font: String {
        switch type {
        case .regular:
            return "AvenirNext-Regular"
        case .demiBold:
            return "AvenirNext-DemiBold"
        case .bold:
            return "AvenirNext-Bold"
        }
    }
}

extension View {
    func avenirFont(size: CGFloat, color: Color, type: AvenirType) -> some View {
        self.modifier(AvenirModifier(size: size, color: color, type: type))
    }
}

//struct AvnrBold12Text: View
//{
//    var text: String
//    var clr: Color
//    var body: some View {
//        Text(text)
//            .font(Font.custom("AvenirNext-Bold", size: 12))
//            .foregroundColor(clr)
//    }
//}
