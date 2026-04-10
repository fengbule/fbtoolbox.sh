# VPS 工具箱

一个更聚焦的 Bash 菜单工具箱，收录常用 VPS 检测、重装、网络与安装入口。

仓库地址:

- https://github.com/fengbule/fbtoolbox

`fb` 子工具来源仓库:

- https://github.com/fengbule/zhuanfa

## 这次整理

- 移除了占位说明页、重复分类和明显偏题的入口
- 保留更常用、可直接执行的 VPS 脚本入口
- 直接运行时会自动安装 / 修复 `toolbox` 命令
- 增加 `version`、`update-self`、`check-links` 和 `uninstall-self` 命令
- 补充本地可跑的 smoke test

## 当前分类

- `fb` 端口转发
- DD 重装脚本
- 综合基准测试
- 性能测试
- 流媒体与 IP 质量
- 测速与路由
- 回程测试
- 系统与网络功能
- 环境与软件安装
- 综合工具脚本

## 直接运行

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/fbtoolbox/main/toolbox.sh)
```

上面这条会先自动安装 / 修复 `toolbox` 命令，然后进入菜单。

## 安装为本地命令

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fengbule/fbtoolbox/main/toolbox.sh) install-self
toolbox
```

Debian / Ubuntu 上会优先安装到 `/usr/local/bin/toolbox`；如果当前用户没有权限写入，会自动回落到 `~/.local/bin/toolbox` 或 `~/bin/toolbox`，并补齐 shell 的 `PATH` 配置。

也可以使用传统安装方式:

```bash
curl -fsSL https://raw.githubusercontent.com/fengbule/fbtoolbox/main/toolbox.sh | tr -d '\r' > /usr/local/bin/toolbox
chmod 755 /usr/local/bin/toolbox
toolbox
```

普通用户如果需要写入 `/usr/local/bin`，把上面两条写入命令前面加上 `sudo` 即可。

如果已经下载到本地，直接运行也会自动安装 / 修复 `toolbox` 命令:

```bash
bash toolbox.sh
```

如果安装后当前 shell 仍提示找不到 `toolbox`，先执行:

```bash
hash -r
```

安装完成后的管理命令统一使用 `toolbox`:

```bash
toolbox
toolbox help
toolbox version
toolbox update-self
toolbox check-links
toolbox uninstall-self
```

## 本地测试

```bash
bash tests/smoke.sh
```

只检查菜单里的远程 URL 是否可达，不执行第三方脚本:

```bash
bash toolbox.sh check-links
```

## 仓库配置

- `.gitattributes` 统一脚本和文档使用 `LF`
- `.editorconfig` 统一 `UTF-8`、末尾换行和缩进风格
- `.gitignore` 忽略本地编辑器垃圾和常见下载产物
- `.github/workflows/smoke.yml` 在 GitHub Actions 中自动跑 smoke test

## 说明

- 某些命令包含占位符，例如 `password`、`端口`、`region_name`，执行前建议先修改
- 远程脚本来自第三方仓库，运行前请自行判断风险
- DD、内核优化、网络改写一类命令都已标记为危险操作
- `toolbox check-links` 只做 URL 可达性检查，不执行第三方脚本；第三方服务临时故障时会给出警告
- Debian / Ubuntu 会优先尝试系统级安装，必要时自动回落到用户目录安装
- `toolbox uninstall-self` 只删除安装出来的命令文件，不回滚已经执行过的外部脚本或系统改动

## 换行控制

仓库根目录提供了 `.gitattributes`，强制脚本和文档使用 `LF`:

```gitattributes
*.sh text eol=lf
*.md text eol=lf
```
