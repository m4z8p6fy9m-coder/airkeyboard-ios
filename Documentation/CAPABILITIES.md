# Supported customization and API decisions

Documentation reviewed on 2026-10-20. Source-level design decisions below are not device test results.

| Area | Supported approach | Boundary |
| --- | --- | --- |
| Custom keyboard | UIKit UIInputViewController + UITextDocumentProxy | Only supported host fields; secure fields and some phone inputs switch to system keyboard; host apps may reject extensions |
| Themes | Render AirKeyboard’s own UIKit keys | Cannot theme Apple’s keyboard, SpringBoard, Wallet or arbitrary apps |
| Audio | Bundled AVAudioPlayer taps under optional keyboard Full Access | No audio promise without permission; device mute/volume/routes apply; silent fallback |
| Settings sharing | App Group active snapshot; keyboard reads only | Current Apple guidance allows shared-container reads without Full Access; older archived guidance differs; verify on every supported OS |
| Controls | WidgetKit ControlWidget + SetValueIntent | iOS 18+; changes AirKeyboard preference only; cannot grant permissions or replace Control Center |
| Widgets | WidgetKit timeline and widgetURL | Supported widget regions only; system schedules updates; tapping opens Themes |
| Setup | Public app-settings URL plus manual guide | Cannot enable/select keyboard programmatically or reliably inspect installation status |
| Lock Screen | Rectangular accessory widget | Cannot replace Face ID/passcode UI or reskin whole Lock Screen |

Minimum deployment is iOS 18, chosen for ControlWidget APIs. SwiftUI and UIKit remain native. The implementation intentionally avoids newer appearance APIs that would increase this minimum. User-driven wallpaper/Home Screen edits can use Apple's own customization UI; this release supplies neither wallpaper automation nor alternate app icons.

## Primary Apple references

- [Creating a custom keyboard](https://developer.apple.com/documentation/uikit/creating-a-custom-keyboard): extension architecture and Info.plist configuration.
- [Handling text interactions](https://developer.apple.com/documentation/uikit/handling-text-interactions-in-custom-keyboards): insertion/deletion and context changes.
- [UITextDocumentProxy](https://developer.apple.com/documentation/uikit/uitextdocumentproxy): host traits and context API.
- [Configuring open access](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard): sandbox, current read-only shared-container capability and explicit user grant.
- [Archived Custom Keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html): secure-field/host restrictions and explicit audio restrictions. Some container-sharing language predates the current guidance above.
- [RequestsOpenAccess](https://developer.apple.com/documentation/bundleresources/information-property-list/nsextension/nsextensionattributes/requestsopenaccess): requested capability, not a silent user grant.
- [Creating controls](https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system): static control configuration, value provider, SetValueIntent, reloads.
- [WidgetKit controls](https://developer.apple.com/documentation/widgetkit/controls-collection) and [StaticControlConfiguration](https://developer.apple.com/documentation/widgetkit/staticcontrolconfiguration): iOS 18 system integration.
- [Creating a widget extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension), [TimelineProvider](https://developer.apple.com/documentation/widgetkit/timelineprovider), [widgetURL](https://developer.apple.com/documentation/swiftui/view/widgeturl(_:)): system timeline and app entry points.
- [NSFileCoordinator](https://developer.apple.com/documentation/foundation/nsfilecoordinator): coordinated access across app/extension processes.
- [Required-reason API declarations](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype): own-app UserDefaults reason CA92.1 for appearance AppStorage.

The project includes a shared privacy manifest declaring no tracking or collected data and the own-app UserDefaults reason. There are no network clients, keyboard logs, private APIs or system-modification techniques. Re-audit the manifest when adding APIs; source scans are not a substitute for a privacy/security review.
