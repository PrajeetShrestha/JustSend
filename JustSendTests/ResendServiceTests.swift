//
//  ResendServiceTests.swift
//  JustSendTests
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import XCTest
@testable import JustSend

class ResendServiceTests: XCTestCase {
    var service: ResendService!
    var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        service = ResendService(apiKey: "re_test_key", session: session)
    }

    override func tearDown() {
        service = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testSendEmail_Success() async throws {
        // Given
        let expectedID = "msg_12345"
        let responseData = """
        {
            "id": "\(expectedID)"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString == "https://api.resend.com/emails" else {
                throw URLError(.badURL)
            }
            
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseData)
        }

        // When
        let response = try await service.sendEmail(
            from: "test@example.com",
            to: ["recipient@example.com"],
            subject: "Test Subject",
            htmlContent: "<p>Hello</p>"
        )

        // Then
        XCTAssertEqual(response.id, expectedID)
    }

    func testSendEmail_Unauthorized() async {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        // When/Then
        do {
            _ = try await service.sendEmail(
                from: "test@example.com",
                to: ["recipient@example.com"],
                subject: "Test Subject",
                htmlContent: "<p>Hello</p>"
            )
            XCTFail("Should throw error")
        } catch let error as ResendError {
            if case .httpError(let statusCode) = error {
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testSendEmail_MissingAPIKey() async {
        // Given
        service = ResendService(apiKey: "", session: session)

        // When/Then
        do {
            _ = try await service.sendEmail(
                from: "test@example.com",
                to: ["recipient@example.com"],
                subject: "Test",
                htmlContent: "content"
            )
            XCTFail("Should throw missing API key error")
        } catch ResendError.missingAPIKey {
            // Success
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func testSendEmail_RequestPayload() async throws {
        // Given
        let to = ["recipient@example.com"]
        let from = "sender@example.com"
        let subject = "Subject"
        let html = "HTML"
        let text = "Text"
        var requestPayload: [String: Any]?
        
        MockURLProtocol.requestHandler = { request in
            // Verify request body
            var bodyData = request.httpBody
            if bodyData == nil, let stream = request.httpBodyStream {
                stream.open()
                var buffer = [UInt8](repeating: 0, count: 4096)
                bodyData = Data()
                while stream.hasBytesAvailable {
                    let len = stream.read(&buffer, maxLength: buffer.count)
                    if len > 0 {
                        bodyData?.append(buffer, count: len)
                    } else {
                        break
                    }
                }
                stream.close()
            }
            
            guard let data = bodyData else {
                XCTFail("httpBody and httpBodyStream are nil")
                throw URLError(.cannotDecodeRawData)
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    XCTFail("Body is not a dictionary")
                    throw URLError(.cannotDecodeRawData)
                }
                
                requestPayload = json
                print("DEBUG: Payload: \(json)")
                
                // Assertions inside handler might not propagate correctly if run on bg thread,
                // but URLSession runs callback on delegate queue.
                // We'll capture and assert outside or just assert here.
            } catch {
                XCTFail("JSON parsing failed: \(error)")
                throw error
            }
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let respData = """
            { "id": "msg_123" }
            """.data(using: .utf8)
            return (response, respData)
        }
        
        // When
        _ = try await service.sendEmail(
            from: from,
            to: to,
            subject: subject,
            htmlContent: html,
            textContent: text
        )
        
        // Then (Verify captured payload)
        guard let json = requestPayload else {
            XCTFail("No payload captured")
            return
        }
        
        XCTAssertEqual(json["from"] as? String, from)
        XCTAssertEqual(json["to"] as? [String], to)
        XCTAssertEqual(json["subject"] as? String, subject)
        XCTAssertEqual(json["html"] as? String, html)
        XCTAssertEqual(json["text"] as? String, text)
    }
}
