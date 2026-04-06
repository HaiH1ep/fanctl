import Foundation

enum ProcessDetector {

    /// Returns the set of currently running process names (lowercased).
    static func runningProcessNames() -> Set<String> {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-axco", "command"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var names = Set<String>()
        for line in output.split(separator: "\n").dropFirst() { // skip header
            let name = line.trimmingCharacters(in: .whitespaces).lowercased()
            if !name.isEmpty {
                names.insert(name)
            }
        }
        return names
    }

    /// Returns rules whose app name matches a currently running process.
    /// Matching strategy: exact match first, then prefix match to handle
    /// truncated or compound names (e.g. "code" matches "code helper").
    /// Avoids false positives from pure substring matching.
    static func activeRules(from rules: [AppRule]) -> [AppRule] {
        let running = runningProcessNames()
        return rules.filter { rule in
            let appLower = rule.app.lowercased()
            return running.contains(appLower) || running.contains { $0.hasPrefix(appLower) }
        }
    }

    /// Given active rules, returns the maximum desired RPM per fan index.
    static func resolveDesiredSpeeds(from rules: [AppRule]) -> [Int: Float] {
        var speeds: [Int: Float] = [:]
        for rule in rules {
            if let current = speeds[rule.fanIndex] {
                speeds[rule.fanIndex] = max(current, rule.rpm)
            } else {
                speeds[rule.fanIndex] = rule.rpm
            }
        }
        return speeds
    }
}
