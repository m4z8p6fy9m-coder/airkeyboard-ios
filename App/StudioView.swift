import SwiftUI

struct StudioView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State var theme: Theme
    @State private var saved = false
    @State private var reset = false
    @State private var previewDark = true
    @State private var previewOpaque = false
    @State private var previewContrast = false
    @State private var openingTheme: Theme?
    @Environment(\.accessibilityReduceTransparency) private var systemOpaque
    @Environment(\.colorSchemeContrast) private var systemContrast
    private var validationMessage: String? {
        do { _ = try theme.validated(); return nil }
        catch { return error.localizedDescription }
    }
    @FocusState private var nameFocused: Bool
    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Toggle(isOn: $previewDark) {
                        Label("Dark preview", systemImage: previewDark ? "moon.fill" : "sun.max.fill")
                    }.accessibilityIdentifier("studio.preview.dark")
                    KeyboardPreview(theme: theme) { model.previewSound(theme.soundPack) }
                        .environment(\.accessibilityReduceTransparency, systemOpaque || previewOpaque)
                        .environment(\.colorSchemeContrast, systemContrast == .increased || previewContrast ? .increased : .standard)
                }
                .padding(12)
                .background(previewDark ? Color(red: 0.06, green: 0.09, blue: 0.12) : Color(red: 0.96, green: 0.97, blue: 0.98),
                            in: RoundedRectangle(cornerRadius: 20))
                .environment(\.colorScheme, previewDark ? .dark : .light)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("Changes appear live. Light/dark switches adaptive palettes when available; fixed palettes keep their colors. Audio previews respect device mute and volume preferences.")
            }
            Section("Accessibility preview") {
                Toggle("Opaque key surfaces", isOn: $previewOpaque)
                    .accessibilityIdentifier("studio.preview.opaque")
                Toggle("Increase contrast", isOn: $previewContrast)
                    .accessibilityIdentifier("studio.preview.contrast")
                if let ratio = theme.minimumPrimaryContrast(dark: previewDark) {
                    Text("Minimum primary text contrast: \(ratio, specifier: "%.2f"):1")
                        .foregroundStyle(ratio < 4.5 ? Color.orange : Color.secondary)
                        .accessibilityIdentifier("studio.contrast.ratio")
                    if ratio < 4.5 { Text("Below the 4.5:1 small-text target. Review the key and text colors.") }
                }
            } footer: {
                Text(theme.rendering?.surface == .glass
                     ? "Contrast is measured on the opaque fallback, not the live blur. System accessibility settings always take precedence. This is not an accessibility audit."
                     : "Contrast covers primary glyphs on normal, modifier and pressed keys. Secondary labels and actual device rendering still need review.")
            }
            Section("Identity") {
                TextField("Name", text: $theme.name)
                    .accessibilityIdentifier("studio.name")
                    .focused($nameFocused).submitLabel(.done).onSubmit { nameFocused = false }
                TextField("Description", text: $theme.description, axis: .vertical)
                if theme.rendering?.light != nil {
                    Toggle("Follow system appearance", isOn: Binding(
                        get: { theme.rendering?.followsSystem == true },
                        set: { theme.rendering?.followsSystem = $0 }))
                }
                Picker("Appearance", selection: Binding(get: { theme.appearance }, set: {
                    theme.appearance = $0
                    theme.rendering?.followsSystem = false
                })) {
                    ForEach(ThemeAppearance.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            Section("Palette") {
                color("Background", .background); color("Keys", .key)
                if theme.rendering != nil { color("Special keys", .specialKey) }
                color("Text", .primary); color("Secondary labels", .secondary)
                color("Accent", .accent); color("Pressed keys", .pressed); color("Borders", .border)
            } footer: {
                Text(theme.rendering?.followsSystem == true
                     ? "Editing the displayed light or dark palette. The other palette is preserved."
                     : "Editing the fixed palette.")
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
            if let validationMessage {
                Section("Cannot save yet") { Text(validationMessage).foregroundStyle(.red) }
            }
            Section {
                Button("Revert unsaved changes", systemImage: "arrow.uturn.backward") {
                    if let openingTheme { theme = openingTheme }
                }.disabled(openingTheme == nil || openingTheme == theme)
                Button("Reset design", role: .destructive) { reset = true }
            }
        }
        .onAppear {
            if openingTheme == nil { openingTheme = theme }
            previewDark = theme.rendering?.followsSystem == true ? colorScheme == .dark : theme.appearance == .dark
        }
        .navigationTitle("Keyboard Studio").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save & apply") {
                    nameFocused = false
                    Task { if await model.save(theme), await model.apply(theme) { saved = true } }
                }.disabled(model.busy || validationMessage != nil)
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
    private func color(_ title: String, _ role: ThemeColorRole) -> some View {
        let surfaceRoles: [ThemeColorRole] = [.key, .specialKey, .pressed, .border]
        let alpha = theme.rendering?.surface == .glass && surfaceRoles.contains(role)
        return ColorPicker(title, selection: Binding(
            get: { Color(hex: theme.color(role, dark: previewDark)) },
            set: { theme.setColor(alpha ? $0.rgbaHex : $0.rgbHex, role: role, dark: previewDark) }),
            supportsOpacity: alpha)
    }
    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(value.wrappedValue, specifier: "%.1f")").font(.subheadline)
            Slider(value: value, in: range).accessibilityLabel(title)
        }
    }
}
