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

echo "[1/15] bash -n"
bash -n "$SCRIPT_PATH"

TMP_DIR="$(mktemp -d)"

echo "[2/15] help/version/check-links list"
bash "$SCRIPT_PATH" help >/dev/null
bash "$SCRIPT_PATH" version >/dev/null
LINK_LIST="$(bash "$SCRIPT_PATH" check-links --list 2>"${TMP_DIR}/check-links-list.err")"
if [[ -s "${TMP_DIR}/check-links-list.err" ]]; then
  cat "${TMP_DIR}/check-links-list.err" >&2
  exit 1
fi
grep -F "https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh" <<< "$LINK_LIST" >/dev/null
grep -F "https://yabs.sh" <<< "$LINK_LIST" >/dev/null

echo "[3/15] invalid command"
if bash "$SCRIPT_PATH" invalid-command >/dev/null 2>&1; then
  echo "expected invalid-command to fail" >&2
  exit 1
fi

echo "[4/15] auto install from menu"
AUTO_BIN_DIR="${TMP_DIR}/auto-bin"
printf '0\n' | TERM=dumb env PATH="${AUTO_BIN_DIR}:$PATH" SELF_TARGET="${AUTO_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" menu >/dev/null
[[ -x "${AUTO_BIN_DIR}/toolbox" ]]
PATH="${AUTO_BIN_DIR}:$PATH" toolbox version >/dev/null

echo "[5/15] install-self"
INSTALL_BIN_DIR="${TMP_DIR}/manual-bin"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" install-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[6/15] installed command management"
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox help | grep -F "toolbox uninstall-self" >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox version >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox check-links --list >/dev/null 2>"${TMP_DIR}/installed-check-links-list.err"
if [[ -s "${TMP_DIR}/installed-check-links-list.err" ]]; then
  cat "${TMP_DIR}/installed-check-links-list.err" >&2
  exit 1
fi
printf '0\n' | TERM=dumb env PATH="${INSTALL_BIN_DIR}:$PATH" toolbox menu >/dev/null

echo "[7/15] update-self"
PATH="${INSTALL_BIN_DIR}:$PATH" \
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" \
TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" \
toolbox update-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[8/15] uninstall installed command"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" toolbox uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[9/15] uninstall updated command"
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" "${INSTALL_BIN_DIR}/toolbox-remote" uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[10/15] main menu smoke"
printf '0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[11/15] first submenu smoke"
printf '1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[12/15] all submenus smoke"
for menu_index in {1..10}; do
  printf '%s\n0\n0\n' "$menu_index" | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null
done

echo "[13/15] port 25 command smoke"
PORT25_VIEW="$(printf '8\n8\n1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu)"
grep -F "smtp.office365.com" <<< "$PORT25_VIEW" >/dev/null
if grep -F "telnet smtp.aol.com" <<< "$PORT25_VIEW" >/dev/null; then
  echo "port 25 test should not depend on telnet smtp.aol.com anymore" >&2
  exit 1
fi

echo "[14/15] git whitespace check"
git -C "$ROOT_DIR" diff --check

echo "[15/15] cleanup"
cleanup
TMP_DIR=""

echo "Smoke tests passed."
