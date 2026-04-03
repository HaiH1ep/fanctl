import Foundation

public struct SMCSensorReading: Sendable {
    public let key: String
    public let label: String
    public let category: SensorCategory
    public let temperature: Float

    public init(key: String, label: String, category: SensorCategory, temperature: Float) {
        self.key = key
        self.label = label
        self.category = category
        self.temperature = temperature
    }
}

public struct SMCFanReading: Sendable {
    public let index: Int
    public let name: String
    public let currentRPM: Float
    public let minRPM: Float
    public let maxRPM: Float
    public let targetRPM: Float
    public let isManual: Bool

    public init(index: Int, name: String, currentRPM: Float, minRPM: Float, maxRPM: Float, targetRPM: Float, isManual: Bool) {
        self.index = index
        self.name = name
        self.currentRPM = currentRPM
        self.minRPM = minRPM
        self.maxRPM = maxRPM
        self.targetRPM = targetRPM
        self.isManual = isManual
    }
}
