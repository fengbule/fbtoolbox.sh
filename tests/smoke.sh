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

echo "[1/16] bash -n"
bash -n "$SCRIPT_PATH"

TMP_DIR="$(mktemp -d)"
FAKE_FB_SCRIPT="${TMP_DIR}/fake-fb.sh"

cat > "$FAKE_FB_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -t 0 ]]; then
  printf 'fake-fb tty-ok (stdin)\n'
elif [[ -r /dev/tty && -w /dev/tty ]]; then
  printf 'fake-fb tty-ok (/dev/tty)\n'
else
  echo "fake-fb requires a tty" >&2
  exit 1
fi
EOF

echo "[2/16] help/version/check-links list"
bash "$SCRIPT_PATH" help >/dev/null
bash "$SCRIPT_PATH" version >/dev/null
LINK_LIST="$(bash "$SCRIPT_PATH" check-links --list 2>"${TMP_DIR}/check-links-list.err")"
if [[ -s "${TMP_DIR}/check-links-list.err" ]]; then
  cat "${TMP_DIR}/check-links-list.err" >&2
  exit 1
fi
grep -F "https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh" <<< "$LINK_LIST" >/dev/null
grep -F "https://yabs.sh" <<< "$LINK_LIST" >/dev/null

echo "[3/16] invalid command"
if bash "$SCRIPT_PATH" invalid-command >/dev/null 2>&1; then
  echo "expected invalid-command to fail" >&2
  exit 1
fi

echo "[4/16] auto install from menu"
AUTO_BIN_DIR="${TMP_DIR}/auto-bin"
printf '0\n' | TERM=dumb env PATH="${AUTO_BIN_DIR}:$PATH" SELF_TARGET="${AUTO_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" menu >/dev/null
[[ -x "${AUTO_BIN_DIR}/toolbox" ]]
PATH="${AUTO_BIN_DIR}:$PATH" toolbox version >/dev/null

echo "[5/16] install-self"
INSTALL_BIN_DIR="${TMP_DIR}/manual-bin"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" install-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[6/16] installed command management"
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox help | grep -F "toolbox uninstall-self" >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox version >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox check-links --list >/dev/null 2>"${TMP_DIR}/installed-check-links-list.err"
if [[ -s "${TMP_DIR}/installed-check-links-list.err" ]]; then
  cat "${TMP_DIR}/installed-check-links-list.err" >&2
  exit 1
fi
printf '0\n' | TERM=dumb env PATH="${INSTALL_BIN_DIR}:$PATH" toolbox menu >/dev/null

echo "[7/16] update-self"
PATH="${INSTALL_BIN_DIR}:$PATH" \
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" \
TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" \
toolbox update-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[8/16] uninstall installed command"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" toolbox uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[9/16] uninstall updated command"
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" "${INSTALL_BIN_DIR}/toolbox-remote" uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[10/16] main menu smoke"
printf '0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[11/16] first submenu smoke"
printf '1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[12/16] all submenus smoke"
for menu_index in {1..10}; do
  printf '%s\n0\n0\n' "$menu_index" | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null
done

echo "[13/16] non-tty fb execute smoke"
if command -v script >/dev/null 2>&1; then
  FB_NONTTY_VIEW="$(printf '1\n1\n2\n\nY\n0\n0\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 FB_SOURCE_URL="file://${FAKE_FB_SCRIPT}" bash "$SCRIPT_PATH" menu 2>"${TMP_DIR}/fb-nontty.err" || true)"
  grep -F "fake-fb tty-ok" <<< "$FB_NONTTY_VIEW" >/dev/null
  if [[ -s "${TMP_DIR}/fb-nontty.err" ]]; then
    cat "${TMP_DIR}/fb-nontty.err" >&2
    exit 1
  fi
else
  echo "script unavailable, skipping pseudo-tty smoke"
fi

echo "[14/17] port 25 command smoke"
PORT25_VIEW="$(printf '8\n8\n1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu)"
grep -F "smtp.office365.com" <<< "$PORT25_VIEW" >/dev/null
if grep -F "telnet smtp.aol.com" <<< "$PORT25_VIEW" >/dev/null; then
  echo "port 25 test should not depend on telnet smtp.aol.com anymore" >&2
  exit 1
fi

echo "[15/17] SKY-BOX command smoke"
SKYBOX_VIEW="$(printf '10\n2\n1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu)"
grep -F "./box.sh" <<< "$SKYBOX_VIEW" >/dev/null
if grep -F "&& clear &&" <<< "$SKYBOX_VIEW" >/dev/null; then
  echo "SKY-BOX command should not hard-fail on clear anymore" >&2
  exit 1
fi

echo "[16/17] git whitespace check"
git -C "$ROOT_DIR" diff --check

echo "[17/17] cleanup"
cleanup
TMP_DIR=""

echo "Smoke tests passed."
