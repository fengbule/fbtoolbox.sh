#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="VPS 工具箱"
APP_VERSION="v1.2.0"
APP_REPO="https://github.com/fengbule/fbtoolbox.sh"
SELF_SOURCE_URL="${TOOLBOX_SELF_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/fbtoolbox.sh/main/toolbox.sh}"
SELF_TARGET="${SELF_TARGET:-/usr/local/bin/toolbox}"
FB_SOURCE_URL="${FB_SOURCE_URL:-https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh}"

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
  echo
  read -r -p "按回车继续..." _
}

clear_screen() {
  if [[ -t 1 ]] && command -v clear >/dev/null 2>&1; then
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
    read -r -p "确认执行？[Y/n]: " yn
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

install_self() {
  local target_dir
  if [[ ! -f "$0" ]]; then
    log "当前脚本不是本地常规文件，改为从远程安装。"
    install_self_remote
    return 0
  fi
  target_dir="$(dirname "$SELF_TARGET")"
  mkdir -p "$target_dir"
  install -m 0755 "$0" "$SELF_TARGET"
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
  install -m 0755 "$tmp" "$SELF_TARGET"
  rm -f "$tmp"
  log "已从远程安装到 $SELF_TARGET"
  log "以后直接输入 toolbox 即可"
}

show_main_menu() {
  show_header
  echo "1) fb 端口转发"
  echo "2) DD 重装脚本"
  echo "3) 综合测试脚本"
  echo "4) 性能测试"
  echo "5) 流媒体及 IP 质量测试"
  echo "6) 测速脚本"
  echo "7) 回程测试"
  echo "8) 功能脚本"
  echo "9) 一键安装常用环境及软件"
  echo "10) 综合功能脚本"
  echo "11) 其它"
  echo "12) VPS 常备小命令"
  echo "13) 杜甫检测脚本"
  echo "98) 从远程更新/安装 toolbox"
  echo "99) 安装本地 toolbox 命令"
  echo "0) 退出"
  echo
}

menu_fb() {
  local n=""
  while true; do
    show_header
    show_submenu_title "fb 端口转发"
    echo "1) 一键运行远程版 fb"
    echo "2) 安装 fb 命令"
    echo "3) 进入本机 fb 菜单"
    echo "4) 查看 fb 帮助"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "一键运行远程版 fb" "bash <(curl -fsSL ${FB_SOURCE_URL})"
        ;;
      2)
        handle_command_item "安装 fb 命令" "bash <(curl -fsSL ${FB_SOURCE_URL}) install-self"
        ;;
      3)
        handle_command_item "进入本机 fb 菜单" "fb menu" "normal" "需要先安装 fb 命令。"
        ;;
      4)
        handle_command_item "查看 fb 帮助" "fb help" "normal" "需要先安装 fb 命令。"
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

menu_dd() {
  local n=""
  while true; do
    show_header
    show_submenu_title "DD 重装脚本"
    echo "1) 史上最强 DD 脚本 Debian 12"
    echo "2) 萌咖 DD 脚本"
    echo "3) beta.gs DD 脚本"
    echo "4) DD Windows 10"
    echo "5) Windows 默认账号密码"
    echo "6) Windows 激活命令"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "史上最强 DD 脚本 Debian 12" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'password'" "danger" "执行前建议把 password 改成你自己的 root 密码。"
        ;;
      2)
        handle_command_item "萌咖 DD 脚本" "bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 11 -v 64 -p 密码 -port 端口 -a -firmware" "danger" "执行前建议把命令里的 密码 和 端口 改成你自己的值。"
        ;;
      3)
        handle_command_item "beta.gs DD 脚本" "wget --no-check-certificate -O NewReinstall.sh https://raw.githubusercontent.com/fcurrk/reinstall/master/NewReinstall.sh && chmod a+x NewReinstall.sh && bash NewReinstall.sh" "danger" "重装前请确认控制台或 VNC 可用。"
        ;;
      4)
        handle_command_item "DD Windows 10" "bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang 'cn'" "danger" "默认账号 Administrator，默认密码 Teddysun.com。"
        ;;
      5)
        handle_info_item "Windows 默认账号密码" $'账户: Administrator\n密码: Teddysun.com'
        ;;
      6)
        handle_info_item "Windows 激活命令" "$(cat <<'EOF'
登录 Windows 后:
1. 按 Windows + R
2. 输入 powershell 并回车
3. 在弹出的窗口里执行:

irm https://get.activated.win | iex
EOF
)"
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

