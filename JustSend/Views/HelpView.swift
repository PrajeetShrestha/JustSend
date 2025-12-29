//
//  HelpView.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 29/12/2025.
//

import SwiftUI

struct HelpView: View {
    @State private var selectedSection: HelpSection = .setup

    enum HelpSection: String, CaseIterable, Identifiable {
        case setup = "App Setup"
        case account = "Account Setup"
        case about = "About"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .setup: return "wrench.and.screwdriver"
            case .account: return "person.badge.key"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        HSplitView {
            // Section list
            List(HelpSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150, idealWidth: 180, maxWidth: 200)

            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedSection {
                    case .setup:
                        appSetupContent
                    case .account:
                        accountSetupContent
                    case .about:
                        aboutContent
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - App Setup Content

    private var appSetupContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("App Setup Guide")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Welcome to JustSend! This guide will help you get started with sending emails.")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()

            // Step 1
            setupStep(
                number: 1,
                title: "Get a Resend API Key",
                content: """
                JustSend uses Resend to send emails. You'll need to create an account and get an API key:

                1. Visit resend.com and create a free account
                2. Go to the API Keys section in your dashboard
                3. Click "Create API Key"
                4. Copy the generated key (you'll need it later)
                """
            )

            // Step 2
            setupStep(
                number: 2,
                title: "Verify Your Domain",
                content: """
                To send emails from your own domain, you need to verify it in Resend:

                1. In your Resend dashboard, go to "Domains"
                2. Click "Add Domain" and enter your domain name
                3. Add the required DNS records to your domain registrar
                4. Wait for verification (usually takes a few minutes)

                Note: You can use onboarding@resend.dev for testing without domain verification.
                """
            )

            // Step 3
            setupStep(
                number: 3,
                title: "Add Your First Account",
                content: """
                Once you have your API key and verified domain:

                1. Click "Accounts" in the sidebar
                2. Click the "+" button to add a new account
                3. Enter your website/brand name
                4. Enter your sender email address (must use verified domain)
                5. Paste your Resend API key
                6. Optionally add a signature
                7. Click "Save"
                """
            )

            // Step 4
            setupStep(
                number: 4,
                title: "Start Sending Emails",
                content: """
                You're all set! Now you can:

                • Click "Compose" to write a new email
                • Select your sender account
                • Add recipients, subject, and content
                • Use the rich text editor for formatting
                • Attach files if needed
                • Click "Send" to deliver your email
                """
            )

            Divider()

            // Tips section
            VStack(alignment: .leading, spacing: 12) {
                Label("Pro Tips", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                tipItem("Set a default account to speed up email composition")
                tipItem("Create email signatures for consistent branding")
                tipItem("Use HTML templates for complex email designs")
                tipItem("Check the 'Sent' section to view your email history")
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // MARK: - Account Setup Content

    private var accountSetupContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Account Setup")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Learn how to configure and manage your sender accounts.")
                .font(.body)
                .foregroundColor(.secondary)

            Divider()

            // Creating an account
            VStack(alignment: .leading, spacing: 16) {
                Label("Creating a Sender Account", systemImage: "person.badge.plus")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("""
                Each sender account represents a unique "From" address for your emails. You can create multiple accounts for different purposes or brands.
                """)

                VStack(alignment: .leading, spacing: 8) {
                    accountField("Website Name", description: "A friendly name for this account (e.g., 'My Company')")
                    accountField("Email Address", description: "The sender email address (must be from a verified domain)")
                    accountField("API Key", description: "Your Resend API key (stored securely in Keychain)")
                    accountField("Signature", description: "Optional HTML signature appended to emails")
                    accountField("Set as Default", description: "Use this account by default when composing")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            Divider()

            // Managing accounts
            VStack(alignment: .leading, spacing: 16) {
                Label("Managing Accounts", systemImage: "gearshape.2")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 12) {
                    actionItem(icon: "pencil", title: "Edit Account", description: "Click on an account to modify its details")
                    actionItem(icon: "signature", title: "Edit Signature", description: "Click the gear icon to open the signature editor")
                    actionItem(icon: "star.fill", title: "Set Default", description: "Toggle 'Set as Default' to use an account automatically")
                    actionItem(icon: "trash", title: "Delete Account", description: "Click the delete button to remove an account")
                }
            }

            Divider()

            // Security note
            VStack(alignment: .leading, spacing: 12) {
                Label("Security", systemImage: "lock.shield.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                Text("""
                Your API keys are stored securely in the macOS Keychain and are never saved in plain text. The app uses Apple's native security infrastructure to protect your credentials.
                """)
                .font(.callout)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // MARK: - About Content

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // App icon and name
            HStack(spacing: 20) {
                Image(systemName: "paperplane.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue.gradient)

                VStack(alignment: .leading, spacing: 4) {
                    Text("JustSend")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Simple Email Sending for macOS")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("About JustSend")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("""
                JustSend is a lightweight, native macOS application for sending emails through the Resend API. Built with SwiftUI and designed for simplicity, it provides a clean interface for composing and sending emails without the complexity of traditional email clients.
                """)
                .font(.body)
            }

            // Features
            VStack(alignment: .leading, spacing: 12) {
                Text("Features")
                    .font(.title2)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    featureItem(icon: "envelope.fill", title: "Rich Email Composer", description: "Full HTML support with formatting")
                    featureItem(icon: "person.2.fill", title: "Multiple Accounts", description: "Manage different sender identities")
                    featureItem(icon: "paperclip", title: "Attachments", description: "Send files up to 40MB")
                    featureItem(icon: "clock.fill", title: "Email History", description: "Track all sent emails")
                    featureItem(icon: "signature", title: "Signatures", description: "Custom HTML signatures")
                    featureItem(icon: "lock.fill", title: "Secure Storage", description: "Keychain-protected API keys")
                }
            }

            Divider()

            // Credits
            VStack(alignment: .leading, spacing: 12) {
                Text("Credits")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 8) {
                    creditItem("Built with", "SwiftUI & SwiftData")
                    creditItem("Email Service", "Resend (resend.com)")
                    creditItem("Rich Text Editor", "InfomaniakRichHTMLEditor")
                }
            }

            Spacer()

            // Footer
            HStack {
                Spacer()
                Text("Made with ❤️ for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }

    // MARK: - Helper Views

    private func setupStep(number: Int, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.blue))

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func tipItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.orange)
            Text(text)
                .font(.callout)
        }
    }

    private func accountField(_ name: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func actionItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func creditItem(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
        .font(.callout)
    }
}

#Preview {
    HelpView()
}
