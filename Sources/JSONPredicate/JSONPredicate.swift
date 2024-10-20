import Assertions
import CollectionExtensions
import Foundation
import JSON
import NumericExtensions

public typealias JSONArrayPredicate = [JSONPredicate]
public typealias JSONObjectPredicate = [String: JSONPredicate]

public struct JSONPredicate: CustomDebugStringConvertible {
    struct Mismatch {
        let path: [String]
        let description: String
    }
    
    private let description: String
    private let matcher: (_ path: [String], _ value: any JSONValue) -> [Mismatch]

    init(description: String, matcher: @escaping ([String], any JSONValue) -> [Mismatch]) {
        self.description = description
        self.matcher = matcher
    }
    
    init(description: String, matcher: @escaping (any JSONValue) -> String?) {
        self.description = description
        self.matcher = { path, value in
            if let result = matcher(value) {
                return [.init(path: path, description: result)]
            } else {
                return []
            }
        }
    }

    public static func exactly(_ expectedElement: (any JSONValue)?) -> JSONPredicate {
        .init(description: "\(expectedElement.debugDescription)") { actualElement in
            guard actualElement.jsonErased == (expectedElement?.jsonErased ?? .null) else {
                return "\(expectedElement.debugDescription) != '\(actualElement.debugDescription)'"
            }

            return nil
        }
    }

    public static func null() -> JSONPredicate {
        .init(description: "is null") { actualElement in
            guard actualElement is Null else {
                return "Expected null, got '\(actualElement.debugDescription)'"
            }

            return nil
        }
    }

    public static func number(
        description: String,
        _ numberPredicate: @escaping (Double) -> Bool,
        mismatchMessage: @escaping (Double) -> String
    ) -> JSONPredicate {
        .init(description: description) { actualElement in
            guard let actualNumber = actualElement as? Double else {
                return "Expected a number, got a \(Swift.type(of: actualElement))"
            }

            guard numberPredicate(actualNumber) else {
                return mismatchMessage(actualNumber)
            }
            
            return nil
        }
    }
    
    static func number<Integer: BinaryInteger>(
        description: String,
        _ numberPredicate: @escaping (Integer) -> Bool,
        mismatchMessage: @escaping (Double) -> String
    ) -> JSONPredicate {
        number(
            description: description,
            { (actualNumber: Double) in numberPredicate(.init(actualNumber)) },
            mismatchMessage: mismatchMessage
        )
    }
    
    static func number<FloatingPoint: BinaryFloatingPoint>(
        description: String,
        _ numberPredicate: @escaping (FloatingPoint) -> Bool,
        mismatchMessage: @escaping (Double) -> String
    ) -> JSONPredicate {
        number(
            description: description,
            { (actualNumber: Double) in numberPredicate(.init(actualNumber)) },
            mismatchMessage: mismatchMessage
        )
    }

    public static func string(
        description: String,
        _ stringPredicate: @escaping (String) -> Bool,
        mismatchMessage: @escaping (String) -> String
    ) -> JSONPredicate {
        JSONPredicate(description: description) { actualElement in
            guard let actualString = actualElement as? String else {
                return "Expected a string, got a \(Swift.type(of: actualElement))"
            }
            
            guard stringPredicate(actualString) else {
                return mismatchMessage(actualString)
            }
            
            return nil
        }
    }

    public static func array(
        _ expectedArray: JSONArrayPredicate
    ) -> JSONPredicate {
        JSONPredicate(description: "\(expectedArray)") { path, actualElement in
            guard let actualArray = actualElement as? JSONArray else {
                return [.init(path: path, description: "Expected an array, got a \(Swift.type(of: actualElement))")]
            }

            var mismatches: [Mismatch] = []

            for index in 0 ..< (Swift.max(expectedArray.count, actualArray.count)) {                
                let expectedValue = expectedArray[safe: index]
                let actualValue = actualArray[safe: index]

                guard let actualValue else {
                    mismatches.append(.init(path: path, description: "- \(index): \(expectedValue!)"))
                    continue
                }

                guard let expectedValue else {
                    mismatches.append(.init(path: path, description: "+ \(index): \(actualValue)"))
                    continue
                }
                
                mismatches.append(contentsOf: expectedValue.matcher(path.appending(index.description), actualValue))
            }

            return mismatches
        }
    }
    
