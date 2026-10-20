"""Portable artifact checks. These do NOT compile or execute Swift/iOS code."""
from pathlib import Path
import json
import plistlib
import re
import struct
import unittest
import wave
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def parse_pbx(text):
    text = re.sub(r'//[^\n]*|/\*.*?\*/', '', text, flags=re.S)
    tokens = re.findall(r'"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+', text)
    index = 0
    def take(expected=None):
        nonlocal index
        token = tokens[index]; index += 1
        if expected is not None and token != expected:
            raise ValueError(f'Expected {expected}, found {token}')
        return token
    def value():
        nonlocal index
        if tokens[index] == '{':
            take('{'); result = {}
            while tokens[index] != '}':
                key = take(); take('='); result[key.strip('"')] = value(); take(';')
            take('}'); return result
        if tokens[index] == '(':
            take('('); result = []
            while tokens[index] != ')':
                result.append(value())
                if tokens[index] == ',': take(',')
            take(')'); return result
        token = take()
        return json.loads(token) if token.startswith('"') else token
    result = value()
    if index != len(tokens): raise ValueError('Trailing project data')
    return result

class RepositoryChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.project = parse_pbx((ROOT / 'AirKeyboard.xcodeproj/project.pbxproj').read_text())
        cls.objects = cls.project['objects']

    def test_project_graph_and_all_file_references(self):
        self.assertEqual(self.objects[self.project['rootObject']]['isa'], 'PBXProject')
        for ident, obj in self.objects.items():
            for key in ['buildConfigurationList', 'mainGroup', 'productRefGroup', 'productReference', 'fileRef', 'target', 'targetProxy', 'containerPortal', 'remoteGlobalIDString']:
                if key in obj: self.assertIn(obj[key], self.objects, (ident, key))
            for key in ['children', 'buildConfigurations', 'buildPhases', 'dependencies', 'targets', 'files']:
                for ref in obj.get(key, []): self.assertIn(ref, self.objects, (ident, key))
            if obj['isa'] == 'PBXFileReference' and obj.get('sourceTree') == 'SOURCE_ROOT':
                self.assertTrue((ROOT / obj['path']).exists(), obj['path'])

    def test_targets_embed_both_extensions(self):
        targets = {o['name']: o for o in self.objects.values() if o['isa'] == 'PBXNativeTarget'}
        self.assertEqual(set(targets), {'AirKeyboard', 'AirKeyboardKeyboard', 'AirKeyboardWidgets', 'AirKeyboardTests'})
        app = targets['AirKeyboard']
        self.assertEqual(len(app['dependencies']), 2)
        embeds = [self.objects[p] for p in app['buildPhases'] if self.objects[p]['isa'] == 'PBXCopyFilesBuildPhase']
        self.assertEqual(embeds[0]['dstSubfolderSpec'], '13')
        products = [self.objects[self.objects[b]['fileRef']]['path'] for b in embeds[0]['files']]
        self.assertEqual(set(products), {'AirKeyboardKeyboard.appex', 'AirKeyboardWidgets.appex'})
        for name, target in targets.items():
            for cfg_id in self.objects[target['buildConfigurationList']]['buildConfigurations']:
                cfg = self.objects[cfg_id]['buildSettings']
                self.assertEqual(cfg['DEVELOPMENT_TEAM'], '')
                if name != 'AirKeyboardTests':
                    for key in ['INFOPLIST_FILE', 'CODE_SIGN_ENTITLEMENTS']:
                        self.assertTrue((ROOT / cfg[key]).is_file())

    def test_source_membership_and_resource_membership(self):
        targets = [o for o in self.objects.values() if o['isa'] == 'PBXNativeTarget']
        all_swift = set()
        for target in targets:
            source_paths, resources = [], []
            for phase in target['buildPhases']:
                obj = self.objects[phase]
                paths = [self.objects[self.objects[b]['fileRef']]['path'] for b in obj.get('files', [])]
                if obj['isa'] == 'PBXSourcesBuildPhase': source_paths += paths
                if obj['isa'] == 'PBXResourcesBuildPhase': resources += paths
            all_swift.update(source_paths)
            self.assertEqual(len(source_paths), len(set(source_paths)))
            if target['name'] in ['AirKeyboard', 'AirKeyboardKeyboard']:
                self.assertEqual(len([p for p in resources if p.endswith('.wav')]), 4)
                self.assertIn('Shared/Platform/SoundEngine.swift', source_paths)
            if target['name'] == 'AirKeyboardWidgets':
                self.assertIn('Widgets/SoundControl.swift', source_paths)
                self.assertNotIn('Shared/Platform/SoundEngine.swift', source_paths)
        expected = {str(p.relative_to(ROOT)).replace('\\', '/') for p in ROOT.rglob('*.swift')
                    if p.name != 'Package.swift' and not any(part in {'.build', 'build', 'DerivedData'} for part in p.relative_to(ROOT).parts)}
        self.assertEqual(all_swift, expected)

    def test_entitlements_and_extension_configuration(self):
        group = plistlib.loads((ROOT / 'Config/App-Info.plist').read_bytes())['AirKeyboardAppGroup']
        self.assertRegex(group, r'^group\.[A-Za-z0-9.-]+$')
        for name in ['App', 'Keyboard', 'Widgets']:
            data = plistlib.loads((ROOT / f'Config/{name}.entitlements').read_bytes())
            self.assertEqual(data['com.apple.security.application-groups'], [group])
            info = plistlib.loads((ROOT / f'Config/{name}-Info.plist').read_bytes())
            self.assertEqual(info['AirKeyboardAppGroup'], group)
        keyboard = plistlib.loads((ROOT / 'Config/Keyboard-Info.plist').read_bytes())['NSExtension']
        self.assertEqual(keyboard['NSExtensionPointIdentifier'], 'com.apple.keyboard-service')
        self.assertTrue(keyboard['NSExtensionAttributes']['RequestsOpenAccess'])
        self.assertEqual(keyboard['NSExtensionPrincipalClass'], '$(PRODUCT_MODULE_NAME).KeyboardViewController')
        privacy = plistlib.loads((ROOT / 'Resources/PrivacyInfo.xcprivacy').read_bytes())
        self.assertFalse(privacy['NSPrivacyTracking'])
        self.assertEqual(privacy['NSPrivacyCollectedDataTypes'], [])
        self.assertEqual(privacy['NSPrivacyAccessedAPITypes'][0]['NSPrivacyAccessedAPITypeReasons'], ['CA92.1'])

    def test_scheme_points_to_real_targets(self):
        scheme = ET.parse(ROOT / 'AirKeyboard.xcodeproj/xcshareddata/xcschemes/AirKeyboard.xcscheme')
        for element in scheme.findall('.//BuildableReference'):
            target = self.objects[element.attrib['BlueprintIdentifier']]
            self.assertEqual(target['name'], element.attrib['BlueprintName'])
        self.assertEqual(len(scheme.findall('.//TestableReference')), 1)

    def test_original_audio_is_short_bounded_pcm(self):
        fingerprints = set()
        for pack in ['tactile', 'mechanical', 'pop', 'digital']:
            with wave.open(str(ROOT / f'Resources/{pack}.wav'), 'rb') as audio:
                self.assertEqual((audio.getnchannels(), audio.getsampwidth(), audio.getframerate()), (1, 2, 44100))
                self.assertLessEqual(audio.getnframes() / audio.getframerate(), 0.05)
                data = audio.readframes(audio.getnframes())
                samples = struct.unpack('<' + 'h' * (len(data)//2), data)
                self.assertGreater(max(abs(v) for v in samples), 100)
                self.assertLess(max(abs(v) for v in samples), 16384)
                self.assertLess(abs(samples[0]), 10)
                self.assertLess(abs(samples[-1]), 10)
                fingerprints.add(data)
        self.assertEqual(len(fingerprints), 4)

    def test_example_packages_match_schema_and_starters(self):
        schema = json.loads((ROOT / 'Documentation/theme.schema.json').read_text())
        examples = list((ROOT / 'Examples').glob('*.json'))
        self.assertEqual(len(examples), 6)
        identifiers = set()
        swift = (ROOT / 'Shared/Core/StarterThemes.swift').read_text()
        for path in examples:
            value = json.loads(path.read_text())
            self.assertLessEqual(path.stat().st_size, 65536)
            self.assertTrue(set(schema['required']).issubset(value))
            for key, spec in schema['properties'].items():
                item = value[key]
                if spec['type'] == 'string':
                    self.assertIsInstance(item, str)
                    if 'pattern' in spec: self.assertRegex(item, spec['pattern'])
                    if 'minLength' in spec: self.assertGreaterEqual(len(item), spec['minLength'])
                    if 'maxLength' in spec: self.assertLessEqual(len(item), spec['maxLength'])
                else:
                    self.assertIsInstance(item, (int, float)); self.assertNotIsInstance(item, bool)
                    if spec['type'] == 'integer': self.assertIsInstance(item, int)
                    if 'minimum' in spec: self.assertGreaterEqual(item, spec['minimum'])
                    if 'maximum' in spec: self.assertLessEqual(item, spec['maximum'])
                if 'enum' in spec: self.assertIn(item, spec['enum'])
                if 'const' in spec: self.assertEqual(item, spec['const'])
            identifiers.add(value['id'])
            self.assertIn('"' + value['name'] + '"', swift)
            for key in ['background', 'key', 'primary', 'secondary', 'accent']:
                self.assertIn('"' + value[key][1:] + '"', swift)
        self.assertEqual(len(identifiers), 6)

    def test_no_network_or_clipboard_client_in_sources(self):
        for path in list((ROOT / 'App').glob('*.swift')) + list((ROOT / 'Keyboard').glob('*.swift')) + list((ROOT / 'Shared').rglob('*.swift')):
            source = path.read_text()
            for token in ['URLSession', 'NSURLConnection', 'NWConnection', 'UIPasteboard', 'import Network', 'WKWebView']:
                self.assertNotIn(token, source, str(path))
        # This source scan is a narrow regression guard, not a complete security audit.

if __name__ == '__main__':
    unittest.main(verbosity=2)
