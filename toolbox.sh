#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="VPS 工具箱"
APP_VERSION="v2.3.1"
APP_REPO="https://github.com/fengbule/fbtoolbox"
SELF_SOURCE_URL="${TOOLBOX_SELF_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/fbtoolbox/main/toolbox.sh}"
SELF_TARGET="${SELF_TARGET:-}"
FB_SOURCE_URL="${FB_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh}"
TOOLBOX_AUTO_INSTALL="${TOOLBOX_AUTO_INSTALL:-1}"
ITEM_SEP=$'\t'
PORT25_TEST_CMD='hosts=(smtp.aol.com smtp.gmail.com smtp.office365.com); for host in "${hosts[@]}"; do echo "测试 ${host}:25 ..."; if timeout 8 bash -c ":</dev/tcp/${host}/25" 2>/dev/null; then echo "可连通: ${host}:25"; exit 0; fi; echo "不可达: ${host}:25"; done; echo "所有测试目标都无法连通。常见原因是机房封禁出站 25 端口、防火墙限制或本地路由不可达。"; exit 1'
PATH_BLOCK_BEGIN="# >>> toolbox path >>>"
PATH_BLOCK_END="# <<< toolbox path <<<"

if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
  C0='\033[0m'
  C1='\033[0;32m'
  C2='\033[1;33m'
  C3='\033[0;31m'
  C4='\033[0;36m'
  C5='\033[1;35m'
  CW='\033[1;37m'
  DIM='\033[2m'
else
  C0=''
  C1=''
  C2=''
  C3=''
  C4=''
  C5=''
  CW=''
  DIM=''
fi

log()  { echo -e "${C1}[INFO]${C0} $*"; }
warn() { echo -e "${C2}[WARN]${C0} $*" >&2; }
err()  { echo -e "${C3}[ERR ]${C0} $*" >&2; }
die()  { err "$*"; exit 1; }

pause_enter() {
  if [[ ! -t 0 ]]; then
    return 0
  fi
  echo
  read -r -p "按回车继续..." _
}

clear_screen() {
  if [[ -t 0 && -t 1 ]] && command -v clear >/dev/null 2>&1; then
    clear || true
  fi
}

show_header() {
  clear_screen
  echo -e "${CW}============================================================${C0}"
  echo -e "${CW}                     ${APP_NAME} ${C4}${APP_VERSION}${C0}"
  echo -e "${CW}============================================================${C0}"
  echo -e "${DIM}仓库: ${APP_REPO}${C0}"
  echo -e "${DIM}远程运行: bash <(curl -fsSL ${SELF_SOURCE_URL})${C0}"
  echo
}

show_submenu_title() {
  echo -e "${C5}=== $1 ===${C0}"
  echo
}

show_command() {
  local title="$1" cmd="$2" note="${3:-}"
  show_header
  show_submenu_title "$title"
  echo -e "${CW}${cmd}${C0}"
  if [[ -n "$note" ]]; then
    echo
    echo -e "${DIM}${note}${C0}"
  fi
  pause_enter
}

prepare_command() {
  local default_cmd="$1" note="${2:-}" input=""
  show_header
  show_submenu_title "准备执行命令"
  echo -e "${CW}${default_cmd}${C0}"
  if [[ -n "$note" ]]; then
    echo
    echo -e "${DIM}${note}${C0}"
  fi
  echo
  read -r -p "回车直接执行，或输入修改后的完整命令；输入 n 取消: " input
  case "$input" in
    [Nn])
      return 1
      ;;
    "")
      RUN_CMD="$default_cmd"
      ;;
    *)
      RUN_CMD="$input"
      ;;
  esac
  return 0
}

run_command_in_pseudo_tty() {
  local cmd="$1" wrapper="" status=0
  wrapper="$(mktemp)"
  printf '#!/usr/bin/env bash\nexec bash -lc %q\n' "$cmd" > "$wrapper"
  chmod 700 "$wrapper"

  if script -qec "$wrapper" /dev/null; then
    status=0
  else
    status=$?
  fi

  rm -f "$wrapper"
  return $status
}

run_prepared_command() {
  local cmd="$1"
  if [[ ! -t 0 ]] && command -v script >/dev/null 2>&1; then
    run_command_in_pseudo_tty "$cmd"
    return $?
  fi
  bash -lc "$cmd"
}

