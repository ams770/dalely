import Foundation

enum LocalStore {
    private static var directory: URL {
        if let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: StorageKeys.appGroupId) {
            let dir = shared.appendingPathComponent("Dalely", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let legacyBase = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let legacyDir = legacyBase.appendingPathComponent("Dalely", isDirectory: true)
            let legacySpots = legacyDir.appendingPathComponent("spots.json")
            let sharedSpots = dir.appendingPathComponent("spots.json")
            if !FileManager.default.fileExists(atPath: sharedSpots.path) && FileManager.default.fileExists(atPath: legacySpots.path) {
                try? FileManager.default.copyItem(at: legacySpots, to: sharedSpots)
            }
            return dir
        }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Dalely", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var spotsURL: URL { directory.appendingPathComponent("spots.json") }
    static var settingsURL: URL { directory.appendingPathComponent("settings.json") }

    static func loadSpots() -> [Spot] {
        guard let data = try? Data(contentsOf: spotsURL) else { return [] }
        return (try? JSONDecoder.dalely.decode([Spot].self, from: data)) ?? []
    }

    static func saveSpots(_ spots: [Spot]) {
        guard let data = try? JSONEncoder.dalely.encode(spots) else { return }
        try? data.write(to: spotsURL, options: .atomic)
    }

    static func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsURL) else { return AppSettings() }
        return (try? JSONDecoder.dalely.decode(AppSettings.self, from: data)) ?? AppSettings()
    }

    static func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder.dalely.encode(settings) else { return }
        try? data.write(to: settingsURL, options: .atomic)
    }
}

extension JSONDecoder {
    static var dalely: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }
}

extension JSONEncoder {
    static var dalely: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
