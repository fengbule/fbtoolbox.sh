#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/toolbox.sh"
TMP_DIR=""

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}

trap cleanup EXIT

echo "[1/8] bash -n"
bash -n "$SCRIPT_PATH"

echo "[2/8] help/version"
bash "$SCRIPT_PATH" help >/dev/null
bash "$SCRIPT_PATH" version >/dev/null

echo "[3/8] invalid command"
if bash "$SCRIPT_PATH" invalid-command >/dev/null 2>&1; then
  echo "expected invalid-command to fail" >&2
  exit 1
fi

echo "[4/8] install-self"
TMP_DIR="$(mktemp -d)"
SELF_TARGET="${TMP_DIR}/toolbox" bash "$SCRIPT_PATH" install-self >/dev/null
[[ -x "${TMP_DIR}/toolbox" ]]

echo "[5/8] update-self"
SELF_TARGET="${TMP_DIR}/toolbox-remote" \
TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" \
bash "$SCRIPT_PATH" update-self >/dev/null
[[ -x "${TMP_DIR}/toolbox-remote" ]]

echo "[6/8] main menu smoke"
printf '0\n' | TERM=dumb bash "$SCRIPT_PATH" menu >/dev/null

echo "[7/8] submenu smoke"
printf '1\n0\n0\n' | TERM=dumb bash "$SCRIPT_PATH" menu >/dev/null

echo "[8/8] cleanup"
cleanup
TMP_DIR=""

echo "Smoke tests passed."
