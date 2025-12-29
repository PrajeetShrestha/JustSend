# JustSend

**JustSend** is a lightweight, native macOS application designed purely for sending emails through the Resend API. It simplifies the email experience by removing the inbox, allowing you to focus solely on composing and sending messages.

## Features

- **Rich Email Composer**: Full HTML support with formatting.
- **Multiple Accounts**: Manage different sender identities.
- **Attachments**: Send files up to 40MB.
- **Email History**: Track all sent emails.
- **Signatures**: Custom HTML signatures.
- **Secure Storage**: API keys are stored securely in the macOS Keychain.

## App Setup Guide

JustSend uses Resend to send emails. Follow these steps to get started:

### 1. Get a Resend API Key

1.  Visit [resend.com](https://resend.com) and create a free account.
2.  Go to the API Keys section in your dashboard.
3.  Click "Create API Key".
4.  Copy the generated key (you'll need it later).

### 2. Verify Your Domain

To send emails from your own domain, you need to verify it in Resend:

1.  In your Resend dashboard, go to "Domains".
2.  Click "Add Domain" and enter your domain name.
3.  Add the required DNS records to your domain registrar.
4.  Wait for verification (usually takes a few minutes).

> **Note**: You can use `onboarding@resend.dev` for testing without domain verification.

### 3. Add Your First Account

Once you have your API key and verified domain:

1.  Click "Accounts" in the sidebar.
2.  Click the "+" button to add a new account.
3.  Enter your website/brand name.
4.  Enter your sender email address (must use verified domain).
5.  Paste your Resend API key.
6.  Optionally add a signature.
7.  Click "Save".

## Firebase Setup (Required for Building)

This project uses Firebase for analytics. To build and run the app, you need to provide your own `GoogleService-Info.plist`.

1.  Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/).
2.  Add an iOS app with the Bundle ID: `com.codekunda.custom.JustSend` (or your own if you changed it).
3.  Download the `GoogleService-Info.plist` file.
4.  Place it in the root directory of the project (same folder as `JustSend.xcodeproj`).
5.  **Note**: This file is ignored by git for security reasons.

## Configuration Setup (Required for Building)

The project uses a `release.xcconfig` file to manage build settings like `TEAM_ID` and `BUNDLE_ID` for Release builds. This file is ignored by git.

1.  Locate `sample.xcconfig` in the project root.
2.  Duplicate it and rename the copy to `release.xcconfig`.
3.  Open `release.xcconfig` and fill in your details:
    ```xcconfig
    TEAM_ID = YOUR_TEAM_ID
    BUNDLE_ID = com.your.bundle.id
    ```
4.  These values will automatically be injected into the `Info.plist` and Build Settings.

## Account Setup

Each sender account represents a unique "From" address for your emails. You can create multiple accounts for different purposes or brands.

- **Website Name**: A friendly name for this account (e.g., 'My Company').
- **Email Address**: The sender email address.
- **API Key**: Your Resend API key.
- **Signature**: Optional HTML signature appended to emails.
- **Set as Default**: Use this account by default when composing.

### Managing Accounts

- **Edit Account**: Click on an account to modify its details.
- **Edit Signature**: Click the gear icon to open the signature editor.
- **Set Default**: Toggle 'Set as Default' to use an account automatically.
- **Delete Account**: Click the delete button to remove an account.

## Security

Your API keys are stored securely in the macOS Keychain and are never saved in plain text. The app uses Apple's native security infrastructure to protect your credentials.

## Download

You can download the latest version from the [Releases](https://github.com/PrajeetShrestha/JustSend/releases) page.

## Building from Source

> **Note**: `create_dmg.sh` and `deploy.sh` scripts are currently disabled due to notarization requirements. Please use `scripts/manual_deploy.sh` for deployment (if available) or build manually via Xcode.

1.  Clone the repository:

    ```bash
    git clone https://github.com/PrajeetShrestha/JustSend.git
    cd JustSend
    ```

2.  Open `JustSend.xcodeproj` in Xcode.

3.  Build and Run.

## Credits

- **Built with**: SwiftUI & SwiftData
- **Email Service**: Resend (resend.com)
- **Rich Text Editor**: InfomaniakRichHTMLEditor

## License

[MIT License](LICENSE)
