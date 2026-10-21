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
| iOS Simulator Core XCTest | 16 passed in run #20 |
| App UI save/relaunch test | Passed in run #20: both preview appearances, create/save, terminate/relaunch and find the persisted theme (66.154 seconds) |
| Signed device build | Not produced |
| Installable iPhone IPA | Not produced |
| Physical iPhone/USB install/typing/audio | Not tested |

[Run #20](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39634992350), tested commit `f17568818222115c671249bb2612e3ebff38f5d6`, completed successfully on 2026-10-21. Xcode 16.4 (16F6), ARM64 host, iOS Simulator SDK 18.5. Both sets of 16 Foundation cases passed, and the expanded real-app UI workflow passed in 66.154 seconds. The same core cases run on two platforms; they are not 32 distinct tests. Source and Windows jobs also passed.

The workflow bounds daemon startup and every Xcode command, initializes CoreSimulator immediately before each invocation, boots in a dedicated YAML step, disables post-test diagnostic collection and sets a 25-minute job limit. The verified standard ARM64 runner remains in use; the retiring macos-14 image is not reintroduced. Build/boot/test outcomes and logs are separate, and the Simulator app is archived before runtime tests.

The current artifact was downloaded and its SHA-256 matched GitHub's `2774467f507f4ddf1221c3dd53a438531107e5e89acb931537b2e8f35f881b1d`; ZIP integrity passed. The post-test Home Screen snapshot is not relabeled as editor artwork. An authentic Studio capture is attached inside the XCTest bundle; README media deliberately remain labeled placeholders.

The only app-code change in this maintenance work is StudioView: an independent light/dark preview context, SF Symbols and a rounded surround. Theme tokens, persistence and keyboard/widget code are unchanged. The preview remains directly bound to editor state. The UI test targets the actual trailing switch control and waits up to three seconds for each expected accessibility value. The first expanded test failed at its row-center tap; that failure remains visible in Actions. No assertion was removed to obtain the green run.

## Open-source presentation

The v0.1.0 Simulator Foundation draft adds a concise README, live repository badges, asset provenance, CHANGELOG.md, issue/PR templates and a Good First Issues contribution path. These do not establish device compatibility. Every entry links to actual evidence or remains explicitly pending.

## Free-first policy and remaining limits

Active Actions use only standard Ubuntu, macos-15 (standard ARM64) and Windows runners in a public repository, with no signing secrets and one-day artifact retention. No paid dependency, subscription, mandatory backend, premium runner or cloud Mac is configured. The certificate-required hosted workflow was removed. The optional device-package workflow produces re-signing input only after actual device compilation; it has not established a device result.

Free Personal Team testing on an existing/borrowed Mac is documented with expiry/capability limits. Local mode deliberately gives up cross-target theme/control synchronization when App Groups cannot be provisioned. No identity, profile or entitlement authority is fabricated. Simulator apps are never represented as iPhone IPAs.

Remaining acceptance work: real host-field typing and lifecycle; audible feedback/mute/access matrix; widgets/control execution and shared updates; accessibility and device profiling; valid device signing/install and USB workflow. No prediction, swipe input, dictation, arbitrary Control Center replacement, passcode-screen replacement or security bypass is implemented. See TESTING.md and FREE-DEVELOPMENT.md.
