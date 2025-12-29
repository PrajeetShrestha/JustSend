//
//  EmailAttachmentTests.swift
//  JustSendTests
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import XCTest
@testable import JustSend

class EmailAttachmentTests: XCTestCase {

    func testMimeTypeDetection() throws {
        // Setup temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test.pdf")
        try "dummy content".write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Test
        let attachment = try EmailAttachment.fromURL(fileURL)
        
        XCTAssertEqual(attachment.contentType, "application/pdf")
        XCTAssertEqual(attachment.filename, "test.pdf")
        
        // Cleanup
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func testBase64Encoding() throws {
        // Setup
        let content = "Hello World"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("hello.txt")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Test
        let attachment = try EmailAttachment.fromURL(fileURL)
        let decodedData = Data(base64Encoded: attachment.content)!
        let decodedString = String(data: decodedData, encoding: .utf8)
        
        XCTAssertEqual(decodedString, content)
        XCTAssertEqual(attachment.contentType, "text/plain")
        
        // Cleanup
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func testUnknownExtension() throws {
         // Setup
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test.xyz")
        try "data".write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Test
        let attachment = try EmailAttachment.fromURL(fileURL)
        
        XCTAssertEqual(attachment.contentType, "application/octet-stream")
        
        // Cleanup
        try FileManager.default.removeItem(at: fileURL)
    }
}
