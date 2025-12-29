//
//  AccountsViewModelTests.swift
//  JustSendTests
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import XCTest
import SwiftData
@testable import JustSend

@MainActor
class AccountsViewModelTests: XCTestCase {
    var viewModel: AccountsViewModel!
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SenderAccount.self, configurations: config)
        context = container.mainContext
        viewModel = AccountsViewModel()
        viewModel.setModelContext(context)
    }

    override func tearDown() {
        viewModel = nil
        context = nil
        container = nil
    }

    func testAddAccount() {
        // When
        viewModel.addAccount(
            websiteName: "Test Web",
            emailAddress: "test@example.com",
            apiKey: "re_12345",
            signature: "Signature"
        )

        // Then
        XCTAssertEqual(viewModel.accounts.count, 1)
        let added = viewModel.accounts.first
        XCTAssertEqual(added?.websiteName, "Test Web")
        XCTAssertEqual(added?.emailAddress, "test@example.com")
        XCTAssertEqual(added?.apiKey, "re_12345")
        XCTAssertEqual(added?.signature, "Signature")
        XCTAssertTrue(added?.isDefault ?? false)
    }

    func testUpdateAccount() {
        // Given
        viewModel.addAccount(
            websiteName: "Old Name",
            emailAddress: "old@example.com",
            apiKey: "re_old",
            signature: nil
        )
        let account = viewModel.accounts.first!

        // When
        viewModel.updateAccount(
            account,
            websiteName: "New Name",
            emailAddress: "new@example.com",
            apiKey: "re_new",
            signature: "New Sig"
        )

        // Then
        XCTAssertEqual(account.websiteName, "New Name")
        XCTAssertEqual(account.emailAddress, "new@example.com")
        XCTAssertEqual(account.apiKey, "re_new")
        XCTAssertEqual(account.signature, "New Sig")
    }

    func testDeleteAccount() {
        // Given
        viewModel.addAccount(
            websiteName: "To Delete",
            emailAddress: "delete@example.com",
            apiKey: "re_delete",
            signature: nil
        )
        let account = viewModel.accounts.first!

        // When
        viewModel.deleteAccount(account)

        // Then
        XCTAssertTrue(viewModel.accounts.isEmpty)
    }

    func testSetAsDefault() {
        // Given
        viewModel.addAccount(websiteName: "Acc 1", emailAddress: "1@test.com", apiKey: "re_1", signature: nil)
        viewModel.addAccount(websiteName: "Acc 2", emailAddress: "2@test.com", apiKey: "re_2", signature: nil)
        
        let acc1 = viewModel.accounts.first { $0.websiteName == "Acc 1" }!
        let acc2 = viewModel.accounts.first { $0.websiteName == "Acc 2" }!
        
        // Initially first added is default
        XCTAssertTrue(acc1.isDefault)
        XCTAssertFalse(acc2.isDefault)
        
        // When
        viewModel.setAsDefault(acc2)
        
        // Then
        XCTAssertFalse(acc1.isDefault)
        XCTAssertTrue(acc2.isDefault)
        XCTAssertEqual(viewModel.defaultAccount?.id, acc2.id)
    }

    func testValidateAPIKey() {
        XCTAssertTrue(viewModel.validateAPIKeyFormat("re_123456789"))
        XCTAssertFalse(viewModel.validateAPIKeyFormat("invalid"))
        XCTAssertFalse(viewModel.validateAPIKeyFormat("re_short"))
    }
    
    func testValidateEmail() {
        XCTAssertTrue(viewModel.validateEmailFormat("test@example.com"))
        XCTAssertFalse(viewModel.validateEmailFormat("invalid"))
        XCTAssertFalse(viewModel.validateEmailFormat("test@"))
        XCTAssertFalse(viewModel.validateEmailFormat("@example.com"))
    }
    
    func testGetExistingDomain() {
        // Given
        viewModel.addAccount(websiteName: "MySite", emailAddress: "hello@mysite.com", apiKey: "re_key", signature: nil)
        
        // Then
        XCTAssertEqual(viewModel.getExistingDomain(for: "MySite"), "mysite.com")
        XCTAssertEqual(viewModel.getExistingDomain(for: "MYSITE"), "mysite.com") // Case insensitive check
        XCTAssertNil(viewModel.getExistingDomain(for: "Other"))
    }
}
