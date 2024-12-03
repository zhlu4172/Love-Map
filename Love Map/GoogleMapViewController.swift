//
//  GoogleMapViewController.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import Foundation
import UIKit
import GoogleMaps

class GoogleMapViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 创建一个 GMSCameraPosition 来展示地图中心
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(mapView)

        // 创建一个标记
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = mapView
    }
}
