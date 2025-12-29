//
//  MainView.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import SwiftUI
import SwiftData

enum NavigationItem: String, CaseIterable, Identifiable {
    case compose = "Compose"
    case sent = "Sent"
    case accounts = "Accounts"
    case help = "Help"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .compose: return "square.and.pencil"
        case .sent: return "paperplane.fill"
        case .accounts: return "person.crop.circle"
        case .help: return "questionmark.circle"
        }
    }

    var label: String { rawValue }
}

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SenderAccount.createdAt, order: .reverse) private var accounts: [SenderAccount]
    @State private var selectedNavItem: NavigationItem = .compose
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(selection: $selectedNavItem) {
                Section {
                    ForEach(NavigationItem.allCases) { item in
                        NavigationLink(value: item) {
                            Label(item.label, systemImage: item.icon)
                        }
                    }
                }

                Section("Quick Info") {
                    HStack {
                        Text("Accounts")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(accounts.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)

                    if let defaultAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first {
                        HStack {
                            Text("Default")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(defaultAccount.websiteName)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .font(.caption)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        selectedNavItem = .compose
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("New Email")
                }
            }
        } detail: {
            // Detail view based on selection
            Group {
                switch selectedNavItem {
                case .compose:
                    EmailComposerView()
                case .sent:
                    SentEmailsView()
                case .accounts:
                    AccountsView()
                case .help:
                    HelpView()
                }
            }
        }
        .navigationTitle(selectedNavItem.label)
        .frame(minWidth: 950, minHeight: 600)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [SenderAccount.self, SentEmail.self, StoredAttachment.self], inMemory: true)
}
