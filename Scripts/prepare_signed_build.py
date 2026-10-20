"""Configure an ephemeral macOS CI signing environment from explicit developer secrets.

No credentials are embedded in the repository, emitted to stdout, or added to artifacts.
"""
import argparse
import base64
from datetime import datetime, timezone
import importlib.util
import os
from pathlib import Path
import plistlib
import re
import secrets
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def run(*args):
    result = subprocess.run(args, capture_output=True)
    if result.returncode:
        # security/cms diagnostics can contain account/profile details; do not echo them.
        raise RuntimeError('Signing tool failed: ' + args[0] + ' ' + args[1])
    return result.stdout

def validate_profile(profile, bundle_id, group, team):
    entitlements = profile.get('Entitlements', {})
    if profile.get('TeamIdentifier') != [team]:
        raise ValueError('A provisioning profile belongs to a different team')
    prefixes = profile.get('ApplicationIdentifierPrefix', [])
    if not any(entitlements.get('application-identifier') == prefix + '.' + bundle_id for prefix in prefixes):
        raise ValueError('A profile does not match its explicit target bundle identifier')
    if entitlements.get('com.apple.security.application-groups') != [group]:
        raise ValueError('Every profile must authorize exactly the configured App Group')
    if not entitlements.get('get-task-allow') or not profile.get('ProvisionedDevices'):
        raise ValueError('Use development provisioning profiles for registered devices')
    expiry = profile.get('ExpirationDate')
    if not isinstance(expiry, datetime) or expiry.replace(tzinfo=timezone.utc) <= datetime.now(timezone.utc):
        raise ValueError('A provisioning profile has expired or has no expiry')
    if not re.fullmatch(r'[A-Za-z0-9-]{16,64}', profile.get('UUID', '')):
        raise ValueError('Invalid profile UUID')
    return profile['UUID']

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle-prefix', required=True)
    parser.add_argument('--app-group', required=True)
    parser.add_argument('--team', required=True)
    parser.add_argument('--temporary', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z0-9-]+){2,}', args.bundle_prefix):
        raise ValueError('Use an owned reverse-domain bundle prefix')
    if not re.fullmatch(r'group\.[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+', args.app_group):
        raise ValueError('Use a registered group identifier')
    if not re.fullmatch(r'[A-Z0-9]{10}', args.team):
        raise ValueError('Use your real ten-character Apple team identifier')
    names = ['APPLE_CERTIFICATE_P12_BASE64', 'APPLE_CERTIFICATE_PASSWORD', 'APPLE_APP_PROFILE_BASE64',
             'APPLE_KEYBOARD_PROFILE_BASE64', 'APPLE_WIDGETS_PROFILE_BASE64']
    for name in names:
        if not os.environ.get(name):
            raise ValueError('Missing GitHub Actions secret: ' + name)
    temporary = Path(args.temporary).resolve()
    temporary.mkdir(parents=True, exist_ok=True)
    keychain = temporary / 'AirKeyboard-signing.keychain-db'
    password = secrets.token_urlsafe(32)
    cert = temporary / 'certificate.p12'
    cert.write_bytes(base64.b64decode(os.environ[names[0]], validate=True))
    cert.chmod(0o600)
    run('security', 'create-keychain', '-p', password, str(keychain))
    run('security', 'set-keychain-settings', '-lut', '21600', str(keychain))
    run('security', 'unlock-keychain', '-p', password, str(keychain))
    run('security', 'import', str(cert), '-P', os.environ[names[1]], '-k', str(keychain), '-T', '/usr/bin/codesign', '-T', '/usr/bin/security')
    run('security', 'set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', password, str(keychain))
    run('security', 'list-keychains', '-d', 'user', '-s', str(keychain))
    cert.unlink()
    installed = Path.home() / 'Library/MobileDevice/Provisioning Profiles'
    installed.mkdir(parents=True, exist_ok=True)
    profiles, overrides = {}, {}
    for target, suffix, env in [
        ('AirKeyboard', '', 'APPLE_APP_PROFILE_BASE64'),
        ('AirKeyboardKeyboard', '.keyboard', 'APPLE_KEYBOARD_PROFILE_BASE64'),
        ('AirKeyboardWidgets', '.widgets', 'APPLE_WIDGETS_PROFILE_BASE64'),
    ]:
        data = base64.b64decode(os.environ[env], validate=True)
        path = temporary / (target + '.mobileprovision')
        path.write_bytes(data); path.chmod(0o600)
        profile = plistlib.loads(run('security', 'cms', '-D', '-i', str(path)))
        bundle_id = args.bundle_prefix + suffix
        identifier = validate_profile(profile, bundle_id, args.app_group, args.team)
        (installed / (identifier + '.mobileprovision')).write_bytes(data)
        profiles[bundle_id] = identifier
        overrides[target] = {
            'PRODUCT_BUNDLE_IDENTIFIER': bundle_id, 'CODE_SIGN_STYLE': 'Manual',
            'DEVELOPMENT_TEAM': args.team, 'CODE_SIGN_IDENTITY': 'Apple Development',
            'PROVISIONING_PROFILE_SPECIFIER': identifier,
        }
    spec = importlib.util.spec_from_file_location('project_generator', ROOT / 'Scripts/generate_project.py')
    generator = importlib.util.module_from_spec(spec); spec.loader.exec_module(generator)
    generator.generate_configuration(args.app_group)
    generator.generate_project(overrides)
    export = {'method': 'debugging', 'teamID': args.team, 'signingStyle': 'manual',
              'signingCertificate': 'Apple Development', 'provisioningProfiles': profiles,
              'destination': 'export', 'manageAppVersionAndBuildNumber': False}
    (temporary / 'ExportOptions.plist').write_bytes(plistlib.dumps(export))
    print('Configured three development profiles and matching App Group. Credentials were not printed.')

if __name__ == '__main__':
    main()
