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
    func makeUIViewController(context: Context) -> GoogleMapViewController {
        return GoogleMapViewController() // 使用我们刚刚创建的 UIViewController
    }

    func updateUIViewController(_ uiViewController: GoogleMapViewController, context: Context) {
        // 可以根据需要更新视图控制器的内容
    }
}