    public static func object(
        _ expectedObject: JSONObjectPredicate
    ) -> JSONPredicate {
        JSONPredicate(description: "\(expectedObject)") { path, actualElement in
            guard let actualObject = actualElement as? JSONObject else {
                return [.init(path: path, description: "Expected an object, got a \(Swift.type(of: actualElement))")]
            }

            let expectedKeys = expectedObject.keys.store(in: Set.self)
            let actualKeys = actualObject.keys.store(in: Set.self)

            var mismatches: [Mismatch] = []
            
            let missingKeys = expectedKeys.removingAll(of: actualKeys)
            let extraKeys = actualKeys.removingAll(of: expectedKeys)

            for missingKey in missingKeys {
                mismatches.append(.init(path: path, description: "- \(missingKey): \(expectedObject[missingKey]!)"))
            }
            
            for extraKey in extraKeys {
                mismatches.append(.init(path: path, description: "+ \(extraKey): \(actualObject[extraKey]!)"))
            }

            for (key, expectedValue) in expectedObject {
                let path = path.appending(key)
                
                mismatches.append(contentsOf: expectedValue.matcher(path, actualObject[key]!))
            }
            
            return mismatches
        }
    }

    public func mismatches(with value: any JSONValue) -> String? {
        let mismatches = matcher([], value)
        
        if mismatches.isEmpty {
            return nil
        }
        
        return mismatches
            .map { mismatch in
                let path = mismatch.path
                let description = mismatch.description
                
                if path.isEmpty {
                    return description
                } else {
                    return "\(path.joined(separator: ".")): \(description)"
                }
            }
            .joined(separator: "\n")
    }

    public var debugDescription: String {
        description
    }
}

public func assertMatches(
    _ value: any JSONValue,
    _ matcher: JSONPredicate,
    message: @autoclosure () -> String? = nil
) throws {
    if let mismatches = matcher.mismatches(with: value) {
        throw Fail("\(message() ?? "JSON does not match"):\n\n\(mismatches)")
    }
}

public extension JSONPredicate {
    static func greaterThan(_ expectedNumber: Double) -> JSONPredicate {
        number(
            description: "> \(expectedNumber)",
            { actualNumber in actualNumber > expectedNumber },
            mismatchMessage: { actualNumber in "\(actualNumber) <= \(expectedNumber)" }
        )
    }
    
    static func lessThan(_ expectedNumber: Double) -> JSONPredicate {
        number(
            description: "< \(expectedNumber)",
            { actualNumber in actualNumber < expectedNumber },
            mismatchMessage: { actualNumber in "\(actualNumber) >= \(expectedNumber)" }
        )
    }
    
    static func approximately(_ expectedNumber: Double, tolerance: Double) -> JSONPredicate {
        number(
            description: "\(expectedNumber) +/- \(tolerance)",
            { actualNumber in actualNumber.isApproximately(expectedNumber, tolerance: tolerance) },
            mismatchMessage: { actualNumber in "\(actualNumber) != \(expectedNumber) +/- \(tolerance)" }
        )
    }

    static func approximately(_ expectedValue: Double?, tolerance: Double) -> JSONPredicate {
        if let expectedValue {
            approximately(expectedValue, tolerance: tolerance)
        } else {
            null()
        }
    }
}

public extension JSONPredicate {
    static func stringContaining(_ expectedValue: String) -> JSONPredicate {
        string(
            description: "contains \(expectedValue)",
            { actualValue in actualValue.contains(expectedValue) },
            mismatchMessage: { actualValue in "\"\(actualValue)\" does not contain \"\(expectedValue)\"" }
        )
    }
}

public extension JSONPredicate {
    static func date(
        description: String,
        formatter: DateFormatter,
        _ stringPredicate: @escaping (Date) -> Bool,
        mismatchMessage: @escaping (Date) -> String
    ) -> JSONPredicate {
        JSONPredicate(description: description) { actualElement in
            guard let actualString = actualElement as? String, let actualDate = formatter.date(from: actualString) else {
                return "Expected a string, got a \(Swift.type(of: actualElement))"
            }
            
            guard !stringPredicate(actualDate) else {
                return mismatchMessage(actualDate)
            }
            
            return nil
        }
    }
    
    static func dateInRange(_ range: Range<Date>, formatter: DateFormatter) -> JSONPredicate {
        date(
            description: "\(range)",
            formatter: formatter,
            { actualDate in
                // Don't use .contains, because that doesn't include the boundaries
                actualDate >= range.lowerBound && actualDate <= range.upperBound
            },
            mismatchMessage: { actualDate in "\(range) does not contain \(actualDate)" }
        )
    }
}
