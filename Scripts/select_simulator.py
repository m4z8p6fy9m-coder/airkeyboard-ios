"""Select an iPhone Simulator eligible for the CURRENT Xcode scheme, not another SDK."""
from pathlib import Path
import re
import json
import sys
import time
import subprocess

def choose_destination(output):
    marker = 'Available destinations for the "AirKeyboard" scheme:'
    available = output.partition(marker)[2].partition('Ineligible destinations')[0]
    candidates = []
    for body in re.findall(r'\{([^{}]+)\}', available):
        values = {}
        for item in body.split(','):
            key, separator, value = item.strip().partition(':')
            if separator:
                values[key] = value.strip()
        if values.get('platform') != 'iOS Simulator' or not values.get('name', '').startswith('iPhone'):
            continue
        identifier, version = values.get('id', ''), values.get('OS', '')
        if not re.fullmatch(r'[0-9A-Fa-f-]{36}', identifier) or not re.fullmatch(r'\d+(?:\.\d+)*', version):
            continue
        parsed = tuple(map(int, version.split('.')))
        if parsed[0] >= 18:
            candidates.append((parsed, values['name'], identifier))
    if not candidates:
        raise ValueError('No eligible iPhone Simulator with iOS 18+ for the selected Xcode. Install a compatible runtime.')
    return max(candidates)[2]

def compatible_runtime(runtimes, sdk):
    ceiling = tuple(map(int, sdk.split('.'))) + (0,) * (3 - len(sdk.split('.')))
    candidates = []
    for runtime in runtimes:
        version = tuple(map(int, runtime.get('version', '0').split('.')))
        version += (0,) * (3 - len(version))
        if (runtime.get('isAvailable') is True and '.iOS-' in runtime.get('identifier', '')
                and (18, 0, 0) <= version <= ceiling):
            candidates.append((version, runtime['identifier']))
    if not candidates:
        raise ValueError('No installed available iOS 18+ runtime compatible with the selected Xcode SDK.')
    return max(candidates)[1]

def run(*args):
    if Path(args[0]).name == 'xcodebuild':
        import contextlib
        from ci_command import execute
        log = Path(__file__).resolve().parents[1] / 'build/evidence/simulator-destinations.txt'
        with contextlib.redirect_stdout(sys.stderr):
            code = execute(list(args), 90, log)
        output = log.read_text(encoding='utf-8')
        if code:
            raise subprocess.CalledProcessError(code, args, output=output)
        return output
    try:
        return subprocess.check_output(args, stderr=subprocess.STDOUT, text=True, timeout=60)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as error:
        print(f'::error::Simulator command failed: {args}; {error.output}', file=sys.stderr)
        raise

if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    evidence = root / 'build/evidence'
    evidence.mkdir(parents=True, exist_ok=True)
    command = ['xcodebuild', '-project', str(root / 'AirKeyboard.xcodeproj'),
               '-scheme', 'AirKeyboard', '-showdestinations']
    output = run(*command)
    (evidence / 'simulator-destinations.txt').write_text(output)
    try:
        identifier = choose_destination(output)
    except ValueError:
        # New runner images can have a compatible runtime but no pre-created device.
        runtimes = run('xcrun', 'simctl', 'list', 'runtimes', '-j')
        types = run('xcrun', 'simctl', 'list', 'devicetypes', '-j')
        (evidence / 'simulator-runtimes.json').write_text(runtimes)
        (evidence / 'simulator-device-types.json').write_text(types)
        runtime = compatible_runtime(json.loads(runtimes)['runtimes'],
                                     run('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version').strip())
        runtime_value = next(r for r in json.loads(runtimes)['runtimes'] if r['identifier'] == runtime)
        version = list(map(int, runtime_value['version'].split('.')))
        version += [0] * (3 - len(version))
        encoded = (version[0] << 16) + (version[1] << 8) + version[2]
        phones = [d for d in json.loads(types)['devicetypes'] if d['name'].startswith('iPhone')
                  and d.get('minRuntimeVersion', 0) <= encoded <= d.get('maxRuntimeVersion', 0xffffffff)]
        if not phones:
            raise ValueError('No installed iPhone device type supports the compatible runtime.')
        device_type = max(phones, key=lambda d: d['name'])['identifier']
        created = run('xcrun', 'simctl', 'create', 'AirKeyboard-CI', device_type, runtime).strip()
        print('Created an actual Simulator device: ' + created, file=sys.stderr)
        for attempt in range(3):
            output = run(*command)
            (evidence / 'simulator-destinations.txt').write_text(output)
            try:
                identifier = choose_destination(output)
                break
            except ValueError:
                if attempt == 2:
                    print(output, file=sys.stderr)
                    raise
                time.sleep(5)
    print('SIMULATOR_UDID=' + identifier)