execute_command() {
  local title="$1" default_cmd="$2" mode="${3:-normal}" note="${4:-}" yn="" status=0
  RUN_CMD=""
  prepare_command "$default_cmd" "$note" || return 0
  show_header
  show_submenu_title "$title"
  echo -e "${CW}${RUN_CMD}${C0}"
  echo
  if [[ "$mode" == "danger" ]]; then
    echo -e "${C3}危险操作提示: 该命令可能导致重装系统、覆盖网络配置、修改内核或中断连接。${C0}"
    echo
    read -r -p "确认继续请输入 YES: " yn
    [[ "$yn" == "YES" ]] || return 0
  else
    read -r -p "确认执行? [Y/n]: " yn
    yn="${yn:-Y}"
    [[ "$yn" =~ ^[Yy]$ ]] || return 0
  fi
  echo
  if run_prepared_command "$RUN_CMD"; then
    log "命令执行完成。"
  else
    status=$?
    warn "命令执行失败，退出码: $status"
  fi
  pause_enter
}

handle_command_item() {
  local title="$1" cmd="$2" mode="${3:-normal}" note="${4:-}" act=""
  while true; do
    show_header
    show_submenu_title "$title"
    echo "1) 查看命令"
    echo "2) 执行命令"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " act
    act="${act:-1}"
    case "$act" in
      1)
        show_command "$title" "$cmd" "$note"
        return 0
        ;;
      2)
        execute_command "$title" "$cmd" "$mode" "$note"
        return 0
        ;;
      0)
        return 0
        ;;
      *)
        warn "无效选择"
        pause_enter
        ;;
    esac
  done
}

handle_info_item() {
  local title="$1" body="$2"
  show_header
  show_submenu_title "$title"
  printf '%s\n' "$body"
  pause_enter
}

print_version() {
  printf '%s\n' "${APP_NAME} ${APP_VERSION}"
}

path_has_dir() {
  local dir="$1"
  [[ ":$PATH:" == *":${dir}:"* ]]
}

is_debian_or_ubuntu() {
  local os_release="/etc/os-release"
  local id="" id_like=""

  [[ -r "$os_release" ]] || return 1
  # shellcheck disable=SC1090
  . "$os_release"
  id=" ${ID:-} "
  id_like=" ${ID_LIKE:-} "
  [[ "$id" == *" debian "* || "$id" == *" ubuntu "* || "$id_like" == *" debian "* || "$id_like" == *" ubuntu "* ]]
}

resolve_existing_toolbox_command() {
  local existing=""
  existing="$(command -v toolbox 2>/dev/null || true)"
  [[ -n "$existing" && -f "$existing" ]] || return 1
  is_installed_toolbox "$existing" || return 1
  printf '%s\n' "$existing"
}

dedupe_targets() {
  local item
  local -A seen=()
  local unique=()
  for item in "$@"; do
    [[ -n "$item" ]] || continue
    if [[ -z "${seen[$item]+x}" ]]; then
      unique+=("$item")
      seen["$item"]=1
    fi
  done
  printf '%s\n' "${unique[@]}"
}

build_install_target_candidates() {
  local existing=""
  local candidates=()

  if [[ -n "$SELF_TARGET" ]]; then
    printf '%s\n' "$SELF_TARGET"
    return 0
  fi

  existing="$(resolve_existing_toolbox_command || true)"
  candidates+=("$existing")
  candidates+=("/usr/local/bin/toolbox")

  if [[ -n "${HOME:-}" ]]; then
    if is_debian_or_ubuntu; then
      candidates+=("${HOME}/.local/bin/toolbox")
      candidates+=("${HOME}/bin/toolbox")
    else
      candidates+=("${HOME}/bin/toolbox")
      candidates+=("${HOME}/.local/bin/toolbox")
    fi
  fi

  dedupe_targets "${candidates[@]}"
}

