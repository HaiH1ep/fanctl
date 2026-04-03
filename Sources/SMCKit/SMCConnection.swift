import Foundation
import IOKit

/// Thread-safe SMC connection.
///
/// All public methods are serialized via an internal NSLock.
/// **Lock ordering**: callers must never hold an external lock that
/// an SMCConnection callback could try to acquire — this lock is
/// always the innermost in the call chain.
public final class SMCConnection: @unchecked Sendable {
    private var connection: io_connect_t = 0
    private var isOpen = false
    private let lock = NSLock()

    public init() {}

    deinit {
        if isOpen { close() }
    }

    // MARK: - Thread-safe wrapper

    private func synchronized<T>(_ work: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }

    // MARK: - Open / Close

    public func open() throws {
        try synchronized {
            let service = IOServiceGetMatchingService(
                kIOMainPortDefault,
                IOServiceMatching("AppleSMC")
            )
            guard service != IO_OBJECT_NULL else {
                throw SMCError.driverNotFound
            }
            let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
            IOObjectRelease(service)
            guard result == kIOReturnSuccess else {
                throw SMCError.failedToOpen
            }
            isOpen = true
        }
    }

    public func close() {
        synchronized {
            if isOpen {
                IOServiceClose(connection)
                connection = 0
                isOpen = false
            }
        }
    }

    // MARK: - Raw SMC call

    private func callSMC(_ input: inout SMCKeyData_t) throws -> SMCKeyData_t {
        var output = SMCKeyData_t()
        let inputSize = MemoryLayout<SMCKeyData_t>.stride
        var outputSize = MemoryLayout<SMCKeyData_t>.stride

        let result = IOConnectCallStructMethod(
            connection,
            kSMCIOKitSelector,
            &input,
            inputSize,
            &output,
            &outputSize
        )
        guard result == kIOReturnSuccess else {
            throw SMCError.readFailed(fourCharCodeToString(input.key), result)
        }
        return output
    }

    // MARK: - Get Key Info (data type and size)

    private func getKeyInfo(key: UInt32) throws -> SMCKeyData_keyInfo_t {
        var input = SMCKeyData_t()
        input.key = key
        input.data8 = SMCCommand.readKeyInfo.rawValue

        let output = try callSMC(&input)
        return output.keyInfo
    }

    // MARK: - Read Key

    public func readKey(_ key: String) throws -> SMCVal {
        try synchronized {
            let keyCode = fourCharCode(key)

            // Phase 1: Get key info
            let keyInfo = try getKeyInfo(key: keyCode)
            guard keyInfo.dataSize > 0 else {
                throw SMCError.keyNotFound(key)
            }

            // Phase 2: Read value
            var input = SMCKeyData_t()
            input.key = keyCode
            input.keyInfo = keyInfo
            input.data8 = SMCCommand.readBytes.rawValue

            let output = try callSMC(&input)

            // Extract bytes from the tuple
            let size = Int(keyInfo.dataSize)
            var bytes = [UInt8](repeating: 0, count: size)
            withUnsafeBytes(of: output.bytes) { ptr in
                for i in 0..<min(size, 32) {
                    bytes[i] = ptr[i]
                }
            }

            return SMCVal(
                key: key,
                dataSize: keyInfo.dataSize,
                dataType: fourCharCodeToString(keyInfo.dataType),
                bytes: bytes
            )
        }
    }

    // MARK: - Write Key

    public func writeKey(_ key: String, dataType: String, bytes: [UInt8]) throws {
        try synchronized {
            let keyCode = fourCharCode(key)

            // Get key info first to validate
            let keyInfo = try getKeyInfo(key: keyCode)

            var input = SMCKeyData_t()
            input.key = keyCode
            input.data8 = SMCCommand.writeBytes.rawValue
            input.keyInfo = keyInfo

            // Copy bytes into the tuple
            withUnsafeMutableBytes(of: &input.bytes) { ptr in
                for i in 0..<min(bytes.count, 32) {
                    ptr[i] = bytes[i]
                }
            }

            var output = SMCKeyData_t()
            let inputSize = MemoryLayout<SMCKeyData_t>.stride
            var outputSize = MemoryLayout<SMCKeyData_t>.stride

            let result = IOConnectCallStructMethod(
                connection,
                kSMCIOKitSelector,
                &input,
                inputSize,
                &output,
                &outputSize
            )
            guard result == kIOReturnSuccess else {
                throw SMCError.writeFailed(key, result)
            }
        }
    }

    // MARK: - Write Float

    public func writeFloat(_ key: String, value: Float) throws {
        try writeKey(key, dataType: "flt ", bytes: smcBytesFromFloat(value))
    }

    // MARK: - Write UInt8

    public func writeUInt8(_ key: String, value: UInt8) throws {
        try writeKey(key, dataType: "ui8 ", bytes: [value])
    }

    // MARK: - Get Total Key Count

    public func getKeyCount() throws -> UInt32 {
        try synchronized {
            var input = SMCKeyData_t()
            input.data8 = SMCCommand.getKeyCount.rawValue
            let output = try callSMC(&input)
            return output.data32
        }
    }

    // MARK: - Read Key by Index

    public func readKeyAtIndex(_ index: UInt32) throws -> String {
        try synchronized {
            var input = SMCKeyData_t()
            input.data8 = SMCCommand.readIndex.rawValue
            input.data32 = index
            let output = try callSMC(&input)
            return fourCharCodeToString(output.key)
        }
    }

    // MARK: - Enumerate All Keys

    public func enumerateKeys() throws -> [String] {
        try synchronized {
            var input = SMCKeyData_t()
            input.data8 = SMCCommand.getKeyCount.rawValue
            let countOutput = try callSMC(&input)
            let count = countOutput.data32

            var keys: [String] = []
            keys.reserveCapacity(Int(count))
            for i in 0..<count {
                var indexInput = SMCKeyData_t()
                indexInput.data8 = SMCCommand.readIndex.rawValue
                indexInput.data32 = i
                if let output = try? callSMC(&indexInput) {
                    keys.append(fourCharCodeToString(output.key))
                }
            }
            return keys
        }
    }

    // MARK: - Convenience: Read Float

    public func readFloat(_ key: String) throws -> Float {
        let val = try readKey(key)
        return decodeSmcValue(val)
    }

    // MARK: - Convenience: Read UInt8

    public func readUInt8(_ key: String) throws -> UInt8 {
        let val = try readKey(key)
        return uint8FromBytes(val.bytes)
    }

    // MARK: - Convenience: Read String (ch8*)

    public func readString(_ key: String) throws -> String {
        let val = try readKey(key)
        let data = Data(val.bytes.prefix(Int(val.dataSize)))
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? ""
    }
}
