import XCTest

@testable import JSON

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
    func testJSONValue() throws {
        let aString = "Hello!"
        let aNumber = 5.0
        let aBool = false
        
        let json: any JSONValue = [
            "bool": false,
            "number": 5,
            "string": aString,
            "array": [
                true,
                aNumber,
                aBool,
                null,
                "Hello again!"
            ],
            "object": [
                "number": 2.6,
                "string": "Nested Hello!"
            ]
        ]
        
        var jsonErased = json.jsonErased
                        
        let test = jsonErased.object
        let test2 = test?
            .string
        
        let data = jsonErased.prettyPrinted
        
        jsonErased.object?.number = 5.jsonErased
        
        print("TEST")
    }
    
    func testJSONRepresentable() throws {
        let jsonRepresentable: any JSONRepresentable = [
            "bool": false,
            "number": 5,
            "string": "dewd",
            "array": [
                true,
                5,
                false,
                null,
                "Hello!"
            ],
            "object": [
                "number": 2.6,
                "string": "Whoa!"
            ],
            "embedded": TestStruct(
                intValue: 8,
                stringValue: "bruh",
                innerValue: .init(
                    floatValue: 2.5,
                    innerIntValue: 19
                )
            )
        ]
        
        let json = try jsonRepresentable
            .jsonValue
        
        let jsonified = try TestStruct(
            intValue: 8,
            stringValue: "bruh",
            innerValue: .init(
                floatValue: 2.5,
                innerIntValue: 19
            )
        ).jsonValue
        
        let unjsonified = try TestStruct(json: jsonified)
        
        print("TEST")
    }
}
