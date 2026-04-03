import Foundation
import SMCKit

// MARK: - Status Command

func statusCommand() {
    let service = SMCSensorService()
    let temps = service.readTemperatures()
    let fans = service.readFans()

    print("Chip: \(ChipIdentifier.brandString)")
    print("")

    // Group temperatures by category
    if temps.isEmpty {
        print("No temperature sensors detected.")
    } else {
        print("=== Temperatures ===")
        let grouped = Dictionary(grouping: temps) { $0.category }
        let categoryOrder: [SensorCategory] = [
            .cpuEfficiency, .cpuPerformance, .gpu, .memory, .battery, .system, .other
        ]
        for category in categoryOrder {
            guard let readings = grouped[category], !readings.isEmpty else { continue }
            print("  \(category.rawValue)")
            for reading in readings {
                let temp = "\(Int(reading.temperature.rounded()))°C"
                print("    \(reading.label.padding(toLength: 20, withPad: " ", startingAt: 0)) \(temp)")
            }
        }
    }

    print("")

    if fans.isEmpty {
        print("No fans detected.")
    } else {
        print("=== Fans ===")
        for fan in fans {
            let mode = fan.isManual ? "manual" : "auto"
            let rpm = Int(fan.currentRPM.rounded())
            let min = Int(fan.minRPM.rounded())
            let max = Int(fan.maxRPM.rounded())
            print("  Fan \(fan.index) [\(fan.name)]  \(rpm) RPM  (min: \(min)  max: \(max))  [\(mode)]")
        }
    }
}

// MARK: - Set Command

func setCommand(fanIndex: Int, rpm: Float) {
    guard getuid() == 0 else {
        printError("Error: Setting fan speed requires root privileges.")
        printError("Run with: sudo fanctl set \(fanIndex) \(Int(rpm))")
        exit(1)
    }

    do {
        let writer = try FanWriteService()

        // Validate fan index
        guard fanIndex >= 0 && fanIndex < writer.fanCount else {
            printError("Error: Invalid fan index \(fanIndex). This machine has \(writer.fanCount) fan(s) (0..\(writer.fanCount - 1)).")
            exit(1)
        }

        // Validate RPM range
        let min = writer.minRPM(for: fanIndex)
        let max = writer.maxRPM(for: fanIndex)
        let clampedRPM = Swift.min(Swift.max(rpm, min), max)
        if clampedRPM != rpm {
            print("Note: RPM clamped to \(Int(clampedRPM)) (range: \(Int(min))-\(Int(max)))")
        }

        try writer.setFanSpeed(fanIndex: fanIndex, rpm: clampedRPM)
        print("Fan \(fanIndex) set to \(Int(clampedRPM)) RPM (manual mode)")
        print("Run 'sudo fanctl reset' to return to automatic control.")
    } catch {
        printError("Error: \(error)")
        exit(1)
    }
}

// MARK: - Reset Command

func resetCommand() {
    guard getuid() == 0 else {
        printError("Error: Resetting fans requires root privileges.")
        printError("Run with: sudo fanctl reset")
        exit(1)
    }

    do {
        let writer = try FanWriteService()
        writer.resetAllFans()
        print("All fans reset to automatic control.")
    } catch {
        printError("Error: \(error)")
        exit(1)
    }
}

// MARK: - Monitor Command

func monitorCommand(interval: TimeInterval) {
    let service = SMCSensorService()

    print("Monitoring (Ctrl-C to stop, refreshing every \(Int(interval))s)...")
    print("")

    while shouldExit == 0 {
        // Clear screen
        print("\u{1B}[2J\u{1B}[H", terminator: "")

        let temps = service.readTemperatures()
        let fans = service.readFans()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        print("Fan Monitor — \(dateFormatter.string(from: Date()))  (Ctrl-C to stop)")
        print("Chip: \(ChipIdentifier.brandString)")
        print("")

        if !temps.isEmpty {
            print("=== Temperatures ===")
            let grouped = Dictionary(grouping: temps) { $0.category }
            let categoryOrder: [SensorCategory] = [
                .cpuEfficiency, .cpuPerformance, .gpu, .memory, .battery, .system, .other
            ]
            for category in categoryOrder {
                guard let readings = grouped[category], !readings.isEmpty else { continue }
                print("  \(category.rawValue)")
                for reading in readings {
                    let temp = "\(Int(reading.temperature.rounded()))°C"
                    let bar = temperatureBar(reading.temperature)
                    print("    \(reading.label.padding(toLength: 20, withPad: " ", startingAt: 0)) \(temp.padding(toLength: 6, withPad: " ", startingAt: 0)) \(bar)")
                }
            }
        }

        print("")

        if !fans.isEmpty {
            print("=== Fans ===")
            for fan in fans {
                let mode = fan.isManual ? "manual" : "auto"
                let rpm = Int(fan.currentRPM.rounded())
                let min = Int(fan.minRPM.rounded())
                let max = Int(fan.maxRPM.rounded())
                let pct = max > min ? Int(Float(rpm - min) / Float(max - min) * 100) : 0
                print("  Fan \(fan.index) [\(fan.name)]  \(rpm) RPM (\(pct)%)  (min: \(min)  max: \(max))  [\(mode)]")
            }
        }

        // Sleep in short intervals to stay responsive to SIGINT
        for _ in 0..<Int(interval * 10) where shouldExit == 0 {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
    print("\nExiting monitor.")
}

// MARK: - Helpers

func printUsage() {
    print("""
    fanctl — macOS Fan Controller CLI

    Usage:
      fanctl                     Show temperatures and fan speeds
      fanctl status              Same as above
      fanctl set <fan> <rpm>     Set fan to manual mode at given RPM (requires sudo)
      fanctl reset               Reset all fans to automatic (requires sudo)
      fanctl monitor [interval]  Live display, refreshing every N seconds (default: 2)

    Examples:
      fanctl                     Show current status
      sudo fanctl set 0 2000     Set fan 0 to 2000 RPM
      sudo fanctl reset          Reset all fans to auto
      fanctl monitor 1           Monitor with 1-second refresh
    """)
}

func printError(_ message: String) {
    fputs(message + "\n", stderr)
}

private func temperatureBar(_ temp: Float) -> String {
    let filled = Int(temp / 100.0 * 20)
    let clamped = max(0, min(20, filled))
    let bar = String(repeating: "#", count: clamped) + String(repeating: ".", count: 20 - clamped)
    return "[\(bar)]"
}
