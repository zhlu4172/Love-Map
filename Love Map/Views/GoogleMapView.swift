//
//  GoogleMapView.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import Foundation
import SwiftUI
import GoogleMaps


struct GoogleMapView: UIViewControllerRepresentable {
    var userId: String 
    var reloadTrigger: Bool

    func makeUIViewController(context: Context) -> GoogleMapViewController {
        let viewController = GoogleMapViewController()
        viewController.userId = userId // Pass user ID to ViewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: GoogleMapViewController, context: Context) {
        uiViewController.reloadMapData()
    }
}


