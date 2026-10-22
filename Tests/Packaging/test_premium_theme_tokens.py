"""Portable checks of supplied tokens and examples; not a Swift/iOS runtime test."""
import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class PremiumTokenTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = json.loads((ROOT / 'Documentation/PremiumThemes/design-tokens.json').read_text(encoding='utf-8'))['themes']
        cls.swift = (ROOT / 'Shared/Core/StarterThemes.swift').read_text(encoding='utf-8')

    def test_supplied_palettes_match_examples_and_compiled_catalog_source(self):
        roles = {'keyboardBackground': 'background', 'keyBackground': 'key', 'keyText': 'primary',
                 'secondaryText': 'secondary', 'keyBorder': 'border', 'pressedOverlay': 'pressed', 'accent': 'accent'}
        for slug, spec in self.spec.items():
            value = json.loads((ROOT / ('Examples/' + slug + '.json')).read_text(encoding='utf-8'))
            block = self.swift.split('name: "' + spec['displayName'] + '"')[1].split('Theme(id:')[0]
            for src, dest in roles.items():
                self.assertEqual(value[dest], spec['dark'][src])
                self.assertIn(dest + ': "' + value[dest] + '"', block)
            self.assertEqual(value['rendering']['specialKey'], spec['dark']['specialKeyBackground'])
            self.assertIn('specialKey: "' + value['rendering']['specialKey'] + '"', block)
            self.assertEqual(value['spacing'], 5)
            self.assertEqual(value['padding'], 6)
            self.assertEqual(value['layout'], 'qwerty')
            self.assertEqual(value['rendering']['followsSystem'], slug == 'cupertino-native')
            self.assertEqual(value['rendering']['surface'], 'glass' if slug == 'slate-glass' else 'solid')
            self.assertEqual(value['cornerRadius'], spec['geometryOverrides']['keyCornerRadiusPt'])
            if slug == 'cupertino-native':
                for src, dest in dict(roles, specialKeyBackground='specialKey').items():
                    self.assertEqual(value['rendering']['light'][dest], spec['light'][src])
                    self.assertIn(dest + ': "' + spec['light'][src] + '"', block)

    def test_source_swift_and_json_palettes_agree(self):
        source = (ROOT / 'Documentation/PremiumThemes/PremiumKeyboardThemes.swift.txt').read_text(encoding='utf-8')
        for theme in self.spec.values():
            for mode in ['dark', 'light']:
                for role, color in theme[mode].items():
                    if role.startswith('suggestion'): continue  # No prediction strip exists in this app.
                    self.assertIn(role + ': Color(themeHex: "' + color + '")', source)

    def test_key_color_contrast_including_opaque_glass_fallback(self):
        def luminance(color):
            parts = [int(color[i:i+2], 16) / 255 for i in (1, 3, 5)]
            parts = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in parts]
            return sum(x * w for x, w in zip(parts, [0.2126, 0.7152, 0.0722]))
        for slug, spec in self.spec.items():
            for mode in ['dark', 'light']:
                for key in ['keyBackground', 'specialKeyBackground']:
                    bg = spec[mode][key]
                    if slug == 'slate-glass': bg = '#343B47' if key == 'keyBackground' else '#414957'
                    a, b = sorted([luminance(spec[mode]['keyText']), luminance(bg)])
                    self.assertGreaterEqual((b + 0.05) / (a + 0.05), 4.5, (slug, mode, key))

    def test_input_layout_and_extension_lifecycle_are_unchanged(self):
        # Baseline digests protect this task's explicit no-input/no-layout/no-lifecycle scope.
        # These do not require git history (including in source archives or shallow checkouts).
        import hashlib
        after = (ROOT / 'Keyboard/KeyboardViewController.swift').read_text(encoding='utf-8')
        def digest(value): return hashlib.sha256(value.encode()).hexdigest()
        self.assertEqual(digest(after.split('    override func viewDidLoad()')[1].split('    private func render()')[0]), '6a1ad0396acf8ad3b5a06c4b1a92823bc58fbe25713eda4327e82bebc0d09627')
        self.assertEqual(digest(after.split('    private func insert(')[1].split('\nprivate final class KeyButton:')[0]), '66bdae35377a3076dc3d6758632fb0a311cafe8e0b9672917b23def3b217363c')
        self.assertEqual(digest(after.split('        if !sharingAvailable {')[1].split('    private func button(')[0]), 'b4c5364c7153476890cfaab07d96c930049a297c1f31e0238c325ea9f941aec0')
        self.assertEqual(digest((ROOT / "Shared/Core/KeyboardState.swift").read_text(encoding="utf-8")), 'fbc01626ee0c531d955542468a2a967a4dd42424bbaffab40d57c74d46f964c0')

if __name__ == "__main__": unittest.main()
