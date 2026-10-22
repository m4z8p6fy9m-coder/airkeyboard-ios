import SwiftUI
import UniformTypeIdentifiers

struct ThemeDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var theme: Theme
    init(theme: Theme) { self.theme = theme }
    init(configuration: ReadConfiguration) throws {
        theme = try ThemeCodec.decode(configuration.file.regularFileContents ?? Data())
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try ThemeCodec.encode(theme))
    }
}

struct ThemesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var importing = false
    @State private var exporting = false
    @State private var exportTheme = StarterThemes.defaultTheme
    @State private var deletion: Theme?
    @State private var favoritesOnly = false
    @State private var query = ""
    @State private var order = ThemeSortOrder.catalog
    private var catalog: [Theme] {
        model.library.catalog(query: query, favoritesOnly: favoritesOnly, order: order)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Toggle("Favorites only", isOn: $favoritesOnly)
                Picker("Sort themes", selection: $order) {
                    Text("Catalog").tag(ThemeSortOrder.catalog)
                    Text("Name").tag(ThemeSortOrder.name)
                    Text("Favorites first").tag(ThemeSortOrder.favorites)
                }.accessibilityIdentifier("themes.sort")
                if model.library.themes.count >= 200 {
                    Label("Library full: export and delete a design before saving a new one.", systemImage: "tray.full")
                        .font(.callout).foregroundStyle(.secondary)
                }
                if catalog.isEmpty {
                    ContentUnavailableView("No matching themes", systemImage: "magnifyingglass",
                                           description: Text("Clear the search or turn off Favorites only."))
                }
                ForEach(catalog) { theme in
                    Surface {
                        HStack {
                            VStack(alignment: .leading) { Text(theme.name).font(.title3.bold()); Text(theme.description).font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            Button { Task { await model.favorite(theme.id) } } label: {
                                Image(systemName: model.library.favorites.contains(theme.id) ? "heart.fill" : "heart")
                            }.accessibilityLabel("Favorite \(theme.name)")
                            .disabled(!model.library.themes.contains(where: { $0.id == theme.id }))
                        }
                        KeyboardPreview(theme: theme)
                        HStack {
                            Button(model.settings.theme == theme ? "Applied" : "Apply") { Task { await model.apply(theme) } }
                                .buttonStyle(.borderedProminent)
                            NavigationLink("Edit") { StudioView(theme: theme) }
                                .accessibilityIdentifier("theme.edit.\(theme.id.uuidString)")
                            Spacer()
                            Menu {
                                Button("Duplicate", systemImage: "plus.square.on.square") {
                                    var copy = theme; copy.id = UUID(); copy.name = String(theme.name.prefix(50)) + " copy"
                                    Task { _ = await model.save(copy) }
                                }
                                Button("Export JSON", systemImage: "square.and.arrow.up") { exportTheme = theme; exporting = true }
                                if !StarterThemes.all.contains(where: { $0.id == theme.id }) {
                                    Button("Delete", role: .destructive) { deletion = theme }
                                }
                            } label: { Image(systemName: "ellipsis.circle").padding(8) }.accessibilityLabel("Theme actions")
                        }
                    }
                }
            }.padding(20).disabled(model.busy)
        }.navigationTitle("Themes")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search name or description")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Import", systemImage: "square.and.arrow.down") { importing = true } }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { StudioView(theme: newTheme) } label: { Label("New theme", systemImage: "plus") }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): Task { await model.importTheme(url) }
            case .failure(let error): model.error = error.localizedDescription
            }
        }
        .fileExporter(isPresented: $exporting, document: ThemeDocument(theme: exportTheme), contentType: .json,
                      defaultFilename: "AirKeyboard-theme") { result in
            if case .failure(let error) = result { model.error = error.localizedDescription }
        }
        .confirmationDialog("Delete \(deletion?.name ?? "theme")?", isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } })) {
            Button("Delete theme", role: .destructive) { if let theme = deletion { Task { await model.delete(theme.id) } }; deletion = nil }
        } message: { Text("This removes the saved theme. Export it first to keep a copy.") }
    }
    private var newTheme: Theme {
        var theme = StarterThemes.defaultTheme; theme.id = UUID(); theme.name = "Untitled"; return theme
    }
}
