import Foundation

/// App library store. Call on a background task. A verified backup survives a corrupt primary.
struct JSONStore<Value: Codable> {
    let url: URL
    let validate: (Value) throws -> Value
    var backup: URL { url.appendingPathExtension("backup") }
    func load() throws -> Value? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) || fm.fileExists(atPath: backup.path) else { return nil }
        do { return try read(url) }
        catch {
            // Surface both errors if no valid recovery copy exists.
            do { return try read(backup) }
            catch { throw ThemeError.invalid("saved data and its recovery copy could not be read: \(error.localizedDescription)") }
        }
    }
    private func read(_ path: URL) throws -> Value {
        guard let size = try path.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 4_194_304
        else { throw ThemeError.tooLarge }
        return try validate(JSONDecoder().decode(Value.self, from: Data(contentsOf: path)))
    }
    func save(_ value: Value) throws {
        let data = try JSONEncoder().encode(validate(value))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let old = try? read(url) {
            try JSONEncoder().encode(old).write(to: backup, options: .atomic)
        }
        try data.write(to: url, options: .atomic)
        if !FileManager.default.fileExists(atPath: backup.path) { try data.write(to: backup, options: .atomic) }
    }
}
