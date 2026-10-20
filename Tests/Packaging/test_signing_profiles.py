from datetime import datetime, timedelta, timezone
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('signing', ROOT / 'Scripts/prepare_signed_build.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

class ProfileTests(unittest.TestCase):
    def setUp(self):
        self.profile = {
            'TeamIdentifier': ['ABCDEFGHIJ'], 'ApplicationIdentifierPrefix': ['ABCDEFGHIJ'],
            'Entitlements': {'application-identifier': 'ABCDEFGHIJ.com.example.airkeyboard',
                'com.apple.security.application-groups': ['group.com.example.airkeyboard'], 'get-task-allow': True},
            'ProvisionedDevices': ['synthetic-test-device-not-a-real-udid'],
            'ExpirationDate': datetime.now(timezone.utc) + timedelta(days=1),
            'UUID': '11111111-1111-1111-1111-111111111111'
        }
    def validate(self):
        return MODULE.validate_profile(self.profile, 'com.example.airkeyboard', 'group.com.example.airkeyboard', 'ABCDEFGHIJ')

    def test_accepts_matching_development_profile(self):
        self.assertEqual(self.validate(), self.profile['UUID'])

    def test_rejects_wrong_group(self):
        self.profile['Entitlements']['com.apple.security.application-groups'] = ['group.other.app']
        with self.assertRaisesRegex(ValueError, 'App Group'):
            self.validate()

    def test_rejects_wrong_team_and_wildcard_identifier(self):
        self.profile['TeamIdentifier'] = ['OTHERTEAM1']
        with self.assertRaisesRegex(ValueError, 'team'):
            self.validate()
        self.profile['TeamIdentifier'] = ['ABCDEFGHIJ']
        self.profile['Entitlements']['application-identifier'] = 'ABCDEFGHIJ.*'
        with self.assertRaisesRegex(ValueError, 'bundle identifier'):
            self.validate()

    def test_rejects_expired_profile(self):
        self.profile['ExpirationDate'] = datetime.now(timezone.utc) - timedelta(days=1)
        with self.assertRaisesRegex(ValueError, 'expired'):
            self.validate()

    def test_rejects_distribution_profile(self):
        self.profile['Entitlements']['get-task-allow'] = False
        with self.assertRaisesRegex(ValueError, 'development'):
            self.validate()

if __name__ == '__main__':
    unittest.main(verbosity=2)
