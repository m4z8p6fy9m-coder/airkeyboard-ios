# Local quality improvements – 2026-10-22

## Implemented

- Theme catalog: name/description search with multiple terms, case/diacritic folding, catalog/name/favorites-first sorting, empty-result guidance and full-library messaging. Search/sort only derive results; they do not mutate saved themes. Virtual premium presets remain visible at the 200-saved-theme limit.
- Studio: adaptive color edits update the displayed branch instead of silently editing the dark palette or flattening system-following. Glass tint, modifier, border and pressed alpha remain editable. Original colors in the other branch are retained.
- Accessibility preview: force opaque key surfaces and stronger borders while preserving the actual system settings as the minimum. Numeric primary-glyph contrast includes modifier and pressed fills; for glass it measures only the known opaque fallback. This is a design aid, not a WCAG/VoiceOver/device certification.
- Editing: inline validation and disabled save for invalid data; revert all unsaved changes to the opening snapshot. Reset-to-starter remains a separate existing action.
- Library: explicit capacity error with export/delete advice; editing an existing item at capacity remains supported. Failed additions never evict a saved design.
- Color validation and drawing share one strict ASCII #RRGGBB / #RRGGBBAA parser. Trailing newline, whitespace, malformed hex and non-ASCII lookalikes are rejected. The alpha suffix remains the final byte.
- Portable checks now validate the actual nested JSON schema, including adaptive light palettes, required metadata, glass-only alpha, exact color termination and numeric bounds. The validator intentionally supports only the subset used by this checked-in schema, not arbitrary third-party schemas.

## Actual verification

- `python Scripts/check_repository.py`: 8 checks passed.
- `python -m unittest discover -s Tests/Packaging -q`: 29 tests passed.
- New Python schema tests cover all ten examples and adversarial nested/opaque/numeric/color cases. Existing production-source digests still confirm unchanged input, layout and extension-controller lifecycle.
- Six additional Swift XCTest methods exercise strict color parsing, 21:1/1:1 reference contrast, adaptive branch preservation and round-trip, search normalization, concrete sorted order/favorites and full-capacity update/rejection behavior.
- Two additional UI workflows target Slate search plus opaque-preview controls and invalid-name save disabling. Accessibility identifiers are included for stable targets.
- After explicit authorization to upload a separate verification branch, [CI run #23](https://github.com/m4z8p6fy9m-coder/airkeyboard-ios/actions/runs/39835280173) passed all three jobs: 27 macOS Foundation XCTest cases, an unsigned Simulator build, 27 Simulator core cases and all 3 real-app UI tests. The core cases are the same suite in two environments, not 54 distinct cases. See [Apple-Verification.md](Apple-Verification.md) for the tested commit, timings, failed-build fixes and evidence limits. Physical-device verification remains open.

## Scope and remaining work

Implementation stays on local `local/premium-themes` and the separately authorized remote `premium-themes-verification` branch. Main and the live release are unchanged; no CI workflow was edited. No dependency, backend, payment or telemetry added. Keyboard actions, key placement, widths, timings and extension-controller lifecycle are unchanged. Unrelated pre-existing working-tree changes remain excluded from the commits.

The macOS source tests, Simulator build and all three UI workflows have now passed. Before claiming device/release readiness: check adaptive light/dark changes and actual system transparency/contrast settings live, test real host inputs and measure per-key material memory/frame cost. Audio, App Group entitlement behavior, VoiceOver, Dynamic Type and physical iPhone verification remain open in [Device-Verification.md](Device-Verification.md).
