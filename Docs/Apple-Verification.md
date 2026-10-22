# Apple/Xcode verification — 2026-10-22

[CI run #23](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39835280173) completed successfully in 9m 30s on the separate `premium-themes-verification` branch. All three jobs passed. This records one successful run, not a guarantee of future runner availability.

Tested remote source: **`8a17dafd1d05ad5a3b9bbe0d90a9494228fd4e20`**. It matches the committed implementation at local **`381442f5e68bb608009221c3a57820871e0f14f0`**; the histories differ because the files were uploaded through GitHub's authenticated web interface. Subsequent documentation-only commits do not change the tested implementation. Main and the published v0.1.0 release were not changed.

## Actual results

| Check | Result |
| --- | --- |
| CI source checks | 8 repository checks + 26 Python packaging tests passed |
| Windows companion | Build succeeded; 7 inspector self-tests passed; no installation on an iPhone |
| macOS Foundation tests (`swift test`) | 27 XCTest cases, 0 failures |
| Xcode Simulator build | `BUILD SUCCEEDED`; app, UIKit keyboard extension and WidgetKit/Control Center extension built without device signing |
| Explicit Simulator boot | Succeeded |
| Core XCTest on Simulator | 27 cases, 0 failures; the same suite also ran through `swift test` above |
| Real-app UI tests | 3 cases, 0 failures; 86.089s total |
| Local Windows checks | 8 repository checks + 29 packaging tests passed; the extra 3 runtime-selection tests are pre-existing local-only changes excluded from the upload |

Toolchain recorded by the run: standard `macos-15` runner, `arm64`, Xcode 16.4 (16F6), iPhone SE (3rd generation) Simulator with iOS 26.2. Xcode used its iPhoneSimulator18.5 SDK; the installed Simulator runtime is a separate version. No workflow file was changed for this verification.

The UI tests verified:

1. Opening Studio, switching the preview both ways, saving a uniquely named theme, terminating/relaunching the app and finding the persisted theme through search (51.065s).
2. Clearing the theme name and observing Save & apply become disabled (19.399s).
3. Searching for Slate Glass, opening its editor, enabling opaque preview and finding the contrast readout (15.626s).

These assertions do not constitute screenshot pixel comparison, VoiceOver testing or a real keyboard-extension host test. Three original XCTest screenshot attachments were retained in the result bundle: `Theme Studio light preview`, `Saved theme after app relaunch`, and `Slate Glass opaque preview controls`. A fixed dark theme retains its key colors when the light preview surround is selected, as explained in Studio.

## Fixes established by actual failed builds

- [Run #21](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39811412838): SwiftUI could not type-check the combined Studio expression in time. Local commit `e90d98f` split it into focused computed sections.
- [Run #22](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39834306356): Xcode rejected writes to read-only accessibility environment values and two Section initializers. Local commit `381442f` uses a dedicated writable preview environment value, preserves the actual system settings as the minimum, and provides explicit section headers/footers.
- Local commits `848ee35` and `887843a` retain the UI assertions while making scrolling controls reachable and sharing accessible key-surface rendering across app/widget previews.

## Evidence and limits

The [run artifact](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39835280173/artifacts/12449774775) contains logs, the unsigned Simulator app archive and `TestResults.xcresult`. Its configured retention is one day (expires 2026-10-23); a local copy was downloaded and ZIP integrity and SHA-256 were checked:

`253eadfecfff438923e4da34c1d48024d5972cc0bad4ba9bba83d2fc01e00d3e`

Non-failing warnings remain: GitHub's Node 20 action deprecation notice, AppIntents metadata extraction for targets without that framework, and stripping notices for Apple's already-signed XCTest libraries. They were not suppressed. Updating action versions is outside this verification's unchanged-workflow scope.

**Simulator-only. Device verification pending.** There is no signed device build or installable iPhone IPA. Audio, haptics, entitlement-backed App Group sharing, installed widgets/Control Center, UIKit blur quality/performance in real host apps, VoiceOver, Dynamic Type and system accessibility changes still need the [device checklist](Device-Verification.md). No paid service, new dependency, signing credential or security bypass was added.
