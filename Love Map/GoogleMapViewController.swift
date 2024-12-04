import Foundation
import UIKit
import WebKit
import GoogleMaps
import FirebaseFirestore


class GoogleMapViewController: UIViewController, WKScriptMessageHandler {
    var userId: String = "" // 当前用户的 UID
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the WKWebView
        let webViewConfig = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name: "iosListener") // JS-to-Swift messaging
        webViewConfig.userContentController = contentController
        webView = WKWebView(frame: self.view.bounds, configuration: webViewConfig)
        view.addSubview(webView)

        // Load the Cesium HTML page
        if let url = Bundle.main.url(forResource: "globalMap", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        }

        // Fetch visited cities and pass GeoJSON to the web page
        fetchVisitedCities(for: userId) { geoJSON in
            DispatchQueue.main.async {
                self.sendGeoJSONToWebView(geoJSON: geoJSON)
            }
        }
    }

    private func fetchVisitedCities(for userId: String, completion: @escaping (String) -> Void) {
        print("Fetching visits for userId: \(userId)")
        let db = Firestore.firestore()

        db.collection("maps")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { (ownedSnapshot, error) in
                if let error = error {
                    print("Error fetching owned maps: \(error.localizedDescription)")
                    completion("")
                    return
                }

                let ownedMapIds = ownedSnapshot?.documents.compactMap { $0.documentID } ?? []
                print("Owned map IDs: \(ownedMapIds)")

                db.collection("maps")
                    .whereField("sharedWith", arrayContains: userId)
                    .getDocuments { (sharedSnapshot, error) in
                        if let error = error {
                            print("Error fetching shared maps: \(error.localizedDescription)")
                            completion("")
                            return
                        }

                        let sharedMapIds = sharedSnapshot?.documents.compactMap { $0.documentID } ?? []
                        print("Shared map IDs: \(sharedMapIds)")

                        let allMapIds = ownedMapIds + sharedMapIds
                        print("All accessible map IDs: \(allMapIds)")

                        guard !allMapIds.isEmpty else {
                            print("No maps found for userId: \(userId)")
                            completion("")
                            return
                        }

                        // Query visits for all maps
                        db.collection("visits")
                            .whereField("mapId", in: allMapIds)
                            .getDocuments { (visitsSnapshot, error) in
                                if let error = error {
                                    print("Error fetching visits: \(error.localizedDescription)")
                                    completion("")
                                    return
                                }

                                guard let documents = visitsSnapshot?.documents else {
                                    print("No visits found for userId: \(userId)")
                                    completion("")
                                    return
                                }

                                print("Fetched \(documents.count) visits for userId: \(userId)")

                                var features: [[String: Any]] = []
                                for document in documents {
                                    print("Visit document data: \(document.data())") // Print each visit document
                                    if let cityName = document.data()["cityName"] as? String,
                                       let countryCode = document.data()["countryCode"] as? String,
                                       let latitude = document.data()["latitude"] as? Double,
                                       let longitude = document.data()["longitude"] as? Double {
                                        let feature: [String: Any] = [
                                            "type": "Feature",
                                            "properties": ["name": cityName, "country": countryCode],
                                            "geometry": [
                                                "type": "Point",
                                                "coordinates": [longitude, latitude]
                                            ]
                                        ]
                                        features.append(feature)
                                    }
                                }

                                let geoJSON: [String: Any] = [
                                    "type": "FeatureCollection",
                                    "features": features
                                ]

                                if let jsonData = try? JSONSerialization.data(withJSONObject: geoJSON, options: []),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    print("GeoJSON created successfully: \(jsonString)")
                                    completion(jsonString)
                                } else {
                                    print("Failed to create GeoJSON")
                                    completion("")
                                }
                            }
                    }
            }
    }

    private func sendGeoJSONToWebView(geoJSON: String) {
        let escapedGeoJSON = geoJSON
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "'", with: "\\'")
        let script = "window.postMessage('\(escapedGeoJSON)', '*')"
        print("Sending GeoJSON to WebView: \(escapedGeoJSON)")
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error sending GeoJSON to WebView: \(error.localizedDescription)")
            } else {
                print("GeoJSON successfully sent to WebView.")
            }
        }
    }


    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Message from JavaScript: \(message.body)")
    }
}
