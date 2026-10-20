import SwiftUI

struct SoundsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var value = SoundPreferences()
    @State private var saving = false
    var body: some View {
        Form {
            Section {
                Text("Small sounds.\nA different feeling.").font(.largeTitle.bold())
                Text("Four original, short synthesized taps. No recordings, no downloads.").foregroundStyle(.secondary)
            }
            Section("Sound packs") {
                ForEach(SoundPack.allCases, id: \.self) { pack in
                    HStack {
                        Button { value.pack = pack } label: {
                            Label(pack.title, systemImage: value.pack == pack ? "checkmark.circle.fill" : "circle")
                        }
                        Spacer()
                        Button("Preview", systemImage: "play.fill") {
                            var preview = value; preview.enabled = true; preview.pack = pack
                            if !model.audio.play(preview) { model.error = model.audio.failure }
                        }.labelStyle(.iconOnly).accessibilityLabel("Preview \(pack.title)")
                    }.buttonStyle(.borderless)
                }
            }
            Section("Keyboard playback") {
                Toggle("Enable optional keyboard audio", isOn: $value.enabled)
                Text("Volume").font(.subheadline)
                Slider(value: $value.volume, in: 0...1).accessibilityLabel("Sound volume")
                Text("Intensity").font(.subheadline)
                Slider(value: $value.intensity, in: 0...1).accessibilityLabel("Sound intensity")
                Button(saving ? "Saving…" : "Save sound preferences") {
                    saving = true
                    Task { await model.sound(value); saving = false }
                }.disabled(saving)
            } footer: {
                Text("Custom keyboard audio requires Allow Full Access. Without it, typing stays silent. Full Access expands iOS sandbox permissions, including network capability; AirKeyboard contains no network client and never transmits typing. Audio uses the ambient category, respecting Silent mode and device volume. In-app previews need no Full Access.")
            }
        }.navigationTitle("Sounds")
        .onAppear { value = model.settings.sound }
        .onChange(of: model.settings.sound) { _, updated in value = updated }
    }
}
