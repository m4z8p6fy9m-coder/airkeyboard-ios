#!/bin/bash
# The workflow boots the selected device in its own YAML step before the test phase.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/evidence
case "${1:-build}" in
  build)
    python3 Scripts/ci_command.py --timeout 420 --log build/evidence/simulator-build.log \
      xcodebuild -project AirKeyboard.xcodeproj -scheme AirKeyboard -configuration Debug \
      -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
      -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
    APP="build/DerivedData/Build/Products/Debug-iphonesimulator/AirKeyboard.app"
    ditto -c -k --keepParent "$APP" build/evidence/AirKeyboard-Simulator.app.zip
    printf '%s\n' 'iOS SIMULATOR app only. Not an installable iPhone IPA or signed device build. Test outcome is recorded separately.' > build/evidence/README.txt
    ;;
  test)
    : "${SIMULATOR_UDID:?Select and boot a Simulator in the workflow before testing}"
    python3 Scripts/ci_command.py --timeout 420 --log build/evidence/simulator-tests.log \
      xcodebuild -project AirKeyboard.xcodeproj -scheme AirKeyboard \
      -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" -destination-timeout 60 \
      -derivedDataPath build/DerivedData -resultBundlePath build/TestResults.xcresult \
      -collect-test-diagnostics never -test-timeouts-enabled YES \
      -default-test-execution-time-allowance 180 -maximum-test-execution-time-allowance 240 \
      -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
      CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test
    python3 Scripts/ci_command.py --timeout 30 --log build/evidence/screenshot.log \
      xcrun simctl io "$SIMULATOR_UDID" screenshot build/evidence/AirKeyboard-Simulator.png
    ;;
  *) echo 'Usage: simulator_build.sh build|test (test requires a booted SIMULATOR_UDID)' >&2; exit 2 ;;
esac
