"""Stream CI output to a durable log and bound commands, including daemon startup."""
import argparse
import os
from pathlib import Path
import signal
import subprocess
import sys
import threading
import time


def execute(command, timeout, log, stream=True, report_errors=True):
    log = Path(log)
    log.parent.mkdir(parents=True, exist_ok=True)
    print(f"CI command ({timeout}s limit): {' '.join(command)}", flush=True)
    started = time.monotonic()
    with log.open('w', encoding='utf-8') as output:
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   start_new_session=True)

        def copy_output():
            for data in iter(process.stdout.readline, b''):
                line = data.decode('utf-8', errors='replace')
                output.write(line)
                output.flush()
                if stream:
                    print(line, end='', flush=True)

        reader = threading.Thread(target=copy_output, daemon=True)
        reader.start()
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            message = f"::{'error' if report_errors else 'warning'}::Timed out after {timeout}s: {' '.join(command)}; see {log}"
            print(message, flush=True)
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
            code = 124
        reader.join(timeout=5)
    print(f"CI command exited {code} after {time.monotonic() - started:.1f}s; log: {log}", flush=True)
    if code and report_errors:
        print(f"::error::Command failed (exit {code}): {' '.join(command)}; see {log}", flush=True)
    return code


def wake_simulator(log):
    """Bounded read-only daemon probe; retry startup contention once, never hide failure."""
    for attempt in range(2):
        attempt_log = str(Path(log).with_suffix(f'.wake-{attempt + 1}.log'))
        code = execute(['xcrun', 'simctl', 'list', 'devices', 'booted', '-j'],
                       25, attempt_log, stream=False, report_errors=False)
        if code == 0:
            return 0
        if attempt == 0:
            print('::warning::CoreSimulator probe failed; retrying once after 3s', flush=True)
            time.sleep(3)
    print(f'::error::CoreSimulator unavailable after two bounded probes; see {log} wake logs', flush=True)
    return code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--timeout', type=int, required=True)
    parser.add_argument('--log', required=True)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if not args.command or args.timeout <= 0:
        parser.error('a command and positive timeout are required')
    if Path(args.command[0]).name == 'xcodebuild':
        # Initialize CoreSimulator immediately before every xcodebuild invocation.
        code = wake_simulator(args.log)
        if code:
            return code
    return execute(args.command, args.timeout, args.log)


if __name__ == '__main__':
    sys.exit(main())
