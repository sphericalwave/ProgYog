//
//  ProgressiveYogApp.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

@main
struct ProgYogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SeriesList()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        //let data = ProgYogDatabase() //TODO: Must call first launch
        //data.seedDB()
        return true
    }
}
