# v0.1.0 – Simulator Foundation

**Simulator-only. Device verification pending.**

This is a draft for review, not a published device release. No installable iPhone IPA is supplied.

## Included

Native SwiftUI theme studio and library, UIKit keyboard, six original themes, original sound packs, bounded JSON packages, WidgetKit/control source and an optional Windows helper. MIT licensed, offline, no subscriptions or paid build services.

## Verification

[Successful run #17](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39623141955), code commit `c3d373e31fc6b48831ad8a710dc7ac6d33ed88ff`: all Simulator products compiled, 16 Foundation tests passed on macOS and separately on iOS Simulator, and one real-app create/save/relaunch UI test passed. Standard ARM64 runner, Xcode 16.4, iOS Simulator 18.5. These are separate source/runtime checks, not physical-device verification.

CI includes CoreSimulator initialization, a dedicated boot step, command timeouts, no post-test diagnostic collection and a 25-minute job limit. The README exposes the live CI status and explicit evidence. Logo uses the project's own icon; demo/studio media remain clearly labeled placeholders, not product captures.

## Limited Studio polish

The editor keeps direct reactive theme bindings and adds a local light/dark preview context with SF Symbols and a rounded surround. It preserves palette tokens and stored theme appearance. The existing UI workflow is extended to switch both ways and attach an authentic editor capture; its current CI outcome must be checked separately from the earlier run #17 evidence.

## Pending before device claims

Physical iPhone installation and host typing; Apple signing/provisioning; actual audio/mute/Full Access behavior; shared App Group/widget/control integration; Accessibility device matrix. See the verification report and testing guide.

The release target is `v0.1.0`. Keep it as a GitHub draft until a maintainer chooses to publish; saving the draft does not claim the tag or a device binary is already released.

Full changes: [CHANGELOG.md](../CHANGELOG.md).
