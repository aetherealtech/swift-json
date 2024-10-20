import Foundation

public protocol JSONRepresentable {
    var jsonValue: any JSONValue { get throws }
}

public protocol JSONValue {
    var jsonErased: AnyJSONValue { get }
}

//public extension JSONRepresentable where Self: JSONValue {
//    var jsonValue: any JSONValue { jsonErased.unwrapped }
//}

public struct Null: JSONRepresentable, JSONValue, Codable, Sendable {
    fileprivate init() {}

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard container.decodeNil() else {
            throw DecodingError.typeMismatch(Null.self, .init(codingPath: container.codingPath, debugDescription: "Expected nil"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
    
    public var jsonErased: AnyJSONValue { .null }
    
    public var jsonValue: any JSONValue { self }
}

public let null = Null()

extension Bool: JSONRepresentable, JSONValue { public var jsonErased: AnyJSONValue { .bool(self) }; public var jsonValue: any JSONValue { self } }
extension Double: JSONRepresentable, JSONValue { public var jsonErased: AnyJSONValue { .number(self) }; public var jsonValue: any JSONValue { self } }
extension String: JSONRepresentable, JSONValue { public var jsonErased: AnyJSONValue { .string(self) }; public var jsonValue: any JSONValue { self } }

public typealias JSONArray = [any JSONValue]
public typealias JSONObject = [String: any JSONValue]

//public extension BinaryInteger { var jsonValue: any JSONValue { Double(self) } }
//public extension BinaryFloatingPoint { var jsonValue: any JSONValue { Double(self) } }
//
//extension Int: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension Int8: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension Int16: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension Int32: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension Int64: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//
//@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
//extension Int128: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//
//extension UInt: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension UInt8: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension UInt16: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension UInt32: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension UInt64: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//
//@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
//extension UInt128: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//
//extension Float: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }
//extension Float80: JSONRepresentable { public var jsonValue: any JSONValue { Double(self) } }

public extension JSONValue {
//    func encode(to encoder: any Encoder) throws {
//        try jsonErased.encode(to: encoder)
//    }
    
//    func hash(into hasher: inout Hasher) {
//        jsonErased.hash(into: &hasher)
//    }
}

public typealias JSONArrayRepresentable = [any JSONRepresentable]
public typealias JSONObjectRepresentable = [String: any JSONRepresentable]

extension (any JSONRepresentable)?: JSONRepresentable {
    public var jsonValue: any JSONValue { get throws { try self?.jsonValue ?? null } }
}

//extension (any JSONValue)?: JSONValue {
//    public var jsonErased: AnyJSONValue {
//        if let self {
//            self.jsonErased
//        } else {
//            .null
//        }
//    }
//    
//    public init(from decoder: any Decoder) throws {
//        if let boolValue = try? Bool(from: decoder) {
//            self = boolValue
//        } else if let numberValue = try? Double(from: decoder) {
//            self = numberValue
//        } else if let stringValue = try? String(from: decoder) {
//            self = stringValue
//        } else if let arrayValue = try? JSONArray(from: decoder) {
//            self = arrayValue
//        } else if let objectValue = try? JSONObject(from: decoder) {
//            self = objectValue
//        } else {
//            let container = try decoder.singleValueContainer()
//            
//            if container.decodeNil() {
//                self = nil
//            } else {
//                throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: ""))
//            }
//        }
//    }
//    
////    public var description: String {
////        if let self {
////            self.description
////        } else {
////            "NULL"
////        }
////    }
//    
//    public func encode(to encoder: any Encoder) throws {
//        if let self {
//            try self.jsonErased.encode(to: encoder)
//        } else {
//            var container = encoder.singleValueContainer()
//            try container.encodeNil()
//        }
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        if let self {
//            self.jsonErased.hash(into: &hasher)
//        }
//    }
//    
////    public subscript(dynamicMember key: String) -> (any JSONValue)? {
////        _read {
////            yield self?[dynamicMember: key]
////        }
////        _modify {
////            yield &self![dynamicMember: key]
////        }
////    }
//}

//public func == (lhs: any JSONValue, rhs: any JSONValue) -> Bool {
//    lhs.jsonErased == rhs.jsonErased
//}
//
//public func != (lhs: any JSONValue, rhs: any JSONValue) -> Bool {
//    !(lhs == rhs)
//}
//
//public func == (lhs: (any JSONValue)?, rhs: (any JSONValue)?) -> Bool {
//    if let lhs {
//        guard let rhs else {
//            return false
//        }
//        
//        return lhs == rhs
//    } else {
//        return rhs == nil
//    }
//}
//
//public func != (lhs: (any JSONValue)?, rhs: (any JSONValue)?) -> Bool {
//    !(lhs == rhs)
//}

extension JSONArrayRepresentable: JSONRepresentable {
    public var jsonValue: any JSONValue {
        get throws {
            try map { try $0.jsonValue }
        }
    }
}

extension JSONArray: JSONValue {
    public var jsonValue: any JSONValue { self }
    
    public var jsonErased: AnyJSONValue {
        .array(self)
    }
    
    public init(from decoder: any Decoder) throws {
        self.init()
        
        var container = try decoder.unkeyedContainer()
        
        while !container.isAtEnd {
            append(try container.decode(AnyJSONValue.self).unwrapped)
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        for element in self {
            try container.encode(element.jsonErased)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.elementsEqual(rhs) { lhs, rhs in lhs.jsonErased == rhs.jsonErased }
    }
    
    public func hash(into hasher: inout Hasher) {
        for element in self {
            element.jsonErased.hash(into: &hasher)
        }
    }
}

extension JSONObjectRepresentable: JSONRepresentable {
    public var jsonValue: any JSONValue {
        get throws {
            try mapValues { try $0.jsonValue }
        }
    }
}

extension JSONObject: JSONValue {
    public var jsonValue: any JSONValue { self }
    
    public var jsonErased: AnyJSONValue {
        .object(self)
    }
    
    struct CodingKeys: CodingKey {
        var stringValue: String
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { nil }
        
        init?(intValue: Int) {
            nil
        }
    }
    
    public init(from decoder: any Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        for key in container.allKeys {
            self[key.stringValue] = try container.decode(AnyJSONValue.self, forKey: key).unwrapped
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        for (key, value) in self {
            try container.encode(value.jsonErased, forKey: .init(stringValue: key)!)
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.keys == rhs.keys else {
            return false
        }
        
        for key in lhs.keys where lhs[key]?.jsonErased != rhs[key]?.jsonErased {
            return false
        }
        
        return true
    }
    
    public func hash(into hasher: inout Hasher) {
        for (key, value) in self {
            key.hash(into: &hasher)
            value.jsonErased.hash(into: &hasher)
        }
    }
}

@dynamicMemberLookup
public enum AnyJSONValue: JSONRepresentable, Codable, Hashable, CustomStringConvertible {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array(JSONArray)
    case object(JSONObject)
    
    public init(from decoder: any Decoder) throws {
        if let boolValue = try? Bool(from: decoder) {
            self = .bool(boolValue)
        } else if let numberValue = try? Double(from: decoder) {
            self = .number(numberValue)
        } else if let stringValue = try? String(from: decoder) {
            self = .string(stringValue)
        } else if let arrayValue = try? JSONArray(from: decoder) {
            self = .array(arrayValue)
        } else if let objectValue = try? JSONObject(from: decoder) {
            self = .object(objectValue)
        } else {
            let container = try decoder.singleValueContainer()
            
            if container.decodeNil() {
                self = .null
            } else {
                throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: ""))
            }
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        switch self {
            case .null: var container = encoder.singleValueContainer(); try container.encodeNil()
            case let .bool(bool): try bool.encode(to: encoder)
            case let .number(number): try number.encode(to: encoder)
            case let .string(string): try string.encode(to: encoder)
            case let .array(array): try array.encode(to: encoder)
            case let .object(object): try object.encode(to: encoder)
        }
    }
    
    public var unwrapped: any JSONValue {
        switch self {
            case .null: Null()
            case let .bool(bool): bool
            case let .number(number): number
            case let .string(string): string
            case let .array(array): array
            case let .object(object): object
        }
    }
    
    var type: String {
        switch self {
            case .null: return "null"
            case .bool: return "bool"
            case .number: return "number"
            case .string: return "string"
            case .array: return "array"
            case .object: return "object"
        }
    }
    
    public var description: String {
        switch self {
            case .null: "NULL"
            case let .bool(bool): bool.description
            case let .number(number): number.description
            case let .string(string): string.description
            case let .array(array): array.description
            case let .object(object): object.description
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch lhs {
            case .null:
                if case .null = rhs { return true} else { return false }
            case let .bool(lhs):
                if case let .bool(rhs) = rhs { return lhs == rhs } else { return false }
            case let .number(lhs):
                if case let .number(rhs) = rhs { return lhs == rhs } else { return false }
            case let .string(lhs):
                if case let .string(rhs) = rhs { return lhs == rhs } else { return false }
            case let .array(lhs):
                if case let .array(rhs) = rhs { return lhs == rhs } else { return false }
            case let .object(lhs):
                if case let .object(rhs) = rhs { return lhs == rhs } else { return false }
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
            case .null:
                break
            case let .bool(bool):
                bool.hash(into: &hasher)
            case let .number(number):
                number.hash(into: &hasher)
            case let .string(string):
                string.hash(into: &hasher)
            case let .array(array):
                array.hash(into: &hasher)
            case let .object(object):
                object.hash(into: &hasher)
        }
    }
    
    subscript(position: Int) -> AnyJSONValue {
        get {
            guard case let .array(jsonArray) = self else {
                fatalError("Invalid subscript, JSON element is not an array")
            }
            
            return jsonArray[position].jsonErased
        }
        set {
            guard case var .array(jsonArray) = self else {
                fatalError("Invalid subscript, JSON element is not an array")
            }
            
            jsonArray[position] = newValue.unwrapped
            
            self = .array(jsonArray)
        }
    }
    
    subscript(key: String) -> AnyJSONValue? {
        get {
            guard case let .object(jsonObject) = self else {
                return .null
            }
            
            return jsonObject[key]?.jsonErased
        }
        set {
            guard case var .object(jsonObject) = self else {
                fatalError("Invalid subscript, JSON element is not an object")
            }
            
            jsonObject[key] = newValue?.unwrapped
            
            self = .object(jsonObject)
        }
    }
    
    subscript(dynamicMember key: String) -> AnyJSONValue? {
        _read {
            yield self[key]
        }
        _modify {
            yield &self[key]
        }
    }
    
    public var jsonValue: any JSONValue { unwrapped }
}

public extension Encodable {
    var jsonValue: any JSONValue {
        get throws {
            try JSONValueEncoder().encode(self)
        }
    }
}

public extension Decodable {
    init(json: some JSONValue) throws {
        self = try JSONValueDecoder().decode(Self.self, from: json)
    }
}

public enum JSONError: LocalizedError {
    case invalidType(Any.Type)
    
    public var errorDescription: String? {
        switch self {
            case let .invalidType(type): return "Value of type \(type) is not a valid JSONElement"
        }
    }
}

//public extension JSONValue {
//    subscript(position: Int) -> (any JSONValue)? {
//        _read {
//            yield nil
//        }
//        _modify {
//            fatalError("Invalid subscript, JSON element is not an array")
//        }
//    }
//    
//    subscript(key: String) -> (any JSONValue)? {
//        _read {
//            yield nil
//        }
//        _modify {
//            fatalError("Invalid subscript, JSON element is not an object")
//        }
//    }
//    
//    subscript(dynamicMember key: String) -> (any JSONValue)? {
//        _read {
//            yield self[key]
//        }
//        _modify {
//            yield &self[key]
//        }
//    }
//}

public extension JSONValue {
    func data(pretty: Bool) -> Data {
        data(encoder: pretty ? JSONEncoder.withPrettyPrinting : JSONEncoder())
    }

    func data(encoder: JSONEncoder) -> Data {
        try! encoder.encode(jsonErased)
    }

    var data: Data { data(pretty: false) }
    var prettyData: Data { data(pretty: true) }

    func printed(pretty: Bool) -> String {
        .init(data: data(pretty: pretty), encoding: .utf8)!
    }

    var printed: String { printed(pretty: false) }
    var prettyPrinted: String { printed(pretty: true) }
}

public extension JSONValue {
    var debugDescription: String {
        switch jsonErased {
            case .null: return "null"
            case let .bool(value): return "\(value)"
            case let .number(value): return "\(value)"
            case let .string(value): return "'\(value)'"
            case let .array(value): return "\(value.map(\.debugDescription))"
            case let .object(value): return "\(value.mapValues(\.debugDescription))"
        }
    }

    func jsonData(pretty: Bool) -> Data {
        data(encoder: pretty ? JSONEncoder.withPrettyPrinting : JSONEncoder())
    }

    func jsonData(encoder: JSONEncoder) -> Data {
        try! encoder.encode(jsonErased)
    }

    var jsonData: Data { data(pretty: false) }
    var prettyJSONData: Data { data(pretty: true) }

    func jsonPrinted(pretty: Bool) -> String {
        .init(data: data(pretty: pretty), encoding: .utf8)!
    }

    var jsonPrinted: String { printed(pretty: false) }
    var prettyJSONPrinted: String { printed(pretty: true) }
}

public extension JSONEncoder {
    static var withPrettyPrinting: JSONEncoder {
        let result = JSONEncoder()
        result.outputFormatting = .prettyPrinted
        return result
    }
}
