import importlib.util
from pathlib import Path
import plistlib
import re
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result

class FreeConfigurationTests(unittest.TestCase):
    def test_active_workflows_use_only_standard_public_runners_without_apple_secrets(self):
        workflows = list((ROOT / '.github/workflows').glob('*.yml'))
        self.assertTrue(workflows)
        for workflow in workflows:
            text = workflow.read_text()
            runners = re.findall(r'^\s+runs-on:\s*(\S+)\s*$', text, re.M)
            self.assertTrue(runners)
            self.assertTrue(set(runners) <= {'macos-15', 'macos-15-intel', 'ubuntu-latest', 'windows-latest'})
            self.assertNotIn('secrets.', text)
            self.assertEqual(len(runners), text.count('if: github.event.repository.private == false'))
            self.assertTrue(all(int(days) <= 1 for days in re.findall(r'retention-days:\s*(\d+)', text)))
        self.assertFalse((ROOT / '.github/workflows/iphone-signed.yml').exists())

    def test_local_device_generation_removes_app_groups_for_all_targets(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / 'project'
            shutil.copytree(ROOT, destination, ignore=shutil.ignore_patterns('.git', 'dist', 'build', '.build', '__pycache__'))
            generator = module('generator_local_test', ROOT / 'Scripts/generate_project.py')
            generator.ROOT = destination
            generator.generate_configuration(local_device=True)
            generator.generate_project(local_device=True)
            checker = module('checker_local_test', ROOT / 'Scripts/check_repository.py')
            project = checker.parse_pbx((destination / 'AirKeyboard.xcodeproj/project.pbxproj').read_text())
            for name in ['App', 'Keyboard', 'Widgets']:
                self.assertEqual(plistlib.loads((destination / f'Config/{name}.entitlements').read_bytes()), {})
                self.assertEqual(plistlib.loads((destination / f'Config/{name}-Info.plist').read_bytes())['AirKeyboardStorageMode'], 'local')
            targets = [o for o in project['objects'].values() if o['isa'] == 'PBXNativeTarget' and not o['name'].endswith('Tests')]
            self.assertEqual(len(targets), 3)
            for target in targets:
                configs = project['objects'][target['buildConfigurationList']]['buildConfigurations']
                for config in configs:
                    settings = project['objects'][config]['buildSettings']
                    self.assertEqual(settings['CODE_SIGN_ENTITLEMENTS'], '')
                    self.assertEqual(settings['DEVELOPMENT_TEAM'], '')

    def test_default_configuration_keeps_shared_capability_optional(self):
        with tempfile.TemporaryDirectory() as temporary:
            generator = module('generator_shared_test', ROOT / 'Scripts/generate_project.py')
            generator.ROOT = Path(temporary)
            generator.generate_configuration()
            for name in ['App', 'Keyboard', 'Widgets']:
                info = plistlib.loads((Path(temporary) / f'Config/{name}-Info.plist').read_bytes())
                self.assertEqual(info['AirKeyboardStorageMode'], 'automatic')
                self.assertEqual(info['AirKeyboardAppGroup'], 'group.org.example.airkeyboard')
            self.assertNotIn('APPLE_CERTIFICATE', (ROOT / '.github/workflows/ci.yml').read_text())

if __name__ == '__main__':
    unittest.main(verbosity=2)
