import Foundation

// MARK: - Chip Generation

public enum ChipGeneration: String, CaseIterable, Sendable {
    case m1, m1Pro, m1Max, m1Ultra
    case m2, m2Pro, m2Max, m2Ultra
    case m3, m3Pro, m3Max
    case m4, m4Pro, m4Max
    case unknown
}

// MARK: - Sensor Category

public enum SensorCategory: String, Sendable {
    case cpuEfficiency = "CPU Efficiency"
    case cpuPerformance = "CPU Performance"
    case gpu = "GPU"
    case memory = "Memory"
    case battery = "Battery"
    case system = "System"
    case other = "Other"
}

// MARK: - Sensor Definition

public struct SensorDefinition: Sendable {
    public let key: String
    public let label: String
    public let category: SensorCategory

    public init(key: String, label: String, category: SensorCategory) {
        self.key = key
        self.label = label
        self.category = category
    }
}

// MARK: - Fan Key Helpers

public enum FanKeys {
    public static let fanCount = "FNum"

    public static func actualSpeed(_ index: Int) -> String { "F\(index)Ac" }
    public static func minSpeed(_ index: Int) -> String { "F\(index)Mn" }
    public static func maxSpeed(_ index: Int) -> String { "F\(index)Mx" }
    public static func targetSpeed(_ index: Int) -> String { "F\(index)Tg" }
    public static func mode(_ index: Int) -> String { "F\(index)Md" }
    public static func safeSpeed(_ index: Int) -> String { "F\(index)Sf" }
    public static func fanID(_ index: Int) -> String { "F\(index)ID" }

    public static let forceTest = "Ftst"
    public static let forceBitmask = "FS! "
}

// MARK: - Common Cross-Platform Keys

public let commonSensorKeys: [SensorDefinition] = [
    SensorDefinition(key: "TB0T", label: "Battery", category: .battery),
    SensorDefinition(key: "TW0P", label: "WiFi Module", category: .system),
    SensorDefinition(key: "Tm0P", label: "Mainboard", category: .system),
    SensorDefinition(key: "TA0P", label: "Ambient", category: .system),
    SensorDefinition(key: "PSTR", label: "System Power (W)", category: .system),
]

// MARK: - Per-Generation Temperature Keys

public func temperatureKeys(for chip: ChipGeneration) -> [SensorDefinition] {
    switch chip {
    case .m1, .m1Pro, .m1Max, .m1Ultra:
        return m1TemperatureKeys
    case .m2, .m2Pro, .m2Max, .m2Ultra:
        return m2TemperatureKeys
    case .m3, .m3Pro, .m3Max:
        return m3TemperatureKeys
    case .m4, .m4Pro, .m4Max:
        return m4TemperatureKeys
    case .unknown:
        return []
    }
}

// MARK: - M1 Keys

private let m1TemperatureKeys: [SensorDefinition] = [
    // CPU Efficiency
    SensorDefinition(key: "Tp09", label: "CPU E-Core 1", category: .cpuEfficiency),
    SensorDefinition(key: "Tp0T", label: "CPU E-Core 2", category: .cpuEfficiency),
    // CPU Performance
    SensorDefinition(key: "Tp01", label: "CPU P-Core 1", category: .cpuPerformance),
    SensorDefinition(key: "Tp05", label: "CPU P-Core 2", category: .cpuPerformance),
    SensorDefinition(key: "Tp0D", label: "CPU P-Core 3", category: .cpuPerformance),
    SensorDefinition(key: "Tp0H", label: "CPU P-Core 4", category: .cpuPerformance),
    SensorDefinition(key: "Tp0L", label: "CPU P-Core 5", category: .cpuPerformance),
    SensorDefinition(key: "Tp0P", label: "CPU P-Core 6", category: .cpuPerformance),
    SensorDefinition(key: "Tp0X", label: "CPU P-Core 7", category: .cpuPerformance),
    SensorDefinition(key: "Tp0b", label: "CPU P-Core 8", category: .cpuPerformance),
    // GPU
    SensorDefinition(key: "Tg05", label: "GPU 1", category: .gpu),
    SensorDefinition(key: "Tg0D", label: "GPU 2", category: .gpu),
    SensorDefinition(key: "Tg0L", label: "GPU 3", category: .gpu),
    SensorDefinition(key: "Tg0T", label: "GPU 4", category: .gpu),
]

