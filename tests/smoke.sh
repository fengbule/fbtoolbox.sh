#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/toolbox.sh"
CURRENT_VERSION="$(sed -n 's/^APP_VERSION="\(v[^"]*\)"/\1/p' "$SCRIPT_PATH" | head -n1)"
TMP_DIR=""

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}

trap cleanup EXIT

echo "[1/18] bash -n"
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

echo "[2/18] help/version/check-links list"
bash "$SCRIPT_PATH" help >/dev/null
bash "$SCRIPT_PATH" version >/dev/null
LINK_LIST="$(bash "$SCRIPT_PATH" check-links --list 2>"${TMP_DIR}/check-links-list.err")"
if [[ -s "${TMP_DIR}/check-links-list.err" ]]; then
  cat "${TMP_DIR}/check-links-list.err" >&2
  exit 1
fi
grep -F "https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh" <<< "$LINK_LIST" >/dev/null
grep -F "https://yabs.sh" <<< "$LINK_LIST" >/dev/null

echo "[3/18] invalid command"
if bash "$SCRIPT_PATH" invalid-command >/dev/null 2>&1; then
  echo "expected invalid-command to fail" >&2
  exit 1
fi

echo "[4/18] auto install from menu"
AUTO_BIN_DIR="${TMP_DIR}/auto-bin"
printf '0\n' | TERM=dumb env PATH="${AUTO_BIN_DIR}:$PATH" SELF_TARGET="${AUTO_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" menu >/dev/null
[[ -x "${AUTO_BIN_DIR}/toolbox" ]]
PATH="${AUTO_BIN_DIR}:$PATH" toolbox version >/dev/null

echo "[5/18] install-self"
INSTALL_BIN_DIR="${TMP_DIR}/manual-bin"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" bash "$SCRIPT_PATH" install-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[6/18] installed command management"
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox help | grep -F "toolbox uninstall-self" >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox version >/dev/null
PATH="${INSTALL_BIN_DIR}:$PATH" toolbox check-links --list >/dev/null 2>"${TMP_DIR}/installed-check-links-list.err"
if [[ -s "${TMP_DIR}/installed-check-links-list.err" ]]; then
  cat "${TMP_DIR}/installed-check-links-list.err" >&2
  exit 1
fi
printf '0\n' | TERM=dumb env PATH="${INSTALL_BIN_DIR}:$PATH" toolbox menu >/dev/null

echo "[7/18] update-self"
PATH="${INSTALL_BIN_DIR}:$PATH" \
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" \
TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" \
toolbox update-self >/dev/null
[[ -x "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[8/18] remote menu auto-updates stale install"
STALE_BIN_DIR="${TMP_DIR}/stale-bin"
mkdir -p "$STALE_BIN_DIR"
sed 's/^APP_VERSION="v[^"]*"/APP_VERSION="v0.0.1"/' "$SCRIPT_PATH" > "${STALE_BIN_DIR}/toolbox"
chmod +x "${STALE_BIN_DIR}/toolbox"
printf '0\n' | TERM=dumb env PATH="${STALE_BIN_DIR}:$PATH" TOOLBOX_SELF_SOURCE_URL="file://${SCRIPT_PATH}" bash <(cat "$SCRIPT_PATH") menu >/dev/null
grep -F "APP_VERSION=\"${CURRENT_VERSION}\"" "${STALE_BIN_DIR}/toolbox" >/dev/null
PATH="${STALE_BIN_DIR}:$PATH" toolbox version >/dev/null

echo "[9/18] uninstall installed command"
PATH="${INSTALL_BIN_DIR}:$PATH" SELF_TARGET="${INSTALL_BIN_DIR}/toolbox" toolbox uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox" ]]

echo "[10/18] uninstall updated command"
SELF_TARGET="${INSTALL_BIN_DIR}/toolbox-remote" "${INSTALL_BIN_DIR}/toolbox-remote" uninstall-self >/dev/null
[[ ! -e "${INSTALL_BIN_DIR}/toolbox-remote" ]]

echo "[11/18] main menu smoke"
printf '0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[12/18] first submenu smoke"
printf '1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null

echo "[13/18] all submenus smoke"
for menu_index in {1..10}; do
  printf '%s\n0\n0\n' "$menu_index" | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu >/dev/null
done

echo "[14/18] non-tty fb execute smoke"
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

echo "[15/18] port 25 command smoke"
PORT25_VIEW="$(printf '8\n8\n1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu)"
grep -F "smtp.office365.com" <<< "$PORT25_VIEW" >/dev/null
if grep -F "telnet smtp.aol.com" <<< "$PORT25_VIEW" >/dev/null; then
  echo "port 25 test should not depend on telnet smtp.aol.com anymore" >&2
  exit 1
fi

echo "[16/18] SKY-BOX command smoke"
SKYBOX_VIEW="$(printf '10\n2\n1\n0\n0\n' | TERM=dumb env TOOLBOX_AUTO_INSTALL=0 bash "$SCRIPT_PATH" menu)"
grep -F "./box.sh" <<< "$SKYBOX_VIEW" >/dev/null
if grep -F "&& clear &&" <<< "$SKYBOX_VIEW" >/dev/null; then
  echo "SKY-BOX command should not hard-fail on clear anymore" >&2
  exit 1
fi

echo "[17/18] git whitespace check"
git -C "$ROOT_DIR" diff --check

echo "[18/18] cleanup"
cleanup
TMP_DIR=""

echo "Smoke tests passed."