menu_benchmark_all() {
  local n=""
  while true; do
    show_header
    show_submenu_title "综合测试脚本"
    echo "1) bench.sh"
    echo "2) LemonBench"
    echo "3) 融合怪 ecs.sh"
    echo "4) NodeBench"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "bench.sh" "wget -qO- bench.sh | bash"
        ;;
      2)
        handle_command_item "LemonBench" "wget -qO- https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast"
        ;;
      3)
        handle_command_item "融合怪 ecs.sh" "bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)"
        ;;
      4)
        handle_command_item "NodeBench" "bash <(curl -sL https://raw.githubusercontent.com/LloydAsp/NodeBench/main/NodeBench.sh)"
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

menu_perf() {
  local n=""
  while true; do
    show_header
    show_submenu_title "性能测试"
    echo "1) yabs"
    echo "2) 跳过网络，只测 GB5"
    echo "3) 跳过网络和磁盘，只测 GB5"
    echo "4) 改测 GB5 不测 GB6"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "yabs" "curl -sL yabs.sh | bash"
        ;;
      2)
        handle_command_item "跳过网络，只测 GB5" "curl -sL yabs.sh | bash -s -- -i5"
        ;;
      3)
        handle_command_item "跳过网络和磁盘，只测 GB5" "curl -sL yabs.sh | bash -s -- -if5"
        ;;
      4)
        handle_command_item "改测 GB5 不测 GB6" "curl -sL yabs.sh | bash -s -- -5"
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

menu_media() {
  local n=""
  while true; do
    show_header
    show_submenu_title "流媒体及 IP 质量测试"
    echo "1) 最常用版本"
    echo "2) 原生检测脚本"
    echo "3) 准确度最高版本"
    echo "4) IP 质量体检脚本"
    echo "5) 一键修改解锁 DNS"
    echo "6) BBR v3 优化脚本"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "最常用版本" "bash <(curl -L -s check.unlock.media)"
        ;;
      2)
        handle_command_item "原生检测脚本" "bash <(curl -sL Media.Check.Place)"
        ;;
      3)
        handle_command_item "准确度最高版本" "bash <(curl -L -s https://github.com/1-stream/RegionRestrictionCheck/raw/main/check.sh)"
        ;;
      4)
        handle_command_item "IP 质量体检脚本" "bash <(curl -sL IP.Check.Place)"
        ;;
      5)
        handle_command_item "一键修改解锁 DNS" "wget https://raw.githubusercontent.com/Jimmyzxk/DNS-Alice-Unlock/refs/heads/main/dns-unlock.sh && bash dns-unlock.sh"
        ;;
      6)
        handle_command_item "BBR v3 优化脚本" 'bash <(curl -fsSL "https://raw.githubusercontent.com/Eric86777/vps-tcp-tune/main/install-alias.sh?$(date +%s)")' "normal" "安装后执行 source ~/.bashrc 或 source ~/.zshrc，然后直接输入 bbr。"
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

menu_speedtest() {
  local n=""
  while true; do
    show_header
    show_submenu_title "测速脚本"
    echo "1) Speedtest"
    echo "2) Taier"
    echo "3) hyperspeed"
    echo "4) 全球测速"
    echo "5) 区域速度测试"
    echo "6) Ping 和路由测试"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "Speedtest" "bash <(curl -sL bash.icu/speedtest)"
        ;;
      2)
        handle_command_item "Taier" "bash <(curl -sL res.yserver.ink/taier.sh)"
        ;;
      3)
        handle_command_item "hyperspeed" "bash <(curl -Lso- https://bench.im/hyperspeed)"
        ;;
      4)
        handle_command_item "全球测速" "wget -qO- nws.sh | bash"
        ;;
      5)
        handle_command_item "区域速度测试" "wget -qO- nws.sh | bash -s -- -r region_name" "normal" "执行前建议把 region_name 改成目标区域。"
        ;;
      6)
        handle_command_item "Ping 和路由测试" "wget -qO- nws.sh | bash -s -- -rt [region]" "normal" "执行前建议把 [region] 改成目标区域。"
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

menu_backtrace() {
  local n=""
  while true; do
    show_header
    show_submenu_title "回程测试"
    echo "1) 直接显示回程（小白用）"
    echo "2) 回程详细测试 AutoTrace"
    echo "3) testrace"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "直接显示回程（小白用）" "curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh"
        ;;
      2)
        handle_command_item "回程详细测试 AutoTrace" "wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/AutoTrace.sh && chmod +x AutoTrace.sh && bash AutoTrace.sh"
        ;;
      3)
        handle_command_item "testrace" "wget https://ghproxy.com/https://raw.githubusercontent.com/vpsxb/testrace/main/testrace.sh -O testrace.sh && bash testrace.sh"
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

