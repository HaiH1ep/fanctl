import Foundation
import SMCKit

/// Simplified synchronous fan control for CLI usage.
/// Requires root privileges for write operations.
final class FanWriteService {
    private let smc = SMCConnection()
    let fanCount: Int

    init() throws {
        try smc.open()
        if let val = try? smc.readKey(FanKeys.fanCount) {
            fanCount = Int(uint8FromBytes(val.bytes))
        } else {
            fanCount = 0
        }
    }

    deinit {
        smc.close()
    }

    // MARK: - Set Fan Speed

    func setFanSpeed(fanIndex: Int, rpm: Float) throws {
        // Step 1: Write Ftst = 1 (diagnostic flag to unlock manual control)
        try smc.writeUInt8(FanKeys.forceTest, value: 1)

        // Step 2: Retry writing fan mode to manual until thermalmonitord yields
        var success = false
        for _ in 0..<60 {
            do {
                try smc.writeUInt8(FanKeys.mode(fanIndex), value: 1)
                success = true
                break
            } catch {
                Thread.sleep(forTimeInterval: 0.1)
                try? smc.writeUInt8(FanKeys.forceTest, value: 1)
            }
        }

        guard success else {
            throw SMCError.writeFailed("F\(fanIndex)Md", kIOReturnError)
        }

        // Step 3: Set target speed
        try smc.writeFloat(FanKeys.targetSpeed(fanIndex), value: rpm)
    }

    // MARK: - Reset All Fans

    func resetAllFans() {
        for i in 0..<fanCount {
            try? smc.writeUInt8(FanKeys.mode(i), value: 0)
        }
        try? smc.writeUInt8(FanKeys.forceTest, value: 0)
    }

    // MARK: - Fan Info

    func minRPM(for fanIndex: Int) -> Float {
        (try? smc.readFloat(FanKeys.minSpeed(fanIndex))) ?? 0
    }

    func maxRPM(for fanIndex: Int) -> Float {
        (try? smc.readFloat(FanKeys.maxSpeed(fanIndex))) ?? 0
    }
}
