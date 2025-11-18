//
//  ContentView.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    
    
    var body: some View {
        // Vertical Stack
//        VStack {
//            Text("Build your map with your lover")
//                .foregroundColor(Color("PrimaryColor"))
//        }
//        .padding()
        
        TabView {
                // First Tab：Map page  
            MapView()
            .tabItem {
                Label("Map", systemImage: "map")
            }
                
                // Second Tab：Profile page
            NavigationStack {
                ProfileView(viewModel: viewModel)
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.large)
            }

            .tabItem {
                Label("Me", systemImage: "person")
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: AuthenticationViewModel())
    }
}
