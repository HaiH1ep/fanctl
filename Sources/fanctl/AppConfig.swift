import Foundation

// MARK: - Data Structures

struct AppRule: Codable, Equatable {
    let app: String
    let fanIndex: Int
    let rpm: Float
}

struct AppConfig: Codable {
    var rules: [AppRule] = []
}

// MARK: - Config Store

final class ConfigStore {

    static func configFileURL() -> URL {
        let home = realHomeDirectory()
        return home.appendingPathComponent(".config/fanctl/apps.json")
    }

    func load() -> AppConfig {
        let url = ConfigStore.configFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return AppConfig()
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            printError("Warning: Could not read config at \(url.path): \(error.localizedDescription)")
            return AppConfig()
        }
    }

    func save(_ config: AppConfig) throws {
        let url = ConfigStore.configFileURL()
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
        // When running under sudo, restore ownership to the real user so
        // non-root commands (list, unwatch) can write the file later.
        if let sudoUser = ProcessInfo.processInfo.environment["SUDO_USER"],
           let pw = getpwnam(sudoUser) {
            let uid = pw.pointee.pw_uid
            let gid = pw.pointee.pw_gid
            chown(url.path, uid, gid)
            chown(dir.path, uid, gid)
        }
    }

    // MARK: - Helpers

    /// Resolves the real user's home directory, even when running under sudo.
    private static func realHomeDirectory() -> URL {
        if let sudoUser = ProcessInfo.processInfo.environment["SUDO_USER"],
           let pw = getpwnam(sudoUser) {
            return URL(fileURLWithPath: String(cString: pw.pointee.pw_dir))
        }
        return URL(fileURLWithPath: NSHomeDirectory())
    }
}
