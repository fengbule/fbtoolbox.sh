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

echo "[1/11] bash -n"
bash -n "$SCRIPT_PATH"

echo "[2/11] help/version"
bash "$SCRIPT_PATH" help >/dev/null
bash "$SCRIPT_PATH" version >/dev/null

echo "[3/11] invalid command"
if bash "$SCRIPT_PATH" invalid-command >/dev/null 2>&1; then
  echo "expected invalid-command to fail" >&2
  exit 1
fi

echo "[4/11] install-self"
TMP_DIR="$(mktemp -d)"
PATH="${TMP_DIR}:$PATH" SELF_TARGET="${TMP_DIR}/toolbox" bash "$SCRIPT_PATH" install-self >/dev/null
[[ -x "${TMP_DIR}/toolbox" ]]

echo "[5/11] installed command management"
PATH="${TMP_DIR}:$PATH" toolbox help | grep -F "toolbox uninstall-self" >/dev/null
PATH="${TMP_DIR}:$PATH" toolbox version >/dev/null
printf '0\n' | TERM=dumb env PATH="${TMP_DIR}:$PATH" toolbox menu >/dev/null

echo "[6/11] update-self"
PATH="${TMP_DIR}:$PATH" \
SELF_TARGET="${TMP_DIR}/toolbox-remote" \
TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" \
toolbox update-self >/dev/null
[[ -x "${TMP_DIR}/toolbox-remote" ]]

echo "[7/11] uninstall installed command"
PATH="${TMP_DIR}:$PATH" SELF_TARGET="${TMP_DIR}/toolbox" toolbox uninstall-self >/dev/null
[[ ! -e "${TMP_DIR}/toolbox" ]]

echo "[8/11] uninstall updated command"
SELF_TARGET="${TMP_DIR}/toolbox-remote" "${TMP_DIR}/toolbox-remote" uninstall-self >/dev/null
[[ ! -e "${TMP_DIR}/toolbox-remote" ]]

echo "[9/11] main menu smoke"
printf '0\n' | TERM=dumb bash "$SCRIPT_PATH" menu >/dev/null

echo "[10/11] submenu smoke"
printf '1\n0\n0\n' | TERM=dumb bash "$SCRIPT_PATH" menu >/dev/null

echo "[11/11] cleanup"
cleanup
TMP_DIR=""

echo "Smoke tests passed."
