//
//  ConfigManager.swift
//  Love Map
//
//  Created by Emma Lu on 25/10/2024.
//

import Foundation

/// Configuration manager for unified management of all API keys and configurations in the app
final class ConfigManager {
    static let shared = ConfigManager()
    
    private var config: [String: String] = [:]
    
    private init() {
        loadConfig()
    }
    
    /// Load configuration from config.json file
    private func loadConfig() {
        guard let path = Bundle.main.path(forResource: "config", ofType: "json"),
              let data = NSData(contentsOfFile: path) as Data?,
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            print("Failed to load config.json")
            return
        }
        
        config = jsonObject
        print("Config loaded successfully: \(config.keys.joined(separator: ", "))")
    }
    
    /// Google Maps API Key
    var googleMapsAPIKey: String {
        return config["GOOGLE_MAPS_API_KEY"] ?? ""
    }
    
    /// Cesium Ion Access Token
    var cesiumIonAccessToken: String {
        return config["CESIUM_ION_ACCESS_TOKEN"] ?? ""
    }
    
    /// Geoapify API Key
    var geoapifyAPIKey: String {
        return config["GEOAPIFY_API_KEY"] ?? ""
    }
    
    /// Get configuration value for specified key
    func getValue(for key: String) -> String? {
        return config[key]
    }
    
    /// Check if all required API keys are configured
    func validateConfiguration() -> Bool {
        let requiredKeys = ["GOOGLE_MAPS_API_KEY", "CESIUM_ION_ACCESS_TOKEN", "GEOAPIFY_API_KEY"]
        let missingKeys = requiredKeys.filter { config[$0]?.isEmpty ?? true }
        
        if !missingKeys.isEmpty {
            print("Missing API keys: \(missingKeys.joined(separator: ", "))")
            return false
        }
        
        print("All required API keys are configured")
        return true
    }
    
    /// Reload configuration (for debugging or configuration updates)
    func reloadConfig() {
        loadConfig()
    }
}

