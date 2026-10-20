"""Emit a GitHub Actions environment assignment for an installed iOS 18+ iPhone."""
import json
import subprocess

data = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '-j']))
for runtime, devices in sorted(data['devices'].items(), reverse=True):
    if 'SimRuntime.iOS-' not in runtime:
        continue
    major = int(runtime.split('iOS-')[1].split('-')[0])
    if major < 18:
        continue
    for device in devices:
        if device.get('isAvailable') and device['name'].startswith('iPhone'):
            print('SIMULATOR_UDID=' + device['udid'])
            raise SystemExit(0)
raise SystemExit('No available iPhone simulator with iOS 18 or newer is installed.')
