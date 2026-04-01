import Foundation

enum APICoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

struct AnyCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decode<T: Decodable>(_ type: T.Type, forAnyKey keys: [String]) throws -> T {
        for key in keys {
            if let value = try decodeIfPresent(type, forKey: AnyCodingKey(key)) {
                return value
            }
        }

        throw DecodingError.keyNotFound(
            AnyCodingKey(keys.first ?? "unknown"),
            .init(codingPath: codingPath, debugDescription: "Missing keys: \(keys.joined(separator: ", "))")
        )
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forAnyKey keys: [String]) throws -> T? {
        for key in keys {
            if let value = try decodeIfPresent(type, forKey: AnyCodingKey(key)) {
                return value
            }
        }
        return nil
    }
}
