//
//  Styles.swift
//  FitWrenchData
//
//  Created by Aaron Anthony on 2020-08-10.
//  Copyright © 2020 SphericalWaveSoftware. All rights reserved.
//

import UIKit

//
//enum SWStyle {
//    case dark
//    case light
//}

struct SwTheme
{
    let background = UIColor(red: 25 / 255, green: 58 / 255, blue: 231 / 255, alpha: 1.0)
    let titleColor = UIColor.white
    let tintColor = UIColor.white
    
    init() {
        let standardBarAppearance = UINavigationBarAppearance()
        standardBarAppearance.configureWithOpaqueBackground()
        standardBarAppearance.backgroundColor = background
        //standardBarAppearance.
        
        let d = UIFontDescriptor(name: "AvenirNext-Bold", size: 16)
        let font = UIFont.init(descriptor: d, size: 18)
        
        standardBarAppearance.titleTextAttributes = [.foregroundColor: titleColor, .font: font ]
        standardBarAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor, .font: font]
        standardBarAppearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: titleColor, .font: font]
        
        UINavigationBar.appearance().standardAppearance = standardBarAppearance
        UINavigationBar.appearance().compactAppearance = standardBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = standardBarAppearance
        
        UINavigationBar.appearance().tintColor = tintColor //tint the nav back arrow
        
        let attributes = [NSAttributedString.Key.font: font]
        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        
        UISegmentedControl.appearance().selectedSegmentTintColor = background //UIColor(.purple1)
        UISegmentedControl.appearance().backgroundColor = UIColor(.white)
        
        
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: background], for: .normal)
        
        //UISwitch.appearance().tintColor = .purple1
        UISwitch.appearance().onTintColor = background
        //let barApperance = UINavigationBar.appearance()
        //barApperance.tintColor = .white
        //barApperance.backgroundColor = .purple1
        //barApperance.isTranslucent = false
    }
}
