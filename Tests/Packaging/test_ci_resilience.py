"""Regression cases for the actual CoreSimulator startup failures in runs 24/25."""
import contextlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'Scripts' / (name + '.py'))
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


COMMAND = module('ci_command')
SELECTION = module('select_simulator')


class SimulatorResilienceTests(unittest.TestCase):
    def test_transient_probe_failure_recovers_with_separate_evidence(self):
        with patch.object(COMMAND, 'execute', side_effect=[124, 0]) as execute, \
                patch.object(COMMAND.time, 'sleep') as sleep, contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(COMMAND.wake_simulator('build/test.log'), 0)
        self.assertEqual(execute.call_count, 2)
        self.assertNotEqual(execute.call_args_list[0].args[2], execute.call_args_list[1].args[2])
        self.assertEqual(execute.call_args.args[0], ['xcrun', 'simctl', 'list', 'devices', 'booted', '-j'])
        sleep.assert_called_once_with(3)
        self.assertNotIn('::error::', output.getvalue())

    def test_persistent_probe_failure_blocks_xcodebuild(self):
        args = ['ci_command.py', '--timeout', '60', '--log', 'build/test.log', 'xcodebuild', '-version']
        with patch.object(COMMAND.sys, 'argv', args), \
                patch.object(COMMAND, 'execute', return_value=124) as execute, \
                patch.object(COMMAND.time, 'sleep'), contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(COMMAND.main(), 124)
        self.assertEqual(execute.call_count, 2)
        self.assertTrue(all(call.args[0][0] == 'xcrun' for call in execute.call_args_list))
        self.assertIn('::error::CoreSimulator unavailable', output.getvalue())

    def test_successful_probe_does_not_retry(self):
        with patch.object(COMMAND, 'execute', return_value=0) as execute, patch.object(COMMAND.time, 'sleep') as sleep:
            self.assertEqual(COMMAND.wake_simulator('build/test.log'), 0)
        execute.assert_called_once()
        sleep.assert_not_called()

    def test_available_but_newer_runtime_is_excluded_by_sdk(self):
        destinations = '''Available destinations for the "AirKeyboard" scheme:
        { platform:iOS Simulator, id:11111111-1111-1111-1111-111111111111, OS:18.5, name:iPhone 16 }
        { platform:iOS Simulator, id:22222222-2222-2222-2222-222222222222, OS:26.2, name:iPhone SE }
        '''
        self.assertEqual(SELECTION.choose_destination(destinations, '18.5'), '11111111-1111-1111-1111-111111111111')

    def test_newer_only_destinations_require_compatible_device_creation(self):
        destinations = '''Available destinations for the "AirKeyboard" scheme:
        { platform:iOS Simulator, id:22222222-2222-2222-2222-222222222222, OS:26.2, name:iPhone SE }
        '''
        with self.assertRaises(ValueError):
            SELECTION.choose_destination(destinations, '18.5')

    def test_patch_versions_are_compared_numerically(self):
        destinations = '''Available destinations for the "AirKeyboard" scheme:
        { platform:iOS Simulator, id:11111111-1111-1111-1111-111111111111, OS:18.5, name:iPhone 16 }
        { platform:iOS Simulator, id:22222222-2222-2222-2222-222222222222, OS:18.5.1, name:iPhone 16 }
        '''
        self.assertEqual(SELECTION.choose_destination(destinations, '18.5.0'), '11111111-1111-1111-1111-111111111111')
