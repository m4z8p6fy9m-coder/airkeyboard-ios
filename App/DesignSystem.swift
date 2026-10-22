import SwiftUI

struct Surface<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.primary.opacity(0.08)))
    }
}

struct KeyboardPreview: View {
    var theme: Theme
    @State private var text = ""
    @State private var state = KeyboardState()
    @Environment(\.colorScheme) private var colorScheme
    private var displayTheme: Theme { theme.resolved(dark: colorScheme == .dark) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onKey: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(text.isEmpty ? "Try your design" : text).lineLimit(2)
                    .font(.body).accessibilityLabel("Preview text: \(text)")
                Spacer()
                Button("Clear") { text = "" }.font(.caption)
            }.foregroundStyle(Color(hex: displayTheme.primary)).padding(.horizontal, 6)
            ForEach(Array(state.rows(layout: theme.layout).enumerated()), id: \.offset) { _, row in
                HStack(spacing: theme.spacing) {
                    ForEach(row, id: \.self) { key in
                        previewKey(state.shift == .off ? key : key.uppercased()) {
                            text.append(contentsOf: state.character(key)); onKey?()
                        }
                    }
                }
            }
            HStack(spacing: theme.spacing) {
                previewKey(state.shift == .locked ? "⇪" : "⇧") { state.toggleShift() }
                    .accessibilityLabel("Shift")
                    .contextMenu { Button("Caps Lock") { state.toggleShift(lock: true) } }
                previewKey(state.page == .letters ? "123" : "ABC") {
                    state.page = state.page == .letters ? .numbers : .letters
                }
                previewKey("space") { text.append(" "); onKey?() }.frame(minWidth: 80)
                previewKey("⌫") { if !text.isEmpty { text.removeLast() }; onKey?() }.accessibilityLabel("Delete")
            }
        }
        .padding(theme.padding + 4)
        .background(Color(hex: displayTheme.background), in: RoundedRectangle(cornerRadius: 18))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: theme)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Interactive keyboard preview")
    }
    private func previewKey(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(.body, design: theme.font == .rounded ? .rounded : theme.font == .monospaced ? .monospaced : .default))
                .minimumScaleFactor(0.6).lineLimit(1).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(PreviewKeyStyle(theme: displayTheme, special: ["⇪", "⇧", "123", "ABC", "⌫"].contains(label)))
    }
}
struct PreviewKeyStyle: ButtonStyle {
    let theme: Theme
    var special = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundStyle(Color(hex: theme.primary))
            .background(ThemeKeySurface(theme: theme, special: special, pressed: configuration.isPressed))
    }
}

