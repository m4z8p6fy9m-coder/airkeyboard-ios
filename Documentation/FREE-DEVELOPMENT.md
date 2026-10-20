# Free development policy

AirKeyboard source and original assets are MIT licensed. Development must require no paid Apple membership, rented Mac, paid CI plan, API subscription or backend. Native app features work offline. GitHub is an optional source/CI host, not an app runtime dependency.

## Default path

The public `airkeyboard-ios` repository runs source checks, Foundation tests, unsigned iOS Simulator builds/tests, app launch and Windows companion tests using standard `ubuntu-latest`, `macos-15` and `windows-latest` runners. No secrets, certificate or provisioning profile is required. Jobs are guarded to run only in a public repository; no larger/premium runner is configured. Artifacts have one-day retention. No payment method or spending budget is configured by this project.

GitHub currently documents standard hosted runners as free for public repositories. Storage limits and service terms still apply; artifacts are kept briefly, and this project never opts into a paid service. [GitHub runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), [billing overview](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

On an already available Mac, Xcode and its simulator also support this path locally:

```sh
python3 Scripts/check_repository.py
python3 -m unittest discover -s Tests/Packaging -v
swift test
bash Scripts/simulator_build.sh
```

Windows can edit all source, run portable/companion tests and use the public CI results. Windows does not contain Xcode or an iOS simulator; renaming a simulator app or a source ZIP to IPA cannot make it installable on an iPhone.

## Local settings without App Groups

If an authorized App Group container is unavailable, each process uses its own Application Support settings file. The containing app can still edit, save, import/export themes and preview sounds. The keyboard supplies its own built-in theme picker and sound preference in local mode. No data is secretly shared across sandbox boundaries. The app explains this mode. Widgets show sharing unavailable, and the cross-process sound intent returns an error instead of pretending to change the app.

For optional free Personal Team experimentation on your own device using an available Mac:

```sh
python3 Scripts/generate_project.py --local-device
```

This regenerates the project/configuration with App Group entitlements removed and explicitly isolated storage. Open Xcode, use your free personal Apple Account, choose unique bundle IDs for the three targets and your iPhone, and let Xcode handle the supported signing flow. The script does not create identities or profiles and does not defeat capability checks. It overwrites generated configuration; preserve personal edits first. To restore the default project, run the generator without the flag.

Apple documents Personal Teams as supporting personal-device testing with limits: provisioning expires after seven days, up to ten temporary App IDs, up to three devices and up to three installed apps per device. Extensions may consume additional identifiers; actual eligibility/capabilities remain subject to Xcode/Apple checks. Some capabilities, notably shared App Groups, must not be assumed available with a free team. This release does not require a paid membership to develop and does not promise every shared integration under free signing. [Apple account overview](https://developer.apple.com/help/account/basics/about-your-developer-account), [supported capabilities](https://developer.apple.com/help/account/reference/supported-capabilities-ios/).

Without access to an existing/borrowed Mac, public CI can still compile/test the simulator project. It cannot grant you a personal Apple signature or install a simulator binary on an iPhone. Free external signers can be considered separately under their terms; they are optional and are not evidence that AirKeyboard's extensions or App Group work on a device.

## Evidence categories

1. **Source tests:** real portable or Swift model tests; do not establish UI or iOS execution.
2. **Simulator build:** actual Xcode compilation of app and extensions against the simulator SDK.
3. **Simulator tests/launch:** actual XCTest or app process on a named simulator; no real-device claim.
4. **Signed device build:** physical-device binary signed by a valid Apple identity/profile. Not required for the default path and not implied by simulator success.
5. **Installable IPA:** a device package with valid applicable signing/provisioning; actual install and hardware checks are separate again.

The optional device-package workflow produces a re-signing input only after a real device compilation. It is not the default acceptance gate. The previous certificate-required hosted signing workflow was removed from active Actions for this free-first policy. No Apple secrets or paid services are added.
