"""Select an iPhone Simulator eligible for the CURRENT Xcode scheme, not another SDK."""
from pathlib import Path
import re
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

if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    output = subprocess.check_output(['xcodebuild', '-project', str(root / 'AirKeyboard.xcodeproj'),
                                     '-scheme', 'AirKeyboard', '-showdestinations'],
                                     stderr=subprocess.STDOUT, text=True, cwd=root)
    print('SIMULATOR_UDID=' + choose_destination(output))
