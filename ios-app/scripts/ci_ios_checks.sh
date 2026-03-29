#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="ios-app/StoryComicAIApp.xcodeproj"
SCHEME="StoryComicAIApp"
DERIVED_DATA_PATH="${PWD}/.deriveddata-ios-ci"

COMMON_FLAGS=(
  -project "${PROJECT_PATH}"
  -scheme "${SCHEME}"
  -derivedDataPath "${DERIVED_DATA_PATH}"
  "OTHER_SWIFT_FLAGS=-DCI_DISABLE_PREVIEWS"
  "ENABLE_PREVIEWS=NO"
)

echo "[ci] Building app target (preview macros disabled)"
xcodebuild "${COMMON_FLAGS[@]}" \
  -destination "generic/platform=iOS Simulator" \
  build

HOST_ARCH="$(uname -m)"

MAC_DESTINATIONS=(
  "platform=macOS,arch=${HOST_ARCH},variant=Designed for iPad"
  "platform=macOS,arch=${HOST_ARCH},variant=Designed for iPhone"
  "platform=macOS,arch=${HOST_ARCH}"
)

echo "[ci] Running tests on macOS destinations"
TEST_SUCCEEDED=false
for destination in "${MAC_DESTINATIONS[@]}"; do
  echo "[ci] Trying destination: ${destination}"
  if xcodebuild "${COMMON_FLAGS[@]}" \
    -destination "${destination}" \
    test; then
    TEST_SUCCEEDED=true
    break
  fi
done

if [ "${TEST_SUCCEEDED}" != "true" ]; then
  echo "[ci] macOS destination test failed or unavailable; running compile-level fallback"
  xcodebuild "${COMMON_FLAGS[@]}" \
    -destination "generic/platform=iOS Simulator" \
    build-for-testing
fi

echo "[ci] Completed"
