import XCTest
@testable import SensitiveString

final class SensitiveStringTests: XCTestCase {
    
    // MARK: - String Representation Tests
    
    func testDescriptionShowsHash() throws {
        let secret = SensitiveString("my-secret-value")
        let result = secret.description
        
        XCTAssertTrue(result.hasPrefix("sha256:"))
        XCTAssertFalse(result.contains("my-secret-value"))
        XCTAssertEqual(result.count, 71) // "sha256:" (7) + 64 hex chars
    }
    
    func testDebugDescriptionShowsHash() throws {
        let secret = SensitiveString("my-secret-value")
        let result = secret.debugDescription
        
        XCTAssertTrue(result.hasPrefix("SensitiveString(sha256:"))
        XCTAssertFalse(result.contains("my-secret-value"))
    }
    
    func testStringInterpolationShowsHash() throws {
        let secret = SensitiveString("my-secret-value")
        let result = "\(secret)"
        
        XCTAssertTrue(result.hasPrefix("sha256:"))
        XCTAssertFalse(result.contains("my-secret-value"))
    }
    
    // MARK: - Value Access Tests
    
    func testValueReturnsPlaintext() throws {
        let secret = SensitiveString("my-secret-value")
        XCTAssertEqual(secret.value, "my-secret-value")
    }
    
    func testGetValueReturnsPlaintext() throws {
        let secret = SensitiveString("my-secret-value")
        XCTAssertEqual(secret.getValue(), "my-secret-value")
    }
    
    // MARK: - Utility Tests
    
    func testCount() throws {
        let secret = SensitiveString("12345")
        XCTAssertEqual(secret.count, 5)
    }
    
    func testIsEmpty() throws {
        let empty = SensitiveString("")
        let notEmpty = SensitiveString("value")
        
        XCTAssertTrue(empty.isEmpty)
        XCTAssertFalse(notEmpty.isEmpty)
    }
    
    func testEquality() throws {
        let secret1 = SensitiveString("same-value")
        let secret2 = SensitiveString("same-value")
        let secret3 = SensitiveString("different-value")
        
        XCTAssertEqual(secret1, secret2)
        XCTAssertNotEqual(secret1, secret3)
    }
    
    func testHashable() throws {
        let secret1 = SensitiveString("value1")
        let secret2 = SensitiveString("value2")
        let secret3 = SensitiveString("value1") // Same as secret1
        
        var set = Set<SensitiveString>()
        set.insert(secret1)
        set.insert(secret2)
        
        XCTAssertEqual(set.count, 2)
        
        // Same value shouldn't add duplicate
        set.insert(secret3)
        XCTAssertEqual(set.count, 2)
    }
    
    func testConsistentHash() throws {
        let secret1 = SensitiveString("consistent-value")
        let secret2 = SensitiveString("consistent-value")
        
        XCTAssertEqual(secret1.description, secret2.description)
    }
    
    // MARK: - Helper Method Tests
    
    func testIsSensitiveString() throws {
        let secret = SensitiveString("value")
        
        XCTAssertTrue(SensitiveString.isSensitiveString(secret))
        XCTAssertFalse(SensitiveString.isSensitiveString("plain string"))
        XCTAssertFalse(SensitiveString.isSensitiveString(123))
    }
    
    func testExtractValue() throws {
        let secret = SensitiveString("secret")
        let plain = "plain"
        
        XCTAssertEqual(SensitiveString.extractValue(secret), "secret")
        XCTAssertEqual(SensitiveString.extractValue(plain), "plain")
        XCTAssertNil(SensitiveString.extractValue(123))
    }
    
    func testExtractRequiredValue() throws {
        let secret = SensitiveString("secret")
        let plain = "plain"
        
        XCTAssertEqual(try SensitiveString.extractRequiredValue(secret), "secret")
        XCTAssertEqual(try SensitiveString.extractRequiredValue(plain), "plain")
        
        XCTAssertThrowsError(try SensitiveString.extractRequiredValue(123))
    }
    
    func testSensitive() throws {
        let secret = SensitiveString("original")
        
        // Already sensitive - returns equivalent object
        let result1 = SensitiveString.sensitive(secret)
        XCTAssertEqual(result1, secret)
        
        // Convert string
        let result2 = SensitiveString.sensitive("plain")
        XCTAssertEqual(result2?.value, "plain")
        
        // Other types return nil
        XCTAssertNil(SensitiveString.sensitive(123))
    }
    
    // MARK: - String Literal Tests
    
    func testStringLiteral() throws {
        let secret: SensitiveString = "my-secret"
        XCTAssertEqual(secret.value, "my-secret")
    }
    
    // MARK: - Codable Tests
    
    func testJSONEncoding() throws {
        struct Credentials: Codable {
            let username: String
            let password: SensitiveString
        }
        
        let creds = Credentials(
            username: "user@example.com",
            password: SensitiveString("secret123")
        )
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(creds)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("user@example.com"))
        XCTAssertTrue(jsonString.contains("sha256:"))
        XCTAssertFalse(jsonString.contains("secret123"))
    }
    
    func testJSONDecoding() throws {
        struct Credentials: Codable {
            let username: String
            let password: SensitiveString
        }
        
        let jsonString = """
        {
            "username": "user@example.com",
            "password": "decoded-value"
        }
        """
        
        let decoder = JSONDecoder()
        let jsonData = jsonString.data(using: .utf8)!
        let creds = try decoder.decode(Credentials.self, from: jsonData)
        
        XCTAssertEqual(creds.username, "user@example.com")
        XCTAssertEqual(creds.password.value, "decoded-value")
    }
    
    func testPropertyListEncoding() throws {
        struct Config: Codable {
            let apiKey: SensitiveString
        }
        
        let config = Config(apiKey: SensitiveString("secret-key"))
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let plistData = try encoder.encode(config)
        let plistString = String(data: plistData, encoding: .utf8)!
        
        XCTAssertTrue(plistString.contains("sha256:"))
        XCTAssertFalse(plistString.contains("secret-key"))
    }
}

