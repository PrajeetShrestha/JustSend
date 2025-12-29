//
//  JustSendApp.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import SwiftUI
import SwiftData
import FirebaseCore
import Combine
import Sparkle

// MARK: - Sparkle Update View Model
// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// MARK: - Check for Updates View
// This intermediate view is necessary for the disabled state on the menu item
// to work properly before Monterey. See Sparkle documentation for details.
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater) {
        self.updater = updater
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }

    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

@main
struct JustSendApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        FirebaseApp.configure()
        
        // Initialize the updater controller with default configuration
        // If you need custom delegate behavior, create and pass delegates here
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SenderAccount.self,
            SentEmail.self,
            StoredAttachment.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("JustSend") {
            MainView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
