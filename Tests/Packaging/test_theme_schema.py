"""Exercise the actual nested package schema; does not execute the Swift decoder."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('repository_checks', ROOT / 'Scripts/check_repository.py')
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)

class ThemeSchemaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema = json.loads((ROOT / 'Documentation/theme.schema.json').read_text())
        cls.solid = json.loads((ROOT / 'Examples/cupertino-native.json').read_text())
        cls.glass = json.loads((ROOT / 'Examples/slate-glass.json').read_text())

    def rejects(self, value):
        with self.assertRaises(ValueError): checks.validate_schema(value, self.schema)

    def test_all_legacy_and_extended_examples_validate(self):
        for path in (ROOT / 'Examples').glob('*.json'):
            with self.subTest(path=path.name): checks.validate_schema(json.loads(path.read_text()), self.schema)

    def test_invalid_nested_light_palette_cannot_bypass_validation(self):
        for color in ['#FFFFFF\n', '#FFF', '#１２３４５６', '#GGGGGG']:
            value = copy.deepcopy(self.solid); value['rendering']['light']['key'] = color
            self.rejects(value)
        value = copy.deepcopy(self.solid); del value['rendering']['light']
        self.rejects(value)
        value = copy.deepcopy(self.solid); value['rendering']['followsSystem'] = 'yes'
        self.rejects(value)

    def test_glass_alpha_is_not_accepted_for_opaque_surfaces_or_text(self):
        checks.validate_schema(self.glass, self.schema)
        value = copy.deepcopy(self.glass); value['rendering']['surface'] = 'solid'
        self.rejects(value)
        for role in ['primary', 'background', 'accent']:
            value = copy.deepcopy(self.glass); value[role] = '#FFFFFFFF'
            self.rejects(value)

    def test_exact_hex_and_numeric_bounds(self):
        for field, invalid in [('key', '#FFFFFF\n'), ('padding', True), ('spacing', float('nan')),
                               ('cornerRadius', -1), ('borderWidth', 3), ('minimumIOS', 19)]:
            value = copy.deepcopy(self.glass); value[field] = invalid
            self.rejects(value)

if __name__ == '__main__': unittest.main()
