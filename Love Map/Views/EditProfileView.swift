//
//  EditProfileView.swift
//  Love Map
//
//  Created by Emma Lu on 1/11/2024.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var userName: String
    @State private var userBio: String
    @State private var newAvatarImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var isEditingUserName = false
    @State private var isEditingBio = false
    @State private var showingSuccessAlert = false
    @Environment(\.presentationMode) private var presentationMode // For closing the view
    private let imgurService = ImgurService()
    
    init(viewModel: AuthenticationViewModel) {
        self.viewModel = viewModel
        _userName = State(initialValue: viewModel.emailSignInResult?.userName ?? "")
        _userBio = State(initialValue: viewModel.emailSignInResult?.userBio ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Display either the new avatar or the current avatar from the database
            if let newAvatarImage = newAvatarImage {
                Image(uiImage: newAvatarImage)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .onTapGesture {
                        showingImagePicker = true
                    }
            } else if let avatarUrl = viewModel.emailSignInResult?.userAvatarUrl, !avatarUrl.isEmpty {
                WebImage(url: URL(string: avatarUrl))
                    .resizable()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .onTapGesture {
                        showingImagePicker = true
                    }
            } else {
                Image("ImageTry")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .onTapGesture {
                        showingImagePicker = true
                    }
            }

            TextField("User Name", text: $userName, onEditingChanged: { isEditing in
                isEditingUserName = isEditing
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .foregroundColor(isEditingUserName ? .black : .gray)
            
            TextField("Bio", text: $userBio, onEditingChanged: { isEditing in
                isEditingBio = isEditing
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .foregroundColor(isEditingBio ? .black : .gray)
            
            Button("Save Changes") {
                if let newAvatarImage = newAvatarImage {
                    imgurService.uploadImageToImgur(image: newAvatarImage) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let url):
                                viewModel.updateUserProfile(userName: userName, userBio: userBio, avatarUrl: url)
                                showingSuccessAlert = true
                            case .failure(let error):
                                print("Failed to upload image to Imgur: \(error)")
                            }
                        }
                    }
                } else {
                    viewModel.updateUserProfile(userName: userName, userBio: userBio, avatarUrl: nil)
                    showingSuccessAlert = true
                }
            }
            .padding()
            .background(Color("PrimaryColor"))
            .foregroundColor(.white)
            .cornerRadius(30)
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("Update Successful"),
                    message: Text("Your profile has been updated."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .padding()
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $newAvatarImage)
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = AuthenticationViewModel()
        mockViewModel.emailSignInResult = EmailSignInResultModel(
            uid: "12345",
            email: "test@example.com",
            userName: "Test User",
            userBio: "This is a bio",
            userAvatarUrl: ""
        )
        
        return EditProfileView(viewModel: mockViewModel)
    }
}
