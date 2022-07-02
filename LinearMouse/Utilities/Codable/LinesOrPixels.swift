// MIT License
// Copyright (c) 2021-2022 Jiahao Lu

import Foundation

/// Accepts lines (e.g. 3) or pixels (e.g. "12px").
enum LinesOrPixels {
    case line(Int)
    case pixel(Decimal)
}

extension LinesOrPixels: CustomStringConvertible {
    var description: String {
        switch self {
        case let .line(value):
            return String(value)
        case let .pixel(value):
            return "\(value)px"
        }
    }
}

extension LinesOrPixels: Codable {
    enum ValueError: Error {
        case invalidValue
        case unknownUnit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let value = try container.decode(Int.self)
            self = .line(value)
        } catch {
            let stringValue = try container.decode(String.self)
            let regex = try NSRegularExpression(pattern: #"^([\d.]+)(px|)$"#, options: [])

            let matches = regex.matches(
                in: stringValue,
                range: NSRange(stringValue.startIndex ..< stringValue.endIndex, in: stringValue)
            )
            guard let match = matches.first else {
                throw CustomDecodingError(in: container, error: ValueError.invalidValue)
            }

            guard let valueRange = Range(match.range(at: 1), in: stringValue) else {
                throw ValueError.invalidValue
            }

            guard let unitRange = Range(match.range(at: 2), in: stringValue) else {
                throw ValueError.invalidValue
            }

            let valueString = String(stringValue[valueRange])
            let unitString = String(stringValue[unitRange])

            switch unitString {
            case "":
                guard let value = Int(valueString, radix: 10) else {
                    throw ValueError.invalidValue
                }

                self = .line(value)

            case "px":
                guard let value = Decimal(string: valueString) else {
                    throw ValueError.invalidValue
                }

                self = .pixel(value)

            default:
                throw ValueError.unknownUnit
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .line(value):
            try container.encode(value)
        case let .pixel(value):
            try container.encode("\(value)px")
        }
    }
}

extension LinesOrPixels.ValueError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidValue:
            return NSLocalizedString(
                "LinesOrPixels must be a number or a string representing value and unit",
                comment: ""
            )
        case .unknownUnit:
            return NSLocalizedString("Unit must be empty or \"px\"", comment: "")
        }
    }
}
