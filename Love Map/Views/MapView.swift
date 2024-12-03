//
//  MapView.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import SwiftUI
import GoogleMaps

struct MapView: View {
    @State private var userId: String = ""
    @State private var isLoading = true // 控制加载状态

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading map...")
            } else {
                VStack {
                    // 顶部的标题和按钮
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
                                // 用户图标按钮
                                print("User icon tapped!")
                            }) {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                            
                            Button(action: {
                                // 加号图标按钮
                                print("Add new location tapped!")
                            }) {
                                Image(systemName: "plus.square")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                        }
                        .padding()
                    }
                    .padding(.top, 20) // 顶部留白
                    
                    Spacer()

                    // GoogleMapView 显示地图，传递用户 ID
                    GoogleMapView(userId: userId)
                        .frame(height: 400) // 设置地图高度

                    Spacer()
                }
            }
        }
        .background(Color.white)
        .onAppear {
            fetchCurrentUserId()
        }
    }

    /// 获取当前用户 ID
    private func fetchCurrentUserId() {
        do {
            let user = try AuthenticationManager.shared.getAuthenticatedUser()
            userId = user.uid // 获取用户 UID
            isLoading = false
            print("User ID fetched: \(userId)")
        } catch {
            print("Failed to fetch authenticated user: \(error)")
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
