# Audio implementation and permission boundaries

`SoundEngine` is shared by the app and keyboard. Four bundled mono 44.1 kHz, 16-bit PCM WAV files are synthesized from deterministic decaying oscillators and filtered noise by `Scripts/generate_project.py`. They are approximately 28–45 ms long. `ASSETS.md` records provenance and license.

Preparation reads the small files on a background task, creates AVAudioPlayer instances and prepares them. Apple documents that [prepareToPlay](https://developer.apple.com/documentation/avfaudio/avaudioplayer/preparetoplay()) activates the session; the engine therefore sets the ambient category before preparation and deactivates afterward. Preparation failures are recorded. A keypress uses the cached player; AVAudioPlayer may need to reacquire hardware buffers after idle/deactivation. The previous tap is paused before another begins, preventing layered playback. Volume × intensity controls a capped amplitude preference, not hardware gain. Silent, disabled, zero-volume and zero-intensity settings stop optional audio. Missing files or failed playback produce silence and a visible status/error. Playback is not reported successful merely because a preview button was tapped.

The audio session uses `.ambient`, which Apple documents as mixing with other audio and respecting the Ring/Silent switch and screen locking. Session setup is cached while active; interruptions and route changes stop playback and invalidate that state. The next explicit tap may reactivate it. The engine does not auto-resume after an interruption. The keyboard releases players on disappearance/memory pressure. Device behavior, audio-session ownership in host apps, rapid-tap latency and route changes are **unverified**.

## Full Access

Current [open-access guidance](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard) says the restricted keyboard has no speaker access. The [archived keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html) explicitly places audio, including `playInputClick`, behind open access. The keyboard therefore declares `RequestsOpenAccess = true`, but this **only makes an optional Settings switch available**. It does not grant permission. `hasFullAccess` is checked before any audio preparation or playback. It is rechecked during visible lifecycle refreshes and at each keypress. No microphone permission is requested.

Full Access broadens the sandbox beyond audio, including networking and shared-container writes. AirKeyboard has no network implementation and never uses those capabilities to transmit input. Keyboard settings are read-only in this release. The app explains the broader grant; the user can leave it off or revoke it at any time. Ordinary typing remains functional, using built-in themes if shared settings cannot be read. In-app previews require no keyboard permission.

## System clicks are different from custom packs

Apple’s [UIInputViewAudioFeedback getter](https://developer.apple.com/documentation/uikit/uiinputviewaudiofeedback/enableinputclickswhenvisible) and [playInputClick](https://developer.apple.com/documentation/uikit/uidevice/playinputclick()) produce the **system** input click only when an eligible visible input view opts in and the user's system Keyboard Clicks preference permits it. They do not select arbitrary sound files or support the pack volume/intensity settings. They are not a documented no-Full-Access escape hatch for custom keyboard audio.

AirKeyboard uses AVAudioPlayer for the four actual custom packs and **silence** as fallback. It does not silently substitute a system click, hardcode private system sound IDs, bypass mute, or claim ordinary clicks and arbitrary audio have identical semantics. Whether a user wants system clicks as a separate explicit mode is deferred until device verification.

## Required device tests

Test on iOS 18 and a current iOS release, with Full Access off/on/revoked while the keyboard is visible. Test sounds disabled, Silent pack, zero levels, Silent mode, hardware volume, headphones, Bluetooth, music playback, phone interruptions, foreground/background transitions, extension relaunch and missing resources. Measure rapid typing latency and confirm no overlapping taps or ongoing audio after dismissal. A simulator or WAV-format check cannot establish these outcomes.
