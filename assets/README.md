# README media status

These files serve project documentation only and do not imply hardware verification.

| File | Current content | Status / replacement |
| --- | --- | --- |
| `logo.png` | Exact copy of the original code-drawn app icon | Provisional project logo; original MIT asset, not AirCard branding. |
| `demo.gif` | Single-frame graphic explicitly labeled MEDIA PLACEHOLDER | Not a demo recording. Replace with an authentic Simulator walkthrough at the same path. |
| `theme-studio.png` | Authentic, unedited Simulator capture from successful run #20 | Theme Studio with the preview switch off (light surroundings), while Dark Glass key colors remain unchanged. |

The GIF placeholder deliberately shows no fabricated iOS UI. Its label remains explicit until an actual recording is supplied. The Studio image is a real capture, not a mockup. The existing post-test CI screenshot depicts the Simulator Home Screen; it is not relabeled as a Theme Studio screenshot. The XCTest result bundle separately contains the real save/relaunch workflow attachment.

Regenerate the provisional logo and GIF placeholder on Windows with built-in .NET drawing APIs (no packages). The generator preserves an existing Studio image; it creates a labeled Studio fallback only when that file is absent:

```powershell
./Scripts/generate_readme_assets.ps1
```

For replacements record the source commit, simulator/device model, iOS build and capture steps. Remove private text/identifiers before submission and preserve truthful alt text. Update this file and ASSETS.md; do not label a mockup as an actual capture. All project-created graphics are MIT licensed; system font files are not redistributed.

## Authentic Studio capture provenance

- Successful workflow: [run #20](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39634992350).
- Tested commit: `f17568818222115c671249bb2612e3ebff38f5d6`; Xcode 16.4 / Simulator SDK 18.5 / iOS Simulator runtime 26.2, iPhone SE (3rd generation).
- Source: `ThemeWorkflowTests.testCreateSaveAndReloadThemeInTheRealApp`, attachment **Theme Studio light preview**. The test switches the actual control off, confirms value 0, captures the editor, then switches back and completes save/relaunch verification.
- Original PNG extracted byte-for-byte from the XCTest bundle; no cropping, compositing, recoloring or simulated UI. SHA-256: `faf8eaf3a0520722c4234f05189861143d17ffbe720015c66b8a82dc2efc24d0`.
- GitHub artifact digest: `2774467f507f4ddf1221c3dd53a438531107e5e89acb931537b2e8f35f881b1d`.
- This is a Simulator capture, not proof of physical-device installation, audible sound or App Group behavior.
