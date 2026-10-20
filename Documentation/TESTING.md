# Testing and troubleshooting

## Executed on Windows

`python Scripts/check_repository.py`: **8 tests passed**. These inspect the OpenStep project graph, source/resource membership, extension embedding, shared scheme references, entitlement and Info.plist consistency, privacy declarations, six example packages, short original WAV assets and a narrow source guard against network/clipboard clients. They do not compile Swift, run the importer, play sounds or operate an iPhone. See IMPLEMENTATION_REPORT.md.

Windows follow-up: the native companion EXE compiled successfully and its **7 C# self-tests passed**. The actual WinForms surface was rendered and visually reviewed. `python -m unittest discover -s Tests/Packaging -v` ran **12 passing tests** for IPA packaging and profile validation. Fixtures use synthetic Mach-O headers and invented profile identifiers; they do not establish real Apple signing or iPhone installation. Total executed local checks: **27**. The hosted IPA/signing workflows and physical USB/signing/install path remain unexecuted. Follow WINDOWS.md for setup.

## Native tests to run on a Mac

`swift test` runs 13 Foundation XCTest cases covering all starter-theme round trips, malformed/oversized packages, invalid colors/geometry, future versions/enums, ignored path metadata, name/compatibility validation, real temporary-file import/export, library integrity, save/reload/corruption recovery, invalid-save preservation, sound preferences, shift/caps/layout state, and shared-settings serialization/defaults.

The AirKeyboard Xcode scheme also runs those core tests in AirKeyboardTests on an iOS simulator. Follow README build/test commands. Compile all three product targets before considering a first release. There are no automated host-field UI tests or end-to-end control tests yet. `SharedStore` app/control races and App Intent execution still require signed integration tests; core serialization tests alone cannot prove them.

## Device acceptance checklist

Record exact iPhone model, iOS build, Xcode build, signing configuration and observations. Test iOS 18 plus the latest supported iOS where hardware is available.

- Fresh install: launch, six themes, silent defaults; configure shared App Group. Test the deliberate missing-entitlement fallback in a development build.
- Theme workflow: favorite, duplicate, edit all palette/geometry/font/layout fields, tap the interactive preview, save/apply, force-quit/reopen, reset, export via Files, import as a new item, delete after confirmation. Active theme should reach the keyboard within its next visible refresh.
- Imports: missing fields, unexpected metadata, invalid enums/colors, unsupported schema, invalid UUID, JSON arrays, empty data, file over 64 KB, unreadable provider files, canceled picker. No crash or unwanted overwrite.
- Persistence: two saves, corrupt primary, recover valid backup; corrupt both and confirm clear errors. Confirm a failed write is not reported as success.
- Host input: Notes and at least one third-party app; ordinary text, email, URL, number, decimal, search and multiline traits. Confirm text inserts into the host, selected text replacement, backspace over emoji/graphemes as handled by the proxy, backspace repeat, shift once, double-tap Caps Lock/unlock, numbers→symbols→letters, space, return labels and newline behavior, enabled-return handling, globe tap/hold, cursor/context changes and new host fields.
- Boundaries: secure/password field reverts to Apple's keyboard; restricted hosts may reject extension. Phone-pad hosts may substitute a system layout; the AirKeyboard number page is a general symbol keyboard rather than a dedicated numeric pad.
- Lifecycle/layout: rotate, small and large phones, iPad portrait/landscape, keyboard dismiss/reopen, extension termination, low memory, rapid text entry. Check constraints, touch targets, no stuck delete-repeat timer and no input lag.
- Audio: use the full matrix in AUDIO.md. Actual listening, Full Access gating, Silent mode and latency are release gates. Confirm disabling sounds and choosing Silent stop playback.
- Controls: add the sound toggle in Control Center. Toggle while the app/keyboard is open, suspended and terminated. Check saved state and updated provider; theme should not revert when toggling. Revoke Full Access: saved enabled state must not produce sound.
- Widgets: add small/medium Home Screen and rectangular Lock Screen widgets. Apply themes; confirm label/palette and sound state after system refresh. Tap and confirm Themes opens. Check tinted widgets, redaction and Lock Screen legibility.
- Accessibility: VoiceOver labels and typing; largest Dynamic Type sizes; Increase Contrast, Reduce Transparency, Reduce Motion; system/light/dark app appearance; low-contrast custom colors; reachable switch key. No decorative button should be inert. Preview keys use 44-point minimum height; actual key sizing adapts within system constraints and needs device review.
- Privacy: inspect traffic, console and persisted files during typing. No input history/network calls should exist. Static token scanning alone does not establish that result.

## Troubleshooting

**Xcode build fails:** check the first actual compiler error, the selected SDK and target source membership. This Windows-authored source has not yet been compiled. Do not label failures as signing-only without reading diagnostics.

**App Group unavailable:** use the same registered group in three entitlements and SharedStore.group, with matching provisioning. A free/personal team may not provision required capabilities. Keyboard typing can still use Dark Glass; shared customization cannot be claimed verified.

**Theme does not change:** save/apply in the containing app, confirm no shared-storage error, then reopen the keyboard or wait for its two-second visible refresh. Confirm all targets use the same installed bundle prefix/group. A saved library edit alone is not an apply.

**No audio:** check enabled preference, selected pack, nonzero volume/intensity, Full Access in keyboard Settings, device mute, hardware volume and current audio route. App previews do not need Full Access. Missing or failed assets intentionally remain silent. System Keyboard Clicks does not select these custom files.

**Control/widget is stale:** foreground the app to refresh its state; verify group/signing and current system scheduling. Remove/re-add after installing a new extension build. The control represents the saved enabled preference, not proof of audible output.

**Keyboard unavailable:** add it in Settings and select with the globe key in a supported non-secure field. Some applications block extensions. No programmatic activation or supported reliable status check is supplied.

**No iOS simulator in CI:** install an iOS 18+ runtime, inspect `xcrun simctl list devices available`, then re-run simulator selection. CI is prepared but has not yet run; runner inventories can change.
