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
                // 第一个 Tab：Map 页面
            MapView()
            .tabItem {
                Label("Map", systemImage: "map")
            }
                
                // 第二个 Tab：Profile 页面
            ProfileView(viewModel: viewModel)
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
