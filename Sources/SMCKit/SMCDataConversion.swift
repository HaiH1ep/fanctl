import Foundation

// MARK: - Four-character code conversion

public func fourCharCode(_ key: String) -> UInt32 {
    var result: UInt32 = 0
    for char in key.utf8.prefix(4) {
        result = (result << 8) | UInt32(char)
    }
    return result
}

public func fourCharCodeToString(_ code: UInt32) -> String {
    let bytes = [
        UInt8((code >> 24) & 0xFF),
        UInt8((code >> 16) & 0xFF),
        UInt8((code >> 8) & 0xFF),
        UInt8(code & 0xFF)
    ]
    return String(bytes: bytes, encoding: .ascii) ?? "????"
}

// MARK: - Apple Silicon float (flt) — 4-byte IEEE 754 little-endian

public func floatFromSMCBytes(_ bytes: [UInt8]) -> Float {
    guard bytes.count >= 4 else { return 0 }
    var value: Float = 0
    withUnsafeMutableBytes(of: &value) { ptr in
        ptr[0] = bytes[0]
        ptr[1] = bytes[1]
        ptr[2] = bytes[2]
        ptr[3] = bytes[3]
    }
    return value
}

public func smcBytesFromFloat(_ value: Float) -> [UInt8] {
    var v = value
    return withUnsafeBytes(of: &v) { Array($0) }
}

// MARK: - Intel fixed-point formats (for completeness)

public func floatFromFPE2(_ bytes: [UInt8]) -> Float {
    guard bytes.count >= 2 else { return 0 }
    let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
    return Float(raw) / 4.0
}

public func floatFromSP78(_ bytes: [UInt8]) -> Float {
    guard bytes.count >= 2 else { return 0 }
    let raw = Int16(bitPattern: (UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
    return Float(raw) / 256.0
}

// MARK: - UInt8/UInt16/UInt32 from bytes

public func uint8FromBytes(_ bytes: [UInt8]) -> UInt8 {
    bytes.first ?? 0
}

public func uint16FromBytes(_ bytes: [UInt8]) -> UInt16 {
    guard bytes.count >= 2 else { return 0 }
    return (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
}

public func uint32FromBytes(_ bytes: [UInt8]) -> UInt32 {
    guard bytes.count >= 4 else { return 0 }
    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}

// MARK: - Generic SMCVal decoder

public func decodeSmcValue(_ val: SMCVal) -> Float {
    switch val.dataType {
    case "flt ":
        return floatFromSMCBytes(val.bytes)
    case "fpe2":
        return floatFromFPE2(val.bytes)
    case "sp78":
        return floatFromSP78(val.bytes)
    case "ui8 ":
        return Float(uint8FromBytes(val.bytes))
    case "ui16":
        return Float(uint16FromBytes(val.bytes))
    case "ui32":
        return Float(uint32FromBytes(val.bytes))
    default:
        return floatFromSMCBytes(val.bytes)
    }
}
