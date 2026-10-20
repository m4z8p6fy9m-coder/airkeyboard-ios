import SwiftUI
import WidgetKit

struct ThemeEntry: TimelineEntry {
    let date: Date
    var settings = SharedSettings()
    var unavailable = false
}
struct ThemeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThemeEntry { ThemeEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (ThemeEntry) -> Void) {
        Task { completion(await entry()) }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ThemeEntry>) -> Void) {
        Task { completion(Timeline(entries: [await entry()], policy: .after(.now.addingTimeInterval(900)))) }
    }
    private func entry() async -> ThemeEntry {
        do { return ThemeEntry(date: .now, settings: try await SharedStore.load(requiresShared: true)) }
        catch { return ThemeEntry(date: .now, unavailable: true) }
    }
}
struct ThemeWidgetView: View {
    let entry: ThemeEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("AirKeyboard", systemImage: "keyboard").font(.caption)
            Text(entry.unavailable ? "Sharing unavailable" : entry.settings.theme.name).font(.headline)
            if family != .accessoryRectangular {
                HStack(spacing: 5) {
                    ForEach(["A", "I", "R"], id: \.self) { key in
                        Text(key).font(.title3.bold()).frame(maxWidth: .infinity, minHeight: 36)
                            .foregroundStyle(Color(hex: entry.settings.theme.primary))
                            .background(Color(hex: entry.settings.theme.key), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
                Text(entry.unavailable ? "Open app for local themes" : entry.settings.sound.enabled ? entry.settings.sound.pack.title : "Sounds off").font(.caption)
            }
        }
        .containerBackground(for: .widget) { Color(hex: entry.settings.theme.background) }
        .foregroundStyle(family == .accessoryRectangular ? Color.primary : Color(hex: entry.settings.theme.primary))
        .widgetURL(URL(string: "airkeyboard://themes"))
    }
}
struct ThemeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "org.example.airkeyboard.theme", provider: ThemeProvider()) { ThemeWidgetView(entry: $0) }
            .configurationDisplayName("Current design")
            .description("Your active AirKeyboard theme. Tap to open Themes.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
@main struct AirKeyboardWidgets: WidgetBundle {
    var body: some Widget { ThemeWidget(); SoundControl() }
}
