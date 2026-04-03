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

func setCommand(fanIndex: Int, rpm: Float, watchApps: [String] = []) {
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

        if !watchApps.isEmpty {
            let store = ConfigStore()
            var config = store.load()
            for app in watchApps {
                // Update existing rule or add new one
                if let idx = config.rules.firstIndex(where: { $0.app.lowercased() == app.lowercased() && $0.fanIndex == fanIndex }) {
                    config.rules[idx] = AppRule(app: app, fanIndex: fanIndex, rpm: clampedRPM)
                } else {
                    config.rules.append(AppRule(app: app, fanIndex: fanIndex, rpm: clampedRPM))
                }
            }
            do {
                try store.save(config)
                print("Registered \(watchApps.count) app(s) for watch: \(watchApps.joined(separator: ", "))")
            } catch {
                printError("Warning: Could not save config: \(error.localizedDescription)")
            }
        }

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

// MARK: - List Command

func listCommand() {
    let config = ConfigStore().load()
    if config.rules.isEmpty {
        print("No app rules registered.")
        print("Use 'sudo fanctl set <fan> <rpm> -w <app> ...' to register apps.")
        return
    }

    print("Registered app rules:")
    // Group by (fanIndex, rpm)
    let grouped = Dictionary(grouping: config.rules) { "\($0.fanIndex):\(Int($0.rpm))" }
    let sortedKeys = grouped.keys.sorted()
    for key in sortedKeys {
        guard let rules = grouped[key], let first = rules.first else { continue }
        let apps = rules.map { $0.app }.joined(separator: ", ")
        print("  Fan \(first.fanIndex)  \(Int(first.rpm)) RPM  <- \(apps)")
    }
}

// MARK: - Unwatch Command

func unwatchCommand(apps: [String]) {
    let store = ConfigStore()
    var config = store.load()
    let before = config.rules.count
    let appsLower = apps.map { $0.lowercased() }
    config.rules.removeAll { rule in
        appsLower.contains(rule.app.lowercased())
    }
    let removed = before - config.rules.count
    do {
        try store.save(config)
        print("Removed \(removed) rule(s) for: \(apps.joined(separator: ", "))")
    } catch {
        printError("Error: Could not save config: \(error.localizedDescription)")
        exit(1)
    }
}

// MARK: - Watch Command

func watchCommand(interval: TimeInterval) {
    guard getuid() == 0 else {
        printError("Error: Watch mode requires root privileges.")
        printError("Run with: sudo fanctl watch")
        exit(1)
    }

    let store = ConfigStore()
    let config = store.load()

    if config.rules.isEmpty {
        print("No app rules configured.")
        print("Use 'sudo fanctl set <fan> <rpm> -w <app> ...' to register apps.")
        return
    }

    do {
        let writer = try FanWriteService()
        var previousSpeeds: [Int: Float] = [:]
        var managedFans = Set<Int>()

        print("Watching \(config.rules.count) rule(s), polling every \(Int(interval))s (Ctrl-C to stop)...")

        while shouldExit == 0 {
            let active = ProcessDetector.activeRules(from: config.rules)
            let desired = ProcessDetector.resolveDesiredSpeeds(from: active)

            // Apply new or changed speeds
            for (fan, rpm) in desired {
                if previousSpeeds[fan] != rpm {
                    let min = writer.minRPM(for: fan)
                    let max = writer.maxRPM(for: fan)
                    let clamped = Swift.min(Swift.max(rpm, min), max)
                    do {
                        try writer.setFanSpeed(fanIndex: fan, rpm: clamped)
                        let apps = active.filter { $0.fanIndex == fan }.map { $0.app }
                        print("Fan \(fan) -> \(Int(clamped)) RPM (apps: \(apps.joined(separator: ", ")))")
                    } catch {
                        printError("Warning: Failed to set fan \(fan): \(error.localizedDescription)")
                    }
                    previousSpeeds[fan] = rpm
                    managedFans.insert(fan)
                }
            }

            // Reset fans that no longer have active rules
            for fan in managedFans where desired[fan] == nil {
                writer.resetFan(at: fan)
                print("Fan \(fan) -> auto (no active apps)")
                previousSpeeds.removeValue(forKey: fan)
            }
            managedFans = managedFans.intersection(desired.keys)

            // Sleep in short intervals to stay responsive to SIGINT
            for _ in 0..<Int(interval * 10) where shouldExit == 0 {
                Thread.sleep(forTimeInterval: 0.1)
            }
        }

        // On exit, reset all managed fans
        writer.resetAllFans()
        print("\nAll fans reset to automatic. Exiting watch.")
    } catch {
        printError("Error: \(error)")
        exit(1)
    }
}

// MARK: - Helpers

func printUsage() {
    print("""
    fanctl — macOS Fan Controller CLI

    Usage:
      fanctl                     Show temperatures and fan speeds
      fanctl status              Same as above
      fanctl set <fan> <rpm>     Set fan to manual mode at given RPM (requires sudo)
      fanctl set <fan> <rpm> -w <app1> [app2 ...]
                                 Set fan speed and register apps for watch mode
      fanctl list                Show registered app rules
      fanctl unwatch <app1> [app2 ...]
                                 Remove app rules
      fanctl watch [interval]    Watch for registered apps and control fans (requires sudo)
      fanctl reset               Reset all fans to automatic (requires sudo)
      fanctl monitor [interval]  Live display, refreshing every N seconds (default: 2)

    Examples:
      fanctl                     Show current status
      sudo fanctl set 0 2000     Set fan 0 to 2000 RPM
      sudo fanctl set 0 3000 -w code xcode
                                 Set fan 0 and register code, xcode for watch
      fanctl list                Show all registered app rules
      fanctl unwatch code xcode  Remove rules for code and xcode
      sudo fanctl watch          Watch for registered apps (polls every 5s)
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
