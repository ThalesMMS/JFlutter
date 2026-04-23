#!/usr/bin/env bash
# Creates a signed macOS Release archive and exports App Store artifacts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${MACOS_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
MIN_FLUTTER_VERSION="${MIN_FLUTTER_VERSION:-3.27.0}"
discover_flutter_bin
WORKSPACE_PATH="${WORKSPACE_PATH:-${MACOS_DIR}/Runner.xcworkspace}"
SCHEME_NAME="${SCHEME_NAME:-Runner}"
TARGET_NAME="${TARGET_NAME:-Runner}"
CONFIGURATION_NAME="${CONFIGURATION_NAME:-Release}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-${MACOS_DIR}/ExportOptions.plist}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${REPO_ROOT}/build/macos/archive/${SCHEME_NAME}.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-${REPO_ROOT}/build/macos/export}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${REPO_ROOT}/build/macos/derived_data}"
MACOS_BUILD_ROOT="${REPO_ROOT}/build/macos"

require_command xcodebuild

FLUTTER_VERSION_OUTPUT="$("${FLUTTER_BIN}" --version)"
FLUTTER_VERSION="$(awk 'NR==1 { print $2; exit }' <<<"${FLUTTER_VERSION_OUTPUT}")"

if [[ -z "${FLUTTER_VERSION}" ]]; then
  echo "Error: Could not determine the installed Flutter version." >&2
  exit 1
fi

if ! version_gte "${FLUTTER_VERSION}" "${MIN_FLUTTER_VERSION}"; then
  echo "Error: Flutter ${MIN_FLUTTER_VERSION}+ is required, but '${FLUTTER_VERSION}' is installed." >&2
  exit 1
fi

if ! command -v pod >/dev/null 2>&1; then
  echo "Error: CocoaPods is not installed or 'pod' is not in PATH." >&2
  echo "Install CocoaPods before running the macOS archive workflow on a clean machine." >&2
  exit 1
fi

if [[ ! -f "${EXPORT_OPTIONS_PLIST}" ]]; then
  echo "Error: Export options plist '${EXPORT_OPTIONS_PLIST}' does not exist." >&2
  exit 1
fi

validate_export_options_plist() {
  local plist_team_id
  local plist_signing_style
  local expected_signing_style

  plist_team_id="$(/usr/libexec/PlistBuddy -c 'Print :teamID' "${EXPORT_OPTIONS_PLIST}" 2>/dev/null || true)"
  plist_signing_style="$(/usr/libexec/PlistBuddy -c 'Print :signingStyle' "${EXPORT_OPTIONS_PLIST}" 2>/dev/null || true)"
  expected_signing_style="$(tr '[:upper:]' '[:lower:]' <<<"${CODE_SIGN_STYLE}")"

  if [[ -z "${plist_team_id}" ]]; then
    echo "Error: Export options plist '${EXPORT_OPTIONS_PLIST}' is missing teamID. Expected '${DEVELOPMENT_TEAM}'." >&2
    exit 1
  fi

  if [[ -z "${plist_signing_style}" ]]; then
    echo "Error: Export options plist '${EXPORT_OPTIONS_PLIST}' is missing signingStyle. Expected '${expected_signing_style}'." >&2
    exit 1
  fi

  if [[ "${plist_team_id}" != "${DEVELOPMENT_TEAM}" ]]; then
    echo "Error: Export options plist teamID mismatch. Expected '${DEVELOPMENT_TEAM}', found '${plist_team_id}'." >&2
    exit 1
  fi

  if [[ "${plist_signing_style}" != "${expected_signing_style}" ]]; then
    echo "Error: Export options plist signingStyle mismatch. Expected '${expected_signing_style}' from CODE_SIGN_STYLE='${CODE_SIGN_STYLE}', found '${plist_signing_style}'." >&2
    exit 1
  fi
}

mkdir -p "${MACOS_BUILD_ROOT}"
MACOS_BUILD_ROOT="$(cd "${MACOS_BUILD_ROOT}" && pwd -P)"
ARCHIVE_ROOT="${MACOS_BUILD_ROOT}/archive"
EXPORT_ROOT="${MACOS_BUILD_ROOT}/export"
DERIVED_DATA_ROOT="${MACOS_BUILD_ROOT}/derived_data"

ARCHIVE_PATH="$(validate_managed_path ARCHIVE_PATH "${ARCHIVE_PATH}" "${ARCHIVE_ROOT}" ".xcarchive")"
EXPORT_PATH="$(validate_managed_path EXPORT_PATH "${EXPORT_PATH}" "${EXPORT_ROOT}")"
DERIVED_DATA_PATH="$(validate_managed_path DERIVED_DATA_PATH "${DERIVED_DATA_PATH}" "${DERIVED_DATA_ROOT}")"
ARCHIVE_DIR="$(validate_managed_path ARCHIVE_DIR "$(dirname "${ARCHIVE_PATH}")" "${ARCHIVE_ROOT}")"

mkdir -p "${ARCHIVE_DIR}" "${EXPORT_PATH}" "${DERIVED_DATA_PATH}"
rm -rf "${ARCHIVE_PATH}" "${EXPORT_PATH}"
mkdir -p "${EXPORT_PATH}"

echo "==> flutter pub get"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" pub get)

echo "==> pod install"
(cd "${MACOS_DIR}" && pod install)

validate_release_configuration
validate_export_options_plist

echo "==> flutter build macos --release"
(cd "${REPO_ROOT}" && "${FLUTTER_BIN}" build macos --release)

echo "==> xcodebuild archive"
xcodebuild \
  -workspace "${WORKSPACE_PATH}" \
  -scheme "${SCHEME_NAME}" \
  -configuration "${CONFIGURATION_NAME}" \
  -destination "generic/platform=macOS" \
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
echo "Exported macOS artifacts at ${EXPORT_PATH}"
