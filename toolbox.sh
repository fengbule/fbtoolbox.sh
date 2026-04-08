#!/usr/bin/env bash
set -Eeuo pipefail

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
C5='\033[1;35m'
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

danger_run_cmd() {
  local title="$1" cmd="$2"
  echo
  echo -e "${C3}危险操作：${title}${C0}"
  echo -e "${C3}此操作可能导致系统重装、网络中断、配置覆盖或数据丢失。${C0}"
  echo
  echo -e "${CW}${cmd}${C0}"
  echo
  read -r -p "确认继续？请输入 YES: " yn
  [[ "$yn" == "YES" ]] || return 0
  bash -c "$cmd"
}

show_cmd() {
  local title="$1" cmd="$2"
  echo
  echo -e "${C5}[$title]${C0}"
  echo -e "${CW}${cmd}${C0}"
  echo
}

handle_item() {
  local title="$1" cmd="$2" mode="${3:-normal}"
  echo "1) 查看命令"
  echo "2) 直接执行"
  echo "0) 返回"
  read -r -p "请选择 [1]: " act
  act="${act:-1}"
  case "$act" in
    1)
      show_cmd "$title" "$cmd"
      pause_enter
      ;;
    2)
      if [[ "$mode" == "danger" ]]; then
        danger_run_cmd "$title" "$cmd"
      else
        run_cmd "$cmd"
      fi
      pause_enter
      ;;
    0) ;;
    *)
      warn "无效选择"
      pause_enter
      ;;
  esac
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
  echo "99) 安装 toolbox 命令"
  echo "0) 退出"
  echo
}

