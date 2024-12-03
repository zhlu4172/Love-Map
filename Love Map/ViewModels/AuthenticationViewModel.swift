//
//  AuthenticationViewModel.swift
//  Love Map
//
//  Created by Emma Lu on 1/11/2024.
//

import Foundation
import GoogleSignIn
import SwiftUI
import FirebaseAuth
import Firebase
import FirebaseCore
import FirebaseStorage
import FirebaseFirestore

struct GoogleSignInResultModel {
    let idToken: String
    let accessToken: String
}

struct EmailSignInResultModel: Equatable {
    let uid: String
    let email: String
    var userName: String
    var userBio: String
    var userAvatarUrl: String

    init(uid: String, email: String, userName: String = "Unknown", userBio: String = "", userAvatarUrl: String = "") {
        self.uid = uid
        self.email = email
        self.userName = userName
        self.userBio = userBio
        self.userAvatarUrl = userAvatarUrl
    }
}

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var emailSignInResult: EmailSignInResultModel?
    @Published var isLoggedIn: Bool = false
    private var ref: DatabaseReference!
    
    init() {
        ref = Database.database().reference() // 初始化数据库引用
    }

    // Email 登录方法
    func loginWithEmail(email: String, password: String) async throws {
        let authResult = try await AuthenticationManager.shared.loginWithEmail(email: email, password: password)
        
        // 检查 authResult 是否有 uid
        if !authResult.uid.isEmpty {
            print("Successfully logged in with UID: \(authResult.uid)")
        } else {
            print("Failed to retrieve UID.")
        }
        self.emailSignInResult = authResult
        self.isLoggedIn = true
        
        print("Successfully logged in with UID: \(authResult.uid)")
        
        await fetchUserProfile()
    }

    // Google 登录方法
    func signInGoogle() async throws {
        guard let topVC = Utilities.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let accessToken = gidSignInResult.user.accessToken.tokenString
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
        
        // 使用 Google 登录，并将结果保存为 EmailSignInResultModel
        self.emailSignInResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        self.isLoggedIn = true
        await fetchUserProfile() // 获取用户信息
    }
    
    
    func fetchUserProfile() async {
        guard let uid = emailSignInResult?.uid, !uid.isEmpty else {
            print("No UID found in fetchUserProfile")
            return
        }
        
        print("Attempting to fetch profile for uid: \(uid)")

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        do {
            let document = try await docRef.getDocument()
            
            // 检查文档是否存在
            if let data = document.data() {
                // 更新 profile 信息
                self.emailSignInResult?.userName = data["name"] as? String ?? "Unknown"
                self.emailSignInResult?.userBio = data["bio"] as? String ?? ""
                self.emailSignInResult?.userAvatarUrl = data["avatarUrl"] as? String ?? ""
                print("User profile fetched successfully: \(data)")
            } else {
                // 如果文档不存在，不创建默认文档，直接输出错误信息
                print("Document does not exist for user \(uid).")
            }
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }



    func resetPassword(email: String) async throws {
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
//    func updateUserProfile(userName: String, userBio: String, newAvatar: UIImage?) {
//        print("Starting updateUserProfile...") // 调试输出
//
//        guard let uid = emailSignInResult?.uid else {
//            print("No UID found") // 确认 UID 存在
//            return
//        }
//        
//        var userData: [String: Any] = [
//            "name": userName,
//            "bio": userBio
//        ]
//        print("userData dictionary created: \(userData)") // 确认数据字典创建
//
//        if let newAvatar = newAvatar, let imageData = newAvatar.jpegData(compressionQuality: 0.8) {
//                let storageRef = Storage.storage().reference().child("avatars/\(uid).jpg")
//                
//                // 上传图片到 Firebase Storage
//                storageRef.putData(imageData, metadata: nil) { metadata, error in
//                    if let error = error {
//                        print("Failed to upload avatar: \(error)")
//                        return
//                    }
//                    
//                    // 获取下载 URL
//                    storageRef.downloadURL { url, error in
//                        if let error = error {
//                            print("Failed to get download URL: \(error)")
//                            return
//                        }
//                        guard let downloadURL = url else { return }
//                        
//                        // 将下载 URL 添加到 userData
//                        userData["profile_picture"] = downloadURL.absoluteString
//                        
//                        // 更新 Firestore 中的用户数据
//                        Firestore.firestore().collection("users").document(uid).setData(userData, merge: true) { error in
//                            if let error = error {
//                                print("Failed to update user data in database: \(error)")
//                            } else {
//                                print("User profile updated successfully!")
//                                // 确保显示更新，重新拉取数据
//                                Task {
//                                    await self.fetchUserProfile()
//                                }
//                            }
//                        }
//                    }
//                }
//            } else {
//            // 没有头像更新，直接更新其他用户信息
//            print("No new avatar, updating other user info")
//            Firestore.firestore().collection("users").document(uid).setData(userData, merge: true){ error in
//                if let error = error {
//                    print("Failed to update user data in database: \(error)")
//                } else {
//                    print("User profile updated successfully!")
//                    // 重新拉取数据确保更新同步
//                    Task {
//                        await self.fetchUserProfile()
//                    }
//                }
//            }
//        }
//    }
    
    func updateUserProfile(userName: String, userBio: String, avatarUrl: String?) {
        guard let uid = emailSignInResult?.uid else { return }
        
        var userData: [String: Any] = [
            "name": userName,
            "bio": userBio
        ]
        
        if let avatarUrl = avatarUrl {
            userData["avatarUrl"] = avatarUrl
        }
        
        Firestore.firestore().collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Failed to update user data in database: \(error)")
            } else {
                print("User profile updated successfully!")
                Task {
                    await self.fetchUserProfile()
                }
            }
        }
    }


}
