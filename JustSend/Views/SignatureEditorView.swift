//
//  SignatureEditorView.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import SwiftUI

struct SignatureEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AccountsViewModel
    let account: SenderAccount
    
    @State private var signatureHTML: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Signature")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Rich Text Editor
            RichTextEditor(htmlContent: $signatureHTML)
                .frame(minWidth: 500, minHeight: 300)
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveSignature()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .onAppear {
            signatureHTML = account.signature ?? ""
        }
    }
    
    private func saveSignature() {
        // We use a custom update method or just update the property if ViewModel logic allows
        // To be safe and trigger updates, we should probably use a method on ViewModel
        // But for now, direct update via ViewModel method we made earlier is best
        viewModel.updateAccount(
            account,
            websiteName: account.websiteName,
            emailAddress: account.emailAddress,
            apiKey: account.apiKey ?? "",
            signature: signatureHTML
        )
        dismiss()
    }
}
