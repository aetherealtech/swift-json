import Combine
import CollectionExtensions

public struct JSONValueEncoder: TopLevelEncoder {
    public func encode<T: Encodable>(_ value: T) throws -> any JSONValue {
        let encoder = Encoder()
        try value.encode(to: encoder)
        return encoder.result
    }
    
    @propertyWrapper
    struct Result<T> {
        var wrappedValue: T {
            get { self.get() }
            nonmutating set { self.set(newValue) }
        }
        
        init(
            get: @escaping () -> T,
            set: @escaping (T) -> Void
        ) {
            self.get = get
            self.set = set
        }
        
        private let get: () -> T
        private let set: (T) -> Void
    }

    struct Encoder: Swift.Encoder {
        @Result
        private(set) var result: any JSONValue
        
        var codingPath: [any CodingKey] = []
        var userInfo: [CodingUserInfoKey : Any] = [:]
        
        init() {
            var result: (any JSONValue)?
            
            self.init(
                result: .init(
                    get: { result! },
                    set: { newValue in result = newValue }
                )
            )
        }
        
        init(
            result: Result<any JSONValue>,
            codingPath: [any CodingKey] = []
        ) {
            _result = result
            
            self.codingPath = codingPath
        }
        
        func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            result = JSONObject()
            
            return .init(KeyedContainer(
                result: .init(get: { result as! JSONObject }, set: { newValue in result = newValue }),
                codingPath: codingPath
            ))
        }
        
        func unkeyedContainer() -> any UnkeyedEncodingContainer {
            result = JSONArray()
            
            return UnkeyedContainer(
                result: .init(get: { result as! JSONArray }, set: { newValue in result = newValue }),
                codingPath: codingPath
            )
        }
        