run_target_command() {
  local target="$1"
  shift

  if "$@" 2>/dev/null; then
    return 0
  fi

  if [[ "$target" == /usr/local/bin/* || "$target" == /usr/bin/* || "$target" == /opt/* ]]; then
    command -v sudo >/dev/null 2>&1 || return 1
    sudo "$@"
    return $?
  fi

  return 1
}

ensure_target_parent_dir() {
  local target="$1"
  local target_dir
  target_dir="$(dirname "$target")"
  run_target_command "$target" mkdir -p "$target_dir"
}

install_file() {
  local source_path="$1" target_path="$2"

  ensure_target_parent_dir "$target_path" || return 1

  if command -v install >/dev/null 2>&1; then
    run_target_command "$target_path" install -m 0755 "$source_path" "$target_path"
    return 0
  fi

  run_target_command "$target_path" cp "$source_path" "$target_path" || return 1
  run_target_command "$target_path" chmod 0755 "$target_path"
}

remove_managed_path_blocks() {
  local file tmp

  [[ -n "${HOME:-}" ]] || return 0

  for file in "${HOME}/.profile" "${HOME}/.bashrc"; do
    [[ -f "$file" ]] || continue
    tmp="$(mktemp)"
    awk -v begin="$PATH_BLOCK_BEGIN" -v end="$PATH_BLOCK_END" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
  done
}

ensure_managed_path_blocks() {
  local target_dir="$1"
  local file

  [[ -n "${HOME:-}" ]] || return 0
  case "$target_dir" in
    "${HOME}/.local/bin"| "${HOME}/bin")
      ;;
    *)
      return 0
      ;;
  esac

  remove_managed_path_blocks

  for file in "${HOME}/.profile" "${HOME}/.bashrc"; do
    mkdir -p "$(dirname "$file")"
    touch "$file"
    {
      printf '\n%s\n' "$PATH_BLOCK_BEGIN"
      printf 'export PATH="%s:$PATH"\n' "$target_dir"
      printf '%s\n' "$PATH_BLOCK_END"
    } >> "$file"
  done
}

show_post_install_hint() {
  local target_dir="$1"

  log "已安装到 $SELF_TARGET"
  if path_has_dir "$target_dir"; then
    log "以后直接输入 toolbox 即可"
    if [[ -t 0 ]]; then
      echo -e "${DIM}如果当前 shell 仍提示找不到 toolbox，可执行 hash -r 后重试。${C0}"
    fi
    return 0
  fi

  case "$target_dir" in
    "${HOME}/.local/bin"| "${HOME}/bin")
      warn "${target_dir} 已写入 Debian / Ubuntu 常用 shell 配置。"
      warn "执行 source ~/.profile 或重新登录后，即可直接使用 toolbox。"
      ;;
    *)
      warn "${target_dir} 当前不在 PATH 中。"
      warn "可直接运行: $SELF_TARGET"
      ;;
  esac
}

show_temporary_run_hint() {
  local target_dir=""

  if [[ -n "$SELF_TARGET" && -f "$SELF_TARGET" ]] && is_installed_toolbox "$SELF_TARGET"; then
    target_dir="$(dirname "$SELF_TARGET")"
    if path_has_dir "$target_dir"; then
      return 0
    fi
    case "$target_dir" in
      "${HOME}/.local/bin"| "${HOME}/bin")
        echo -e "${DIM}提示: toolbox 已安装到 ${target_dir}，执行 source ~/.profile 或重新登录后即可直接使用。${C0}"
        ;;
      *)
        echo -e "${DIM}提示: toolbox 已安装到 ${SELF_TARGET}。${C0}"
        ;;
    esac
    return 0
  fi

  if resolve_existing_toolbox_command >/dev/null 2>&1; then
    return 0
  fi

  echo -e "${DIM}提示: 当前是临时运行模式；脚本会先自动安装 / 修复 toolbox 命令，再进入菜单。${C0}"
}

install_to_best_target() {
  local source_path="$1"
  local candidate target_dir
  local attempted=()

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    attempted+=("$candidate")
    if install_file "$source_path" "$candidate"; then
      SELF_TARGET="$candidate"
      target_dir="$(dirname "$SELF_TARGET")"
      ensure_managed_path_blocks "$target_dir"
      show_post_install_hint "$target_dir"
      return 0
    fi
  done < <(build_install_target_candidates)

  die "无法安装 toolbox。已尝试: ${attempted[*]}"
}

install_self() {
  if [[ ! -f "$0" ]]; then
    log "当前脚本不是本地常规文件，改为从远程安装。"
    install_self_remote
    return 0
  fi
  install_to_best_target "$0"
}

install_self_remote() {
  local tmp target_dir
  target_dir="$(dirname "$SELF_TARGET")"
  mkdir -p "$target_dir"
  tmp="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SELF_SOURCE_URL" | sed 's/\r$//' > "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$SELF_SOURCE_URL" | sed 's/\r$//' > "$tmp"
  else
    rm -f "$tmp"
    die "缺少 curl 或 wget，无法安装 toolbox"
  fi
  install_to_best_target "$tmp"
  rm -f "$tmp"
}

is_installed_toolbox() {
  local target_path="$1"
  [[ -f "$target_path" ]] || return 1
  grep -Fq "APP_REPO=\"${APP_REPO}\"" "$target_path"
}

uninstall_self() {
  local yn=""
  local target_dir

  if [[ -z "$SELF_TARGET" ]]; then
    SELF_TARGET="$(resolve_existing_toolbox_command || true)"
  fi
  [[ -n "$SELF_TARGET" ]] || die "未找到已安装的 toolbox 命令"

  if [[ -d "$SELF_TARGET" && ! -L "$SELF_TARGET" ]]; then
    die "SELF_TARGET 指向目录，拒绝卸载: $SELF_TARGET"
  fi

  if [[ ! -e "$SELF_TARGET" && ! -L "$SELF_TARGET" ]]; then
    log "未发现已安装的 toolbox 命令: $SELF_TARGET"
    return 0
  fi

  if ! is_installed_toolbox "$SELF_TARGET"; then
    die "目标不是当前仓库安装的 toolbox 命令: $SELF_TARGET"
  fi

  if [[ -t 0 ]]; then
    read -r -p "确认卸载 $SELF_TARGET ? [y/N]: " yn
    [[ "$yn" =~ ^[Yy]$ ]] || return 0
  fi

  run_target_command "$SELF_TARGET" rm -f -- "$SELF_TARGET" || die "卸载失败: $SELF_TARGET"
  target_dir="$(dirname "$SELF_TARGET")"
  case "$target_dir" in
    "${HOME}/.local/bin"| "${HOME}/bin")
      remove_managed_path_blocks
      ;;
  esac
  log "已卸载 $SELF_TARGET"
}

ensure_toolbox_command() {
  if [[ "$TOOLBOX_AUTO_INSTALL" != "1" ]]; then
    return 0
  fi

  if resolve_existing_toolbox_command >/dev/null 2>&1; then
    return 0
  fi

  log "未检测到 toolbox 命令，先自动安装 / 修复。"
  if [[ -f "$0" ]]; then
    install_self
  else
    install_self_remote
  fi
}

# 菜单项格式: 类型、显示名称、标题、命令/说明、模式、备注
MAIN_MENU_ITEMS=(
  "fb${ITEM_SEP}fb 端口转发"
  "dd${ITEM_SEP}DD 重装脚本"
  "benchmark${ITEM_SEP}综合基准测试"
  "perf${ITEM_SEP}性能测试"
  "media${ITEM_SEP}流媒体与 IP 质量"
  "speedtest${ITEM_SEP}测速与路由"
  "backtrace${ITEM_SEP}回程测试"
  "functions${ITEM_SEP}系统与网络功能"
  "installers${ITEM_SEP}环境与软件安装"
  "allinone${ITEM_SEP}综合工具脚本"
)

FB_MENU_ITEMS=(
  "cmd${ITEM_SEP}一键运行远程版 fb${ITEM_SEP}一键运行远程版 fb${ITEM_SEP}bash <(curl -fsSL ${FB_SOURCE_URL})${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}安装 fb 命令${ITEM_SEP}安装 fb 命令${ITEM_SEP}bash <(curl -fsSL ${FB_SOURCE_URL}) install-self${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}进入本地 fb 菜单${ITEM_SEP}进入本地 fb 菜单${ITEM_SEP}fb menu${ITEM_SEP}normal${ITEM_SEP}需要先安装 fb 命令。"
  "cmd${ITEM_SEP}查看 fb 帮助${ITEM_SEP}查看 fb 帮助${ITEM_SEP}fb help${ITEM_SEP}normal${ITEM_SEP}需要先安装 fb 命令。"
)

DD_MENU_ITEMS=(
  "cmd${ITEM_SEP}史上最强 DD Debian 12${ITEM_SEP}史上最强 DD Debian 12${ITEM_SEP}curl -fsSLo InstallNET.sh https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'password'${ITEM_SEP}danger${ITEM_SEP}执行前建议把 password 改成你自己的 root 密码。"
  "cmd${ITEM_SEP}MoeClub DD 脚本${ITEM_SEP}MoeClub DD 脚本${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh) -d 11 -v 64 -p 密码 -port 端口 -a -firmware${ITEM_SEP}danger${ITEM_SEP}执行前建议把命令里的 密码 和 端口 改成你自己的值。"
  "cmd${ITEM_SEP}beta.gs DD 脚本${ITEM_SEP}beta.gs DD 脚本${ITEM_SEP}curl -fsSLo NewReinstall.sh https://raw.githubusercontent.com/fcurrk/reinstall/master/NewReinstall.sh && chmod a+x NewReinstall.sh && bash NewReinstall.sh${ITEM_SEP}danger${ITEM_SEP}重装前请确认控制台或 VNC 可用。"
  "cmd${ITEM_SEP}DD Windows 10${ITEM_SEP}DD Windows 10${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang 'cn'${ITEM_SEP}danger${ITEM_SEP}默认账号 Administrator，默认密码 Teddysun.com。"
  "info${ITEM_SEP}查看 Windows 默认账号/密码${ITEM_SEP}Windows 默认账号/密码${ITEM_SEP}账户: Administrator  密码: Teddysun.com${ITEM_SEP}${ITEM_SEP}"
)

BENCHMARK_MENU_ITEMS=(
  "cmd${ITEM_SEP}bench.sh${ITEM_SEP}bench.sh${ITEM_SEP}wget -qO- bench.sh | bash${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}LemonBench${ITEM_SEP}LemonBench${ITEM_SEP}wget -qO- https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}ecs.sh${ITEM_SEP}ecs.sh${ITEM_SEP}bash <(wget -qO- https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}NodeBench${ITEM_SEP}NodeBench${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/LloydAsp/NodeBench/main/NodeBench.sh)${ITEM_SEP}normal${ITEM_SEP}"
)

PERF_MENU_ITEMS=(
  "cmd${ITEM_SEP}yabs${ITEM_SEP}yabs${ITEM_SEP}curl -fsSL yabs.sh | bash${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}只测 GB5${ITEM_SEP}只测 GB5${ITEM_SEP}curl -fsSL yabs.sh | bash -s -- -i5${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}跳过网络和磁盘，仅测 GB5${ITEM_SEP}跳过网络和磁盘，仅测 GB5${ITEM_SEP}curl -fsSL yabs.sh | bash -s -- -if5${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}改测 GB5，不测 GB6${ITEM_SEP}改测 GB5，不测 GB6${ITEM_SEP}curl -fsSL yabs.sh | bash -s -- -5${ITEM_SEP}normal${ITEM_SEP}"
)

MEDIA_MENU_ITEMS=(
  "cmd${ITEM_SEP}常用流媒体检测${ITEM_SEP}常用流媒体检测${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}原生流媒体检测${ITEM_SEP}原生流媒体检测${ITEM_SEP}bash <(curl -fsSL Media.Check.Place)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}精准流媒体检测${ITEM_SEP}精准流媒体检测${ITEM_SEP}bash <(curl -L -s https://github.com/1-stream/RegionRestrictionCheck/raw/main/check.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}IP 质量体检${ITEM_SEP}IP 质量体检${ITEM_SEP}bash <(curl -fsSL IP.Check.Place)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}一键修改解锁 DNS${ITEM_SEP}一键修改解锁 DNS${ITEM_SEP}curl -fsSLo dns-unlock.sh https://raw.githubusercontent.com/Jimmyzxk/DNS-Alice-Unlock/main/dns-unlock.sh && bash dns-unlock.sh${ITEM_SEP}normal${ITEM_SEP}"
)

SPEEDTEST_MENU_ITEMS=(
  "cmd${ITEM_SEP}Speedtest Bench${ITEM_SEP}Speedtest Bench${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/laset-com/speedtest/master/speedtest.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Taier${ITEM_SEP}Taier${ITEM_SEP}bash <(curl -fsSL res.yserver.ink/taier.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Superspeed${ITEM_SEP}Superspeed${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/ernisn/superspeed/master/superspeed.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}全球测速${ITEM_SEP}全球测速${ITEM_SEP}wget -qO- nws.sh | bash${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}区域速度测试${ITEM_SEP}区域速度测试${ITEM_SEP}wget -qO- nws.sh | bash -s -- -r region_name${ITEM_SEP}normal${ITEM_SEP}执行前建议把 region_name 改成目标区域。"
  "cmd${ITEM_SEP}Ping 和路由测试${ITEM_SEP}Ping 和路由测试${ITEM_SEP}wget -qO- nws.sh | bash -s -- -rt [region]${ITEM_SEP}normal${ITEM_SEP}执行前建议把 [region] 改成目标区域。"
)

BACKTRACE_MENU_ITEMS=(
  "cmd${ITEM_SEP}直接显示回程${ITEM_SEP}直接显示回程${ITEM_SEP}curl -fsSL https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh | sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}AutoTrace${ITEM_SEP}AutoTrace${ITEM_SEP}curl -fsSLo AutoTrace.sh https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/AutoTrace.sh && chmod +x AutoTrace.sh && bash AutoTrace.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}testrace${ITEM_SEP}testrace${ITEM_SEP}curl -fsSLo testrace.sh https://raw.githubusercontent.com/vpsxb/testrace/main/testrace.sh && bash testrace.sh${ITEM_SEP}normal${ITEM_SEP}"
)

FUNCTIONS_MENU_ITEMS=(
  "cmd${ITEM_SEP}添加 SWAP${ITEM_SEP}添加 SWAP${ITEM_SEP}curl -fsSLo swap.sh https://www.moerats.com/usr/shell/swap.sh && bash swap.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Fail2ban${ITEM_SEP}Fail2ban${ITEM_SEP}curl -fsSLo fail2ban.sh https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}一键开启 BBR${ITEM_SEP}一键开启 BBR${ITEM_SEP}echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf && echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf && sysctl -p && sysctl net.ipv4.tcp_available_congestion_control && lsmod | grep bbr${ITEM_SEP}danger${ITEM_SEP}"
  "cmd${ITEM_SEP}多功能 BBR 安装脚本${ITEM_SEP}多功能 BBR 安装脚本${ITEM_SEP}wget -qO tcp.sh https://gist.github.com/zeruns/a0ec603f20d1b86de6a774a8ba27588f/raw/4f9957ae23f5efb2bb7c57a198ae2cffebfb1c56/tcp.sh && chmod +x tcp.sh && ./tcp.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Linux-NetSpeed${ITEM_SEP}Linux-NetSpeed${ITEM_SEP}curl -fsSLo tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh && chmod +x tcpx.sh && ./tcpx.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}TCP 窗口调优${ITEM_SEP}TCP 窗口调优${ITEM_SEP}wget -qO tools.sh http://sh.nekoneko.cloud/tools.sh && bash tools.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}添加 WARP${ITEM_SEP}添加 WARP${ITEM_SEP}curl -fsSLo menu.sh https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [license/url/token]${ITEM_SEP}normal${ITEM_SEP}执行前可以把 [option] [license/url/token] 替换成你的参数。"
  "cmd${ITEM_SEP}25 端口开放测试${ITEM_SEP}25 端口开放测试${ITEM_SEP}${PORT25_TEST_CMD}${ITEM_SEP}normal${ITEM_SEP}使用 Bash /dev/tcp 依次测试多个常见 SMTP 目标；全部失败通常表示机房封禁出站 25 端口或路由不可达。"
)

INSTALLERS_MENU_ITEMS=(
  "cmd${ITEM_SEP}Docker${ITEM_SEP}Docker${ITEM_SEP}bash <(curl -fsSL https://get.docker.com)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Python 3 开发环境${ITEM_SEP}Python 3 开发环境${ITEM_SEP}apt-get update && apt-get install -y python3 python3-pip python3-venv${ITEM_SEP}normal${ITEM_SEP}适用于 Debian / Ubuntu 系。"
  "cmd${ITEM_SEP}iperf3${ITEM_SEP}iperf3${ITEM_SEP}apt-get update && apt-get install -y iperf3${ITEM_SEP}normal${ITEM_SEP}适用于 Debian / Ubuntu 系。"
  "cmd${ITEM_SEP}realm${ITEM_SEP}realm${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/zhouh047/realm-oneclick-install/main/realm.sh) -i${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}gost${ITEM_SEP}gost${ITEM_SEP}curl -fsSLo gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Aurora 面板${ITEM_SEP}Aurora 面板${ITEM_SEP}bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}哪吒监控${ITEM_SEP}哪吒监控${ITEM_SEP}curl -fsSLo nezha.sh https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh && chmod +x nezha.sh && sudo ./nezha.sh${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}WARP${ITEM_SEP}WARP${ITEM_SEP}curl -fsSLo menu.sh https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh${ITEM_SEP}normal${ITEM_SEP}"
)

ALLINONE_MENU_ITEMS=(
  "cmd${ITEM_SEP}科技lion${ITEM_SEP}科技lion${ITEM_SEP}apt update -y && apt install -y curl && bash <(curl -fsSL kejilion.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}SKY-BOX${ITEM_SEP}SKY-BOX${ITEM_SEP}wget -qO box.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x box.sh && clear && ./box.sh${ITEM_SEP}normal${ITEM_SEP}"
)

declare -A MENU_TITLES=(
  [fb]="fb 端口转发"
  [dd]="DD 重装脚本"
  [benchmark]="综合基准测试"
  [perf]="性能测试"
  [media]="流媒体与 IP 质量"
  [speedtest]="测速与路由"
  [backtrace]="回程测试"
  [functions]="系统与网络功能"
  [installers]="环境与软件安装"
  [allinone]="综合工具脚本"
)

declare -A MENU_ARRAYS=(
  [fb]="FB_MENU_ITEMS"
  [dd]="DD_MENU_ITEMS"
  [benchmark]="BENCHMARK_MENU_ITEMS"
  [perf]="PERF_MENU_ITEMS"
  [media]="MEDIA_MENU_ITEMS"
  [speedtest]="SPEEDTEST_MENU_ITEMS"
  [backtrace]="BACKTRACE_MENU_ITEMS"
  [functions]="FUNCTIONS_MENU_ITEMS"
  [installers]="INSTALLERS_MENU_ITEMS"
  [allinone]="ALLINONE_MENU_ITEMS"
)

declare -A SHORT_URL_MAP=(
  [bench.sh]="https://bench.sh"
  [yabs.sh]="https://yabs.sh"
  [check.unlock.media]="https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh"
  [Media.Check.Place]="https://Media.Check.Place"
  [IP.Check.Place]="https://IP.Check.Place"
  [res.yserver.ink/taier.sh]="https://res.yserver.ink/taier.sh"
  [nws.sh]="https://nws.sh"
  [kejilion.sh]="https://kejilion.sh"
)

parse_menu_item() {
  ITEM_KIND=""
  ITEM_LABEL=""
  ITEM_TITLE=""
  ITEM_PAYLOAD=""
  ITEM_MODE="normal"
  ITEM_NOTE=""
  IFS="$ITEM_SEP" read -r ITEM_KIND ITEM_LABEL ITEM_TITLE ITEM_PAYLOAD ITEM_MODE ITEM_NOTE <<< "$1"
}

sanitize_probe_token() {
  local token="$1"
  token="${token//\'/}"
  token="${token//\"/}"
  token="${token#<}"
  token="${token#(}"
  token="${token#<\(}"
  token="${token%\)}"
  token="${token%;}"
  token="${token%,}"
  token="${token%|}"
  printf '%s\n' "$token"
}

url_from_probe_token() {
  local token="$1" cleaned
  cleaned="$(sanitize_probe_token "$token")"

  case "$cleaned" in
    http://*|https://*)
      printf '%s\n' "$cleaned"
      ;;
    *)
      if [[ -n "$cleaned" && -n "${SHORT_URL_MAP[$cleaned]+x}" ]]; then
        printf '%s\n' "${SHORT_URL_MAP[$cleaned]}"
      fi
      ;;
  esac
}

extract_probe_urls() {
  local cmd="$1" token url
  local -A seen_targets=()

  for token in $cmd; do
    url="$(url_from_probe_token "$token")"
    [[ -n "$url" ]] || continue
    if [[ -z "${seen_targets[$url]+x}" ]]; then
      seen_targets["$url"]=1
      printf '%s\n' "$url"
    fi
  done
}

probe_url() {
  local url="$1"
  local connect_timeout="${TOOLBOX_LINK_CHECK_CONNECT_TIMEOUT:-5}"
  local max_time="${TOOLBOX_LINK_CHECK_MAX_TIME:-15}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSIL --connect-timeout "$connect_timeout" --max-time "$max_time" "$url" >/dev/null 2>&1 \
      || curl -fsSL --connect-timeout "$connect_timeout" --max-time "$max_time" --range 0-0 "$url" >/dev/null 2>&1
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    wget --spider -q -T "$max_time" -t 1 "$url" >/dev/null 2>&1 \
      || wget -qO- -T "$max_time" -t 1 "$url" >/dev/null 2>&1
    return $?
  fi

  return 2
}

check_menu_links() {
  local mode="${1:-}" item menu_key _ array_name menu_item url seen_key
  local total=0 failures=0
  local -A seen=()

  if [[ "$mode" == "--help" || "$mode" == "-h" ]]; then
    cat <<EOF
用法:
  toolbox check-links
  toolbox check-links --list
  toolbox check-links --strict

说明:
  默认只检查菜单命令里的远程 URL 是否可达，不执行远程脚本。
  --list 只列出将要检查的 URL。
  --strict 在存在不可达 URL 时返回非零退出码。
EOF
    return 0
  fi

  for item in "${MAIN_MENU_ITEMS[@]}"; do
    IFS="$ITEM_SEP" read -r menu_key _ <<< "$item"
    array_name="${MENU_ARRAYS[$menu_key]}"
    local -n menu_items_ref="$array_name"
    for menu_item in "${menu_items_ref[@]}"; do
      parse_menu_item "$menu_item"
      [[ "$ITEM_KIND" == "cmd" ]] || continue
      while IFS= read -r url; do
        [[ -n "$url" ]] || continue
        seen_key="$url"
        [[ -z "${seen[$seen_key]+x}" ]] || continue
        seen["$seen_key"]=1
        ((++total))

        if [[ "$mode" == "--list" ]]; then
          printf '%s\n' "$url"
          continue
        fi

        printf '[CHECK] %s\n' "$url"
        if probe_url "$url"; then
          printf '[OK] %s\n' "$url"
        else
          ((++failures))
          printf '[WARN] %s\n' "$url" >&2
        fi
      done < <(extract_probe_urls "$ITEM_PAYLOAD")
    done
    unset -n menu_items_ref
  done

  if [[ "$mode" == "--list" ]]; then
    return 0
  fi

  printf '检查完成: %d 个 URL，%d 个警告。\n' "$total" "$failures"
  if [[ "$mode" == "--strict" && "$failures" -gt 0 ]]; then
    return 1
  fi
  return 0
}

show_main_menu() {
  local index=1 item menu_key menu_label
  show_header
  for item in "${MAIN_MENU_ITEMS[@]}"; do
    IFS="$ITEM_SEP" read -r menu_key menu_label <<< "$item"
    printf "%d) %s\n" "$index" "$menu_label"
    ((index++))
  done
  echo "97) 卸载已安装的 toolbox 命令"
  echo "98) 从远程更新 / 修复 toolbox"
  echo "99) 安装 / 修复本地 toolbox 命令"
  echo "0) 退出"
  echo
  show_temporary_run_hint
  echo
}

run_menu() {
  local menu_key="$1" choice="" item_count=0 i=0
  local menu_title="${MENU_TITLES[$menu_key]:-}"
  local array_name="${MENU_ARRAYS[$menu_key]:-}"

  [[ -n "$menu_title" && -n "$array_name" ]] || die "未知菜单: $menu_key"

  local -n menu_items_ref="$array_name"
  item_count="${#menu_items_ref[@]}"

  while true; do
    show_header
    show_submenu_title "$menu_title"
    for ((i = 0; i < item_count; i++)); do
      parse_menu_item "${menu_items_ref[i]}"
      printf "%d) %s\n" "$((i + 1))" "$ITEM_LABEL"
    done
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " choice
    choice="${choice:-1}"

    if [[ "$choice" == "0" ]]; then
      return 0
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= item_count )); then
      parse_menu_item "${menu_items_ref[choice - 1]}"
      case "$ITEM_KIND" in
        cmd)
          handle_command_item "$ITEM_TITLE" "$ITEM_PAYLOAD" "${ITEM_MODE:-normal}" "$ITEM_NOTE"
          ;;
        info)
          handle_info_item "$ITEM_TITLE" "$ITEM_PAYLOAD"
          ;;
        *)
          die "未知菜单项类型: $ITEM_KIND"
          ;;
      esac
    else
      warn "无效选择"
      pause_enter
    fi
  done
}

show_help() {
  cat <<EOF
用法:
  bash toolbox.sh
  bash toolbox.sh menu
  bash toolbox.sh install-self
  bash toolbox.sh uninstall-self
  bash <(curl -fsSL ${SELF_SOURCE_URL})
  bash <(curl -fsSL ${SELF_SOURCE_URL}) install-self

安装后管理:
  toolbox
  toolbox menu
  toolbox help
  toolbox version
  toolbox update-self
  toolbox check-links
  toolbox uninstall-self

远程运行:
  bash <(curl -fsSL ${SELF_SOURCE_URL})

远程安装:
  首次直接运行会自动安装 / 修复 toolbox 命令
  bash <(curl -fsSL ${SELF_SOURCE_URL}) install-self
  或
  curl -fsSL ${SELF_SOURCE_URL} | tr -d '\r' > /usr/local/bin/toolbox
  chmod 755 /usr/local/bin/toolbox
  toolbox
  普通用户写入 /usr/local/bin 时，可在写入和 chmod 前加 sudo

说明:
  - 已移除占位说明页、重复分类和明显偏题的入口。
  - 仅保留更聚焦的 VPS 检测、重装、网络和安装类功能。
  - Debian / Ubuntu 优先安装到 /usr/local/bin；无权限时回落到 ~/.local/bin 或 ~/bin。
  - 远程脚本来自第三方仓库，执行前请自行判断风险。
  - check-links 只做远程 URL 可达性检查，不会执行第三方脚本。
  - uninstall-self 仅删除已安装的 toolbox 命令文件，不回滚已执行过的外部脚本或系统改动。
EOF
}

main() {
  local cmd="${1:-menu}" choice="" menu_key="" _

  case "$cmd" in
    install-self)
      install_self
      ;;
    uninstall-self)
      uninstall_self
      ;;
    install-self-remote|update-self)
      install_self_remote
      ;;
    help|-h|--help)
      show_help
      ;;
    version|-v|--version)
      print_version
      ;;
    check-links|doctor|health-check)
      shift || true
      check_menu_links "$@"
      ;;
    menu|"")
      ensure_toolbox_command
      while true; do
        show_main_menu
        read -r -p "请选择分类 [1]: " choice
        choice="${choice:-1}"
        case "$choice" in
          97)
            uninstall_self
            pause_enter
            ;;
          98)
            install_self_remote
            pause_enter
            ;;
          99)
            install_self
            pause_enter
            ;;
          0)
            exit 0
            ;;
          *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#MAIN_MENU_ITEMS[@]} )); then
              IFS="$ITEM_SEP" read -r menu_key _ <<< "${MAIN_MENU_ITEMS[choice - 1]}"
              run_menu "$menu_key"
            else
              warn "无效选择"
              pause_enter
            fi
            ;;
        esac
      done
      ;;
    *)
      err "未知命令: $cmd"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
