# Premium theme integration – local, 2026-10-22

Four supplied designs are integrated into the existing `Theme` / `StarterThemes` system. There is no ThemeManager replacement, payment gate, dependency, network operation or new compiled target. The six original designs remain unchanged; the catalog now contains ten.

## Mapping

| Supplied token | Existing model / extension |
| --- | --- |
| String design ID | Stable UUIDs ending 007–010; copies/imports keep the existing fresh-UUID behavior |
| keyboardBackground / keyBackground | background / key |
| keyText / secondaryText | primary / secondary |
| keyBorder / pressedOverlay / accent | border / pressed / accent |
| specialKeyBackground | Optional rendering.specialKey |
| surfaceStyle glass | Optional rendering.surface = glass |
| light palette / followsSystemAppearance | rendering.light / rendering.followsSystem; resolved copies for drawing |

Cupertino Native follows the app/system environment in Studio and the inherited host appearance in UIKit. Nord, Slate and Midnight remain dark. Existing spacing, padding, key widths, rows, shift/delete/return behavior, input proxy and extension-controller lifecycle are preserved. Theme corner radii and border widths use the supplied surface tokens. Prediction/suggestion tokens are not wired up because the project has no prediction strip.

Optional rendering metadata is absent from old v1 packages and decodes as nil. The old flat palette and six-digit validation remain for legacy themes. Eight-digit **RRGGBBAA** is allowed only on glass surface tokens, not primary text/background colors. Updated packages require this new reader for material/adaptive behavior; older app binaries are not claimed to understand these optional extensions or glass alpha tokens. The schema and four examples document the new metadata.

## Catalog and editing

App load adds missing premium IDs to existing libraries without replacing saved/customized themes or favorites. A full 200-item library is not evicted; unpersisted presets still appear in the catalog and can be applied/edited/exported, but saving requires room and favorites remain disabled until persisted. Applying still obeys the real App Group/local-mode boundary.

Studio can disable system-following. Choosing a fixed appearance disables automatic switching. While adaptive mode is on, palette edits target the displayed light/dark branch and preserve the other branch. The light/dark preview demonstrates adaptive palettes without storing a resolved snapshot. Original source files are preserved here; the supplied Swift starter is deliberately stored as `.swift.txt` so it is not compiled as a second theme system.

## Material rendering

SwiftUI preview keys use ultraThinMaterial plus RGBA tint and border. UIKit keys use UIVisualEffectView / systemUltraThinMaterialDark underneath a separate tint view. Labels stay above the effect; background views do not receive touches or alter intrinsic key sizing. A system-contrast change strengthens borders. Reduce Transparency switches to opaque #343B47 standard keys, #414957 modifier keys, #59616D pressed fill and #7C8593 border. UIKit also uses the opaque surface until it has a window/backdrop context. Changes are observed by the individual key view, without changes to the extension-controller lifecycle.

## Validation actually performed

- 8 portable repository checks pass: project references/membership, package examples, resource/configuration and no network/clipboard client.
- 29 Python packaging/configuration tests pass, including token/source parity, numeric primary-label contrast, unchanged input/layout/controller-lifecycle checks and nested/adversarial schema coverage. The contrast check covers solid colors and the opaque glass fallback, not the composited blur on a device.
- Added XCTest coverage includes legacy decoding, adaptive palette editing, strict RGBA parsing, contrast reference values, catalog search/sort, capacity boundaries and non-destructive/idempotent migration. The round-trip test covers ten themes. These tests have not executed here.
- Swift/Xcode are unavailable on this Windows machine. **No Swift build, XCTest execution, Simulator UI run, screenshot or device result is claimed for this change.** The previous public CI run does not verify this local code.
- Pending on a Mac: `swift test`, Xcode Simulator build/tests, Studio select/edit/apply/export of all four themes, actual extension on light/dark hosts, live appearance changes, Reduce Transparency on/off while visible, Increase Contrast, saved custom themes and library-capacity behavior. Physical-device material quality, input responsiveness and memory cost remain open.

All work and commits are local. No GitHub fetch/push, CI dispatch, release or account setting was used during this task. Existing unrelated working-tree changes were preserved and excluded from these commits. The local branch uses the already cached published commit as its base; no files were discarded to align the index.