        func singleValueContainer() -> any SingleValueEncodingContainer {
            SingleValueContainer(
                result: _result,
                codingPath: codingPath
            )
        }
    }
    
    struct SingleValueContainer: SingleValueEncodingContainer {
        @Result
        private(set) var result: any JSONValue
        
        var codingPath: [any CodingKey]
        
        mutating func encodeNil() { result = Null() }
        
        mutating func encode(_ value: Bool) { result = value }
        
        mutating func encode(_ value: Int) { encode(Double(value)) }
        mutating func encode(_ value: Int8) { encode(Double(value)) }
        mutating func encode(_ value: Int16) { encode(Double(value)) }
        mutating func encode(_ value: Int32) { encode(Double(value)) }
        mutating func encode(_ value: Int64) { encode(Double(value)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func encode(_ value: Int128) { encode(Double(value)) }
        
        mutating func encode(_ value: UInt) { encode(Double(value)) }
        mutating func encode(_ value: UInt8) { encode(Double(value)) }
        mutating func encode(_ value: UInt16) { encode(Double(value)) }
        mutating func encode(_ value: UInt32) { encode(Double(value)) }
        mutating func encode(_ value: UInt64) { encode(Double(value)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func encode(_ value: UInt128) { encode(Double(value)) }
        
        mutating func encode(_ value: Float) { encode(Double(value)) }
        mutating func encode(_ value: Double) { result = value }
        
        mutating func encode(_ value: String) { result = value }
        
        mutating func encode<T: Encodable>(_ value: T) throws {
            let encoder = Encoder(
                result: _result,
                codingPath: codingPath
            )
            
            try value.encode(to: encoder)
        }
    }
    
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        private struct _CodingKey: CodingKey {
            let index: Int
            
            init(index: Int) { self.index = index }
            
            init?(stringValue: String) { return nil }
            init?(intValue: Int) { self.init(index: intValue) }
            
            var stringValue: String { index.description }
            var intValue: Int? { index }
        }
        
        @Result
        private(set) var result: JSONArray
        
        var codingPath: [any CodingKey]
        
        var count: Int { result.count }
        
        mutating func encodeNil() { result.append(Null()) }
        
        mutating func encode(_ value: Bool) { result.append(value) }
        
        mutating func encode(_ value: Int) { encode(Double(value)) }
        mutating func encode(_ value: Int8) { encode(Double(value)) }
        mutating func encode(_ value: Int16) { encode(Double(value)) }
        mutating func encode(_ value: Int32) { encode(Double(value)) }
        mutating func encode(_ value: Int64) { encode(Double(value)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func encode(_ value: Int128) { encode(Double(value)) }
        
        mutating func encode(_ value: UInt) { encode(Double(value)) }
        mutating func encode(_ value: UInt8) { encode(Double(value)) }
        mutating func encode(_ value: UInt16) { encode(Double(value)) }
        mutating func encode(_ value: UInt32) { encode(Double(value)) }
        mutating func encode(_ value: UInt64) { encode(Double(value)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func encode(_ value: UInt128) { encode(Double(value)) }
        
        mutating func encode(_ value: Float) { encode(Double(value)) }
        mutating func encode(_ value: Double) { result.append(value) }
        
        mutating func encode(_ value: String) { result.append(value) }
        
        mutating func encode<T: Encodable>(_ value: T) throws {
            try value.encode(to: superEncoder())
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            result.append(JSONObject())
            let index = result.indices.last!
            
            return .init(KeyedContainer<NestedKey>(
                result: .init(get: { [_result] in _result.wrappedValue[index] as! JSONObject }, set: { [_result] newValue in _result.wrappedValue[index] = newValue }),
                codingPath: codingPath.appending(_CodingKey(index: index))
            ))
        }
        
        mutating func nestedUnkeyedContainer() -> any UnkeyedEncodingContainer {
            result.append(JSONArray())
            let index = result.indices.last!
            
            return UnkeyedContainer(
                result: .init(get: { [_result] in _result.wrappedValue[index] as! JSONArray }, set: { [_result] newValue in _result.wrappedValue[index] = newValue }),
                codingPath: codingPath.appending(_CodingKey(index: index))
            )
        }
        
        mutating func superEncoder() -> any Swift.Encoder {
            result.append(Null())
            let index = result.indices.last!
            
            return Encoder(
                result: .init(
                    get: { [_result] in _result.wrappedValue[index] },
                    set: { [_result] newValue in _result.wrappedValue[index] = newValue }
                ),
                codingPath: codingPath.appending(_CodingKey(index: index))
            )
        }
    }
    
    struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private struct _CodingKey: CodingKey {
            let stringValue: String
            let intValue: Int?
            
            init?(stringValue: String) {
                self.stringValue = stringValue
                self.intValue = nil
            }
            
            init?(intValue: Int) {
                self.intValue = intValue
                self.stringValue = intValue.description
            }
        }
        
        @Result
        private(set) var result: JSONObject
        
        var codingPath: [any CodingKey]
        
        mutating func encodeNil(forKey key: Key) { result[key.stringValue] = Null() }
        
        mutating func encode(_ value: Bool, forKey key: Key) { result[key.stringValue] = value }
        
        mutating func encode(_ value: Int, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: Int8, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: Int16, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: Int32, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: Int64, forKey key: Key) { encode(Double(value), forKey: key) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func encode(_ value: Int128, forKey key: Key) { encode(Double(value), forKey: key) }
        
        mutating func encode(_ value: UInt, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: UInt8, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: UInt16, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: UInt32, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: UInt64, forKey key: Key) { encode(Double(value), forKey: key) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func encode(_ value: UInt128, forKey key: Key) { encode(Double(value), forKey: key) }
        
        mutating func encode(_ value: Float, forKey key: Key) { encode(Double(value), forKey: key) }
        mutating func encode(_ value: Double, forKey key: Key) { result[key.stringValue] = value }
        
        mutating func encode(_ value: String, forKey key: Key) { result[key.stringValue] = value }
        
        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            try value.encode(to: superEncoder(forKey: key))
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            result[key.stringValue] = JSONObject()

            return .init(KeyedContainer<NestedKey>(
                result: .init(get: { [_result] in _result.wrappedValue[key.stringValue] as! JSONObject }, set: { [_result] newValue in _result.wrappedValue[key.stringValue] = newValue }),
                codingPath: codingPath.appending(key)
            ))
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedEncodingContainer {
            result[key.stringValue] = JSONArray()
            
            return UnkeyedContainer(
                result: .init(get: { [_result] in _result.wrappedValue[key.stringValue] as! JSONArray }, set: { [_result] newValue in _result.wrappedValue[key.stringValue] = newValue }),
                codingPath: codingPath.appending(key)
            )
        }
        
        mutating func superEncoder() -> any Swift.Encoder {
            superEncoder(forSomeKey: _CodingKey(stringValue: "super")!)
        }
        
        mutating func superEncoder(forKey key: Key) -> any Swift.Encoder {
            superEncoder(forSomeKey: key)
        }
        
        private mutating func superEncoder(forSomeKey key: some CodingKey) -> any Swift.Encoder {
            result[key.stringValue] = Null()
            
            return Encoder(
                result: .init(
                    get: { [_result] in _result.wrappedValue[key.stringValue]! },
                    set: { [_result] newValue in _result.wrappedValue[key.stringValue] = newValue }
                ),
                codingPath: codingPath.appending(key)
            )
        }
    }
}

public struct JSONValueDecoder: TopLevelDecoder {
    public func decode<T: Decodable>(_ type: T.Type, from input: any JSONValue) throws -> T {
        try .init(from: Decoder(input: input))
    }

    struct Decoder: Swift.Decoder {
        let input: (any JSONValue)?
        
        var codingPath: [any CodingKey] = []
        var userInfo: [CodingUserInfoKey : Any] = [:]

        init(
            input: (any JSONValue)?,
            codingPath: [any CodingKey] = []
        ) {
            self.input = input
            self.codingPath = codingPath
        }
        
        func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> {
            .init(KeyedContainer(
                input: input,
                codingPath: codingPath
            ))
        }
        
        func unkeyedContainer() -> any UnkeyedDecodingContainer {
            UnkeyedContainer(
                input: input,
                codingPath: codingPath
            )
        }
        
        func singleValueContainer() -> any SingleValueDecodingContainer {
            SingleValueContainer(
                input: input,
                codingPath: codingPath
            )
        }
    }
    
    struct SingleValueContainer: SingleValueDecodingContainer {
        let input: (any JSONValue)?

        var codingPath: [any CodingKey]
        
        func decodeNil() -> Bool { input == nil }
        
        func decode(_ type: Bool.Type) throws -> Bool { try decodeType(type) }
        
        func decode(_ type: Int.Type) throws -> Int { .init(try decode(Double.self)) }
        func decode(_ type: Int8.Type) throws -> Int8 { .init(try decode(Double.self)) }
        func decode(_ type: Int16.Type) throws -> Int16 { .init(try decode(Double.self)) }
        func decode(_ type: Int32.Type) throws -> Int32 { .init(try decode(Double.self)) }
        func decode(_ type: Int64.Type) throws -> Int64 { .init(try decode(Double.self)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        func decode(_ type: Int128.Type) throws -> Int128 { .init(try decode(Double.self)) }
        
        func decode(_ type: UInt.Type) throws -> UInt { .init(try decode(Double.self)) }
        func decode(_ type: UInt8.Type) throws -> UInt8 { .init(try decode(Double.self)) }
        func decode(_ type: UInt16.Type) throws -> UInt16 { .init(try decode(Double.self)) }
        func decode(_ type: UInt32.Type) throws -> UInt32 { .init(try decode(Double.self)) }
        func decode(_ type: UInt64.Type) throws -> UInt64 { .init(try decode(Double.self)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        func decode(_ type: UInt128.Type) throws -> UInt128 { .init(try decode(Double.self)) }
        
        func decode(_ type: Float.Type) throws -> Float { .init(try decode(Double.self)) }
        func decode(_ type: Double.Type) throws -> Double { try decodeType(type) }
        
        func decode(_ type: String.Type) throws -> String { try decodeType(type) }
        
        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            try .init(from: Decoder(
                input: input,
                codingPath: codingPath
            ))
        }
        
        private func decodeType<T>(_ type: T.Type) throws -> T {
            guard let result = input as? T else {
                let actualType = Swift.type(of: input)
                throw DecodingError.typeMismatch(actualType, .init(codingPath: codingPath, debugDescription: "Expected a \(type) but found a \(actualType)"))
            }
            
            return result
        }
    }
    
    struct UnkeyedContainer: UnkeyedDecodingContainer {
        private struct _CodingKey: CodingKey {
            let index: Int
            
            init(index: Int) { self.index = index }
            
            init?(stringValue: String) { return nil }
            init?(intValue: Int) { self.init(index: intValue) }
            
            var stringValue: String { index.description }
            var intValue: Int? { index }
        }
        
        init(
            input: (any JSONValue)?,
            codingPath: [any CodingKey]
        ) {
            self.input = input
            self.codingPath = codingPath
        }
        
        let input: (any JSONValue)?
        private var _index = 0
        
        private var index: Int {
            mutating get {
                let result = _index
                _index += 1
                return result
            }
        }
        
        var codingPath: [any CodingKey]
        
        var count: Int? { (input as? JSONArray)?.count }
        var currentIndex: Int { _index }
        var isAtEnd: Bool { _index == count }
        
        mutating func decodeNil() throws -> Bool { try array[index] is Null }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool { try decodeType(type) }
        
        mutating func decode(_ type: Int.Type) throws -> Int { .init(try decode(Double.self)) }
        mutating func decode(_ type: Int8.Type) throws -> Int8 { .init(try decode(Double.self)) }
        mutating func decode(_ type: Int16.Type) throws -> Int16 { .init(try decode(Double.self)) }
        mutating func decode(_ type: Int32.Type) throws -> Int32 { .init(try decode(Double.self)) }
        mutating func decode(_ type: Int64.Type) throws -> Int64 { .init(try decode(Double.self)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func decode(_ type: Int128.Type) throws -> Int128 { .init(try decode(Double.self)) }
        
        mutating func decode(_ type: UInt.Type) throws -> UInt { .init(try decode(Double.self)) }
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 { .init(try decode(Double.self)) }
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 { .init(try decode(Double.self)) }
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 { .init(try decode(Double.self)) }
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 { .init(try decode(Double.self)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        mutating func decode(_ type: UInt128.Type) throws -> UInt128 { .init(try decode(Double.self)) }
        
        mutating func decode(_ type: Float.Type) throws -> Float { .init(try decode(Double.self)) }
        mutating func decode(_ type: Double.Type) throws -> Double { try decodeType(type) }
        
        mutating func decode(_ type: String.Type) throws -> String { try decodeType(type) }
        
        mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
            try .init(from: superDecoder())
        }
        
        private var array: JSONArray {
            get throws {
                guard let array = input as? JSONArray else {
                    let actualType = Swift.type(of: input)
                    throw DecodingError.typeMismatch(actualType, .init(codingPath: codingPath, debugDescription: "Expected an array but found a \(actualType)"))
                }
                
                return array
            }
        }
        
        private mutating func decodeType<T>(_ type: T.Type) throws -> T {
            guard let result = try array[index] as? T else {
                let actualType = Swift.type(of: input)
                throw DecodingError.typeMismatch(actualType, .init(codingPath: codingPath, debugDescription: "Expected a \(type) but found a \(actualType)"))
            }
            
            return result
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            let index = self.index
            
            return .init(KeyedContainer<NestedKey>(
                input: (self.input as? JSONArray)?[index],
                codingPath: codingPath.appending(_CodingKey(index: index))
            ))
        }
        
        mutating func nestedUnkeyedContainer() -> any UnkeyedDecodingContainer {
            let index = self.index
            
            return UnkeyedContainer(
                input: (self.input as? JSONArray)?[index],
                codingPath: codingPath.appending(_CodingKey(index: index))
            )
        }
        
        mutating func superDecoder() -> any Swift.Decoder {
            let index = self.index
            
            return Decoder(
                input: (self.input as? JSONArray)?[index],
                codingPath: codingPath.appending(_CodingKey(index: index))
            )
        }
    }
    
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        private struct _CodingKey: CodingKey {
            let stringValue: String
            let intValue: Int?
            
            init?(stringValue: String) {
                self.stringValue = stringValue
                self.intValue = nil
            }
            
            init?(intValue: Int) {
                self.intValue = intValue
                self.stringValue = intValue.description
            }
        }
        
        let input: (any JSONValue)?
        
        var codingPath: [any CodingKey]
        
        var allKeys: [Key] {
            (input as? JSONObject)?
                .keys
                .compactMap(Key.init(stringValue:)) ?? []
        }
        
        func contains(_ key: Key) -> Bool {
            (input as? JSONObject)?
                .keys
                .contains(key.stringValue) ?? false
        }
        
        func decodeNil(forKey key: Key) throws -> Bool { try object[key.stringValue] is Null }
        
        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try decodeType(type, forKey: key) }
        
        func decode(_ type: Int.Type, forKey key: Key) throws -> Int { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { .init(try decode(Double.self, forKey: key)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        func decode(_ type: Int128.Type, forKey key: Key) throws -> Int128 { .init(try decode(Double.self, forKey: key)) }
        
        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { .init(try decode(Double.self, forKey: key)) }
        
        @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
        func decode(_ type: UInt128.Type, forKey key: Key) throws -> UInt128 { .init(try decode(Double.self, forKey: key)) }
        
        func decode(_ type: Float.Type, forKey key: Key) throws -> Float { .init(try decode(Double.self, forKey: key)) }
        func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try decodeType(type, forKey: key) }
        
        func decode(_ type: String.Type, forKey key: Key) throws -> String { try decodeType(type, forKey: key) }
        
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            try .init(from: superDecoder(forKey: key))
        }
        
        private var object: JSONObject {
            get throws {
                guard let object = input as? JSONObject else {
                    let actualType = Swift.type(of: input)
                    throw DecodingError.typeMismatch(actualType, .init(codingPath: codingPath, debugDescription: "Expected a dictionary but found a \(actualType)"))
                }
                
                return object
            }
        }
        
        private func decodeType<T>(_ type: T.Type, forKey key: Key) throws -> T {
            guard let result = try object[key.stringValue] as? T else {
                let actualType = Swift.type(of: input)
                throw DecodingError.typeMismatch(actualType, .init(codingPath: codingPath, debugDescription: "Expected a \(type) but found a \(actualType)"))
            }
            
            return result
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            .init(KeyedContainer<NestedKey>(
                input: (input as? JSONObject)?[key.stringValue],
                codingPath: codingPath.appending(key)
            ))
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> any UnkeyedDecodingContainer {
            UnkeyedContainer(
                input: (input as? JSONObject)?[key.stringValue],
                codingPath: codingPath.appending(key)
            )
        }
        
        func superDecoder() -> any Swift.Decoder {
            superDecoder(forSomeKey: _CodingKey(stringValue: "super")!)
        }
        
        func superDecoder(forKey key: Key) -> any Swift.Decoder {
            superDecoder(forSomeKey: key)
        }
        
        private func superDecoder(forSomeKey key: some CodingKey) -> any Swift.Decoder {
            Decoder(
                input: (input as? JSONObject)?[key.stringValue],
                codingPath: codingPath.appending(key)
            )
        }
    }
}
