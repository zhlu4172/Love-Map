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
        
        // temporary solution: read Google Maps API Key from config.json
        if let path = Bundle.main.path(forResource: "config", ofType: "json"),
           let data = NSData(contentsOfFile: path) as Data?,
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
           let googleMapsAPIKey = jsonObject["GOOGLE_MAPS_API_KEY"] {
            GMSServices.provideAPIKey(googleMapsAPIKey)
            print("✅ Google Maps API Key configured")
        } else {
            print("❌ Google Maps API Key not found in config")
        }
        
        return true
    }

}
