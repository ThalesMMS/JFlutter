#!/usr/bin/env bash

discover_flutter_bin() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    if [[ -x "${FLUTTER_BIN}" ]] && "${FLUTTER_BIN}" --version >/dev/null 2>&1; then
      return 0
    fi

    echo "Warning: Ignoring FLUTTER_BIN='${FLUTTER_BIN}' because it is not executable or did not respond to '--version'." >&2
    unset FLUTTER_BIN
  fi

  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
    if "${FLUTTER_BIN}" --version >/dev/null 2>&1; then
      return 0
    fi
    unset FLUTTER_BIN
  fi

  if [[ -x "/opt/homebrew/bin/flutter" ]]; then
    FLUTTER_BIN="/opt/homebrew/bin/flutter"
    if "${FLUTTER_BIN}" --version >/dev/null 2>&1; then
      return 0
    fi
    unset FLUTTER_BIN
  fi

  if [[ -x "/usr/local/bin/flutter" ]]; then
    FLUTTER_BIN="/usr/local/bin/flutter"
    if "${FLUTTER_BIN}" --version >/dev/null 2>&1; then
      return 0
    fi
    unset FLUTTER_BIN
  fi

  echo "Error: Flutter was not found on PATH or in the known default locations." >&2
  echo "Set FLUTTER_BIN to your local Flutter binary before running this script." >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: Required command '$1' was not found in PATH." >&2
    exit 1
  fi
}

