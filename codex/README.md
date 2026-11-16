# Codex MCP 配置与迁移

检查日期：2026-11-16（Asia/Shanghai）。机器可迁移的 MCP 配置、内置运行时和托管连接分别记录，避免把某台机器的内部路径或登录状态当成通用安装配置。

## 配置范围

- 用户配置：`xfa`、`xydc-mcp`、`node_repl`、`sif_mcp`，共 4 项。
- 可迁移模板：`config.example.toml` 包含 xfa、西柚、Sif，共 3 项。
- `node_repl` 的二进制路径、浏览器管道、服务路径和进程环境由 Codex 安装生成；在新设备安装对应 Codex 功能恢复，不复制旧机器配置。
- `codex_app`、`cua_repl` 来源于 Codex 已启用插件；artifact session、GitHub、Canva、Sites 等由宿主提供。完整盘点见 `inventory.json`，工具元数据出现不等于账号已授权或业务请求已成功。
- 领星是本仓库原有 DSH 配置，本次没有可调用的领星连接，因此保留并标记未验证。

## 恢复用户 MCP

1. 安装 Node.js 22 或以上及 npm；xfa 固定使用 `xlsx-for-ai@3.2.5`。它是托管 Excel API 的客户端，工具目录可用不代表所有业务功能和 API 权益可用。
2. 在系统的用户环境变量中设置 `XYDC_MCP_TOKEN`、`SIF_MCP_TOKEN`，值仅为 Token 本身，不带 `Bearer ` 前缀。环境变量属于本机凭据管理，不写入仓库；`codex/.env.example` 仅列出变量名，不会自动被 Codex 加载。
3. 将 `config.example.toml` 中的三个服务器块合并进 `~/.codex/config.toml`。同名服务器已存在时替换该服务器块，其他配置保留。模板不是完整 Codex 用户设置，不能覆盖整个文件。
4. 完全退出并重新启动 Codex，使其继承更新后的环境变量；运行 `codex mcp list` 检查声明，再分别验证连接和业务权限。

macOS/Linux 的 xfa 改为：

```toml
[mcp_servers.xfa]
enabled = true
command = "npx"
args = ["--yes", "--package=xlsx-for-ai@3.2.5", "xlsx-for-ai-mcp"]
startup_timeout_sec = 120
tool_timeout_sec = 120
```

Sif 已验证只通过 `Authorization: Bearer ...` 即可握手并列出工具，模板不保留原始 URL 的 `secret-key` 参数。Sif 的额度和订阅要在其服务端另行恢复，令牌存在和连接成功不能证明有业务用量。

## 宿主管理的连接

在新设备通过 Codex 的插件与应用设置安装所需功能，重新授权 GitHub、Canva、Sites 等需要账号连接的应用。不要复制应用登录状态、OAuth 凭据、SSH 私钥、原始 `auth.json` 或 Codex 数据库。`inventory.json` 中的工具数量是本次会话快照，不是服务永久规格。

## DSH 套件

仓库根目录仍是原有 DSH 套件，保留领星并新增西柚、Sif、xfa 声明。`keys.env.example` 列出三个远程服务的凭据名，可继续用原有 `scripts/set-keys.mjs` / `.sh` 写入 DSH 凭据库。Node REPL 和宿主功能不在 DSH 中重新注册。

DSH 补丁已做静态配置校验，本次未在 DSH 宿主启动验收；Codex 模板亦未覆盖当前本机配置。

## Git 地址

```text
git+ssh://git@github.com/haley1109/MCP.git
ssh://git@github.com/haley1109/MCP.git
https://github.com/haley1109/MCP.git
```

第一种用于支持该 URI 的包安装器；Git 命令使用第二或第三种。本次机器 SSH 返回 `Permission denied (publickey)`，因此发布使用已授权的 GitHub 连接。换设备需要自行配置 SSH 公钥授权。

## 官方说明

- [Codex MCP 配置](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)
- [插件、内置 MCP 与用户策略](https://developers.openai.com/plugins/build/plugins)
