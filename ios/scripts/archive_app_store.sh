#!/usr/bin/env bash
# Creates a signed iOS Release archive and exports an App Store IPA.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${IOS_DIR}/.." && pwd)"
if [[ -n "${FLUTTER_BIN:-}" ]]; then
  :
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
elif [[ -x "/usr/local/bin/flutter" ]]; then
  FLUTTER_BIN="/usr/local/bin/flutter"
elif [[ -x "/opt/homebrew/bin/flutter" ]]; then
  FLUTTER_BIN="/opt/homebrew/bin/flutter"
else
  echo "Error: Flutter was not found on PATH or in the known default locations." >&2
  echo "Set FLUTTER_BIN to your local Flutter binary before running this script." >&2
  exit 1
fi
WORKSPACE_PATH="${IOS_DIR}/Runner.xcworkspace"
SCHEME_NAME="${SCHEME_NAME:-Runner}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Release}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-${IOS_DIR}/ExportOptions.plist}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${REPO_ROOT}/build/ios/archive/${SCHEME_NAME}.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-${REPO_ROOT}/build/ios/ipa}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/build/ios/derived_data}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: Required command '$1' was not found in PATH." >&2
    exit 1
  fi
}

require_command xcodebuild

if ! command -v pod >/dev/null 2>&1; then
  echo "Error: CocoaPods is not installed or 'pod' is not in PATH." >&2
  echo "Install CocoaPods before running the iOS archive workflow on a clean machine." >&2
  exit 1
fi

if [[ ! -f "${EXPORT_OPTIONS_PLIST}" ]]; then
  echo "Error: Export options plist '${EXPORT_OPTIONS_PLIST}' does not exist." >&2
  exit 1
fi

mkdir -p "$(dirname "${ARCHIVE_PATH}")" "${EXPORT_PATH}" "${DERIVED_DATA_PATH}"
rm -rf "${ARCHIVE_PATH}" "${EXPORT_PATH}"
mkdir -p "${EXPORT_PATH}"

echo "==> flutter pub get"
"${FLUTTER_BIN}" pub get

echo "==> pod install"
(cd "${IOS_DIR}" && pod install)

echo "==> flutter build ios --release"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" build ios --release)

echo "==> xcodebuild archive"
xcodebuild \
  -workspace "${WORKSPACE_PATH}" \
  -scheme "${SCHEME_NAME}" \
  -configuration "${CONFIGURATION_NAME}" \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -allowProvisioningUpdates \
  archive

echo "==> xcodebuild -exportArchive"
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
  -allowProvisioningUpdates

echo "Archive created at ${ARCHIVE_PATH}"
echo "Exported IPA artifacts at ${EXPORT_PATH}"
