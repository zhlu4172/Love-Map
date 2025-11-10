import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}
    
    // Generate a unique display ID (short code)
    private func generateDisplayId() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = 6
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    // Get authenticated user
    func getAuthenticatedUser() throws -> EmailSignInResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Unknown",
            userBio: "",
            userAvatarUrl: "",
            displayId: "N/A"   
        )
    }

    // Email login
    func loginWithEmail(email: String, password: String) async throws -> EmailSignInResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = authDataResult.user
        
        guard user.isEmailVerified else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please verify your email before logging in."])
        }
        
        print("-------------------------")
        print("User UID:", user.uid)
        
        // Read displayId from Firestore
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(user.uid).getDocument()
        let displayId = doc.data()?["displayId"] as? String ?? "N/A"
        let avatarUrl = doc.data()?["avatarUrl"] as? String ?? ""
        
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Unknown",
            userBio: "",
            userAvatarUrl: avatarUrl,
            displayId: displayId
        )
    }

    // MARK: - Email 注册并发送验证邮件
    func registerWithEmail(email: String, password: String) async throws -> EmailSignInResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        try await authDataResult.user.sendEmailVerification()
        
        let user = authDataResult.user
        
        // Generate unique displayId
        let displayId = generateDisplayId()
        
        // Save user data to Firestore
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": user.displayName ?? "Emma",
            "email": user.email ?? "",
            "bio": "This is bio",
            "avatarUrl": "",
            "displayId": displayId
        ]
        
        try await db.collection("users").document(user.uid).setData(userData)
        print("New user created in Firestore with UID: \(user.uid), displayId: \(displayId)")
        
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Emma",
            userBio: "This is bio",
            userAvatarUrl: "",
            displayId: displayId
        )
    }

    // Reset Password
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}

// Google login method extension
extension AuthenticationManager {
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> EmailSignInResultModel {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authDataResult = try await Auth.auth().signIn(with: credential)
        let user = authDataResult.user
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        var displayId: String = "N/A"
        
        do {
            let document = try await userDocRef.getDocument()
            if document.exists {
                // Existing account
                displayId = document.data()?["displayId"] as? String ?? "N/A"
            } else {
                // First login, create Firestore record
                displayId = generateDisplayId()
                let userData: [String: Any] = [
                    "name": user.displayName ?? "Unknown",
                    "email": user.email ?? "",
                    "bio": "",
                    "avatarUrl": user.photoURL?.absoluteString ?? "",
                    "displayId": displayId
                ]
                try await userDocRef.setData(userData)
                print("New Google user created in Firestore with UID: \(user.uid), displayId: \(displayId)")
            }
        } catch {
            print("Error checking/creating Google user document: \(error.localizedDescription)")
        }
        
        return EmailSignInResultModel(
            uid: user.uid,
            email: user.email ?? "",
            userName: user.displayName ?? "Unknown",
            userBio: "",
            userAvatarUrl: user.photoURL?.absoluteString ?? "",
            displayId: displayId
        )
    }
}