menu_fb() {
  while true; do
    show_header
    echo -e "${C5}=== fb 端口转发工具 ===${C0}"
    echo "1) 一键运行远程版 fb"
    echo "2) 安装 fb 命令"
    echo "3) 进入 fb 菜单"
    echo "4) 查看 fb 帮助"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "一键运行 fb" "bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh)" ;;
      2) handle_item "安装 fb 命令" "bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/zhuanfa/main/fb.sh) install-self" ;;
      3) handle_item "进入 fb 菜单" "fb menu" ;;
      4) handle_item "查看 fb 帮助" "fb help" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_dd() {
  while true; do
    show_header
    echo -e "${C5}=== DD 重装脚本 ===${C0}"
    echo "1) 史上最强脚本 Debian 12"
    echo "2) 萌咖脚本"
    echo "3) beta.gs 脚本"
    echo "4) DD Windows 10"
    echo "5) Windows 激活命令"
    echo "6) Windows 默认账户密码说明"
    echo "0) 返回"
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "InstallNET Debian 12" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'password'" "danger" ;;
      2) handle_item "萌咖 DD" "bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') -d 11 -v 64 -p 密码 -port 端口 -a -firmware" "danger" ;;
      3) handle_item "beta.gs DD" "wget --no-check-certificate -O NewReinstall.sh https://raw.githubusercontent.com/fcurrk/reinstall/master/NewReinstall.sh && chmod a+x NewReinstall.sh && bash NewReinstall.sh" "danger" ;;
      4) handle_item "DD Windows 10" "bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -windows 10 -lang 'cn'" "danger" ;;
      5) handle_item "Windows 激活命令" "powershell -c \"irm https://get.activated.win | iex\"" ;;
      6)
        echo
        echo "账户：Administrator"
        echo "密码：Teddysun.com"
        echo
        pause_enter
        ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_benchmark_all() {
  while true; do
    show_header
    echo -e "${C5}=== 综合测试脚本 ===${C0}"
    echo "1) bench.sh"
    echo "2) LemonBench"
    echo "3) 融合怪 ecs.sh"
    echo "4) NodeBench"
    echo "0) 返回"
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "bench.sh" "wget -qO- bench.sh | bash" ;;
      2) handle_item "LemonBench" "wget -qO- https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast" ;;
      3) handle_item "融合怪" "bash <(wget -qO- --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh)" ;;
      4) handle_item "NodeBench" "bash <(curl -sL https://raw.githubusercontent.com/LloydAsp/NodeBench/main/NodeBench.sh)" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_perf() {
  while true; do
    show_header
    echo -e "${C5}=== 性能测试 ===${C0}"
    echo "1) yabs"
    echo "2) 跳过网络，测 GB5"
    echo "3) 跳过网络和磁盘，测 GB5"
    echo "4) 改测 GB5 不测 GB6"
    echo "0) 返回"
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "yabs" "curl -sL yabs.sh | bash" ;;
      2) handle_item "yabs -i5" "curl -sL yabs.sh | bash -s -- -i5" ;;
      3) handle_item "yabs -if5" "curl -sL yabs.sh | bash -s -- -if5" ;;
      4) handle_item "yabs -5" "curl -sL yabs.sh | bash -s -- -5" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_media() {
  while true; do
    show_header
    echo -e "${C5}=== 流媒体及 IP 质量测试 ===${C0}"
    echo "1) 最常用版本"
    echo "2) 原生检测脚本"
    echo "3) 准确度最高"
    echo "4) IP 质量体检脚本"
    echo "5) 一键修改解锁 DNS"
    echo "6) BBR v3 优化脚本说明"
    echo "0) 返回"
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "check.unlock.media" "bash <(curl -L -s check.unlock.media)" ;;
      2) handle_item "Media.Check.Place" "bash <(curl -sL Media.Check.Place)" ;;
      3) handle_item "RegionRestrictionCheck" "bash <(curl -L -s https://github.com/1-stream/RegionRestrictionCheck/raw/main/check.sh)" ;;
      4) handle_item "IP.Check.Place" "bash <(curl -sL IP.Check.Place)" ;;
      5) handle_item "DNS 解锁" "wget https://raw.githubusercontent.com/Jimmyzxk/DNS-Alice-Unlock/refs/heads/main/dns-unlock.sh && bash dns-unlock.sh" ;;
      6)
        echo
        echo "安装别名："
        echo "bash <(curl -fsSL \"https://raw.githubusercontent.com/Eric86777/vps-tcp-tune/main/install-alias.sh?\$(date +%s)\")"
        echo
        echo "重新加载配置："
        echo "source ~/.bashrc  # 或 source ~/.zshrc"
        echo
        echo "以后直接使用："
        echo "bbr"
        echo
        pause_enter
        ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_speedtest() {
  while true; do
    show_header
    echo -e "${C5}=== 测速脚本 ===${C0}"
    echo "1) Speedtest"
    echo "2) Taier"
    echo "3) hyperspeed"
    echo "4) 全球测速"
    echo "5) 区域速度测试"
    echo "6) Ping 和路由测试"
    echo "0) 返回"
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "Speedtest" "bash <(curl -sL bash.icu/speedtest)" ;;
      2) handle_item "Taier" "bash <(curl -sL res.yserver.ink/taier.sh)" ;;
      3) handle_item "hyperspeed" "bash <(curl -Lso- https://bench.im/hyperspeed)" ;;
      4) handle_item "全球测速" "wget -qO- nws.sh | bash" ;;
      5) handle_item "区域测速" "wget -qO- nws.sh | bash -s -- -r region_name" ;;
      6) handle_item "Ping 和路由测试" "wget -qO- nws.sh | bash -s -- -rt [region]" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_backtrace() {
  while true; do
    show_header
    echo -e "${C5}=== 回程测试 ===${C0}"
    echo "1) 直接显示回程（小白）"
    echo "2) 回程详细测试 AutoTrace"
    echo "3) testrace"
    echo "0) 返回"
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "backtrace" "curl https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh" ;;
      2) handle_item "AutoTrace" "wget -N --no-check-certificate https://raw.githubusercontent.com/Chennhaoo/Shell_Bash/master/AutoTrace.sh && chmod +x AutoTrace.sh && bash AutoTrace.sh" ;;
      3) handle_item "testrace" "wget https://ghproxy.com/https://raw.githubusercontent.com/vpsxb/testrace/main/testrace.sh -O testrace.sh && bash testrace.sh" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_functions() {
  while true; do
    show_header
    echo -e "${C5}=== 功能脚本 ===${C0}"
    echo "1) 添加 SWAP"
    echo "2) Fail2ban"
    echo "3) 一键开启 BBR"
