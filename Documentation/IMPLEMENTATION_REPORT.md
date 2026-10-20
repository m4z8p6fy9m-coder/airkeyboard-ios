# Implementation report — 2026-10-20

## Environment and preservation

The initial workspace contained only empty output/scratch directories, no repository, native code, Xcode project or existing functionality. The host is Windows 10.0.19045 with PowerShell, Python 3.11.9 and Git. Swift and xcodebuild were not found. No macOS, iOS simulator or physical iPhone test session was available. A new native repository was created under `airkeyboard-ios`; no existing project was deleted or replaced. A local Git repository was initialized on `main`, with no remote or commit created.

## What was implemented

- Native SwiftUI containing app: home, themes, interactive Keyboard Studio, sounds, integration previews/setup and settings. Dark default, selectable light/system appearance, reusable material surfaces, Dynamic Type fonts, VoiceOver labels and Reduce Motion-aware preview transitions.
- Six original theme presets and real data editing: colors, geometry, fonts, appearance, QWERTY/QWERTZ and pack association; favorites, duplication, creation, reset, confirmation before custom-theme deletion and active-snapshot apply.
- Private local library with validated saves, atomic writes and a valid prior-copy recovery path. Active settings are shared through an App Group using background coordinated transactions.
- Versioned JSON import/export through Files, 64 KB import bound, validation, future-version/unknown-enum rejection and a fresh local identifier on import. No archive extraction or imported asset paths. JSON Schema and six examples included.
- Actual UIKit keyboard extension: proxy insertion/deletion, shift, double-tap Caps Lock, numbers/symbol pages, space/newline, repeat delete, system input-mode selection, email/URL keys, return labels, capitalization traits, field changes, adaptive height, pressed/disabled states, settings refresh and lifecycle cleanup.
- Four original short WAV packs plus Silent, actual AVAudioPlayer previews, saved enable/volume/intensity preferences, cached assets, ambient session handling, interruption/route handling, failure states and Full Access-gated keyboard playback. No-Full-Access fallback is silent typing.
- Genuine WidgetKit small/medium theme widgets and rectangular Lock Screen widget, deep link into Themes, timeline refresh and a Control Center sound preference toggle backed by SetValueIntent.
- Checked-in Xcode project with app, keyboard, widgets/control and iOS core-test targets; shared scheme, matching App Group entitlements, Info.plists, code-drawn app icon and privacy manifest. No signing identity supplied.
- Foundation Swift Package tests, portable artifact checks, macOS GitHub Actions build/test workflow, MIT license, contribution/conduct/security policies, architecture, capability boundaries, audio/privacy docs and device test plan.

## Created files and targets

All files are new. The target names are **AirKeyboard**, **AirKeyboardKeyboard**, **AirKeyboardWidgets**, and **AirKeyboardTests**. `Package.swift` adds the Foundation-only **AirKeyboardCore** library/test package for macOS test execution. `App/`, `Keyboard/`, `Widgets/`, `Shared/Core/`, `Shared/Platform/`, `Config/`, `Resources/`, `Tests/CoreTests/`, `Examples/`, `Scripts/` and `.github/workflows/ci.yml` separate responsibilities. README describes their contents and exact commands.

## Actually executed

| Check | Outcome |
| --- | --- |
| Environment/tool/repository inspection | Executed; empty workspace; no Swift/Xcode |
| Python project/configuration/audio/icon generation | Executed successfully |
| `python Scripts/check_repository.py` | **8 tests passed** |
| Python bytecode compilation of all three scripts | Executed successfully |
| `swift test` | **Not run** — Swift toolchain unavailable |
| Xcode app/keyboard/widget builds | **Not run** — macOS/Xcode unavailable |
| 13 Foundation XCTest cases / iOS test bundle | Authored; **not run** |
| GitHub Actions workflow | Authored; **not run**; no remote published |
| UI, keyboard typing, audio listening and device tests | **Not run** |

Portable checks establish the consistency of the generated project graph, file membership, extension embedding, scheme references, entitlements/Info.plists/privacy declarations, example-package fields and PCM asset properties. They confirm four distinct nonempty mono 16-bit 44.1 kHz signals, at most 50 ms long, bounded below half-scale with short faded tails. They do **not** establish Swift compilation, AVAudioPlayer success, host typing, sandbox sharing, audio latency or widget/control execution. The source scan is a limited regression guard, not a security audit.

