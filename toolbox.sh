#!/bin/bash
set -Ee
set -u
set -o pipefail

APP_NAME="VPS 工具箱"
APP_VERSION="v1.0.0"
APP_REPO="https://github.com/fengbule/fbtoolbox.sh"
SELF_SOURCE_URL="${TOOLBOX_SELF_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/fbtoolbox.sh/main/toolbox.sh}"
SELF_TARGET="${SELF_TARGET:-/usr/local/bin/toolbox}"

C0='\033[0m'
C1='\033[0;32m'
C2='\033[1;33m'
C3='\033[0;31m'
C4='\033[0;36m'
CW='\033[1;37m'
DIM='\033[2m'

log()  { echo -e "${C1}[INFO]${C0} $*"; }
warn() { echo -e "${C2}[WARN]${C0} $*" >&2; }
err()  { echo -e "${C3}[ERR ]${C0} $*" >&2; }
die()  { err "$*"; exit 1; }

pause_enter() {
  read -r -p "按回车继续..."
}

run_cmd() {
  local cmd="$1"
  echo
  echo -e "${C4}即将执行：${C0}"
  echo -e "${CW}${cmd}${C0}"
  echo
  read -r -p "确认执行？[Y/n]: " yn
  yn="${yn:-Y}"
  [[ "$yn" =~ ^[Yy]$ ]] || return 0
  bash -c "$cmd"
}

install_self() {
  local src
  src="$(readlink -f "$0" 2>/dev/null || echo "$0")"
  install -m 0755 "$src" "$SELF_TARGET"
  log "已安装到 $SELF_TARGET"
  log "以后直接输入 toolbox 即可"
}

install_self_remote() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SELF_SOURCE_URL" -o "$SELF_TARGET"
    chmod 0755 "$SELF_TARGET"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$SELF_TARGET" "$SELF_SOURCE_URL"
    chmod 0755 "$SELF_TARGET"
  else
    die "缺少 curl/wget，无法安装 toolbox"
  fi
  log "已安装到 $SELF_TARGET"
  log "以后直接输入 toolbox 即可"
}

show_header() {
  clear || true
  echo -e "${CW}============================================================${C0}"
  echo -e "${CW}                    ${APP_NAME} ${C4}${APP_VERSION}${C0}"
  echo -e "${CW}============================================================${C0}"
  echo -e "${DIM}仓库: ${APP_REPO}${C0}"
  echo
}

menu_fb() {
  while true; do
    show_header
    echo "1) 一键运行远程版 fb"
    echo "2) 安装 fb 命令"
    echo "3) 进入 fb 菜单"
    echo "4) 查看 fb 帮助"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) run_cmd "bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh)" ;;
      2) run_cmd "bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh) install-self" ;;
      3) run_cmd "fb menu" ;;
      4) run_cmd "fb help" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_main() {
  while true; do
    show_header
    echo "1) fb 端口转发"
    echo "2) 一键运行 yabs"
    echo "3) 一键运行 LemonBench"
    echo "4) 安装 toolbox 命令"
    echo "0) 退出"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) menu_fb ;;
      2) run_cmd "curl -sL yabs.sh | bash"; pause_enter ;;
      3) run_cmd "wget -qO- https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast"; pause_enter ;;
      4) install_self; pause_enter ;;
      0) exit 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

main() {
  local cmd="${1:-menu}"
  case "$cmd" in
    install-self)
      install_self
      ;;
    install-self-remote)
      install_self_remote
      ;;
    menu|"")
      menu_main
      ;;
    help|-h|--help)
      echo "用法:"
      echo "  bash toolbox.sh"
      echo "  bash toolbox.sh install-self"
      echo "  bash toolbox.sh install-self-remote"
      ;;
    *)
      echo "未知命令: $cmd"
      exit 1
      ;;
  esac
}

main "$@"
