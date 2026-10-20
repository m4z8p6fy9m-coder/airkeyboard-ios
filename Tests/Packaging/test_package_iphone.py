import importlib.util
import json
from pathlib import Path
import plistlib
import struct
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('package_iphone', ROOT / 'Scripts/package_iphone.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / 'AirKeyboard.app'
        for index, executable in enumerate(MODULE.EXECUTABLES):
            path = self.app / executable
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(struct.pack('<14I', 0xFEEDFACF, 0x0100000C, 0, 2, 1, 24, 0, 0, 0x32, 24, 2, 0x00120000, 0x00120000, 0))
            info = {'CFBundleExecutable': path.name, 'CFBundleIdentifier': 'org.example.airkeyboard' + ['', '.keyboard', '.widgets'][index],
                    'CFBundleSupportedPlatforms': ['iPhoneOS'], 'MinimumOSVersion': '18.0'}
            (path.parent / 'Info.plist').write_bytes(plistlib.dumps(info, fmt=plistlib.FMT_BINARY))

    def test_packages_both_extensions_and_records_signing_requirement(self):
        output = self.root / 'AirKeyboard.ipa'
        result = MODULE.package(self.app, output)
        self.assertTrue(result['requiresAppleSigning'])
        self.assertEqual(len(result['extensionIdentifiers']), 2)
        self.assertEqual(json.loads(output.with_suffix('.manifest.json').read_text())['sha256'], result['sha256'])
        with zipfile.ZipFile(output) as archive:
            for executable in MODULE.EXECUTABLES:
                self.assertIn('Payload/AirKeyboard.app/' + executable, archive.namelist())
            self.assertIsNone(archive.testzip())

    def test_rejects_simulator_binary(self):
        path = self.app / MODULE.EXECUTABLES[0]
        data = bytearray(path.read_bytes())
        struct.pack_into('<I', data, 40, 7)
        path.write_bytes(data)
        with self.assertRaisesRegex(ValueError, 'Simulator'):
            MODULE.package(self.app, self.root / 'result.ipa')

    def test_rejects_missing_keyboard(self):
        (self.app / MODULE.EXECUTABLES[1]).unlink()
        with self.assertRaises(FileNotFoundError):
            MODULE.package(self.app, self.root / 'result.ipa')

    def test_rejects_wrong_extension_identifier(self):
        path = self.app / 'PlugIns/AirKeyboardKeyboard.appex/Info.plist'
        info = plistlib.loads(path.read_bytes()); info['CFBundleIdentifier'] = 'org.other.keyboard'
        path.write_bytes(plistlib.dumps(info))
        with self.assertRaisesRegex(ValueError, 'prefix'):
            MODULE.package(self.app, self.root / 'result.ipa')

    def test_rejects_output_inside_app(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            MODULE.package(self.app, self.app / 'result.ipa')

    def test_rejects_truncated_binary(self):
        (self.app / 'AirKeyboard').write_bytes(b'broken')
        with self.assertRaisesRegex(ValueError, 'Truncated'):
            MODULE.package(self.app, self.root / 'result.ipa')

    def test_rejects_macos_platform_metadata(self):
        path = self.app / 'Info.plist'
        info = plistlib.loads(path.read_bytes()); info['CFBundleSupportedPlatforms'] = ['MacOSX']
        path.write_bytes(plistlib.dumps(info))
        with self.assertRaisesRegex(ValueError, 'iPhoneOS'):
            MODULE.package(self.app, self.root / 'result.ipa')

if __name__ == '__main__':
    unittest.main(verbosity=2)
