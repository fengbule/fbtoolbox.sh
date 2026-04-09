#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="VPS 工具箱"
APP_VERSION="v2.0.0"
APP_REPO="https://github.com/fengbule/fbtoolbox.sh"
SELF_SOURCE_URL="${TOOLBOX_SELF_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/fbtoolbox.sh/main/toolbox.sh}"
SELF_TARGET="${SELF_TARGET:-/usr/local/bin/toolbox}"
FB_SOURCE_URL="${FB_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh}"
ITEM_SEP=$'\t'

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
  if bash -lc "$RUN_CMD"; then
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

install_file() {
  local source_path="$1" target_path="$2"

  if command -v install >/dev/null 2>&1; then
    install -m 0755 "$source_path" "$target_path"
    return 0
  fi

  cp "$source_path" "$target_path"
  chmod 0755 "$target_path"
}

install_self() {
  local target_dir
  if [[ ! -f "$0" ]]; then
    log "当前脚本不是本地常规文件，改为从远程安装。"
    install_self_remote
    return 0
  fi
  target_dir="$(dirname "$SELF_TARGET")"
  mkdir -p "$target_dir"
  install_file "$0" "$SELF_TARGET"
  log "已安装到 $SELF_TARGET"
  log "以后直接输入 toolbox 即可"
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
  install_file "$tmp" "$SELF_TARGET"
  rm -f "$tmp"
  log "已从远程安装到 $SELF_TARGET"
  log "以后直接输入 toolbox 即可"
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
  "cmd${ITEM_SEP}常用流媒体检测${ITEM_SEP}常用流媒体检测${ITEM_SEP}bash <(curl -L -s check.unlock.media)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}原生流媒体检测${ITEM_SEP}原生流媒体检测${ITEM_SEP}bash <(curl -fsSL Media.Check.Place)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}精准流媒体检测${ITEM_SEP}精准流媒体检测${ITEM_SEP}bash <(curl -L -s https://github.com/1-stream/RegionRestrictionCheck/raw/main/check.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}IP 质量体检${ITEM_SEP}IP 质量体检${ITEM_SEP}bash <(curl -fsSL IP.Check.Place)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}一键修改解锁 DNS${ITEM_SEP}一键修改解锁 DNS${ITEM_SEP}curl -fsSLo dns-unlock.sh https://raw.githubusercontent.com/Jimmyzxk/DNS-Alice-Unlock/main/dns-unlock.sh && bash dns-unlock.sh${ITEM_SEP}normal${ITEM_SEP}"
)

SPEEDTEST_MENU_ITEMS=(
  "cmd${ITEM_SEP}Speedtest${ITEM_SEP}Speedtest${ITEM_SEP}bash <(curl -fsSL bash.icu/speedtest)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}Taier${ITEM_SEP}Taier${ITEM_SEP}bash <(curl -fsSL res.yserver.ink/taier.sh)${ITEM_SEP}normal${ITEM_SEP}"
  "cmd${ITEM_SEP}hyperspeed${ITEM_SEP}hyperspeed${ITEM_SEP}bash <(curl -Lso- https://bench.im/hyperspeed)${ITEM_SEP}normal${ITEM_SEP}"
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
  "cmd${ITEM_SEP}25 端口开放测试${ITEM_SEP}25 端口开放测试${ITEM_SEP}telnet smtp.aol.com 25${ITEM_SEP}normal${ITEM_SEP}系统需要先安装 telnet。"
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

parse_menu_item() {
  ITEM_KIND=""
  ITEM_LABEL=""
  ITEM_TITLE=""
  ITEM_PAYLOAD=""
  ITEM_MODE="normal"
  ITEM_NOTE=""
  IFS="$ITEM_SEP" read -r ITEM_KIND ITEM_LABEL ITEM_TITLE ITEM_PAYLOAD ITEM_MODE ITEM_NOTE <<< "$1"
}

show_main_menu() {
  local index=1 item menu_key menu_label
  show_header
  for item in "${MAIN_MENU_ITEMS[@]}"; do
    IFS="$ITEM_SEP" read -r menu_key menu_label <<< "$item"
    printf "%d) %s\n" "$index" "$menu_label"
    ((index++))
  done
  echo "98) 从远程更新/安装 toolbox"
  echo "99) 安装本地 toolbox 命令"
  echo "0) 退出"
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
  bash toolbox.sh install-self
  bash <(curl -fsSL ${SELF_SOURCE_URL})

安装后管理:
  toolbox
  toolbox menu
  toolbox help
  toolbox version
  toolbox update-self

远程运行:
  bash <(curl -fsSL ${SELF_SOURCE_URL})

远程安装:
  curl -fsSL ${SELF_SOURCE_URL} | tr -d '\r' > /usr/local/bin/toolbox
  chmod 755 /usr/local/bin/toolbox
  toolbox

说明:
  - 已移除占位说明页、重复分类和明显偏题的入口。
  - 仅保留更聚焦的 VPS 检测、重装、网络和安装类功能。
  - 远程脚本来自第三方仓库，执行前请自行判断风险。
EOF
}

main() {
  local cmd="${1:-menu}" choice="" menu_key="" _

  case "$cmd" in
    install-self)
      install_self
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
    menu|"")
      while true; do
        show_main_menu
        read -r -p "请选择分类 [1]: " choice
        choice="${choice:-1}"
        case "$choice" in
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
