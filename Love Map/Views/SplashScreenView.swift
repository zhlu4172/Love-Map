//
//  SplashScreenView.swift
//  Love Map
//
//  Created by Emma Lu on 23/10/2024.
//

import Foundation
import SwiftUI

struct SplashScreenView: View {
    @State private var isActive: Bool = false
    
    var body: some View {
        if isActive {
            LoginView() // Show the login page after splash screen
        } else {
            VStack {
//                Image(systemName: "globe")
//                    .imageScale(.large)
//                // Replace with your logo image here
//                Image("ImageTry")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 300, height: 300)
//
//                Text("Build your map with your lover")
//                    .foregroundColor(Color("PrimaryColor"))
            }
            .onAppear {
                // Wait 2 seconds, then show login page
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
