import Foundation

public final class SMCSensorService {
    private let smc = SMCConnection()
    private let chip: ChipGeneration
    private var availableTemperatureKeys: [SensorDefinition] = []
    private(set) public var fanCount: Int = 0

    public init() {
        self.chip = ChipIdentifier.detect()
        do {
            try smc.open()
            discoverSensors()
        } catch {
            print("SMCSensorService: Failed to open SMC: \(error)")
        }
    }

    deinit {
        smc.close()
    }

    // MARK: - Sensor Discovery

    private func discoverSensors() {
        // FNum is ui8 on Apple Silicon
        if let val = try? smc.readKey(FanKeys.fanCount) {
            fanCount = Int(uint8FromBytes(val.bytes))
        }

        let chipKeys = temperatureKeys(for: chip) + commonSensorKeys
        for def in chipKeys {
            if let val = try? smc.readKey(def.key) {
                let temp = decodeSmcValue(val)
                if temp > 10 && temp < 150 {
                    availableTemperatureKeys.append(def)
                }
            }
        }

        if availableTemperatureKeys.isEmpty {
            discoverByEnumeration()
        }
    }

    private func discoverByEnumeration() {
        guard let allKeys = try? smc.enumerateKeys() else { return }
        for key in allKeys {
            guard key.hasPrefix("T") else { continue }
            guard let val = try? smc.readKey(key) else { continue }
            guard val.dataType == "flt " && val.dataSize == 4 else { continue }

            let temp = floatFromSMCBytes(val.bytes)
            guard temp > 10 && temp < 150 else { continue }

            if let def = sensorLabel(for: key, chip: chip) {
                availableTemperatureKeys.append(def)
            } else {
                availableTemperatureKeys.append(
                    SensorDefinition(key: key, label: key, category: .other)
                )
            }
        }
    }

    // MARK: - Read Temperatures

    public func readTemperatures() -> [SMCSensorReading] {
        availableTemperatureKeys.compactMap { def in
            guard let temp = try? smc.readFloat(def.key) else { return nil }
            guard temp > 10 && temp < 150 else { return nil }
            return SMCSensorReading(
                key: def.key,
                label: def.label,
                category: def.category,
                temperature: temp
            )
        }
    }

    // MARK: - Read Fans

    public func readFans() -> [SMCFanReading] {
        (0..<fanCount).compactMap { index in
            let current = (try? smc.readFloat(FanKeys.actualSpeed(index))) ?? 0
            let min = (try? smc.readFloat(FanKeys.minSpeed(index))) ?? 0
            let max = (try? smc.readFloat(FanKeys.maxSpeed(index))) ?? 0
            let target = (try? smc.readFloat(FanKeys.targetSpeed(index))) ?? 0
            let modeVal = try? smc.readKey(FanKeys.mode(index))
            let mode = modeVal.map { uint8FromBytes($0.bytes) } ?? 0
            let name = (try? smc.readString(FanKeys.fanID(index))) ?? ""

            return SMCFanReading(
                index: index,
                name: name.isEmpty ? "Fan \(index)" : name,
                currentRPM: current,
                minRPM: min,
                maxRPM: max,
                targetRPM: target,
                isManual: mode == 1
            )
        }
    }

    // MARK: - Info

    public var detectedChip: ChipGeneration { chip }
    public var sensorCount: Int { availableTemperatureKeys.count }
}
