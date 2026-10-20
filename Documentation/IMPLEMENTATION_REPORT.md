# Implementation and verification report

Date: 2026-10-20. Public MIT source: https://github.com/m4z8p6fy9m-coder/airkeyboard-ios.

This report supersedes earlier Windows-only status notes. Native code was actually compiled and executed on a standard public GitHub macOS runner, without an Apple certificate, provisioning profile or paid build service.

## Implemented source

- Native SwiftUI app: theme library, favorites, creation/duplication/deletion, interactive UIKit-style preview, palette/geometry/font/layout editor, import/export, settings and sound previews.
- UIKit keyboard extension: actual text proxy insertion/deletion, shift/Caps Lock, letters/numbers/symbols, input traits, repeat delete, globe switching and lifecycle cleanup. Local Design picker supports six original themes without cross-target sharing.
- Six original theme packages, bounded validated JSON format, atomic library/settings persistence and previous valid backup.
- Four original synthesized short WAV packs plus Silent. Ambient-session app previews and optional Full Access-gated keyboard playback. Hardware listening and latency remain unverified.
- WidgetKit timelines and supported Control Center sound preference intent. Cross-process operations explicitly fail/report unavailable without an authorized App Group. Local mode saves independently inside each sandbox.
- Five-target checked-in Xcode project, Swift Package tests, real-app UI test, deterministic project/assets generator and explicit --local-device generation without group entitlements.
- Framework-only Windows helper: actual USB/service inspection, strict IPA structural checks, browser/signer launch and file drag source. It does not sign or claim completed installs.

## Actual evidence

| Category | Result |
| --- | --- |
| Public GitHub/MIT publication | Complete source published and initial remote blob contents verified against local files |
| Portable repository checks | 8 passed locally and on GitHub Ubuntu |
| Python packaging/configuration/selection tests | 18 passed locally and on GitHub Ubuntu; synthetic fixtures establish validators only |
| Windows executable | Framework build succeeded locally and on GitHub Windows; 7 self-tests passed; actual WinForms rendering reviewed |
| macOS Foundation source tests | 16 passed via swift test on Xcode 16.4 runner |
| Simulator compilation | App, keyboard, widget/control built against iOS Simulator 18.5 with CODE_SIGNING_ALLOWED=NO |
| iOS Simulator Core XCTest | 16 passed in run #13 |
| App UI save/relaunch test | Retesting navigation-bar Save action in run #14; not yet claimed passed |
| Signed device build | Not produced |
| Installable iPhone IPA | Not produced |
| Physical iPhone/USB install/typing/audio | Not tested |

[Run #13](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39484433729) established native compilation and both sets of 16 core tests. Its UI automation exposed an unreachable Save button under editing/scrolling. The editor now keeps Save in the navigation bar and dismisses name-field focus; [run #14](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39486335890) validates that correction. Simulator smoke installation/launch and artifact packaging now precede UI tests so a UI failure cannot hide an already built product.

Earlier real CI failures were fixed: iOS 18 package declaration under Swift tools 5.9 and an overly complex SoundsView expression. Runner selection uses actual eligible Xcode destinations, excluding incompatible preinstalled runtimes.

## Free-first policy and remaining limits

Active Actions use only standard Ubuntu, macos-15-intel and Windows runners in a public repository, with no signing secrets and one-day artifact retention. No paid dependency, subscription, mandatory backend, premium runner or cloud Mac is configured. The certificate-required hosted workflow was removed. The optional device-package workflow produces re-signing input only after actual device compilation; it has not established a device result.

Free Personal Team testing on an existing/borrowed Mac is documented with expiry/capability limits. Local mode deliberately gives up cross-target theme/control synchronization when App Groups cannot be provisioned. No identity, profile or entitlement authority is fabricated. Simulator apps are never represented as iPhone IPAs.

Remaining acceptance work: real host-field typing and lifecycle; audible feedback/mute/access matrix; widgets/control execution and shared updates; accessibility and device profiling; valid device signing/install and USB workflow. No prediction, swipe input, dictation, arbitrary Control Center replacement, passcode-screen replacement or security bypass is implemented. See TESTING.md and FREE-DEVELOPMENT.md.
