# VPS 工具箱

一个更聚焦的 Bash 菜单工具箱，收录常用 VPS 检测、重装、网络与安装入口。

仓库地址:

- https://github.com/fengbule/fbtoolbox.sh

`fb` 子工具来源仓库:

- https://github.com/fengbule/zhuanfa

## 这次整理

- 移除了占位说明页、重复分类和明显偏题的入口
- 保留更常用、可直接执行的 VPS 脚本入口
- 增加 `version` 和 `update-self` 命令
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

安装完成后的管理命令统一使用 `toolbox`:

```bash
toolbox
toolbox help
toolbox version
toolbox update-self
```

## 本地测试

```bash
bash tests/smoke.sh
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

## 换行控制

仓库根目录提供了 `.gitattributes`，强制脚本和文档使用 `LF`:

```gitattributes
*.sh text eol=lf
*.md text eol=lf
```
