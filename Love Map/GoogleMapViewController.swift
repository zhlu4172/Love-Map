import Foundation
import UIKit
import GoogleMaps
import FirebaseFirestore

class GoogleMapViewController: UIViewController {
    var userId: String = ""  // 当前用户的 UID
    private var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("User ID is: \(userId)")

        // 初始化地图中心位置
        let camera = GMSCameraPosition.camera(withLatitude: 20.0, longitude: 0.0, zoom: 2.0)
        mapView = GMSMapView.map(withFrame: self.view.bounds, camera: camera)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(mapView)

        // 从 Firestore 加载用户访问记录
        fetchVisitedCities(for: userId) { cities in
            for city in cities {
                print("City: \(city.cityName), Country: \(city.countryCode), Lat: \(city.latitude), Lng: \(city.longitude)")
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)
                marker.title = city.cityName
                marker.snippet = city.countryCode
                marker.map = self.mapView // 将标记添加到地图上
            }
        }
    }

    

    private func fetchVisitedCities(for userId: String, completion: @escaping ([(latitude: Double, longitude: Double, cityName: String, countryCode: String)]) -> Void) {
        let db = Firestore.firestore()

        // 先从 maps 集合中获取用户可以访问的 mapId 列表
        db.collection("maps")
            .whereField("ownerId", isEqualTo: userId) // 用户是地图所有者
            .getDocuments { (ownedSnapshot, error) in
                if let error = error {
                    print("Error fetching owned maps: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let ownedMapIds = ownedSnapshot?.documents.compactMap { $0.documentID } ?? []

                // 查询用户共享的地图
                db.collection("maps")
                    .whereField("sharedWith", arrayContains: userId) // 用户是共享用户
                    .getDocuments { (sharedSnapshot, error) in
                        if let error = error {
                            print("Error fetching shared maps: \(error.localizedDescription)")
                            completion([])
                            return
                        }

                        let sharedMapIds = sharedSnapshot?.documents.compactMap { $0.documentID } ?? []
                        let allMapIds = ownedMapIds + sharedMapIds // 合并所有地图 ID

                        print("All accessible mapIds for userId \(userId): \(allMapIds)")

                        // 如果没有任何地图，直接返回空结果
                        guard !allMapIds.isEmpty else {
                            print("No maps found for userId: \(userId)")
                            completion([])
                            return
                        }

                        // 从 visits 集合中查询所有与这些地图相关的城市
                        db.collection("visits")
                            .whereField("mapId", in: allMapIds)
                            .getDocuments { (visitsSnapshot, error) in
                                if let error = error {
                                    print("Error fetching visits: \(error.localizedDescription)")
                                    completion([])
                                    return
                                }

                                guard let documents = visitsSnapshot?.documents else {
                                    print("No visits found for userId: \(userId)")
                                    completion([])
                                    return
                                }

                                print("Fetched \(documents.count) visits for userId: \(userId)")

                                let cities = documents.compactMap { doc -> (latitude: Double, longitude: Double, cityName: String, countryCode: String)? in
                                    let data = doc.data()
                                    guard let cityName = data["cityName"] as? String,
                                          let countryCode = data["countryCode"] as? String,
                                          let latitude = data["latitude"] as? Double,
                                          let longitude = data["longitude"] as? Double else {
                                        return nil
                                    }
                                    return (latitude: latitude, longitude: longitude, cityName: cityName, countryCode: countryCode)
                                }

                                completion(cities)
                            }
                    }
            }
    }


}
