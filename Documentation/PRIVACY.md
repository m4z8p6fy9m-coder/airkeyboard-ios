# Privacy and security model

AirKeyboard has no accounts, backend, analytics, ads, cloud synchronization, network client, clipboard access, contact access or keystroke history. It never logs typed text. There is no microphone permission and no dictation feature. It has no SDK dependencies.

The keyboard uses host-provided nearby context transiently for capitalization and text insertion/deletion through the public text proxy. The context does not leave memory or become theme/settings data. iOS and the host application remain responsible for their own handling of the text a user enters.

Private app storage contains saved themes/favorites and recovery copies. An App Group contains only the active theme and sound preferences plus a backup. The containing app and widget/control extension write settings; the keyboard reads them and may update them only with Full Access. In local mode each target stores isolated preferences inside its own sandbox; no sharing is implied. Own-app UserDefaults stores the containing app's appearance choice. Exports contain design tokens and a sound pack identifier; they exclude personal sound levels and typed text. Exported themes remain under the user's Files/sharing workflow.

Default optional keyboard sounds are off. Full Access is optional and requested solely to make custom audio possible. iOS grants additional capabilities with that switch; the app cannot ask for an audio-only keyboard sandbox expansion. AirKeyboard does not use the network capabilities. Never treat Full Access itself as a privacy guarantee; review the source and distribution you install. Revoking it stops audio on the next keypress/visible refresh and does not disable typing.

Shared files use sandboxed system containers, coordinated transactions and atomic JSON writes. Malformed settings produce errors or a validated backup; keyboard read failure retains a usable built-in/last-read configuration. Imported content cannot execute, request assets, fetch remote data or choose filesystem paths. The limited JSON format accepts no images, fonts, archives or audio files.

Deleting a theme removes it from the current library. The immediately previous library recovery copy can retain it until a later successful save replaces that backup. Uninstalling the app removes private app data; an App Group's lifetime is managed by iOS and can depend on other installed group members. There is no remote deletion request because there is no server storage.

Native Simulator compilation and Foundation tests have executed. Remaining audit work: signing/entitlement verification, physical sandbox behavior with Full Access off/on, device-file protection inspection, import fuzzing on Apple Foundation, Instruments memory/audio profiling and an independent security review. No audit or device verification is claimed. See `SECURITY.md` for reporting guidance.

The optional Windows helper reads local IPA metadata/program headers and OS USB/service status. It neither reads iPhone contents nor saves device identifiers or Apple account credentials. It opens a browser and an independently installed signer only after a user action. The external signer and GitHub-hosted build services have their own privacy/security terms. The active workflows need no Apple credentials or signing secrets. No signed-device export is claimed.
