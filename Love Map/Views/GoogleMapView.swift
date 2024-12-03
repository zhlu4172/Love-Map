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
    var userId: String // 当前登录用户的 UID

    func makeUIViewController(context: Context) -> GoogleMapViewController {
        let viewController = GoogleMapViewController()
        viewController.userId = userId // 将用户 ID 传递给 ViewController
        return viewController
    }

    func updateUIViewController(_ uiViewController: GoogleMapViewController, context: Context) {
        // 如果需要动态更新视图控制器，可以在这里实现
    }
}


