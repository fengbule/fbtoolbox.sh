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

echo "[1/12] bash -n"
bash -n "$SCRIPT_PATH"

echo "[2/12] help/version"
bash "$SCRIPT_PATH" help >/dev/null
bash "$SCRIPT_PATH" version >/dev/null

echo "[3/12] invalid command"
if bash "$SCRIPT_PATH" invalid-command >/dev/null 2>&1; then
  echo "expected invalid-command to fail" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
echo "[4/12] auto install from menu"
AUTO_BIN_DIR="${TMP_DIR}/auto-bin"
printf '0\n' | TERM=dumb env PATH="${AUTO_BIN_DIR}:$PATH" SELF_TARGET="${AUTO_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" menu >/dev/null
[[ -x "${AUTO_BIN_DIR}/toolbox" ]]
PATH="${AUTO_BIN_DIR}:$PATH" toolbox version >/dev/null

echo "[5/12] install-self"
INSTALL_BIN_DIR="${TMP_DIR}/manual-bin"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" install-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[6/12] installed command management"
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox help | grep -F "toolbox uninstall-self" >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox version >/dev/null
printf '0\n' | TERM=dumb env PATH="${INSTALL_BIN_DIR}:$PATH" toolbox menu >/dev/null

echo "[7/12] update-self"
PATH="${INSTALL_BIN_DIR}:$PATH" \
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" \
TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" \
toolbox update-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[8/12] uninstall installed command"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" toolbox uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[9/12] uninstall updated command"
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" "${INSTALL_BIN_DIR}/toolbox-remote" uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[10/12] main menu smoke"
printf '0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[11/12] submenu smoke"
printf '1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[12/12] cleanup"
cleanup
TMP_DIR=""

echo "Smoke tests passed."