// MARK: - M2 Keys

private let m2TemperatureKeys: [SensorDefinition] = [
    // CPU Efficiency
    SensorDefinition(key: "Tp1h", label: "CPU E-Core 1", category: .cpuEfficiency),
    SensorDefinition(key: "Tp1t", label: "CPU E-Core 2", category: .cpuEfficiency),
    SensorDefinition(key: "Tp1p", label: "CPU E-Core 3", category: .cpuEfficiency),
    SensorDefinition(key: "Tp1l", label: "CPU E-Core 4", category: .cpuEfficiency),
    // CPU Performance
    SensorDefinition(key: "Tp01", label: "CPU P-Core 1", category: .cpuPerformance),
    SensorDefinition(key: "Tp05", label: "CPU P-Core 2", category: .cpuPerformance),
    SensorDefinition(key: "Tp09", label: "CPU P-Core 3", category: .cpuPerformance),
    SensorDefinition(key: "Tp0D", label: "CPU P-Core 4", category: .cpuPerformance),
    SensorDefinition(key: "Tp0X", label: "CPU P-Core 5", category: .cpuPerformance),
    SensorDefinition(key: "Tp0b", label: "CPU P-Core 6", category: .cpuPerformance),
    SensorDefinition(key: "Tp0f", label: "CPU P-Core 7", category: .cpuPerformance),
    SensorDefinition(key: "Tp0j", label: "CPU P-Core 8", category: .cpuPerformance),
    // GPU
    SensorDefinition(key: "Tg0f", label: "GPU 1", category: .gpu),
    SensorDefinition(key: "Tg0j", label: "GPU 2", category: .gpu),
]

// MARK: - M3 Keys

private let m3TemperatureKeys: [SensorDefinition] = [
    // CPU Efficiency
    SensorDefinition(key: "Te05", label: "CPU E-Core 1", category: .cpuEfficiency),
    SensorDefinition(key: "Te0L", label: "CPU E-Core 2", category: .cpuEfficiency),
    SensorDefinition(key: "Te0P", label: "CPU E-Core 3", category: .cpuEfficiency),
    SensorDefinition(key: "Te0S", label: "CPU E-Core 4", category: .cpuEfficiency),
    // CPU Performance
    SensorDefinition(key: "Tf04", label: "CPU P-Core 1", category: .cpuPerformance),
    SensorDefinition(key: "Tf09", label: "CPU P-Core 2", category: .cpuPerformance),
    SensorDefinition(key: "Tf0A", label: "CPU P-Core 3", category: .cpuPerformance),
    SensorDefinition(key: "Tf0B", label: "CPU P-Core 4", category: .cpuPerformance),
    SensorDefinition(key: "Tf0D", label: "CPU P-Core 5", category: .cpuPerformance),
    SensorDefinition(key: "Tf0E", label: "CPU P-Core 6", category: .cpuPerformance),
    SensorDefinition(key: "Tf44", label: "CPU P-Core 7", category: .cpuPerformance),
    SensorDefinition(key: "Tf49", label: "CPU P-Core 8", category: .cpuPerformance),
    SensorDefinition(key: "Tf4A", label: "CPU P-Core 9", category: .cpuPerformance),
    SensorDefinition(key: "Tf4B", label: "CPU P-Core 10", category: .cpuPerformance),
    SensorDefinition(key: "Tf4D", label: "CPU P-Core 11", category: .cpuPerformance),
    SensorDefinition(key: "Tf4E", label: "CPU P-Core 12", category: .cpuPerformance),
    // GPU
    SensorDefinition(key: "Tf14", label: "GPU 1", category: .gpu),
    SensorDefinition(key: "Tf18", label: "GPU 2", category: .gpu),
    SensorDefinition(key: "Tf19", label: "GPU 3", category: .gpu),
    SensorDefinition(key: "Tf1A", label: "GPU 4", category: .gpu),
    SensorDefinition(key: "Tf24", label: "GPU 5", category: .gpu),
    SensorDefinition(key: "Tf28", label: "GPU 6", category: .gpu),
    SensorDefinition(key: "Tf29", label: "GPU 7", category: .gpu),
    SensorDefinition(key: "Tf2A", label: "GPU 8", category: .gpu),
]

// MARK: - M4 / M4 Pro / M4 Max Keys
// Discovered via brute-scan on M4 Pro (macOS 26)

