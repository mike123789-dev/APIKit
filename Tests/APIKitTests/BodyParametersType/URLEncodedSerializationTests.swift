import Foundation
import XCTest
import APIKit

class URLEncodedSerializationTests: XCTestCase {
    // MARK: NSData -> Any
    func testObjectFromData() throws {
        let data = try XCTUnwrap("key1=value1&key2=value2".data(using: .utf8))
        let object = try? URLEncodedSerialization.object(from: data, encoding: .utf8)
        XCTAssertEqual(object?["key1"], "value1")
        XCTAssertEqual(object?["key2"], "value2")
    }
    
    func testObjectFromArray() {
        let parameters: [String : Any] = ["foo": "bar", "array" : ["first", "second"]]
        let serailizedString = URLEncodedSerialization.string(from: parameters)
        XCTAssertTrue(serailizedString.contains("foo=bar"))
        XCTAssertTrue(serailizedString.contains("array=first"))
        XCTAssertTrue(serailizedString.contains("array=second"))
    }

    func testInvalidFormatString() throws {
        let string = "key==value&"

        let data = try XCTUnwrap(string.data(using: .utf8))
        XCTAssertThrowsError(try URLEncodedSerialization.object(from: data, encoding: .utf8)) { error in
            guard let error = error as? URLEncodedSerialization.Error,
                  case .invalidFormatString(let invalidString) = error else {
                XCTFail()
                return
            }

            XCTAssertEqual(string, invalidString)
        }
    }

    func testInvalidString() {
        var bytes = [UInt8]([0xed, 0xa0, 0x80]) // U+D800 (high surrogate)
        let data = Data(bytes: &bytes, count: bytes.count)

        XCTAssertThrowsError(try URLEncodedSerialization.object(from: data, encoding: .utf8)) { error in
            guard let error = error as? URLEncodedSerialization.Error,
                  case .cannotGetStringFromData(let invalidData, let encoding) = error else {
                XCTFail()
                return
            }

            XCTAssertEqual(data, invalidData)
            XCTAssertEqual(encoding, .utf8)
        }
    }

    // MARK: Any -> NSData
    func testDataFromObject() {
        let object = ["hey": "yo"] as Any
        let data = try? URLEncodedSerialization.data(from: object, encoding: .utf8)
        let string = data.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(string, "hey=yo")
    }

    func testNonDictionaryObject() {
        let dictionaries = [["hey": "yo"]] as Any

        XCTAssertThrowsError(try URLEncodedSerialization.data(from: dictionaries, encoding: .utf8)) { error in
            guard let error = error as? URLEncodedSerialization.Error,
                  case .cannotCastObjectToDictionary(let object) = error else {
                XCTFail()
                return
            }

            XCTAssertEqual((object as AnyObject)["hey"], (dictionaries as AnyObject)["hey"])
        }
    }
}
