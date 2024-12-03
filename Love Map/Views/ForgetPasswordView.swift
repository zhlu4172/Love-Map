//
//  ForgetPasswordView.swift
//  Love Map
//
//  Created by Emma Lu on 31/10/2024.
//

import Foundation
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showSuccessMessage: Bool = false

    var body: some View {
        VStack {
            Text("Forgot Password")
                .font(.title)
                .padding(.bottom, 20)

            TextField("Enter your email", text: $email)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                )
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: {
                Task {
                    do {
                        try await viewModel.resetPassword(email: email)
                        showSuccessMessage = true
                        errorMessage = ""
                        showError = false
                    } catch {
                        errorMessage = "Failed to send password reset email. Please check the email entered."
                        showError = true
                    }
                }
            }) {
                Text("Send Reset Email")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("PrimaryColor"))
                    .cornerRadius(30)
            }
            .padding(.top, 20)
            .alert(isPresented: $showSuccessMessage) {
                Alert(
                    title: Text("Password Reset"),
                    message: Text("A password reset email has been sent. Please check your inbox."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }

            Spacer()
        }
        .padding()
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView(viewModel: AuthenticationViewModel())
    }
}
