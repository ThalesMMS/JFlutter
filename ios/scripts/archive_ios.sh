#!/usr/bin/env bash
# Builds, archives, and exports the iOS Release app for App Store distribution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${IOS_DIR}/.." && pwd)"
WORKSPACE_PATH="${WORKSPACE_PATH:-${IOS_DIR}/Runner.xcworkspace}"
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

echo "==> Validating Flutter and iOS toolchain"
require_command flutter
require_command xcodebuild

if [[ ! -f "${EXPORT_OPTIONS_PLIST}" ]]; then
  echo "Error: Export options plist '${EXPORT_OPTIONS_PLIST}' does not exist." >&2
  exit 1
fi

flutter doctor -v

mkdir -p "$(dirname "${ARCHIVE_PATH}")" "${EXPORT_PATH}" "${DERIVED_DATA_PATH}"
rm -rf "${ARCHIVE_PATH}" "${EXPORT_PATH}"
mkdir -p "${EXPORT_PATH}"

echo "==> Running flutter build ios --release"
flutter build ios --release

echo "==> Archiving ${SCHEME_NAME} (${CONFIGURATION_NAME})"
xcodebuild \
  -workspace "${WORKSPACE_PATH}" \
  -scheme "${SCHEME_NAME}" \
  -configuration "${CONFIGURATION_NAME}" \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -allowProvisioningUpdates \
  archive

echo "==> Exporting archive using ${EXPORT_OPTIONS_PLIST}"
xcodebuild \
  -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" \
  -allowProvisioningUpdates

echo "Archive created at ${ARCHIVE_PATH}"
echo "Exported IPA artifacts at ${EXPORT_PATH}"
