//
//  AuthenticationViewModel.swift
//  Love Map
//
//  Created by Emma Lu on 1/11/2024.
//

//import Foundation
//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//@MainActor
//final class AuthenticationViewModel: ObservableObject {
//    @Published var userName: String = ""
//    @Published var userAvatarUrl: String = ""
//    @Published var userBio: String = ""
//
//    func fetchUserProfile() async {
//        // 确保用户已经登录并获取其 UID
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//
//        let db = Firestore.firestore()
//        let docRef = db.collection("users").document(uid)
//
//        do {
//            let document = try await docRef.getDocument()
//            if let data = document.data() {
//                self.userName = data["name"] as? String ?? "Unknown"
//                self.userAvatarUrl = data["avatarUrl"] as? String ?? ""
//                self.userBio = data["bio"] as? String ?? ""
//            }
//        } catch {
//            print("Error fetching user profile: \(error)")
//        }
//    }
//}

