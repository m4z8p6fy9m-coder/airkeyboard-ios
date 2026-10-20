import Foundation

enum SharedStore {
    static let group = Bundle.main.object(forInfoDictionaryKey: "AirKeyboardAppGroup") as? String ?? "group.org.example.airkeyboard"
    private static func storage(requiresShared: Bool = false) throws -> SettingsLocation {
        let localOnly = Bundle.main.object(forInfoDictionaryKey: "AirKeyboardStorageMode") as? String == "local"
        let shared = localOnly ? nil : FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                  appropriateFor: nil, create: true)
        let result = SettingsLocation.resolve(sharedContainer: shared, applicationSupport: support)
        if requiresShared && !result.isShared {
            throw ThemeError.invalid("This action needs a provisioned App Group. Local mode does not share settings between the app, keyboard and widgets.")
        }
        return result
    }
    static func isSharingAvailable() async throws -> Bool {
        try await Task.detached { try storage().isShared }.value
    }
    static func load(requiresShared: Bool = false) async throws -> SharedSettings {
        try await Task.detached(priority: .userInitiated) { try readCoordinated(requiresShared: requiresShared) }.value
    }
    private static func readCoordinated(requiresShared: Bool) throws -> SharedSettings {
        let url = try storage(requiresShared: requiresShared).url
        if !FileManager.default.fileExists(atPath: url.path) &&
            !FileManager.default.fileExists(atPath: url.appendingPathExtension("backup").path) { return SharedSettings() }
        var coordinationError: NSError?
        var result: Result<SharedSettings, Error> = .failure(ThemeError.invalid("coordination did not run"))
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { path in
            result = Result { try JSONStore<SharedSettings>(url: path, validate: { try $0.validated() }).load() ?? SharedSettings() }
        }
        if let error = coordinationError { throw error }
        return try result.get()
    }
    /// One coordinated read-modify-write transaction prevents app/control lost updates.
    static func update(requiresShared: Bool = false, _ mutate: @escaping @Sendable (inout SharedSettings) -> Void) async throws -> SharedSettings {
        try await Task.detached(priority: .userInitiated) {
            let url = try storage(requiresShared: requiresShared).url
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            var coordinationError: NSError?
            var result: Result<SharedSettings, Error> = .failure(ThemeError.invalid("coordination did not run"))
            NSFileCoordinator().coordinate(writingItemAt: url, options: .forMerging, error: &coordinationError) { path in
                result = Result {
                    let store = JSONStore<SharedSettings>(url: path, validate: { try $0.validated() })
                    var value = try store.load() ?? SharedSettings()
                    mutate(&value)
                    try store.save(value)
                    return value
                }
            }
            if let error = coordinationError { throw error }
            return try result.get()
        }.value
    }
}
