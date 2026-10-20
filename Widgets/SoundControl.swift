import AppIntents
import WidgetKit
import SwiftUI

struct SetKeyboardSoundIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Set AirKeyboard sounds"
    @Parameter(title: "Enabled") var value: Bool
    func perform() async throws -> some IntentResult {
        let enabled = value
        _ = try await SharedStore.update(requiresShared: true) { $0.sound.enabled = enabled }
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        return .result()
    }
}

struct SoundControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "org.example.airkeyboard.sounds", provider: Provider()) { enabled in
            ControlWidgetToggle("Keyboard sounds", isOn: enabled, action: SetKeyboardSoundIntent()) { isOn in
                Label(isOn ? "Enabled" : "Silent", systemImage: isOn ? "waveform" : "speaker.slash")
            }
        }
        .displayName("Keyboard sounds")
        .description("Change AirKeyboard’s audio preference. Custom audio still requires keyboard Full Access.")
    }
    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }
        func currentValue() async throws -> Bool { try await SharedStore.load(requiresShared: true).sound.enabled }
    }
}
