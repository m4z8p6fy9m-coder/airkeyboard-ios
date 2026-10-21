# README media status

These files serve project documentation only and do not imply hardware verification.

| File | Current content | Status / replacement |
| --- | --- | --- |
| `logo.png` | Exact copy of the original code-drawn app icon | Provisional project logo; original MIT asset, not AirCard branding. |
| `demo.gif` | Single-frame graphic explicitly labeled MEDIA PLACEHOLDER | Not a demo recording. Replace with an authentic Simulator walkthrough at the same path. |
| `theme-studio.png` | Graphic explicitly labeled MEDIA PLACEHOLDER | Not a product screenshot. Replace with an authentic Theme Studio capture at the same path. |

The placeholders deliberately show no fabricated iOS UI. Their labels and README alt text remain explicit until real captures are supplied. The existing post-test CI screenshot depicts the Simulator Home Screen; it is not relabeled as a Theme Studio screenshot. The XCTest result bundle separately contains the real save/relaunch workflow attachment.

Regenerate the current documentation placeholders on Windows with built-in .NET drawing APIs (no packages):

```powershell
./Scripts/generate_readme_assets.ps1
```

For replacements record the source commit, simulator/device model, iOS build and capture steps. Remove private text/identifiers before submission and preserve truthful alt text. Update this file and ASSETS.md; do not label a mockup as an actual capture. All project-created graphics are MIT licensed; system font files are not redistributed.
