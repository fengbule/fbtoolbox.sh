# VPS 工具箱

一个按分类整理的 Bash 菜单工具箱，收录常用 VPS 脚本、检测命令和安装入口。

仓库地址:

- https://github.com/fengbule/fbtoolbox.sh

`fb` 子工具来源仓库:

- https://github.com/fengbule/zhuanfa

## 功能特点

- 可视化数字菜单，按分类进入不同脚本集合
- 每条命令都支持先查看，再决定是否执行
- 危险操作会二次确认，需要手动输入 `YES`
- 支持安装成 `toolbox` 命令
- 已按 Linux Bash 场景整理为 `UTF-8`、无 BOM、`LF` 换行

## 当前分类

- `fb` 端口转发
- DD 重装脚本
- 综合测试脚本
- 性能测试
- 流媒体及 IP 质量测试
- 测速脚本
- 回程测试
- 功能脚本
- 一键安装常用环境及软件
- 综合功能脚本
- 其它
- VPS 常备小命令
- 杜甫检测脚本

## 直接运行

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/fbtoolbox.sh/main/toolbox.sh)
```

## 安装为本地命令

```bash
curl -fsSL https://raw.githubusercontent.com/fengbule/fbtoolbox.sh/main/toolbox.sh | tr -d '\r' > /usr/local/bin/toolbox
chmod 755 /usr/local/bin/toolbox
toolbox
```

如果已经下载到本地，也可以执行:

```bash
bash toolbox.sh install-self
```

## 说明

- 某些命令包含占位符，例如 `password`、`端口`、`region_name`，执行前建议先修改
- 远程脚本来自第三方仓库，运行前请自行判断风险
- DD、内核优化、网络改写一类命令都已标记为危险操作

## 换行控制

仓库根目录提供了 `.gitattributes`，强制脚本和文档使用 `LF`:

```gitattributes
*.sh text eol=lf
*.md text eol=lf
```