private let m4TemperatureKeys: [SensorDefinition] = [
    // CPU Efficiency cores
    SensorDefinition(key: "Te04", label: "CPU E-Core 1", category: .cpuEfficiency),
    SensorDefinition(key: "Te05", label: "CPU E-Core 2", category: .cpuEfficiency),
    SensorDefinition(key: "Te06", label: "CPU E-Core 3", category: .cpuEfficiency),
    SensorDefinition(key: "Te0R", label: "CPU E-Core 4", category: .cpuEfficiency),
    SensorDefinition(key: "Te0S", label: "CPU E-Core 5", category: .cpuEfficiency),
    SensorDefinition(key: "Te0T", label: "CPU E-Core 6", category: .cpuEfficiency),
    // CPU Performance cores
    SensorDefinition(key: "Tp1k", label: "CPU P-Core 1", category: .cpuPerformance),
    SensorDefinition(key: "Tp1t", label: "CPU P-Core 2", category: .cpuPerformance),
    SensorDefinition(key: "Tp24", label: "CPU P-Core 3", category: .cpuPerformance),
    SensorDefinition(key: "Tp28", label: "CPU P-Core 4", category: .cpuPerformance),
    SensorDefinition(key: "Tp29", label: "CPU P-Core 5", category: .cpuPerformance),
    SensorDefinition(key: "Tp2A", label: "CPU P-Core 6", category: .cpuPerformance),
    // GPU
    SensorDefinition(key: "Tg04", label: "GPU 1", category: .gpu),
    SensorDefinition(key: "Tg05", label: "GPU 2", category: .gpu),
    SensorDefinition(key: "Tg0K", label: "GPU 3", category: .gpu),
    SensorDefinition(key: "Tg0L", label: "GPU 4", category: .gpu),
    SensorDefinition(key: "Tg0R", label: "GPU 5", category: .gpu),
    SensorDefinition(key: "Tg0S", label: "GPU 6", category: .gpu),
    SensorDefinition(key: "Tg0X", label: "GPU 7", category: .gpu),
    SensorDefinition(key: "Tg0Y", label: "GPU 8", category: .gpu),
    SensorDefinition(key: "Tg0d", label: "GPU 9", category: .gpu),
    SensorDefinition(key: "Tg0e", label: "GPU 10", category: .gpu),
    SensorDefinition(key: "Tg0j", label: "GPU 11", category: .gpu),
    SensorDefinition(key: "Tg0k", label: "GPU 12", category: .gpu),
    SensorDefinition(key: "Tg1U", label: "GPU 13", category: .gpu),
    SensorDefinition(key: "Tg1k", label: "GPU 14", category: .gpu),
    SensorDefinition(key: "Tg1l", label: "GPU 15", category: .gpu),
    // System
    SensorDefinition(key: "TH0a", label: "Heatpipe 1", category: .system),
    SensorDefinition(key: "TH0b", label: "Heatpipe 2", category: .system),
    SensorDefinition(key: "TS0P", label: "SSD", category: .system),
    SensorDefinition(key: "TD00", label: "Die 1", category: .system),
    SensorDefinition(key: "TD01", label: "Die 2", category: .system),
    SensorDefinition(key: "TD02", label: "Die 3", category: .system),
    SensorDefinition(key: "TD03", label: "Die 4", category: .system),
    SensorDefinition(key: "TD04", label: "Die 5", category: .system),
    SensorDefinition(key: "TD14", label: "Die 6", category: .system),
    SensorDefinition(key: "TD24", label: "Die 7", category: .system),
]

// MARK: - Lookup helper

private var sensorLabelCache: [String: SensorDefinition] = {
    var cache: [String: SensorDefinition] = [:]
    for def in commonSensorKeys {
        cache[def.key] = def
    }
    let allChipKeys = m1TemperatureKeys + m2TemperatureKeys + m3TemperatureKeys + m4TemperatureKeys
    for def in allChipKeys {
        if cache[def.key] == nil {
            cache[def.key] = def
        }
    }
    return cache
}()

public func sensorLabel(for key: String, chip: ChipGeneration) -> SensorDefinition? {
    // First try chip-specific keys
    let chipKeys = temperatureKeys(for: chip)
    if let def = chipKeys.first(where: { $0.key == key }) {
        return def
    }
    // Then try common keys
    if let def = commonSensorKeys.first(where: { $0.key == key }) {
        return def
    }
    return nil
}
