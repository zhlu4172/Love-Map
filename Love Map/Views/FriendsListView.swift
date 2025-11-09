import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct UserProfile: Identifiable {
    let id: String
    let name: String
    let avatarUrl: String
}

struct FriendsListView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var friends: [UserProfile] = []
    
    var body: some View {
        VStack {
            if friends.isEmpty {
                Text("No friends yet 😢")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(friends) { friend in
                    HStack {
                        if let url = URL(string: friend.avatarUrl), !friend.avatarUrl.isEmpty {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                        Text(friend.name)
                            .font(.headline)
                    }
                }
            }
        }
        .navigationTitle("Friends")
        .onAppear {
            Task {
                await fetchFriends()
            }
        }
        .toolbar {
            Button(action: {
                Task { await fetchFriends() }
            }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    // Firestore Query
    func fetchFriends() async {
        guard let currentUserId = viewModel.emailSignInResult?.uid else {
            print("No current user ID")
            return
        }

        let db = Firestore.firestore()
        var fetchedFriends: [UserProfile] = []

        do {
            let snapshot = try await db.collection("friends")
                .whereField("userIds", arrayContains: currentUserId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()

            for doc in snapshot.documents {
                let userIds = doc["userIds"] as? [String] ?? []
                guard let friendId = userIds.first(where: { $0 != currentUserId }) else { continue }

                let userDoc = try await db.collection("users").document(friendId).getDocument()
                if let data = userDoc.data() {
                    let name = data["name"] as? String ?? "Unknown"
                    let avatarUrl = data["avatarUrl"] as? String ?? ""
                    fetchedFriends.append(UserProfile(id: friendId, name: name, avatarUrl: avatarUrl))
                }
            }
            self.friends = fetchedFriends
        } catch {
            print("Error fetching friends: \(error)")
        }
    }
}
