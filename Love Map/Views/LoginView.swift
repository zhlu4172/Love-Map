//
//  LoginView.swift
//  Love Map
//
//  Created by Emma Lu on 23/10/2024.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
//    @State private var isLoggedIn: Bool = false
    @State private var isRegistering: Bool = false // Toggle between login and register modes
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var showForgotPasswordSheet = false

    var body: some View {
        if viewModel.isLoggedIn {
            ContentView(viewModel: viewModel) // Navigate to the main app after login 
        } else {
            VStack {
                Image("ImageTry")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.vertical, -30)

                TextField("Email", text: $email)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 10) // Adjust vertical padding for top and bottom
                    .padding(.horizontal, 15)
                    .overlay(
                            RoundedRectangle(cornerRadius: 30)                                 .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                        )
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 10)
                

                SecureField("Password", text: $password)
                    .padding(.vertical, 10) // Adjust vertical padding for top and bottom
                    .padding(.horizontal, 15)
                    .overlay(
                            RoundedRectangle(cornerRadius: 30)                                 .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                        )
                    .padding(.horizontal, 10)
                    .padding(.vertical,8)

                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                // login/register
                Button(action: {
                    Task {
                        do {
                            if isRegistering {
                                // Call AuthenticationManager's registration method
                                _ = try await AuthenticationManager.shared.registerWithEmail(email: email, password: password)
                                errorMessage = "A verification email has been sent. Please check your inbox."
                                showError = true
                            } else {
                                // Call AuthenticationManager's login method
//                                let user = try await AuthenticationManager.shared.loginWithEmail(email: email, password: password)
//                                isLoggedIn = true
                                try await viewModel.loginWithEmail(email: email, password: password)
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }) {
                    Text(isRegistering ? "Register" : "Log in")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(30)
                }
                .padding()
                
                
                GoogleSignInButton(
                    viewModel: GoogleSignInButtonViewModel(
                        scheme: .light,
                        style: .wide,
                        state: .normal
                    )
                ) {
                    // Define what happens when the Google Sign-In button is tapped
                    Task{
                        do {
                            try await viewModel.signInGoogle()
                            viewModel.isLoggedIn = true
                        } catch {
                            print(error)
                        }
                    }
                }
                
                
                // Forget password button
                Button(action: {
                    showForgotPasswordSheet = true
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(Color.gray.opacity(0.8))
                }
                .padding(.top, 5)
                .sheet(isPresented: $showForgotPasswordSheet) {
                    ForgotPasswordView(viewModel: viewModel)
                }

                // Toggle between login and registration
                Button(action: {
                    // Reset fields when toggling between login and register modes
                    isRegistering.toggle()
                    email = ""  // Clear the email field
                    password = ""  // Clear the password field
                    errorMessage = ""  // Clear any error messages
                    showError = false  // Hide error message
                }) {
                    Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                        .foregroundColor(Color.gray.opacity(0.8))
                }
                .padding(.vertical, -5)


                Spacer()
            }
            .padding()
        }
    }


    
}

struct Previews_LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
