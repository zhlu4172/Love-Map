//
//  AuthenticationManager.swift
//  Love Map
//
//  Created by Emma Lu on 25/10/2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}

    // 获取当前已认证的用户信息
    func getAuthenticatedUser() throws -> EmailSignInResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Unknown",
            userBio: "" // 可以在登录后通过 fetchUserProfile 更新
        )
    }

    // Email 登录
    func loginWithEmail(email: String, password: String) async throws -> EmailSignInResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = authDataResult.user
        print("-------------------------")
        print(user.uid)
        
        if user.isEmailVerified {
            return EmailSignInResultModel(
                uid: user.uid,
                email: user.email ?? "",
                userName: user.displayName ?? "Unknown",
                userBio: "" // 这里设置为空字符串，可以在登录后通过 fetchUserProfile 更新// 可以在登录后通过 fetchUserProfile 更新
            )
        } else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please verify your email before logging in."])
        }
    }

    // Email 注册并发送验证邮件
//    func registerWithEmail(email: String, password: String) async throws -> EmailSignInResultModel {
//        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
//        try await authDataResult.user.sendEmailVerification()
//        return EmailSignInResultModel(
//            uid: authDataResult.user.uid,
//            email: authDataResult.user.email ?? "",
//            userName: authDataResult.user.displayName ?? "Unknown",
//            userBio: ""
//        )
//    }
    


    // Email 注册并发送验证邮件
    func registerWithEmail(email: String, password: String) async throws -> EmailSignInResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        try await authDataResult.user.sendEmailVerification()
        
        let user = authDataResult.user
        
        // 在 Firestore 中为新用户创建记录
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": user.displayName ?? "Emma",
            "email": user.email ?? "",
            "bio": "This is bio",
            "avatarUrl": ""
        ]
        
        // 将用户数据保存到 Firestore 的 users 集合中
        try await db.collection("users").document(user.uid).setData(userData)
        print("New user created in Firestore with UID: \(user.uid)")
        
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Emma",
            userBio: "This is bio"
        )
    }

    
    // 密码重置
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}

// Google 登录方法扩展
extension AuthenticationManager {
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> EmailSignInResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authDataResult = try await Auth.auth().signIn(with: credential)
        let user = authDataResult.user
        
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Unknown",
            userBio: "" // 可以在登录后通过 fetchUserProfile 更新
        )
    }
}

