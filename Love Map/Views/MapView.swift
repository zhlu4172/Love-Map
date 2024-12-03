//
//  MapView.swift
//  Love Map
//
//  Created by Emma Lu on 20/10/2024.
//

import SwiftUI
import GoogleMaps

struct MapView: View {
    var body: some View {
        VStack {
            // 顶部的标题和按钮
            HStack {
                Spacer()
                VStack {
                    Text("Your Love Map")
                        .font(.custom("HelveticaNeue-Bold", size: 30)) // 自定义字体
                        .foregroundColor(Color("PrimaryColor")) // 粉色标题
                    Text("with Leo")
                        .font(.title2)
                        .foregroundColor(Color("PrimaryColor"))
                }
                Spacer()
                
                HStack {
                    // 用户图标按钮
                    Button(action: {
                        // 你的用户按钮操作
                    }) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    
                    // 加号图标按钮
                    Button(action: {
                        // 你的加号按钮操作
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

            // Google Map View 代替地球图
            GoogleMapView()
                .frame(width: 300, height: 300) // 设置 Google Maps 的尺寸
            
            Spacer()
        }
        .background(Color.white)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
