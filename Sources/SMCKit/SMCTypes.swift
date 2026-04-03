import Foundation
import IOKit

// MARK: - SMC Command Constants

public enum SMCCommand: UInt8 {
    case readBytes    = 5
    case writeBytes   = 6
    case getKeyCount  = 7
    case readIndex    = 8
    case readKeyInfo  = 9
}

public let kSMCIOKitSelector: UInt32 = 2

// MARK: - SMC Data Type Constants

public enum SMCDataType: String {
    case flt  = "flt "   // IEEE 754 float (Apple Silicon)
    case ui8  = "ui8 "   // UInt8
    case ui16 = "ui16"   // UInt16
    case ui32 = "ui32"   // UInt32
    case sp78 = "sp78"   // Signed 8.8 fixed-point (Intel)
    case fpe2 = "fpe2"   // Unsigned 14.2 fixed-point (Intel)
    case ch8  = "ch8*"   // C string
    case flag = "flag"   // Boolean flag
}

// MARK: - SMC Structs (must match kernel's 80-byte layout exactly)

public struct SMCKeyData_vers_t {
    public var major: UInt8 = 0
    public var minor: UInt8 = 0
    public var build: UInt8 = 0
    public var reserved: UInt8 = 0
    public var release: UInt16 = 0

    public init() {}
}

public struct SMCKeyData_pLimitData_t {
    public var version: UInt16 = 0
    public var length: UInt16 = 0
    public var cpuPLimit: UInt32 = 0
    public var gpuPLimit: UInt32 = 0
    public var memPLimit: UInt32 = 0

    public init() {}
}

public struct SMCKeyData_keyInfo_t {
    public var dataSize: UInt32 = 0
    public var dataType: UInt32 = 0
    public var dataAttributes: UInt8 = 0
    // Explicit padding to match kernel struct layout (12 bytes total, not 9)
    public var _pad0: UInt8 = 0
    public var _pad1: UInt8 = 0
    public var _pad2: UInt8 = 0

    public init() {}
}

public struct SMCKeyData_t {
    public var key: UInt32 = 0
    public var vers: SMCKeyData_vers_t = SMCKeyData_vers_t()
    public var pLimitData: SMCKeyData_pLimitData_t = SMCKeyData_pLimitData_t()
    public var keyInfo: SMCKeyData_keyInfo_t = SMCKeyData_keyInfo_t()
    public var result: UInt8 = 0
    public var status: UInt8 = 0
    public var data8: UInt8 = 0
    public var data32: UInt32 = 0
    public var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                       UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                       UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                       UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    public init() {}
}

// MARK: - High-level SMC Value

public struct SMCVal {
    public var key: String
    public var dataSize: UInt32
    public var dataType: String
    public var bytes: [UInt8]

    public init(key: String = "", dataSize: UInt32 = 0, dataType: String = "", bytes: [UInt8] = []) {
        self.key = key
        self.dataSize = dataSize
        self.dataType = dataType
        self.bytes = bytes
    }
}

// MARK: - SMC Errors

public enum SMCError: Error, LocalizedError {
    case driverNotFound
    case failedToOpen
    case keyNotFound(String)
    case readFailed(String, kern_return_t)
    case writeFailed(String, kern_return_t)
    case typeMismatch(expected: String, got: String)

    public var errorDescription: String? {
        switch self {
        case .driverNotFound:
            return "AppleSMC driver not found"
        case .failedToOpen:
            return "Failed to open connection to AppleSMC"
        case .keyNotFound(let key):
            return "SMC key not found: \(key)"
        case .readFailed(let key, let code):
            return "Failed to read SMC key \(key): \(code)"
        case .writeFailed(let key, let code):
            return "Failed to write SMC key \(key): \(code)"
        case .typeMismatch(let expected, let got):
            return "Type mismatch: expected \(expected), got \(got)"
        }
    }
}
