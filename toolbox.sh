#!/usr/bin/env bash
set -Eeu -o pipefail

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
    echo
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
    echo
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
    echo
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
    echo
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
    echo
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
    echo
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
      1) handle_item "添加 SWAP" "wget https://www.moerats.com/usr/shell/swap.sh && bash swap.sh" ;;
      2) handle_item "Fail2ban" "wget --no-check-certificate https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/fail2ban.sh && bash fail2ban.sh 2>&1 | tee fail2ban.log" ;;
      3) handle_item "开启 BBR" "echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf && echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf && sysctl -p && sysctl net.ipv4.tcp_available_congestion_control && lsmod | grep bbr" "danger" ;;
      4) handle_item "多功能 BBR" "wget -N --no-check-certificate 'https://gist.github.com/zeruns/a0ec603f20d1b86de6a774a8ba27588f/raw/4f9957ae23f5efb2bb7c57a198ae2cffebfb1c56/tcp.sh' && chmod +x tcp.sh && ./tcp.sh" ;;
      5) handle_item "锐速/BBRPLUS/BBR2/BBR3" "wget -O tcpx.sh 'https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh' && chmod +x tcpx.sh && ./tcpx.sh" ;;
      6) handle_item "TCP 窗口调优" "wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh" ;;
      7) handle_item "添加 WARP" "wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]" ;;
      8) handle_item "25 端口测试" "telnet smtp.aol.com 25" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_installers() {
  while true; do
    show_header
    echo -e "${C5}=== 一键安装常用环境及软件 ===${C0}"
    echo "1) docker"
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
      1) handle_item "docker" "bash <(curl -sL 'https://get.docker.com')" ;;
      2) handle_item "Python" "curl -O https://raw.githubusercontent.com/lx969788249/lxspacepy/master/pyinstall.sh && chmod +x pyinstall.sh && ./pyinstall.sh" ;;
      3) handle_item "iperf3" "apt install iperf3" ;;
      4) handle_item "realm" "bash <(curl -L https://raw.githubusercontent.com/zhouh047/realm-oneclick-install/main/realm.sh) -i" ;;
      5) handle_item "gost" "wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh" ;;
      6) handle_item "极光面板" "bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh)" ;;
      7) handle_item "哪吒监控" "curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh" ;;
      8)
        echo
        echo "<script>"
        echo "window.ShowNetTransfer = true;"
        echo "window.FixedTopServerName = true;"
        echo "window.DisableAnimatedMan = true"
        echo "</script>"
        echo
        pause_enter
        ;;
      9) handle_item "WARP" "wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh" ;;
      10) handle_item "Aria2" "wget -N git.io/aria2.sh && chmod +x aria2.sh && ./aria2.sh" ;;
      11) handle_item "宝塔" "wget -O install.sh http://v7.hostcli.com/install/install-ubuntu_6.0.sh && sudo bash install.sh" "danger" ;;
      12) handle_item "PVE 虚拟化" "bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/pve/main/scripts/build_backend.sh)" "danger" ;;
      13) handle_item "Argox" "bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh)" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_allinone() {
  while true; do
    show_header
    echo -e "${C5}=== 综合功能脚本 ===${C0}"
    echo "1) 科技lion"
    echo "2) SKY-BOX"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "科技lion" "apt update -y && apt install -y curl && bash <(curl -sL kejilion.sh)" ;;
      2) handle_item "SKY-BOX" "wget -O box.sh https://raw.githubusercontent.com/BlueSkyXN/SKY-BOX/main/box.sh && chmod +x box.sh && clear && ./box.sh" ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_other() {
  while true; do
    show_header
    echo -e "${C5}=== 其它 ===${C0}"
    echo "1) TG 中文汉化"
    echo "2) awesome_docker（占位）"
    echo "3) TCP 迷之调参（占位）"
    echo "4) 去 Google 帮助中心报告 IP 问题（说明）"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1)
        echo
        echo "https://t.me/setlanguage/classic-zh-cn"
        echo
        pause_enter
        ;;
      2)
        echo
        echo "awesome_docker：你可以后续补具体仓库地址。"
        echo
        pause_enter
        ;;
      3)
        echo
        echo "TCP 迷之调参：你可以后续补具体链接。"
        echo
        pause_enter
        ;;
      4)
        echo
        echo "去 Google 帮助中心提交 IP 问题报告。"
        echo
        pause_enter
        ;;
      0) return 0 ;;
      *) warn "无效选择"; pause_enter ;;
    esac
  done
}

menu_smallcmd() {
  show_header
  echo -e "${C5}=== VPS 常备小命令 ===${C0}"
  echo
  echo "参考地址："
  echo "https://www.nodeseek.com/post-424648-1"
  echo
  pause_enter
}

menu_dufu() {
  while true; do
    show_header
    echo -e "${C5}=== 杜甫检测脚本 ===${C0}"
    echo "1) sick.onl"
    echo "2) Aniverse A"
    echo "3) nws.sh"
    echo "4) InstallNET Debian 12"
    echo "5) InstallNET Debian 12 RAID0"
    echo "6) InstallNET 指定网络 DD"
    echo "7) InstallNET 指定密码 DD"
    echo "8) hardware_info 中文"
    echo "9) 禁用 IPv6"
    echo "0) 返回"
    echo
    read -r -p "请选择 [1]: " n
    n="${n:-1}"
    case "$n" in
      1) handle_item "sick.onl" "curl -sL https://sick.onl | bash" ;;
      2) handle_item "Aniverse A" "wget https://github.com/Aniverse/A/raw/i/a && bash a" ;;
      3) handle_item "nws.sh" "wget -qO- nws.sh | bash" ;;
      4) handle_item "InstallNET Debian 12" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12" "danger" ;;
      5) handle_item "InstallNET RAID0" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -raid '0'" "danger" ;;
      6) handle_item "InstallNET 指定网络" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 --ip-addr 139.162.52.1 --ip-mask 24 --ip-gate 139.162.52.1 --ip6-addr 2a07:e040:2:1d3::1 --ip6-gate 2a07:e040::1 --ip6-mask 32" "danger" ;;
      7) handle_item "InstallNET 指定密码" "wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh && bash InstallNET.sh -debian 12 -pwd 'password'" "danger" ;;
      8) handle_item "hardware_info 中文" "curl -sL https://raw.githubusercontent.com/Yuri-NagaSaki/SICK/refs/heads/main/hardware_info.sh | bash -s -- -cn" ;;
      9) handle_item "禁用 IPv6" "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.default.disable_ipv6 = 1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf && sysctl -p" "danger" ;;
      0) return 0 ;;
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
      while true; do
        show_main_menu
        read -r -p "请选择分类 [1]: " n
        n="${n:-1}"
        case "$n" in
          1) menu_fb ;;
          2) menu_dd ;;
          3) menu_benchmark_all ;;
          4) menu_perf ;;
          5) menu_media ;;
          6) menu_speedtest ;;
          7) menu_backtrace ;;
          8) menu_functions ;;
          9) menu_installers ;;
          10) menu_allinone ;;
          11) menu_other ;;
          12) menu_smallcmd ;;
          13) menu_dufu ;;
          99) install_self; pause_enter ;;
          0) exit 0 ;;
          *) warn "无效选择"; pause_enter ;;
        esac
      done
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