version_gte() {
  local actual="$1"
  local minimum="$2"
  local IFS=.
  local i max_len=0
  local -a actual_parts minimum_parts

  read -r -a actual_parts <<<"${actual}"
  read -r -a minimum_parts <<<"${minimum}"

  if (( ${#actual_parts[@]} > max_len )); then
    max_len=${#actual_parts[@]}
  fi
  if (( ${#minimum_parts[@]} > max_len )); then
    max_len=${#minimum_parts[@]}
  fi

  for ((i = 0; i < max_len; i++)); do
    local actual_segment="${actual_parts[i]:-0}"
    local minimum_segment="${minimum_parts[i]:-0}"
    local sanitized_actual=0
    local sanitized_minimum=0

    if [[ "${actual_segment}" =~ ^([0-9]+) ]]; then
      sanitized_actual="${BASH_REMATCH[1]}"
    fi

    if [[ "${minimum_segment}" =~ ^([0-9]+) ]]; then
      sanitized_minimum="${BASH_REMATCH[1]}"
    fi

    if (( 10#${sanitized_actual} > 10#${sanitized_minimum} )); then
      return 0
    fi
    if (( 10#${sanitized_actual} < 10#${sanitized_minimum} )); then
      return 1
    fi
  done

  return 0
}

canonicalize_target_path() {
  local path="$1"
  local current_path="$1"
  local suffix=""

  while [[ ! -d "${current_path}" ]]; do
    local current_name
    current_name="$(basename "${current_path}")"
    suffix="/${current_name}${suffix}"

    local next_path
    next_path="$(dirname "${current_path}")"
    if [[ "${next_path}" == "${current_path}" ]]; then
      echo "Error: Could not resolve an existing parent directory for '${path}'." >&2
      exit 1
    fi
    current_path="${next_path}"
  done

  current_path="$(cd "${current_path}" && pwd -P)"
  printf '%s%s\n' "${current_path}" "${suffix}"
}

validate_managed_path() {
  local name="$1"
  local path="$2"
  local allowed_root="$3"
  local required_suffix="${4:-}"
  local canonical_path

  if [[ -z "${path}" || "${path}" != /* || "${path}" == "/" || "${path}" == "." ]]; then
    echo "Error: Refusing to use unsafe ${name} path '${path}'." >&2
    exit 1
  fi

  canonical_path="$(canonicalize_target_path "${path}")"

  if [[ "${canonical_path}" != "${allowed_root}" && "${canonical_path}" != "${allowed_root}/"* ]]; then
    echo "Error: Refusing to use ${name} path '${canonical_path}'. Expected it under '${allowed_root}'." >&2
    exit 1
  fi

  if [[ -n "${required_suffix}" && "${canonical_path}" != *"${required_suffix}" ]]; then
    echo "Error: Refusing to use ${name} path '${canonical_path}'. Expected suffix '${required_suffix}'." >&2
    exit 1
  fi

  printf '%s\n' "${canonical_path}"
}

# Accepts an optional build settings string; falls back to the global BUILD_SETTINGS.
resolve_build_setting() {
  local key="$1"
  local build_settings="${2:-${BUILD_SETTINGS:-}}"
  local target_name="${3:-${SCHEME_NAME:-Runner}}"
  awk -F ' = ' -v key="${key}" -v target="${target_name}" '
    /^Build settings for action .* target / {
      current_target = $0
      sub(/^Build settings for action .* target /, "", current_target)
      sub(/:$/, "", current_target)

      if (current_target == target) {
        in_target = 1
        next
      }

      if (in_target) {
        exit
      }
    }
    in_target && $1 ~ "^[[:space:]]*" key "$" {
      print $2
      exit
    }
  ' <<<"${build_settings}"
}

require_nonempty_setting() {
  local key="$1"
  local value="$2"
  if [[ -z "${value}" || "${value}" == *'$('* ]]; then
    echo "Error: Required macOS build setting '${key}' is not configured for ${CONFIGURATION_NAME}." >&2
    exit 1
  fi
}

validate_release_configuration() {
  echo "==> Validating macOS release signing and version configuration"
  local build_settings_output
  if ! build_settings_output="$(xcodebuild \
    -workspace "${WORKSPACE_PATH}" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION_NAME}" \
    -showBuildSettings 2>&1)"; then
    echo "Error: Failed to resolve macOS build settings with xcodebuild." >&2
    echo "${build_settings_output}" >&2
    exit 1
  fi
  BUILD_SETTINGS="${build_settings_output}"

  MARKETING_VERSION="$(resolve_build_setting MARKETING_VERSION "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"
  CURRENT_PROJECT_VERSION="$(resolve_build_setting CURRENT_PROJECT_VERSION "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"
  CODE_SIGN_STYLE="$(resolve_build_setting CODE_SIGN_STYLE "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"
  DEVELOPMENT_TEAM="$(resolve_build_setting DEVELOPMENT_TEAM "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"
  PRODUCT_BUNDLE_IDENTIFIER="$(resolve_build_setting PRODUCT_BUNDLE_IDENTIFIER "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"
  PRODUCT_NAME="$(resolve_build_setting PRODUCT_NAME "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"
  CODE_SIGN_ENTITLEMENTS="$(resolve_build_setting CODE_SIGN_ENTITLEMENTS "${BUILD_SETTINGS}" "${TARGET_NAME:-Runner}")"

  require_nonempty_setting MARKETING_VERSION "${MARKETING_VERSION}"
  require_nonempty_setting CURRENT_PROJECT_VERSION "${CURRENT_PROJECT_VERSION}"
  require_nonempty_setting DEVELOPMENT_TEAM "${DEVELOPMENT_TEAM}"
  require_nonempty_setting PRODUCT_BUNDLE_IDENTIFIER "${PRODUCT_BUNDLE_IDENTIFIER}"
  require_nonempty_setting PRODUCT_NAME "${PRODUCT_NAME}"
  require_nonempty_setting CODE_SIGN_ENTITLEMENTS "${CODE_SIGN_ENTITLEMENTS}"

  PUBSPEC_RAW_VERSION="$(awk '/^version:/ { print $2; exit }' "${REPO_ROOT}/pubspec.yaml")"
  PUBSPEC_VERSION="${PUBSPEC_RAW_VERSION%%+*}"
  if [[ "${PUBSPEC_RAW_VERSION}" == *"+"* ]]; then
    PUBSPEC_BUILD="${PUBSPEC_RAW_VERSION#*+}"
  else
    PUBSPEC_BUILD=""
  fi

  if [[ -z "${PUBSPEC_VERSION}" || -z "${PUBSPEC_BUILD}" ]]; then
    echo "Error: Could not parse version/build from ${REPO_ROOT}/pubspec.yaml." >&2
    exit 1
  fi

  if [[ "${MARKETING_VERSION}" != "${PUBSPEC_VERSION}" || "${CURRENT_PROJECT_VERSION}" != "${PUBSPEC_BUILD}" ]]; then
    echo "Error: macOS release version mismatch. pubspec.yaml has '${PUBSPEC_VERSION}+${PUBSPEC_BUILD}', but macOS build settings resolve to '${MARKETING_VERSION}+${CURRENT_PROJECT_VERSION}'." >&2
    exit 1
  fi

  if [[ "${CODE_SIGN_STYLE}" != "Automatic" ]]; then
    echo "Error: Expected CODE_SIGN_STYLE=Automatic for macOS Release, found '${CODE_SIGN_STYLE:-<unset>}'." >&2
    exit 1
  fi

  local canonical_macos_dir
  local entitlements_candidate_path
  local entitlements_path

  canonical_macos_dir="$(cd "${MACOS_DIR}" && pwd -P)"

  if [[ "${CODE_SIGN_ENTITLEMENTS}" == /* ]]; then
    echo "Error: macOS entitlements '${CODE_SIGN_ENTITLEMENTS}' must be inside '${MACOS_DIR}' — path outside of macOS dir detected." >&2
    exit 1
  fi

  if [[ "${CODE_SIGN_ENTITLEMENTS}" == ".." || "${CODE_SIGN_ENTITLEMENTS}" == ../* || "${CODE_SIGN_ENTITLEMENTS}" == */../* || "${CODE_SIGN_ENTITLEMENTS}" == */.. ]]; then
    echo "Error: macOS entitlements '${CODE_SIGN_ENTITLEMENTS}' must be inside '${MACOS_DIR}' — path outside of macOS dir detected." >&2
    exit 1
  fi

  entitlements_candidate_path="${MACOS_DIR}/${CODE_SIGN_ENTITLEMENTS}"
  entitlements_path="$(canonicalize_target_path "${entitlements_candidate_path}")"

  if [[ "${entitlements_path}" != "${canonical_macos_dir}" && "${entitlements_path}" != "${canonical_macos_dir}/"* ]]; then
    echo "Error: macOS entitlements '${CODE_SIGN_ENTITLEMENTS}' must be inside '${MACOS_DIR}' — path outside of macOS dir detected." >&2
    exit 1
  fi

  if [[ -L "${entitlements_candidate_path}" || ! -f "${entitlements_path}" ]]; then
    echo "Error: macOS entitlements file '${MACOS_DIR}/${CODE_SIGN_ENTITLEMENTS}' does not exist." >&2
    exit 1
  fi

  echo "Release bundle id: ${PRODUCT_BUNDLE_IDENTIFIER}"
  echo "Release version: ${MARKETING_VERSION} (${CURRENT_PROJECT_VERSION})"
  echo "Release entitlements: ${CODE_SIGN_ENTITLEMENTS}"
}
