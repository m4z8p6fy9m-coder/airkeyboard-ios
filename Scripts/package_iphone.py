"""Package a REAL device .app for Windows re-signing. Never builds a placeholder IPA."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import plistlib
import struct
import tempfile
import zipfile

EXECUTABLES = (
    'AirKeyboard',
    'PlugIns/AirKeyboardKeyboard.appex/AirKeyboardKeyboard',
    'PlugIns/AirKeyboardWidgets.appex/AirKeyboardWidgets',
)

def inspect_macho(path):
    with path.open('rb') as stream:
        header = stream.read(32)
        if len(header) != 32:
            raise ValueError('Truncated device executable: ' + str(path))
        magic, cpu, _, kind, count, length, _, _ = struct.unpack('<8I', header)
        if (magic, cpu, kind) != (0xFEEDFACF, 0x0100000C, 2):
            raise ValueError('Expected a thin ARM64 executable. Build with ARCHS=arm64: ' + str(path))
        if not 1 <= count <= 4096 or length > 4_194_304:
            raise ValueError('Invalid Mach-O load commands')
        commands = stream.read(length)
        if len(commands) != length:
            raise ValueError('Truncated Mach-O load commands')
        offset, ios = 0, False
        for _ in range(count):
            if offset + 8 > len(commands):
                raise ValueError('Invalid Mach-O command header')
            command, size = struct.unpack_from('<2I', commands, offset)
            if size < 8 or size % 8 or offset + size > len(commands):
                raise ValueError('Invalid Mach-O command size')
            if command == 0x32:
                if size < 24 or struct.unpack_from('<I', commands, offset + 8)[0] != 2:
                    raise ValueError('Simulator/other-platform binary cannot be installed on an iPhone')
                ios = True
            offset += size
        if offset != length or not ios:
            raise ValueError('Missing iOS build platform')

def package(app, output):
    app, output = Path(app).resolve(), Path(output).resolve()
    if app.name != 'AirKeyboard.app' or not app.is_dir() or output.suffix.lower() != '.ipa':
        raise ValueError('Provide the built AirKeyboard.app directory and a .ipa output path')
    if output.is_relative_to(app):
        raise ValueError('Output must be outside the input app')
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
        raise ValueError('Only physical-device iPhoneOS builds are accepted')
    if int(str(info.get('MinimumOSVersion', '0')).split('.')[0]) < 18:
        raise ValueError('AirKeyboard requires iOS 18 or later')
    extension_ids = []
    for executable in EXECUTABLES:
        path = app / executable
        inspect_macho(path)
        metadata = plistlib.loads((path.parent / 'Info.plist').read_bytes())
        if metadata.get('CFBundleExecutable') != path.name:
            raise ValueError('Executable name does not match bundle metadata')
        bundle_id = metadata.get('CFBundleIdentifier', '')
        if executable != EXECUTABLES[0]:
            if not bundle_id.startswith(info['CFBundleIdentifier'] + '.'):
                raise ValueError('Extension bundle identifier must use the app bundle prefix')
            extension_ids.append(bundle_id)
    paths, total = [], 0
    for path in sorted(app.rglob('*')):
        if path.is_symlink():
            raise ValueError('Symlinks are not supported in this iPhone package')
        if path.is_file():
            total += path.stat().st_size
            paths.append(path)
    if total > 1_073_741_824 or len(paths) > 50_000:
        raise ValueError('App exceeds the companion package limits')
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix='airkeyboard-', suffix='.ipa', dir=output.parent)
    os.close(descriptor)
    try:
        with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED) as archive:
            for path in paths:
                archive.write(path, 'Payload/AirKeyboard.app/' + path.relative_to(app).as_posix())
        if Path(temporary).stat().st_size > 536_870_912:
            raise ValueError('Compressed IPA exceeds 512 MB')
        os.replace(temporary, output)
    finally:
        if Path(temporary).exists():
            Path(temporary).unlink()
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    manifest = {
        'formatVersion': 1, 'file': output.name, 'sha256': digest,
        'bundleIdentifier': info['CFBundleIdentifier'], 'extensionIdentifiers': extension_ids,
        'minimumIOS': info['MinimumOSVersion'], 'requiresAppleSigning': True,
        'notice': 'Device build for re-signing. Not installable until signed and provisioned. Retain both extensions and map the App Group consistently.'
    }
    output.with_suffix('.manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    output.with_suffix('.sha256').write_text(digest + '  ' + output.name + '\n', encoding='ascii')
    return manifest

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = package(args.app, args.output)
    print('Packaged real device app: ' + result['file'] + '. Apple signing is still required.')