The README assigns every feature to the requested status categories. Native functionality is **implemented but not yet verified on a physical device**, and its first compile is also outstanding. Asset-file structure and portable repository checks are **implemented and tested**. Native test/CI integration is **partially implemented** until executed. Unsupported system replacement and no-access audio are **blocked by iOS restrictions**. Prediction/swipe/dictation and public GitHub publication are **not implemented**.

## Platform restrictions

The deployment target is iOS 18 because real WidgetKit controls require it. The keyboard cannot replace Apple's keyboard globally, run in secure/password fields, force host apps to permit extensions, or enable itself. The app cannot reliably detect activation. Face ID, passcode UI, SpringBoard, arbitrary Control Center and Wallet internals cannot be reskinned through these APIs.

Custom keyboard audio is optional and gated by RequestsOpenAccess configuration plus the user's explicit Full Access grant and `hasFullAccess` check. Full Access broadens capabilities beyond audio; AirKeyboard contains no network client. System clicks and arbitrary sound packs are different APIs. Without permission or when audio fails, typing remains silent. Current Apple docs describe read-only shared-container access without Full Access; this and older-iOS behavior require physical validation. Audio mute/routes and widget refresh are ultimately controlled by iOS. Apple sources and decisions are linked in CAPABILITIES.md and AUDIO.md.

## Exact next build/install/test steps

1. On a Mac with Xcode 16.4+ and an iOS 18+ SDK/runtime, open `AirKeyboard.xcodeproj` and select **AirKeyboard**.
2. Run `python3 Scripts/check_repository.py`, then `swift test` at repository root.
3. Build and run the Xcode scheme on a compatible iPhone Simulator; use README’s `xcodebuild` commands to compile the app and both embedded extensions, then run the iOS core-test bundle. Fix actual compiler/runtime errors before changing the status table.
4. For device testing, set your development team on the three product targets, replace the placeholder bundle prefix and register your own App Group. Update **all three** entitlements and **all three** `AirKeyboardAppGroup` Info.plist fields to match. SharedStore reads that field at runtime. Ensure provisioning includes that group.
5. Select an iOS 18+ iPhone and Run. Add/select AirKeyboard in Settings → General → Keyboard → Keyboards. Use a supported non-secure Notes field and the globe selector.
6. Test silent typing first. Save/apply a custom theme and confirm sharing. Optionally grant Full Access, explicitly enable audio, and run the AUDIO.md matrix. Test revocation as well as initial denial.
7. Add the AirKeyboard sound control from Control Center’s Add a Control gallery; add widgets from the Home/Lock Screen editors. Verify actual state propagation and tap behavior.
8. Complete TESTING.md with recorded model/OS/results, then update status and consider a public GitHub release. Do not ship based solely on the current portable checks.

**Best next step:** perform the first Mac/Xcode build and core test run, fix concrete native diagnostics, then test keyboard text entry and permission-gated audio on an iPhone before adding more features.

## Windows implementation follow-up

At the user's request, the project now contains an original Windows desktop companion and hosted iPhone packaging/signing workflows. `Desktop/Windows/AirKeyboardConnect.cs` compiles to a real .NET Framework Windows GUI executable; `Build.ps1` requires no NuGet packages. The helper detects Apple USB devices/service status, inspects real IPA structures and ARM64/iOS Mach-O headers, opens the hosted-build page and installed Sideloadly, and supplies an actual file drag source. Signing/login/final installation occur in that external signer; no success is fabricated. A rendered preview of the actual WinForms controls was visually reviewed; no phone was connected for this check.

The Windows compiler was available and **the EXE build succeeded**. Its **7 C# self-tests passed**. **12 new Python tests passed** for `package_iphone.py` and development-profile validation, using synthetic fixtures. Combined with the existing **8 repository checks**, **27 local automated checks passed**. Python scripts compiled successfully. This does not change the outstanding status of the 13 Swift XCTest cases or the first Xcode build.

`.github/workflows/iphone-package.yml` builds the device app on a macOS runner, packages it only after real binaries exist, and builds/tests the Windows helper separately. `.github/workflows/iphone-signed.yml` supports a real team's owned IDs, certificate and three development profiles, validating group consistency before signed export. Neither workflow has run; no actual IPA, Apple signature or device installation is claimed. No remote was created and no credentials were requested in chat or embedded. See WINDOWS.md for exact setup and remaining tests. App Group names are now read from matching Info.plist fields so hosted signing configuration can set them consistently across all targets without rewriting Swift source.
