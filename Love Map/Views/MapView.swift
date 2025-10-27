//
//  MapView.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import SwiftUI
import GoogleMaps
import FirebaseFirestore

struct MapView: View {
    @State private var userId: String = ""
    @State private var isLoading = true
    @State private var visitedCountriesCount: Int = 0
    @State private var totalCountriesCount: Int = 195
    @State private var showPercentage: Bool = false 
    @State private var shouldReloadMap = false
    @State private var showAddCitySheet = false   
    @State private var currentMapId: String = "" // current map ID

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading map...")
            } else {
                VStack {
                    // Top title and buttons
                    HStack {
                        Spacer()
                        VStack {
                            Text("Your Love Map")
                                .font(.custom("HelveticaNeue-Bold", size: 30))
                                .foregroundColor(Color("PrimaryColor"))
                            Text("with your visited cities")
                                .font(.title2)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                // User Icon
                                print("User icon tapped!")
                            }) {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                            
                            Button(action: {
                                // Plus Icon
                                showAddCitySheet.toggle()
                            }) {
                                Image(systemName: "plus.square")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                            .sheet(isPresented: $showAddCitySheet, onDismiss: {
                                fetchVisitedCountriesCount() 
                                shouldReloadMap.toggle()
                            }) {
                                AddCityView(userId: userId, mapId: currentMapId)
                            }
                        }
                        .padding()
                    }
                    .padding(.top, 20) 
                    
                    // Country count display
                    VStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPercentage.toggle() // change mode
                            }
                        }) {
                            HStack {
                                Image(systemName: "airplane")
                                    .font(.title2)
                                    .foregroundColor(Color("PrimaryColor"))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(showPercentage ? 
                                        "Travelled \(String(format: "%.1f", Double(visitedCountriesCount) / Double(totalCountriesCount) * 100))% of the world" :
                                        "Travelled \(visitedCountriesCount) out of \(totalCountriesCount) countries")
                                        .font(.headline)
                                        .foregroundColor(Color("PrimaryColor"))
                                        .multilineTextAlignment(.leading)
                                    
                                    // Travelling progress bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 4)
                                                .cornerRadius(2)
                                            
                                            Rectangle()
                                                .fill(Color("PrimaryColor"))
                                                .frame(width: geometry.size.width * (Double(visitedCountriesCount) / Double(totalCountriesCount)), height: 4)
                                                .cornerRadius(2)
                                                .animation(.easeInOut(duration: 0.5), value: visitedCountriesCount)
                                        }
                                    }
                                    .frame(height: 4)
                                }
                                
                                // Change icon
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title3)
                                    .foregroundColor(Color("PrimaryColor"))
                                    .rotationEffect(.degrees(showPercentage ? 180 : 0))
                                    .animation(.easeInOut(duration: 0.3), value: showPercentage)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // remove button default style
                    }
                    .padding(.bottom, 10)

                    // GoogleMapView show map，transfer user ID
                    GoogleMapView(userId: userId, reloadTrigger: shouldReloadMap)
                        .frame(height: 400)

                    Spacer()
                }
            }
        }
        .background(Color.white)
        .onAppear {
            fetchCurrentUserId()
        }
    }

    private func fetchCurrentUserId() {
        do {
            let user = try AuthenticationManager.shared.getAuthenticatedUser()
            userId = user.uid 
            isLoading = false
            print("User ID fetched: \(userId)")
            fetchUserMapId(for: userId)
        } catch {
            print("Failed to fetch authenticated user: \(error)")
        }
    }

    private func fetchUserMapId(for userId: String) {
        let db = Firestore.firestore()
        db.collection("maps")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching maps: \(error.localizedDescription)")
                    isLoading = false
                    return
                }
                
                if let mapDoc = snapshot?.documents.first {
                    currentMapId = mapDoc.documentID
                    print("✅ currentMapId: \(currentMapId)")
                } else {
                    print("⚠️ No map found for userId \(userId)")
                }
                
                isLoading = false
                fetchVisitedCountriesCount()
            }
    }

    
    // Fetch visited countries count
    private func fetchVisitedCountriesCount() {
        guard !userId.isEmpty else { return }
        
        let db = Firestore.firestore()
        
        // Fetch owned maps
        db.collection("maps")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments { (ownedSnapshot, error) in
                if let error = error {
                    print("Error fetching owned maps: \(error.localizedDescription)")
                    return
                }
                
                let ownedMapIds = ownedSnapshot?.documents.compactMap { $0.documentID } ?? []
                
                // fetch shared maps
                db.collection("maps")
                    .whereField("sharedWith", arrayContains: userId)
                    .getDocuments { (sharedSnapshot, error) in
                        if let error = error {
                            print("Error fetching shared maps: \(error.localizedDescription)")
                            return
                        }
                        
                        let sharedMapIds = sharedSnapshot?.documents.compactMap { $0.documentID } ?? []
                        let allMapIds = ownedMapIds + sharedMapIds
                        
                        guard !allMapIds.isEmpty else {
                            print("No maps found for userId: \(userId)")
                            return
                        }
                        
                        // check all visits
                        db.collection("visits")
                            .whereField("mapId", in: allMapIds)
                            .getDocuments { (visitsSnapshot, error) in
                                if let error = error {
                                    print("Error fetching visits: \(error.localizedDescription)")
                                    return
                                }
                                
                                guard let documents = visitsSnapshot?.documents else {
                                    print("No visits found for userId: \(userId)")
                                    return
                                }
                                
                                // get unique countries code
                                let uniqueCountries = Set(documents.compactMap { doc in
                                    doc.data()["countryCode"] as? String
                                })
                                
                                DispatchQueue.main.async {
                                    self.visitedCountriesCount = uniqueCountries.count
                                    print("Visited countries count: \(self.visitedCountriesCount)")
                                }
                            }
                    }
            }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
