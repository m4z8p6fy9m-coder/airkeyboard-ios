# Asset provenance

All bundled assets are original to this project and released under the repository's MIT License.

| Asset | Origin | License |
| --- | --- | --- |
| Resources/tactile.wav | Deterministic original filtered-noise/oscillator synthesis in Scripts/generate_project.py; seed 20261020 | MIT |
| Resources/mechanical.wav | Same original generator; seed 20261021; distinct frequency/envelope/noise blend | MIT |
| Resources/pop.wav | Same original generator; seed 20261022 | MIT |
| Resources/digital.wav | Same original generator; seed 20261023; small frequency sweep | MIT |
| App/Assets.xcassets/AppIcon.appiconset/icon.png | Original code-drawn ink/mint keyboard design in Scripts/generate_project.py | MIT |
| Examples/*.json and starter palettes | Original theme tokens in Shared/Core/StarterThemes.swift | MIT |

No proprietary keyboard sounds, third-party font files, copied branding or product screenshots are included. Audio format: mono signed 16-bit PCM, 44,100 Hz, 28–45 ms. The deterministic generator is the editable source for both sound and icon assets. Python checks verify signal/file properties; subjective listening has not been performed.

SF Symbols are referenced through Apple's system APIs, not redistributed as source assets; their use is governed by Apple's terms. System fonts and frameworks remain Apple software. This license does not relicense Apple components or grant trademark rights.

## README assets

| Asset | Origin | License / status |
| --- | --- | --- |
| `assets/logo.png` | Byte-for-byte copy of the original app icon above | MIT; provisional project logo. |
| `assets/demo.gif` | Original labeled single-frame documentation placeholder, generated with built-in Windows .NET drawing | MIT; not a demo recording. |
| `assets/theme-studio.png` | Original labeled documentation placeholder from the same generator | MIT; not an iOS screenshot. |

`Scripts/generate_readme_assets.ps1` is the editable source for the two placeholders and copies the logo. It introduces no app or package dependency. System fonts are rendered through installed APIs; no font file is distributed. Replacement capture requirements are in `assets/README.md`.
