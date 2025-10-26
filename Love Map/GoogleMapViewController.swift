import Foundation
import UIKit
import WebKit
import FirebaseFirestore

class GoogleMapViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    var userId: String = "" // current user UID
    private var webView: WKWebView!

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    print("✅ HTML loaded, injecting config.json now...")
    injectConfigJSON()
}

override func viewDidLoad() {
    super.viewDidLoad()

    let webViewConfig = WKWebViewConfiguration()
    let contentController = WKUserContentController()
    contentController.add(self, name: "iosListener")
    webViewConfig.userContentController = contentController
    
    webView = WKWebView(frame: self.view.bounds, configuration: webViewConfig)
    webView.navigationDelegate = self // ✅ 添加代理
    view.addSubview(webView)

    if let url = Bundle.main.url(forResource: "globalMap", withExtension: "html") {
        webView.loadFileURL(url, allowingReadAccessTo: Bundle.main.bundleURL)
    }

    // ✅ 不再需要手动延迟注入
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.fetchVisitedCities(for: self.userId) { cities in
            DispatchQueue.main.async {
                self.sendCityDataToWebView(cities: cities)
            }
        }
    }
}

    private func injectConfigJSON() {
    // 找到 config.json 文件
    if let configPath = Bundle.main.path(forResource: "config", ofType: "json") {
        do {
            let jsonString = try String(contentsOfFile: configPath)
            // 转义特殊字符，避免 JS 报错
            let safeString = jsonString
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")

            // 注入到 JS 全局变量
            let jsCode = """
            window.configDataFromIOS = JSON.parse("\(safeString)");
            console.log('✅ Config injected from iOS');
            """

            webView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("❌ Failed to inject config: \(error.localizedDescription)")
                } else {
                    print("✅ config.json successfully injected into JS")
                }
            }
        } catch {
            print("❌ Failed to read config.json: \(error.localizedDescription)")
        }
    } else {
        print("❌ config.json not found in bundle")
    }
}


    private func fetchVisitedCities(for userId: String, completion: @escaping ([[String: Any]]) -> Void) {
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

                                var cities: [[String: Any]] = []
                                for document in documents {
                                    print("Visit document data: \(document.data())") // Print each visit document
                                    if let cityName = document.data()["cityName"] as? String,
                                       let latitude = document.data()["latitude"] as? Double,
                                       let longitude = document.data()["longitude"] as? Double,
                                       let countryCode = document.data()["countryCode"] as? String {
                                        let city: [String: Any] = [
                                            "cityName": cityName,
                                            "countryName": countryCode,
                                            "latitude": latitude,
                                            "longitude": longitude,
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

    private func sendCityDataToWebView(cities: [[String: Any]]) {
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

// Extension to load config programmatically if needed
extension GoogleMapViewController {
    private func loadConfig() -> [String: String]? {
        guard let path = Bundle.main.path(forResource: "config", ofType: "json"),
              let data = NSData(contentsOfFile: path) as Data?,
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
            print("Failed to load config.json")
            return nil
        }
        
        print("Config loaded: \(jsonObject)")
        return jsonObject
    }
}
