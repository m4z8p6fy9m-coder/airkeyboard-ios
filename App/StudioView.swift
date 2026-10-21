import SwiftUI

struct StudioView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var theme: Theme
    @State private var saved = false
    @State private var reset = false
    @State private var previewDark = true
    @FocusState private var nameFocused: Bool
    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Toggle(isOn: $previewDark) {
                        Label("Dark preview", systemImage: previewDark ? "moon.fill" : "sun.max.fill")
                    }.accessibilityIdentifier("studio.preview.dark")
                    KeyboardPreview(theme: theme) { model.previewSound(theme.soundPack) }
                }
                .padding(12)
                .background(previewDark ? Color(red: 0.06, green: 0.09, blue: 0.12) : Color(red: 0.96, green: 0.97, blue: 0.98),
                            in: RoundedRectangle(cornerRadius: 20))
                .environment(\.colorScheme, previewDark ? .dark : .light)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("Changes appear live. Light/dark changes the preview surroundings and keeps your chosen key colors. Audio previews respect device mute and volume preferences.")
            }
            Section("Identity") {
                TextField("Name", text: $theme.name)
                    .focused($nameFocused).submitLabel(.done).onSubmit { nameFocused = false }
                TextField("Description", text: $theme.description, axis: .vertical)
                Picker("Appearance", selection: $theme.appearance) {
                    ForEach(ThemeAppearance.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            Section("Palette") {
                color("Background", \.background); color("Keys", \.key)
                color("Text", \.primary); color("Secondary labels", \.secondary)
                color("Accent", \.accent); color("Pressed keys", \.pressed); color("Borders", \.border)
            }
            Section("Shape & rhythm") {
                slider("Corner radius", $theme.cornerRadius, 0...20)
                slider("Key spacing", $theme.spacing, 2...8)
                slider("Padding", $theme.padding, 2...12)
                slider("Border width", $theme.borderWidth, 0...2)
            }
            Section("Type & sound") {
                Picker("Font", selection: $theme.font) { ForEach(KeyFont.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) } }
                Picker("Layout", selection: $theme.layout) { ForEach(KeyboardLayout.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) } }
                Picker("Sound pack", selection: $theme.soundPack) { ForEach(SoundPack.allCases, id: \.self) { Text($0.title).tag($0) } }
                Button("Preview sound") { model.previewSound(theme.soundPack) }
            }
            Section {
                Button("Reset design", role: .destructive) { reset = true }
            }
        }
        .onAppear { previewDark = theme.appearance == .dark }
        .navigationTitle("Keyboard Studio").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save & apply") {
                    nameFocused = false
                    Task { if await model.save(theme), await model.apply(theme) { saved = true } }
                }.disabled(model.busy)
            }
        }
        .alert("Theme saved & applied", isPresented: $saved) { Button("Done") { dismiss() } } message: {
            Text(model.sharingAvailable ? "Your design is available to the keyboard and widgets." : "Saved in this app. Local mode cannot share it with the keyboard or widgets; the keyboard has its own built-in design picker.")
        }
        .confirmationDialog("Reset this design?", isPresented: $reset) {
            Button("Reset", role: .destructive) {
                let id = theme.id
                theme = StarterThemes.all.first(where: { $0.id == id }) ?? StarterThemes.defaultTheme
                theme.id = id
            }
        }
    }
    private func color(_ title: String, _ path: WritableKeyPath<Theme, String>) -> some View {
        ColorPicker(title, selection: Binding(get: { Color(hex: theme[keyPath: path]) },
                                             set: { theme[keyPath: path] = $0.rgbHex }), supportsOpacity: false)
    }
    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(value.wrappedValue, specifier: "%.1f")").font(.subheadline)
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }
}
