#!/usr/bin/env bash
# Generates android/key.properties from environment variables for release signing.
# Expected environment variables:
#   JFLUTTER_KEYSTORE_PASSWORD - The keystore password.
#   JFLUTTER_KEY_ALIAS         - The key alias inside the keystore.
#   JFLUTTER_KEY_PASSWORD      - The key password.
# Optional environment variables:
#   JFLUTTER_KEYSTORE_PATH     - Path to the keystore file, relative to android/ (default: keystores/jflutter-release.jks).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
KEY_PROPERTIES_FILE="${ANDROID_DIR}/key.properties"

if [[ -z "${JFLUTTER_KEYSTORE_PASSWORD:-}" ]]; then
  echo "Error: JFLUTTER_KEYSTORE_PASSWORD is not set." >&2
  exit 1
fi

if [[ -z "${JFLUTTER_KEY_ALIAS:-}" ]]; then
  echo "Error: JFLUTTER_KEY_ALIAS is not set." >&2
  exit 1
fi

if [[ -z "${JFLUTTER_KEY_PASSWORD:-}" ]]; then
  echo "Error: JFLUTTER_KEY_PASSWORD is not set." >&2
  exit 1
fi

STORE_FILE_PATH="${JFLUTTER_KEYSTORE_PATH:-keystores/jflutter-release.jks}"

cat >"${KEY_PROPERTIES_FILE}" <<EOF2
storeFile=${STORE_FILE_PATH}
storePassword=${JFLUTTER_KEYSTORE_PASSWORD}
keyAlias=${JFLUTTER_KEY_ALIAS}
keyPassword=${JFLUTTER_KEY_PASSWORD}
EOF2

# Lock down permissions to preserve signing credentials.
if ! chmod 600 "${KEY_PROPERTIES_FILE}" 2>/dev/null; then
  echo "Warning: Unable to restrict permissions on ${KEY_PROPERTIES_FILE}; ensure credentials remain protected on this platform." >&2
fi

echo "Created ${KEY_PROPERTIES_FILE}"
if [[ ${STORE_FILE_PATH} =~ ^/ || ${STORE_FILE_PATH} =~ ^[A-Za-z]:[\\/] ]]; then
  if [[ ! -f "${STORE_FILE_PATH}" ]]; then
    echo "Warning: Keystore file '${STORE_FILE_PATH}' does not exist at the specified absolute path." >&2
  fi
else
  if [[ ! -f "${ANDROID_DIR}/${STORE_FILE_PATH}" ]]; then
    echo "Warning: Keystore file '${STORE_FILE_PATH}' does not exist relative to android/." >&2
  fi
fi
