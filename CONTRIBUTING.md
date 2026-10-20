# Contributing

Start with README, the architecture document and the factual feature-status table. Preserve free public simulator CI and document actual device findings. No paid Apple membership or signing files are prerequisites for contributing. Do not report source inspection as a successful device test.

Use a focused branch. Explain the user-visible problem, implementation, actual checks run and remaining verification. Use native frameworks and no unnecessary dependencies. Maintain no-network/no-logging keyboard behavior. Never include signing credentials, personal team IDs or private files. Keep keyboard input responsive; no per-key file I/O or long animation. Make every visible control meaningful and accessible.

Run `python3 Scripts/check_repository.py` and `swift test`, then build/test the AirKeyboard Xcode scheme. For keyboard/audio/widget changes, provide exact device/OS details and results from Documentation/TESTING.md. Update docs and status when behavior changes.

To add a theme, extend StarterThemes with a unique stable UUID, validate it, provide a matching JSON example and review contrast. To add a sound pack, update SoundPack, SoundEngine assets, generator, resource membership, examples/schema if needed and provenance/license. Keep signals short and respect mute; require an explicit keyboard permission check. To add a control, create a public AppIntent with a real supported action, coordinate only the required shared preference, refresh state, register in the WidgetBundle and update setup instructions.

The checked-in Xcode project can be edited directly. If source/resource membership changes, update `Scripts/generate_project.py` too; do not regenerate over personal signing edits. A new schema/enum requires migration or an explicit compatibility decision and rejection tests.

By submitting a contribution, you agree to license it under the MIT License and confirm you can license all included assets. Do not copy AirCard, proprietary keyboard packs or other apps' branding. Follow CODE_OF_CONDUCT.md.