menu_functions() {
  local n=""
  while true; do
    show_header
    show_submenu_title "功能脚本"
    echo "1) 添加 SWAP"
    echo "2) Fail2ban"
    echo "3) 一键开启 BBR"
    echo "4) 多功能 BBR 安装脚本"
    echo "5) 锐速 / BBRPLUS / BBR2 / BBR3"
    echo "6) TCP 窗口调优"
    echo "7) 添加 WARP"
    echo "8) 25 端口开放测试"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "添加 SWAP" "wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh"
        ;;
      2)
        handle_command_item "Fail2ban" "wget --no-check-certificate https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log"
        ;;
      3)
        handle_command_item "一键开启 BBR" "echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf && echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf && sysctl -p && sysctl net.ipv4.tcp_available_congestion_control && lsmod | grep bbr" "danger"
        ;;
      4)
        handle_command_item "多功能 BBR 安装脚本" "wget -N --no-check-certificate 'https://gist.github.com/zeruns/a0ec603f20d1b86de6a774a8ba27588f/raw/4f9957ae23f5efb2bb7c57a198ae2cffebfb1c56/tcp.sh' && chmod +x tcp.sh && ./tcp.sh"
        ;;
      5)
        handle_command_item "锐速 / BBRPLUS / BBR2 / BBR3" "wget -O tcpx.sh 'https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh' && chmod +x tcpx.sh && ./tcpx.sh"
        ;;
      6)
        handle_command_item "TCP 窗口调优" "wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh"
        ;;
      7)
        handle_command_item "添加 WARP" "wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]" "normal" "执行前可以把 [option] [lisence/url/token] 替换成你的参数。"
        ;;
      8)
        handle_command_item "25 端口开放测试" "telnet smtp.aol.com 25" "normal" "系统需要先安装 telnet。"
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

menu_installers() {
  local n=""
  while true; do
    show_header
    show_submenu_title "一键安装常用环境及软件"
    echo "1) Docker"
    echo "2) Python"
    echo "3) iperf3"
    echo "4) realm"
    echo "5) gost"
    echo "6) 极光面板"
    echo "7) 哪吒监控"
    echo "8) 哪吒前端配置片段"
    echo "9) WARP"
    echo "10) Aria2"
    echo "11) 宝塔"
    echo "12) PVE 虚拟化"
    echo "13) Argox"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "Docker" "bash <(curl -sL 'https://get.docker.com')"
        ;;
      2)
        handle_command_item "Python" "curl -O https://raw.githubusercontent.com/lx969788249/lxspacepy/master/pyinstall.sh && chmod +x pyinstall.sh && ./pyinstall.sh"
        ;;
      3)
        handle_command_item "iperf3" "apt install iperf3" "normal" "适用于 Debian / Ubuntu 系。"
        ;;
      4)
        handle_command_item "realm" "bash <(curl -L https://raw.githubusercontent.com/zhouh047/realm-oneclick-install/main/realm.sh) -i"
        ;;
      5)
        handle_command_item "gost" "wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh"
        ;;
      6)
        handle_command_item "极光面板" "bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)"
        ;;
      7)
        handle_command_item "哪吒监控" "curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh"
        ;;
      8)
        handle_info_item "哪吒前端配置片段" "$(cat <<'EOF'
<script>
window.ShowNetTransfer = true;
window.FixedTopServerName = true;
window.DisableAnimatedMan = true
</script>
EOF
)"
        ;;
      9)
        handle_command_item "WARP" "wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh"
        ;;
      10)
        handle_command_item "Aria2" "wget -N git.io/aria2.sh && chmod +x aria2.sh && ./aria2.sh"
        ;;
      11)
        handle_command_item "宝塔" "wget -O install.sh http://v7.hostcli.com/install/install-ubuntu_6.0.sh && sudo bash install.sh" "danger"
        ;;
      12)
        handle_command_item "PVE 虚拟化" "bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/pve/main/scripts/build_backend.sh)" "danger"
        ;;
      13)
        handle_command_item "Argox" "bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh)"
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

menu_allinone() {
  local n=""
  while true; do
    show_header
    show_submenu_title "综合功能脚本"
    echo "1) 科技lion"
    echo "2) SKY-BOX"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "科技lion" "apt update -y && apt install -y curl && bash <(curl -sL kejilion.sh)"
        ;;
      2)
        handle_command_item "SKY-BOX" "wget -O box.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x box.sh && clear && ./box.sh"
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

