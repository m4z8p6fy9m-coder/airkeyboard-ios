# v0.1.0 – Simulator Foundation

**Simulator-only. Device verification pending.**

Published on 2026-10-21 as a public **pre-release**: [v0.1.0 – Simulator Foundation](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/releases/tag/v0.1.0). No installable iPhone IPA is supplied.

## Included

Native SwiftUI theme studio and library, UIKit keyboard, six original themes, original sound packs, bounded JSON packages, WidgetKit/control source and an optional Windows helper. MIT licensed, offline, no subscriptions or paid build services.

## Verification

[Successful run #20](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39634992350), code commit `f17568818222115c671249bb2612e3ebff38f5d6`: all Simulator products compiled, 16 Foundation tests passed on macOS and separately on iOS Simulator, and one real-app preview-toggle/create/save/relaunch UI test passed in 66.154 seconds. Standard ARM64 runner, Xcode 16.4, Simulator SDK 18.5, execution on iOS Simulator 26.2 (iPhone SE, 3rd generation). These are separate source/runtime checks, not physical-device verification.

CI includes CoreSimulator initialization, a dedicated boot step, command timeouts, no post-test diagnostic collection and a 25-minute job limit. The README exposes the live CI status and explicit evidence. Logo uses the project's own icon; the demo GIF remains a clearly labeled placeholder; the Studio image is an authentic, unedited Simulator capture from run #20 with documented provenance.

## Limited Studio polish

The editor keeps direct reactive theme bindings and adds a local light/dark preview context with SF Symbols and a rounded surround. It preserves palette tokens and stored theme appearance. The existing UI workflow switches both ways without a reload and attaches an authentic editor capture. This expanded workflow passed in run #20; the first row-center tap failure remains in the public history.

## Pending before device claims

Physical iPhone installation and host typing; Apple signing/provisioning; actual audio/mute/Full Access behavior; shared App Group/widget/control integration; Accessibility device matrix. See the verification report and testing guide.

Tag `v0.1.0` resolves to `b36f4be17d2c4abf4d62ab304f3a3cef157afaf7`, independently verified after publication. Later documentation commits on main add the [device checklist](../Docs/Device-Verification.md) and release links; they do not move the tag or establish device verification.

Full changes: [CHANGELOG.md](../CHANGELOG.md).
