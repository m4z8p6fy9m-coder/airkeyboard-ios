# AirKeyboard

Free, MIT-licensed native iOS keyboard customization: SwiftUI studio, UIKit keyboard extension, original sound packs, theme packages, widgets and a supported Control Center sound preference control. Independent of Apple and AirCard. No backend, accounts, analytics, paid APIs or third-party iOS dependencies.

**Public source:** https://github.com/m4z8p6fy9m-coder/airkeyboard-ios

## Free development comes first

No Apple Developer Program subscription, certificate or signing secret is needed for source tests or the simulator pipeline. Standard GitHub-hosted runners are used only in a public repository. No premium runner or paid service is configured. GitHub is optional for development; the app itself is offline.

[Free development policy and limits](Documentation/FREE-DEVELOPMENT.md) explains the difference between source tests, a simulator build, simulator execution, a signed device build and an installable IPA. A simulator artifact cannot be installed on an iPhone.

## Build and test

On a Mac with Xcode 16.4+ and an iOS 18+ simulator runtime:

```sh
python3 Scripts/check_repository.py
python3 -m unittest discover -s Tests/Packaging -v
swift test
bash Scripts/simulator_build.sh
```

Or open `AirKeyboard.xcodeproj` and select the **AirKeyboard** scheme. There is no dependency install or project-generation step required. The checked-in project includes the app, UIKit keyboard, widgets/control, core XCTest and UI test targets. Native APIs target iOS 18.0 because of WidgetKit controls.

On GitHub, **Free simulator build and tests** runs automatically on pushes/PRs and can be started manually from Actions. It uses standard `macos-15-intel`, Ubuntu and Windows runners; no secrets are required. Native artifacts/logs have one-day retention. The simulator artifact contains the `.app`, logs and evidence, **not an iPhone IPA**. The pipeline fails on a real build/test failure and does not manufacture success.

On Windows, run the two Python commands above and `Desktop/Windows/Build.ps1`; use the public Actions run for Xcode compilation. Windows has no Xcode or iOS Simulator.

## Native features and honest limitations

- Six original data-driven themes; live interactive editor for palette, shapes, borders, font, layout and sound association; favorite, duplicate, reset, create/delete and Files import/export.
- Local library with atomic validated writes and a previous valid backup; bounded 64 KB JSON packages and rejection of invalid/future formats; original examples and schema included.
- Actual UIKit text entry through `textDocumentProxy`: shift/Caps Lock, number/symbol pages, space/newline, delete repeat, globe switching, input traits and lifecycle handling. English QWERTY and a QWERTZ arrangement; no prediction/swipe/dictation.
- Four original short synthesized WAV packs, actual app previews, saved volume/intensity/enabled preferences, optional Full Access-gated keyboard audio and silent fallback. No network client or keystroke history.
- WidgetKit theme timelines and supported sound preference control. Cross-process functions require a genuinely available App Group. Without one, the UI states that sharing is unavailable instead of pretending the control changed the app.
- If an App Group is unavailable, the app still saves its themes/preferences in its own sandbox. The keyboard's **Design** button offers its own built-in themes and sound preference. These per-target files are isolated; app-edited custom themes are not silently shared with extensions.

No replacement for Apple's keyboard globally, Face ID/passcode UI, Wallet internals or arbitrary Control Center is claimed. Secure fields and hosts can reject custom keyboards. Keyboard activation is manual; the app has no reliable activation probe.

## Optional free physical-device experiments

An existing/borrowed Mac with Xcode and a free personal Apple Account may allow personal-device testing subject to Apple's limits. To remove App Group signing requirements from the generated project:

```sh
python3 Scripts/generate_project.py --local-device
```

Choose your Personal Team and unique bundle IDs for the app and both extensions in Xcode, connect your iPhone and use Xcode's supported signing flow. No certificates/profiles are invented. This explicit local mode cannot share theme/control settings between targets. Availability of extension capabilities remains subject to Apple checks; it is not a proven device installation path yet. Free profiles expire and require periodic reinstall. No paid membership is required by this project's development policy.

To restore the default simulator/shared-capable configuration, run the generator without that flag. It overwrites generated project/config/assets; preserve personal configuration first. Keyboard setup: Settings → General → Keyboard → Keyboards → Add New Keyboard → AirKeyboard; select with the globe in a supported field. Full Access is optional for audio, never required for ordinary typing.

## Windows companion

`Desktop/Windows/` contains a real framework-only C# helper. It checks Apple USB presence and IPA structure, opens the free build page and can hand an existing device IPA to an independently installed signer. Apple drivers and that signer are optional tools for device experiments, not dependencies of source/simulator development. No iPhone IPA exists merely because the helper compiled. See [Windows guide](Desktop/Windows/README.md).

## Verification status

Status is recorded in [the implementation report](Documentation/IMPLEMENTATION_REPORT.md) with links to actual Actions runs as they become available. Do not infer native or device success from source checks.

- Portable repository checks, Python packager/profile-validator tests and Windows inspector self-tests have executed locally.
- 16 Foundation XCTest cases passed on macOS and 16 passed in iOS Simulator. App and both native extensions compiled with device signing disabled. The app UI save/relaunch test is being retested; consult the report for its actual result.
- Physical iPhone typing/audio, shared App Group behavior, widget/control interactions and accessibility require device testing. No signed-device or installable-IPA result is claimed.

## Project map

`App/` SwiftUI UI/state; `Keyboard/` UIKit extension; `Widgets/` WidgetKit/App Intents; `Shared/Core/` Foundation models/validation/storage; `Shared/Platform/` audio/colors/settings; `Config/` project metadata; `Resources/` original assets/privacy manifest; `Tests/` native and portable tests; `Desktop/Windows/` companion; `Scripts/` build/check/package utilities.

[Architecture](Documentation/ARCHITECTURE.md) · [Theme format](Documentation/THEMES.md) · [Audio](Documentation/AUDIO.md) · [Privacy](Documentation/PRIVACY.md) · [Capabilities](Documentation/CAPABILITIES.md) · [Testing](Documentation/TESTING.md) · [Asset licenses](ASSETS.md) · [Contributing](CONTRIBUTING.md) · [MIT License](LICENSE)
