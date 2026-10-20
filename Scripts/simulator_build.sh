#!/bin/bash
# Free, credential-free iOS Simulator validation. This script never exports a device IPA.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/evidence
xcodebuild -version > build/evidence/toolchain.txt
xcodebuild -project AirKeyboard.xcodeproj -scheme AirKeyboard -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build \
  2>&1 | tee build/evidence/simulator-build.log
SIMULATOR_UDID="$(python3 Scripts/select_simulator.py | cut -d= -f2)"
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
APP="build/DerivedData/Build/Products/Debug-iphonesimulator/AirKeyboard.app"
xcrun simctl install "$SIMULATOR_UDID" "$APP"
xcrun simctl launch "$SIMULATOR_UDID" org.example.airkeyboard | tee build/evidence/simulator-launch.log
xcrun simctl io "$SIMULATOR_UDID" screenshot build/evidence/AirKeyboard-Simulator.png
ditto -c -k --keepParent "$APP" build/evidence/AirKeyboard-Simulator.app.zip
cat > build/evidence/README.txt <<'EOF'
This artifact contains an iOS SIMULATOR app, build/test logs and simulator evidence.
It is NOT a signed device build, installable iPhone IPA, or physical-device test.
Run the .app only in a compatible iOS Simulator on a Mac.
EOF
xcodebuild -project AirKeyboard.xcodeproj -scheme AirKeyboard \
  -destination "id=$SIMULATOR_UDID" -derivedDataPath build/DerivedData \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath build/TestResults.xcresult CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO test \
  2>&1 | tee build/evidence/simulator-tests.log
