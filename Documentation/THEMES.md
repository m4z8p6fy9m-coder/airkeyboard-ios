# Theme packages, version 1

A package is a single UTF-8 JSON file, at most 65,536 bytes. [theme.schema.json](theme.schema.json) documents its structure. See `Examples/` for six complete packages.

All fields are required. Keys are case sensitive. UUID identifiers describe the exported theme; import deliberately assigns a fresh UUID to avoid overwriting local items. Names must have 1–60 Swift Characters, include non-whitespace content and contain no control characters; descriptions allow at most 500 Characters. The JSON Schema length rules count Unicode code points, so unusually combined Unicode text may encounter a stricter external schema validator than the app's Character-based limit. Version and compatibility fields are exactly `schemaVersion: 1` and `minimumIOS: 18`.

Colors are opaque `#RRGGBB` values. There are seven: `background`, `key`, `primary`, `secondary`, `accent`, `pressed`, `border`. Numeric geometry bounds: `cornerRadius` 0–20, `spacing` 2–8, `padding` 2–12, `borderWidth` 0–2. All numbers must be finite. Layouts are `qwerty` and `qwertz`; fonts are `rounded`, `standard`, `monospaced`; appearance is `dark` or `light`; sound packs are `tactile`, `mechanical`, `pop`, `digital`, `silent`.

Appearance records the keyboard’s selected contrast/style mode; it does not automatically regenerate the palette. The app’s appearance preference is independent. Secondary colors style status labels; accent styles shift/return. Sound volume, intensity and enabled state are personal settings and are not exported with a theme. Applying a theme sets its associated pack while preserving the personal audio levels and enabled preference.

Malformed input, missing required fields, wrong types, unknown enum values, unsupported versions, invalid geometry and invalid colors are rejected. The decoder reads the version header before other fields so future versions have a useful error. Unknown **metadata fields** are ignored for compatible schema evolution; they are not retained on export. Unknown fields cannot become file paths, URLs, scripts, assets or runtime instructions. This format accepts no external assets or archives, which removes archive path traversal and decompression risks.

The importer uses the system Files picker and security-scoped access. It checks for a regular file and its size, then reads at most the limit plus one byte before decoding. It never constructs a filesystem path from imported content. Export uses FileDocument and the system exporter; choose Files or share from the system workflow.

To add a starter theme, add data to `StarterThemes.swift`, assign a stable UUID, create a matching JSON example and run tests. Keep readable contrast, provide both appropriate pressed/border states, and test actual key sizes on narrow devices. The editor allows low-contrast user palettes; automated contrast enforcement is not implemented.