menu_other() {
  local n=""
  while true; do
    show_header
    show_submenu_title "其它"
    echo "1) TG 中文汉化"
    echo "2) 送中报告地址"
    echo "3) TCP 迷之调参"
    echo "4) awesome_docker"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_info_item "TG 中文汉化" $'链接:\nhttps://t.me/setlanguage/classic-zh-cn'
        ;;
      2)
        handle_info_item "送中报告地址" $'去 Google 的帮助中心提交 IP 问题报告。\n\n原始整理里没有给出固定链接，这里先保留为说明项。'
        ;;
      3)
        handle_info_item "TCP 迷之调参" $'原始整理里没有给出固定脚本或链接，这里先保留为占位说明项。'
        ;;
      4)
        handle_info_item "awesome_docker" $'原始整理里没有给出固定脚本或链接，这里先保留为占位说明项。'
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

menu_smallcmd() {
  handle_info_item "VPS 常备小命令" "$(cat <<'EOF'
参考地址:
https://www.nodeseek.com/post-424648-1

这是非脚本命令合集，建议按文章里的场景说明手动挑选执行。
EOF
)"
}

menu_dufu() {
  local n=""
  while true; do
    show_header
    show_submenu_title "杜甫检测脚本"
    echo "1) sick.onl"
    echo "2) Aniverse A"
    echo "3) nws.sh"
    echo "4) 下载 InstallNET.sh"
    echo "5) Debian 12 DD"
    echo "6) Debian 12 RAID0 DD"
    echo "7) 指定网络 DD"
    echo "8) 指定密码 DD"
    echo "9) hardware_info 中文"
    echo "10) 禁用 IPv6"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        handle_command_item "sick.onl" "curl -sL https://sick.onl | bash"
        ;;
      2)
        handle_command_item "Aniverse A" "wget https://github.com/Aniverse/A/raw/i/a && bash a"
        ;;
      3)
        handle_command_item "nws.sh" "wget -qO- nws.sh | bash"
        ;;
      4)
        handle_command_item "下载 InstallNET.sh" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh"
        ;;
      5)
        handle_command_item "Debian 12 DD" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12" "danger"
        ;;
      6)
        handle_command_item "Debian 12 RAID0 DD" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -raid '0'" "danger"
        ;;
      7)
        handle_command_item "指定网络 DD" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 --ip-addr 139.162.52.1 --ip-mask 24 --ip-gate 139.162.52.1 --ip6-addr 2a07:e040:2:1d3::1 --ip6-gate 2a07:e040::1 --ip6-mask 32" "danger" "执行前建议改成你自己的 IPv4 / IPv6 参数。"
        ;;
      8)
        handle_command_item "指定密码 DD" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'password'" "danger" "执行前建议把 password 改成你自己的密码。"
        ;;
      9)
        handle_command_item "hardware_info 中文" "curl -sL https://raw.githubusercontent.com/Yuri-NagaSaki/SICK/refs/heads/main/hardware_info.sh | bash -s -- -cn"
        ;;
      10)
        handle_command_item "禁用 IPv6" "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf && sysctl -p" "danger"
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

show_help() {
  cat <<EOF
用法:
  bash toolbox.sh
  bash toolbox.sh menu
  bash toolbox.sh install-self
  bash toolbox.sh install-self-remote

远程运行:
  bash <(curl -fsSL ${SELF_SOURCE_URL})

远程安装:
  curl -fsSL ${SELF_SOURCE_URL} | tr -d '\r' > /usr/local/bin/toolbox
  chmod 755 /usr/local/bin/toolbox
  toolbox
EOF
}

main() {
  local cmd="${1:-menu}" n=""
  case "$cmd" in
    install-self)
      install_self
      ;;
    install-self-remote)
      install_self_remote
      ;;
    help|-h|--help)
      show_help
      ;;
    menu|"")
      while true; do
        show_main_menu
        read -r -p "请选择分类 [1]: " n
        n="${n:-1}"
        case "$n" in
          1)
            menu_fb
            ;;
          2)
            menu_dd
            ;;
          3)
            menu_benchmark_all
            ;;
          4)
            menu_perf
            ;;
          5)
            menu_media
            ;;
          6)
            menu_speedtest
            ;;
          7)
            menu_backtrace
            ;;
          8)
            menu_functions
            ;;
          9)
            menu_installers
            ;;
          10)
            menu_allinone
            ;;
          11)
            menu_other
            ;;
          12)
            menu_smallcmd
            ;;
          13)
            menu_dufu
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
            warn "无效选择"
            pause_enter
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
