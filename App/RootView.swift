import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var phase
    @State private var selection = 0
    var body: some View {
        Group {
            if !model.ready { ProgressView("Opening your studio…") }
            else {
                TabView(selection: $selection) {
                    NavigationStack { HomeView() }.tabItem { Label("Home", systemImage: "square.grid.2x2") }.tag(0)
                    NavigationStack { ThemesView() }.tabItem { Label("Themes", systemImage: "swatchpalette") }.tag(1)
                    NavigationStack { SoundsView() }.tabItem { Label("Sounds", systemImage: "waveform") }.tag(2)
                    NavigationStack { SettingsView() }.tabItem { Label("Settings", systemImage: "slider.horizontal.3") }.tag(3)
                }
            }
        }
        .task { await model.load() }
        .onChange(of: phase) { _, value in
            if value == .active { Task { await model.refreshSettings() } }
            else { model.audio.stop() }
        }
        .onOpenURL { url in
            guard url.scheme == "airkeyboard" else { return }
            selection = url.host == "sounds" ? 2 : 1
        }
        .alert("AirKeyboard", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
    }
}

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("MAKE EVERY\nKEY YOURS.").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("A quieter space for your next big idea.").foregroundStyle(.secondary)
                if !model.sharingAvailable {
                    Surface {
                        Label("Local development mode", systemImage: "externaldrive").font(.headline)
                        Text("Themes and sounds save in this app without a developer subscription. Sharing with the keyboard and widgets needs an available App Group. You can choose built-in designs directly in the keyboard.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Surface {
                    HStack { Label("ACTIVE DESIGN", systemImage: "circle.fill").font(.caption.weight(.semibold)); Spacer(); Text("LOCAL").font(.caption2) }
                    Text(model.settings.theme.name).font(.title2.bold())
                    KeyboardPreview(theme: model.settings.theme)
                    NavigationLink { StudioView(theme: model.settings.theme) } label: { Label("Open Keyboard Studio", systemImage: "paintbrush.pointed") }
                }
                Surface {
                    Label(model.settings.sound.pack.title, systemImage: "waveform").font(.headline)
                    Text(model.settings.sound.enabled ? "Custom audio requires optional Full Access in the keyboard." : "Keyboard sounds are off.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    NavigationLink("Explore sounds") { SoundsView() }
                }
                Surface {
                    Label("Ready when you are", systemImage: "keyboard").font(.headline)
                    Text("iOS does not provide a reliable public activation check. Add AirKeyboard in Settings, then select it with the globe key.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    NavigationLink("Installation guide") { SetupView() }
                }
            }.padding(20)
        }.navigationTitle("AirKeyboard").navigationBarTitleDisplayMode(.inline)
    }
}
