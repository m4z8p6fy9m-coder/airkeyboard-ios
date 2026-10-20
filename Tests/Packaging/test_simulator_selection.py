import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('selection', ROOT / 'Scripts/select_simulator.py')
MODULE = importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(MODULE)

class SimulatorSelectionTests(unittest.TestCase):
    def test_ignores_newer_ineligible_runtime(self):
        output = '''Available destinations for the "AirKeyboard" scheme:
        { platform:iOS Simulator, arch:x86_64, id:11111111-1111-1111-1111-111111111111, OS:18.5, name:iPhone 16 }
        Ineligible destinations for the "AirKeyboard" scheme:
        { platform:iOS Simulator, id:22222222-2222-2222-2222-222222222222, OS:26.0, name:iPhone 17 }
        '''
        self.assertEqual(MODULE.choose_destination(output), '11111111-1111-1111-1111-111111111111')

    def test_ignores_host_devices_and_older_os(self):
        output = '''Available destinations for the "AirKeyboard" scheme:
        { platform:iOS, id:00000000-0000-0000-0000-000000000000, OS:26.0, name:iPhone }
        { platform:iOS Simulator, id:11111111-1111-1111-1111-111111111111, OS:17.5, name:iPhone 15 }
        { platform:iOS Simulator, id:22222222-2222-2222-2222-222222222222, OS:18.5, name:iPhone 16 }
        { platform:iOS Simulator, id:33333333-3333-3333-3333-333333333333, OS:18.6, name:iPhone 16 Pro }
        '''
        self.assertEqual(MODULE.choose_destination(output), '33333333-3333-3333-3333-333333333333')

    def test_no_eligible_device_has_an_explicit_error(self):
        with self.assertRaisesRegex(ValueError, 'No eligible iPhone Simulator'):
            MODULE.choose_destination('Available destinations for the "AirKeyboard" scheme: { platform:iOS Simulator, id:placeholder, name:Any iOS Simulator Device }')

if __name__ == '__main__':
    unittest.main(verbosity=2)
