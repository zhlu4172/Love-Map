//
//  Love_MapApp.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import SwiftUI
import UIKit
import FirebaseAnalytics
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleMaps

@main
struct Love_MapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
//            ContentView()
            LoginView()
        }
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
//        GMSServices.provideAPIKey("AIzaSyDruLtVP-mca27j2QAfk4PM4DkQ0kvBy0w") // 替换为你的 Google Maps API 密钥
        GMSServices.provideAPIKey("None")
        
        return true
    }

}
