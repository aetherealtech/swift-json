import Assertions
import JSON
import XCTest

@testable import JSONPredicate

struct TestStruct: Hashable, Codable {
    struct InnerStruct: Hashable, Codable {
        let floatValue: Double
        let innerIntValue: Int
    }
    
    let intValue: Int
    let stringValue: String
    let innerValue: InnerStruct
}

extension TestStruct: JSONRepresentable {}

final class JSONTests: XCTestCase {
    func testExample() throws {
        let json: any JSONValue = [
            "bool": false,
            "number": 5,
            "string": "dewd",
            "array": [
                true,
                5,
                false,
                null,
                "eww"
            ],
            "object": [
                "number": 2.6,
                "string": "Whoa!"
            ]
        ]
        
        let jsonPredicate: JSONPredicate = .object([
            "bool": .exactly(false),
            "number": .greaterThan(3),
            "string": .stringContaining("de"),
            "array": .array([
                .exactly(true),
                .lessThan(5),
                .exactly(false),
                .null(),
                .exactly("eww")
            ]),
            "object": .object([
//                "number": .lessThan(3),
                "string": .stringContaining("hos")
            ])
        ])
        
        try assertMatches(json, jsonPredicate)
    }
}
