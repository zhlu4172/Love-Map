import SwiftUI
import FirebaseFirestore

struct AddCityView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [CityResult] = []
    @State private var isLoading = false
    
    var userId: String
    var mapId: String

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter a city name...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        fetchCities()
                    }

                if isLoading {
                    ProgressView("Searching...")
                }

                List(searchResults, id: \.id) { city in
                    Button(action: {
                        addCityToFirebase(city)
                    }) {
                        VStack(alignment: .leading) {
                            Text(city.name)
                                .font(.headline)
                            Text(city.country)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Add City")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    func fetchCities() {
        guard !searchText.isEmpty else { return }
        isLoading = true

        let apiKey = ConfigManager.shared.geoapifyAPIKey  // ✅ 从 config.json 读取
        let query = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.geoapify.com/v1/geocode/search?text=\(query)&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async { isLoading = false }
            guard let data = data, error == nil else { return }

            if let decoded = try? JSONDecoder().decode(GeoapifyResponse.self, from: data) {
                DispatchQueue.main.async {
                    searchResults = decoded.features.map {
                        CityResult(
                            id: UUID(),
                            name: $0.properties.city ?? $0.properties.name ?? "Unknown",
                            country: $0.properties.country ?? "Unknown",
                            lat: $0.properties.lat,
                            lon: $0.properties.lon
                        )
                    }
                }
            }
        }.resume()
    }


    func addCityToFirebase(_ city: CityResult) {
        let db = Firestore.firestore()
        let visit: [String: Any] = [
            "mapId": mapId,
            "cityName": city.name,
            "countryCode": city.country,
            "latitude": city.lat,
            "longitude": city.lon,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("visits").addDocument(data: visit) { error in
            if let error = error {
                print("❌ Error adding city: \(error.localizedDescription)")
            } else {
                print("✅ \(city.name) added to mapId \(mapId)")
                dismiss()
            }
        }
    }
}

struct CityResult: Identifiable {
    var id: UUID
    var name: String
    var country: String
    var lat: Double
    var lon: Double
}

struct GeoapifyResponse: Codable {
    let features: [Feature]
    struct Feature: Codable {
        let properties: Properties
    }
    struct Properties: Codable {
        let name: String?
        let city: String?
        let country: String?
        let lat: Double
        let lon: Double
    }
}
