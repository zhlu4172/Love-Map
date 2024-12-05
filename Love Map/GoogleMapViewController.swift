import Foundation
import UIKit
import WebKit
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

        // Fetch visited cities and pass only city and country names to the web page
        fetchVisitedCities(for: userId) { cities in
            DispatchQueue.main.async {
                self.sendCityDataToWebView(cities: cities)
            }
        }
    }

    private func fetchVisitedCities(for userId: String, completion: @escaping ([[String: String]]) -> Void) {
        print("Fetching visits for userId: \(userId)")
        let db = Firestore.firestore()

        db.collection("maps")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { (ownedSnapshot, error) in
                if let error = error {
                    print("Error fetching owned maps: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let ownedMapIds = ownedSnapshot?.documents.compactMap { $0.documentID } ?? []
                print("Owned map IDs: \(ownedMapIds)")

                db.collection("maps")
                    .whereField("sharedWith", arrayContains: userId)
                    .getDocuments { (sharedSnapshot, error) in
                        if let error = error {
                            print("Error fetching shared maps: \(error.localizedDescription)")
                            completion([])
                            return
                        }

                        let sharedMapIds = sharedSnapshot?.documents.compactMap { $0.documentID } ?? []
                        print("Shared map IDs: \(sharedMapIds)")

                        let allMapIds = ownedMapIds + sharedMapIds
                        print("All accessible map IDs: \(allMapIds)")

                        guard !allMapIds.isEmpty else {
                            print("No maps found for userId: \(userId)")
                            completion([])
                            return
                        }

                        // Query visits for all maps
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

                                var cities: [[String: String]] = []
                                for document in documents {
                                    print("Visit document data: \(document.data())") // Print each visit document
                                    if let cityName = document.data()["cityName"] as? String,
                                       let countryCode = document.data()["countryCode"] as? String {
                                        let city: [String: String] = [
                                            "cityName": cityName,
                                            "countryName": countryCode
                                        ]
                                        cities.append(city)
                                    }
                                }

                                print("Cities to send: \(cities)")
                                completion(cities)
                            }
                    }
            }
    }

    private func sendCityDataToWebView(cities: [[String: String]]) {
        // Convert cities array into JSON string format
        let citiesJSON: [String: Any] = ["cities": cities]
        if let jsonData = try? JSONSerialization.data(withJSONObject: citiesJSON, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Sending city data to WebView: \(jsonString)")
            
            let escapedJSON = jsonString
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "'", with: "\\'")
            let script = "window.postMessage('\(escapedJSON)', '*')"
            
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error sending data to WebView: \(error.localizedDescription)")
                } else {
                    print("Data successfully sent to WebView.")
                }
            }
        } else {
            print("Failed to serialize city data to JSON.")
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Message from JavaScript: \(message.body)")
    }
}
