# Architecture

AirKeyboard contains five native targets, with no backend or third-party runtime packages:

| Target | Responsibility |
| --- | --- |
| AirKeyboard | SwiftUI containing app; private theme library; app appearance; authoring and file workflows |
| AirKeyboardKeyboard | UIInputViewController; proxy insertion/deletion; in-memory layout/theme/audio |
| AirKeyboardWidgets | Theme timeline widgets and a sound preference SetValueIntent control |
| AirKeyboardTests | Hostless Foundation/core XCTest bundle for iOS Simulator |
| AirKeyboardUITests | Real-app XCTest UI automation |

The Swift Package exposes the same Foundation-only core to `swift test` on macOS. Xcode compiles those files directly into each relevant target; it does not fetch or link a remote package.

`Theme` is a versioned value type. `ThemeCodec` validates before export and after import. `ThemeLibrary` holds up to 200 unique themes and favorite IDs. The app keeps the library in its private Application Support directory; the keyboard and widget only need the active snapshot, not the full library.

`AppModel` owns visible app state on the main actor. Library file operations, import reads, and shared coordination execute in background tasks. A busy guard serializes app library mutations. Shared updates use coordinated read-modify-write transactions, so a control changing the sound toggle does not write a stale theme snapshot. JSON writes are atomic, with a previous valid backup. If both copies are invalid, an error is surfaced; automatic overwriting is not attempted during a read. Shared keyboard writes require Full Access; local-mode choices are saved only inside its own sandbox.

The extension reads shared settings on appearance and every two seconds while visible. No file is opened on a keypress. It cancels polling and delete-repeat timers when hidden and releases audio on disappearance or memory pressure. A render cache avoids rebuilding rows unless shift, layout, theme or relevant input traits change. The status strip reports silent/fallback state rather than claiming successful audio.

Only short surrounding text context is read transiently for capitalization. Nothing is persisted, logged or transmitted. Document identifiers help reset keyboard state when a host field changes; they are never stored.

The containing app reloads WidgetCenter timelines and ControlCenter controls after settings changes. The sound intent does the same. Widgets also request a 15-minute timeline refresh; iOS ultimately schedules delivery. The app refreshes its settings when it becomes active. The sound settings screen uses an explicit save operation so slider movement does not cause disk writes per frame.

Known limits: library save and active-snapshot apply are separate operations, so a save can succeed while apply fails. The UI only reports “saved & applied” after both succeed. Deleting an active custom theme saves the reduced library and attempts to apply Dark Glass; if sharing fails, the prior snapshot may remain active until another apply succeeds. Library backup recovery restores the preceding valid version, which can omit the latest change. Keyboard feedback latency, actor diagnostics and cross-process coordination still need native execution and profiling.

The optional `Desktop/Windows` companion is a separate C# WinForms executable using .NET Framework libraries. It reads IPA ZIP/Mach-O metadata, queries Windows USB/service state and offers a browser/signer/file-drop workflow. It does not send messages to the phone, intercept keyboard data, store credentials or bundle an external signer. Default CI builds/tests the simulator without Apple credentials; the optional device workflow produces only a re-signing input. No certificate-required workflow remains active. All three Info.plists declare the same `AirKeyboardAppGroup` value, which SharedStore reads at runtime; signed-build configuration updates that value and the matching entitlements together.

## Free local mode

SettingsLocation resolves an authorized group or per-target Application Support. The generator --local-device removes App Group entitlements and forces isolated storage. The app can save its designs; the keyboard provides six local designs and sound preferences. Widgets/control explicitly report sharing unavailable. No cross-sandbox synchronization is claimed. See FREE-DEVELOPMENT.md.
