# Implementation and verification report

Updated: 2026-10-21. Public MIT source: https://github.com/m4z8p6fy9m-coder/airkeyboard-ios.

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
| iOS Simulator Core XCTest | 16 passed in run #17 |
| App UI save/relaunch test | Passed in run #17: create, save, terminate/relaunch and find the persisted theme (81.034 seconds) |
| Signed device build | Not produced |
| Installable iPhone IPA | Not produced |
| Physical iPhone/USB install/typing/audio | Not tested |

[Run #17](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39623141955), tested commit `c3d373e31fc6b48831ad8a710dc7ac6d33ed88ff`, completed successfully on 2026-10-21. Xcode 16.4 (16F6), ARM64 host, iOS Simulator SDK 18.5. The Simulator job took 9m10s; the complete workflow took 9m24s. Both sets of 16 Foundation cases passed, and the real-app UI workflow passed in 81.034 seconds. The same 16 core cases run on two platforms; they are not 32 distinct tests.

The public workflow now bounds daemon startup and every Xcode command, initializes CoreSimulator immediately before each invocation, boots the selected device in a dedicated YAML step, disables post-test diagnostic collection and sets a 25-minute job limit. The universal Simulator app is archived before runtime tests, so a later failure does not hide a successful build. Build/boot/test outcomes and logs are separate. No test is silently skipped to manufacture a green result.

The Simulator artifact was downloaded and its SHA-256 matched GitHub's `db6ae08cfd1385fe169ee7ccf1a57f643808f8426cf091faac8b9d0119bac606`. ZIP integrity and both embedded extensions were checked. The post-test screen capture is a Home Screen image; it is not evidence of the editor's appearance. README media are explicitly labeled placeholders pending authentic captures.

## Open-source presentation

The v0.1.0 Simulator Foundation draft adds a concise README, live repository badges, asset provenance, CHANGELOG.md, issue/PR templates and a Good First Issues contribution path. These do not establish device compatibility. Every entry links to actual evidence or remains explicitly pending.

## Free-first policy and remaining limits

Active Actions use only standard Ubuntu, macos-15 (standard ARM64) and Windows runners in a public repository, with no signing secrets and one-day artifact retention. No paid dependency, subscription, mandatory backend, premium runner or cloud Mac is configured. The certificate-required hosted workflow was removed. The optional device-package workflow produces re-signing input only after actual device compilation; it has not established a device result.

Free Personal Team testing on an existing/borrowed Mac is documented with expiry/capability limits. Local mode deliberately gives up cross-target theme/control synchronization when App Groups cannot be provisioned. No identity, profile or entitlement authority is fabricated. Simulator apps are never represented as iPhone IPAs.

Remaining acceptance work: real host-field typing and lifecycle; audible feedback/mute/access matrix; widgets/control execution and shared updates; accessibility and device profiling; valid device signing/install and USB workflow. No prediction, swipe input, dictation, arbitrary Control Center replacement, passcode-screen replacement or security bypass is implemented. See TESTING.md and FREE-DEVELOPMENT.md.
