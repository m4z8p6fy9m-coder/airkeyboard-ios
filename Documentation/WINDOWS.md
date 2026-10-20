# Windows and free iOS development

Complete MIT source: https://github.com/m4z8p6fy9m-coder/airkeyboard-ios. Windows can edit native source, execute portable tests, build the companion and use public GitHub CI. Xcode/iOS Simulator run on a standard macOS runner. No paid service, cloud Mac or Apple membership is required for source/simulator development.

## Default workflow

1. Run `python Scripts/check_repository.py` and `python -m unittest discover -s Tests/Packaging -v`.
2. Run `Desktop/Windows/Build.ps1`; no NuGet dependencies are needed.
3. Push to the public repository and open Actions, **Free simulator build and tests**. Manual dispatch is available.
4. Read actual job results. The simulator artifact contains a Simulator `.app`, logs/screenshots and XCTest evidence when generated. It expires after one day and cannot run on an iPhone.

The compiled Windows helper opens the real CI page, reports Apple USB/service presence and validates an existing IPA's ZIP, extensions and ARM64/iOS Mach-O metadata. Its seven tests passed locally and in Windows CI. The actual UI was rendered/reviewed. USB detection does not establish pairing or installation. No credentials, serial numbers or phone contents are stored.

## Optional device experiments

See [free development](FREE-DEVELOPMENT.md). An existing/borrowed Mac with Xcode and a free Personal Team can support personal testing within Apple's limits. `python3 Scripts/generate_project.py --local-device` removes App Group entitlements and isolates settings. Capability checks and profile expiry still apply; this is not a verified AirKeyboard device installation.

The optional **iPhone package** workflow can build actual device code and package an input for external re-signing. Intermediate ad-hoc signatures are not Apple-trusted, grant no provisioning capabilities and cannot install the app. The packager rejects simulator binaries/incomplete extensions. No synthetic test fixture is delivered as an IPA. The device workflow has not established a successful device result.

The helper can open an independently installed signer and provide a real file drag source. Apple login, terms, account signing and final installation remain in that tool. No signer is bundled or required for development. General free-account signer support does not prove compatibility with AirKeyboard extensions or shared capabilities. No paid plan is configured.

There is no signed device build, installable IPA or physical iPhone test result. Renaming a Simulator binary cannot change this. Keyboard activation, Full Access, Developer Mode and iOS boundaries stay under supported system/user control.

References: [Apple free account limits](https://developer.apple.com/help/account/basics/about-your-developer-account), [GitHub standard runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners), optional [Sideloadly](https://sideloadly.io/) and [AltStore Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows). These tool descriptions do not establish AirKeyboard installation compatibility.
