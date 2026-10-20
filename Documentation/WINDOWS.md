# Windows companion and hosted iPhone builds

AirKeyboard Connect supplies an original Windows desktop workflow: connect iPhone â†’ obtain/validate the built app â†’ open the signer â†’ install using your Apple account â†’ activate the keyboard. This implements a small desktop companion in this project. It does not copy AirCard code/branding, reproduce its system-modification mechanisms or claim one-click installation without Apple signing.

## What is available now

- A real framework-only Windows executable, `AirKeyboardConnect.exe`, built and self-tested on Windows.
- Actual WMI Apple-USB device discovery and Apple Mobile Device Service status, without storing serial numbers, reading phone contents or claiming pairing is complete.
- Local IPA validation: ZIP path/size/duplicate checks, both required extensions, three thin ARM64 executables, and Mach-O iOS build-platform checks. Files are read without extraction. Simulator builds are rejected. This is a structural check, not signature validation or a security audit.
- An installed Sideloadly launcher and real file-drop handoff. Download, Apple login, signing, selection of the destination iPhone and the final Start action happen in Sideloadly. No undocumented command-line flags or screen-click automation are assumed.
- Hosted standard-macOS workflows for simulator development and an optional device re-signing input. They have not run yet because this repository has no published GitHub remote or supplied signing profiles.

There is **no actual iPhone IPA in the current local deliverable**. Test fixtures are generated only in temporary test directories and deleted; they are never shipped as installable apps.

## Path A: build an IPA for external signing, without your own Mac

1. Upload/push this repository to a GitHub repository you control. No remote is created automatically by these files.
2. Open Actions â†’ **iPhone package** â†’ Run workflow. The workflow uses a hosted macOS runner for Xcode and a Windows runner for the companion. GitHub runner availability/usage terms apply.
3. The iPhone job first runs portable/model checks, then archives the actual device app using `generic/platform=iOS`, `ARCHS=arm64`, with Apple signing disabled. It adds **ad-hoc local integrity signatures** carrying the requested group entitlements. These are **not Apple-trusted development signatures**, do not grant provisioning capabilities and cannot install the app by themselves.
4. `Scripts/package_iphone.py` rejects absent extensions, incorrect metadata or simulator binaries before packaging the real built `.app`. It writes `AirKeyboard.ipa`, a SHA-256 file and a manifest explicitly stating that Apple signing is still required. Failures stop the job; no placeholder IPA is produced.
5. After a successful run, download and unzip the two workflow artifacts. Start the Windows helper, choose the IPA and follow the signer instructions. Keep both extensions. Do not assume a free account or a signer will preserve the App Group required for shared themes; verify that on the device.

This path needs no certificate stored in the repository. It requires an external signer and its supported Apple-account workflow. The project neither redistributes that signer nor automates credential entry.

## Free-first policy replaces certificate-required hosted builds

The certificate-required signed workflow is no longer active. It is not a requirement to contribute, build the simulator, or use the theme editor. See [free development](FREE-DEVELOPMENT.md) for the default no-secrets simulator CI and optional Personal Team/local-mode testing on an available Mac. `prepare_signed_build.py` remains an optional developer utility with validation tests; no workflow invokes it or asks this user to purchase membership. An external signer's general free-account support is not proof that AirKeyboard's shared capabilities work on a device.

## Honest boundaries

The helper can open a browser/signer and offer a real IPA drag source; it cannot assert that an external app finished installing. Apple-USB detection is not proof that a particular iPhone is trusted. It cannot turn a simulator build into a device IPA, turn on Developer Mode, select a keyboard, grant Full Access, replace the passcode UI or alter Apple's system keyboard. It does not access AirTraffic, exploit device sync or bypass signing.

For an end-to-end test, record Windows version, Apple drivers, signer version/account type, iPhone model/iOS and actual outcomes. Confirm both extensions remain installed, themes reach the keyboard, Control Center state persists and optional audio obeys access/mute. The current successful EXE/package tests are not that device test.

## Primary implementation references

- [Sideloadly official site](https://sideloadly.io/): Windows support, IPA drag-and-drop, account signing, install modes, extensions and driver prerequisites. Reviewed 2026-10-20. No compatibility result for AirKeyboard is inferred from the general tool description.
- [AltStore's official Windows guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows): another user-driven Windows installation approach; no automatic AltStore integration is implemented here.
- [Apple: distributing to registered devices](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices): development-device provisioning, archive/export and IPA distribution.
- [Apple: cloud signing and command-line exports](https://developer.apple.com/videos/play/wwdc2021/10204/): xcodebuild archive/export responsibilities.
- [GitHub runner images](https://github.com/actions/runner-images): macOS-hosted Xcode environments. The workflow does not compile iOS with Windows.
