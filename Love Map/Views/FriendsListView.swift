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
    @State private var showingAddFriendAlert = false
    @State private var friendDisplayId = ""
    @State private var showingMessage = false
    @State private var messageText = ""
    
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
                .listStyle(.plain)
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingAddFriendAlert = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                }
                
                Button {
                    Task { await fetchFriends() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
        }
        .alert("Add Friend", isPresented: $showingAddFriendAlert) {
            TextField("Enter friend's display ID", text: $friendDisplayId)
            Button("Add") { Task { await addFriendByDisplayId() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your friend's display ID to send a request.")
        }
        .overlay(
            Group {
                if showingMessage {
                    Text(messageText)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .padding(.bottom, 50)
                }
            },
            alignment: .bottom
        )
        .onAppear {
            Task { await fetchFriends() }
        }
    }

    // MARK: - Fetch Friends
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
            await MainActor.run {
                self.friends = fetchedFriends
            }
        } catch {
            print("Error fetching friends: \(error)")
        }
    }

    // MARK: - Add Friend
    func addFriendByDisplayId() async {
        guard let currentUserId = viewModel.emailSignInResult?.uid else {
            print("No current user ID")
            return
        }
        let db = Firestore.firestore()

        do {
            let userQuery = try await db.collection("users")
                .whereField("displayId", isEqualTo: friendDisplayId.uppercased())
                .getDocuments()
            
            guard let friendDoc = userQuery.documents.first else {
                await showTempMessage("User not found")
                return
            }
            let friendId = friendDoc.documentID
            
            let existingQuery = try await db.collection("friends")
                .whereField("userIds", arrayContains: currentUserId)
                .getDocuments()
            
            for doc in existingQuery.documents {
                let ids = doc["userIds"] as? [String] ?? []
                if ids.contains(friendId) {
                    await showTempMessage("Already added or pending")
                    return
                }
            }
            
            let friendData: [String: Any] = [
                "userIds": [currentUserId, friendId],
                "requestedBy": currentUserId,
                "status": "accepted",
                "requestedAt": Timestamp(date: Date())
            ]
            _ = try await db.collection("friends").addDocument(data: friendData)
            await showTempMessage("Friend added successfully")
            await fetchFriends()
        } catch {
            print("Error adding friend: \(error)")
            await showTempMessage("Error adding friend")
        }
    }

    // MARK: - Toast Message
    @MainActor
    func showTempMessage(_ text: String) async {
        withAnimation {
            messageText = text
            showingMessage = true
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        withAnimation {
            showingMessage = false
        }
    }
}
