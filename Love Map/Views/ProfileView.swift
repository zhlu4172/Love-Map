import SwiftUI
import SDWebImageSwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var showingEditProfile = false
    @State private var isLoading = true   // Loading state
    @State private var copied = false     // ✅ 新增，用于显示“Copied!”

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    VStack {
                        ProgressView("Loading profile...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .font(.headline)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        // User avatar and nickname
                        HStack(alignment: .center) {
                            // Avatar
                            if let url = URL(string: viewModel.emailSignInResult?.userAvatarUrl ?? ""),
                               !(viewModel.emailSignInResult?.userAvatarUrl ?? "").isEmpty {
                                WebImage(url: url)
                                    .resizable()
                                    .indicator(.activity)
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                                    .clipped()
                                    .cornerRadius(geometry.size.width * 0.125)
                            } else {
                                Image("ImageTry") // Local default avatar
                                    .resizable()
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)
                                    .clipped()
                                    .cornerRadius(geometry.size.width * 0.125)
                            }

                            // Username, bio, and display ID
                            VStack(alignment: .leading, spacing: 6) {
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

                                // ✅ Display ID section
                                HStack(spacing: 6) {
                                    Text("ID: \(viewModel.emailSignInResult?.displayId ?? "Loading...")")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)

                                    Button(action: {
                                        let id = viewModel.emailSignInResult?.displayId ?? ""
                                        if !id.isEmpty {
                                            UIPasteboard.general.string = id
                                            withAnimation { copied = true }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                withAnimation { copied = false }
                                            }
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.blue)
                                    }

                                    if copied {
                                        Text("Copied!")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .transition(.opacity)
                                    }
                                }
                            }
                            .padding(.leading, geometry.size.width * 0.05)
                        }
                        .padding(.horizontal, geometry.size.width * 0.05)

                        // Menu Section
                        VStack(alignment: .leading, spacing: 10) {
                            // Friends
                            NavigationLink(destination: FriendsListView(viewModel: viewModel)) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.2")
                                        .foregroundColor(.blue)
                                        .frame(width: 20, height: 20)
                                    Text("Friends")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
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
                }
            }
            .onAppear {
                Task {
                    if let uid = viewModel.emailSignInResult?.uid {
                        print("UID in ProfileView onAppear: \(uid)")
                        await viewModel.fetchUserProfile()
                        withAnimation { isLoading = false }
                    } else {
                        print("No UID found in ProfileView onAppear")
                        withAnimation { isLoading = false }
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
