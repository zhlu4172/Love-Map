//
//  ProfileView.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showingEditProfile = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 20) {
                // 用户头像和昵称
                HStack(alignment: .center) {
                    // 头像
                    if let url = URL(string: viewModel.emailSignInResult?.userAvatarUrl ?? ""), !(viewModel.emailSignInResult?.userAvatarUrl ?? "").isEmpty {
                        WebImage(url: url)
                            .resizable()
                            .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                            .clipped()
                            .cornerRadius(geometry.size.width * 0.125)
                    } else {
                        Image("ImageTry") // 本地默认头像
                            .resizable()
                            .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                            .clipped()
                            .cornerRadius(geometry.size.width * 0.125)
                    }
                    
                    // 用户名和简介
                    VStack(alignment: .leading) {
                        HStack {
                            Text(viewModel.emailSignInResult?.userName ?? "Unknown")
                                .font(.title)
                                .fontWeight(.bold)
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.gray)
                            }
                        }
                        Text(viewModel.emailSignInResult?.userBio ?? "No bio available.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, geometry.size.width * 0.05)
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                
                VStack(alignment: .leading, spacing: 10) {
                    // Friends
                    HStack(spacing: 10) {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Friends")
                            .font(.headline)
                    }
                    
                    // Maps
                    HStack(spacing: 10) {
                        Image(systemName: "map")
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                        Text("Maps")
                            .font(.headline)
                    }
                    
                    // Settings
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                        Text("Settings")
                            .font(.headline)
                    }
                }
                .padding(.horizontal, geometry.size.width * 0.05)

                Spacer()
            }
            .padding(.horizontal, geometry.size.width * 0.05)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .onChange(of: viewModel.emailSignInResult) { _ in
                print("Profile updated, refreshing view")
            }
            .onAppear {
                Task {
                    if let uid = viewModel.emailSignInResult?.uid {
                        print("UID in ProfileView onAppear: \(uid)")
                        await viewModel.fetchUserProfile()
                    } else {
                        print("No UID found in ProfileView onAppear")
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: AuthenticationViewModel())
    }
}
