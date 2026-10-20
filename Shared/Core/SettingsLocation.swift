import Foundation

/// No cross-process sharing is implied when settings live in a target's own sandbox.
struct SettingsLocation: Equatable, Sendable {
    let url: URL
    let isShared: Bool
    static func resolve(sharedContainer: URL?, applicationSupport: URL) -> SettingsLocation {
        if let sharedContainer {
            return SettingsLocation(url: sharedContainer.appendingPathComponent("settings.json"), isShared: true)
        }
        return SettingsLocation(url: applicationSupport.appendingPathComponent("AirKeyboard/settings.json"), isShared: false)
    }
}
