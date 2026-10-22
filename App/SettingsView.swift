import SwiftUI

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "dark"
    var body: some View {
        Form {
            Section("Your space") {
                Picker("Appearance", selection: $appearance) {
                    Text("Dark").tag("dark"); Text("Light").tag("light"); Text("System").tag("system")
                }
                NavigationLink("Controls & widgets") { IntegrationsView() }
                NavigationLink("Keyboard installation") { SetupView() }
                NavigationLink("Import & export") {
                    ScrollView { Text("In Themes, tap Import to choose a version 1 JSON package from Files. Each import creates a new theme. Use a theme’s ••• menu → Export JSON to save or share through Files. Packages contain only design tokens; no images, scripts, audio, or file paths are accepted. The maximum package size is 64 KB.").padding() }.navigationTitle("Theme packages")
                }
            }
            Section("Privacy") {
                Text("Your words stay with you.").font(.headline)
                Text("No accounts, analytics, advertising, servers, clipboard reading, or keystroke history. Themes and settings remain on this device. The keyboard reads only the nearby context needed for capitalization and never saves it.")
                Text("Full Access is optional and only used for custom audio. iOS grants broader capabilities than audio alone. You can revoke it in Settings at any time; typing continues silently.")
            }
            Section("About AirKeyboard") {
                Text("Independent native keyboard customization. Not affiliated with Apple or AirCard.")
                Text("Source code and original synthesized sound assets: MIT License. Copyright © 2026 AirKeyboard contributors. See LICENSE and ASSETS.md in the source distribution for full terms.")
                Text("English QWERTY and QWERTZ · iOS 18+\nNo prediction, swipe typing, dictation, or cloud sync in this release.")
            }
        }.navigationTitle("Settings")
    }
}

struct SetupView: View {
    var body: some View {
        List {
            Section("Install") {
                Text("1. Open iOS Settings → General → Keyboard → Keyboards → Add New Keyboard → AirKeyboard.")
                Text("2. Open Notes or another supported text field. Hold the globe key and select AirKeyboard.")
                Text("3. Optionally enable Allow Full Access in AirKeyboard’s keyboard settings for custom audio. Review the privacy explanation first.")
                Link("Open AirKeyboard app settings", destination: URL(string: UIApplication.openSettingsURLString)!)
            }
            Section("Things iOS decides") {
                Text("Secure text fields and some phone fields use Apple’s keyboard. Apps may block custom keyboards. AirKeyboard cannot verify activation from its containing app.")
                Text("The globe key always lets you switch keyboards. Full Access is not required for basic typing. Themes fall back to Dark Glass if shared settings are unavailable.")
            }
        }.navigationTitle("Keyboard setup")
    }
}

struct IntegrationsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { model.settings.theme.resolved(dark: colorScheme == .dark) }
    var body: some View {
        List {
            Section("In-app widget preview") {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AirKeyboard", systemImage: "keyboard").font(.caption)
                    Text(theme.name).font(.title3.bold())
                    HStack {
                        ForEach(["A", "I", "R"], id: \.self) { key in
                            Text(key).font(.title2).frame(maxWidth: .infinity, minHeight: 44)
                                .background(ThemeKeySurface(theme: theme, special: false, pressed: false, forceOpaque: true))
                        }
                    }
                    Text(model.settings.sound.enabled ? model.settings.sound.pack.title : "Sounds off").font(.caption)
                }
                .padding().foregroundStyle(Color(hex: theme.primary))
                .background(Color(hex: theme.background), in: RoundedRectangle(cornerRadius: 18))
            }
            Section("Control Center · iOS 18+") {
                Toggle("Keyboard sounds preference", isOn: Binding(get: { model.settings.sound.enabled }, set: { enabled in
                    var sound = model.settings.sound; sound.enabled = enabled
                    Task { await model.sound(sound) }
                })).disabled(!model.sharingAvailable)
                if !model.sharingAvailable { Text("Shared control unavailable in local mode. Editor and in-app sound previews remain usable without App Groups.").font(.caption).foregroundStyle(.secondary) }
                Text("Open Control Center, hold an empty area, choose Add a Control, then search AirKeyboard. The sound toggle changes AirKeyboard’s saved audio preference. It cannot grant Full Access or change device mute.")
            }
            Section("Home & Lock Screen") {
                Label("Current design", systemImage: "rectangle.on.rectangle")
                Text("Hold the Home Screen → Edit → Add Widget → AirKeyboard. The Home Screen widget shows your current theme and sound preference; tap it to open Themes. In Lock Screen customization, add the AirKeyboard rectangular widget. Updates follow system scheduling.")
            }
            Section("Within the system’s boundaries") {
                Text("These are genuine WidgetKit integrations. They customize AirKeyboard only. Face ID, passcode UI, Apple’s keyboard, and the rest of Control Center cannot be reskinned.")
            }
        }.navigationTitle("Controls & widgets")
    }
}
