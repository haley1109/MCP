# DSH MCP 套件

一个 DSH 插件，集中声明并管理你使用的**所有** MCP 服务器。装一次，之后新增 MCP 只改配置、不用再装插件。

- 当前声明：领星 ERP、西柚洞察、Sif、xlsx-for-ai（Excel）
- Codex 配置与运行时清单：[codex/README.md](codex/README.md)
- 最新检查：[2026-11-16 MCP 检查报告](docs/mcp-audit-2026-11-16.md)；声明不代表业务调用已通过
- 承载方式：`@deepseek-ai/dsh-mcp-manager`，每个 MCP 是 `servers` 下的一项
- 鉴权：每个服务器用自己的凭据引用（`${credential:名字}`），**仓库内无任何密钥**

## 新设备安装（2 步）

> 想省事的话，直接把 [BOOTSTRAP.md](BOOTSTRAP.md) 里那段口令发给新设备的智能体，它会代你完成安装、写入密钥和验收。

### 1. 安装套件

DSH **插件 → 添加插件**，填：

```
github:haley1109/MCP
```

若该网络访问 github.com:443 超时，可使用已配置 SSH key 的设备改用 SSH 形式：

```
git+ssh://git@github.com/haley1109/MCP.git
```

公开仓库无需认证；SSH 形式需要该设备已配置 GitHub SSH key。

安装后插件列表出现「MCP 套件」。此时服务器已声明，但缺密钥。

### 2. 恢复密钥

把 `keys.env`（从密码管理器或上一台设备拿）放到任意位置，然后：

```bash
PKG=$(ls -d ~/.dsh/profiles/*/node_modules/@local/dsh-mcp-kit | head -1)
"$PKG/scripts/set-keys.sh" ~/keys.env
```

- 脚本按 `NAME=VALUE` 批量写入 `~/.dsh/.credentials.yaml` 的 `refs` 段
- 幂等：重复执行只覆盖对应项，保留其它记录；自动备份旧文件，权限 600
- DSH 监听该文件并自动重连，无需重启
- 没有 bash 的环境（如 Windows）可用 `node "$PKG/scripts/set-keys.mjs" keys.env`

`keys.env` 模板见 `keys.env.example`，它**不会**被提交（`.gitignore`）。

验证：让智能体调用 `mcp__lingxing__help`，返回工具列表即接通。

## 本地技能源（skills）

本插件同时启用 DSH 的文件系统技能提供器（`skill-filesystem`），扫描：

```
~/dsh-skills/skills/<名字>/SKILL.md
```

`~/dsh-skills` 是 `git@github.com:haley1109/Skills.git` 的克隆（91 个 skill）。

**新设备**：

```bash
git clone git@github.com:haley1109/Skills.git ~/dsh-skills
```

**更新技能**：

```bash
git -C ~/dsh-skills pull --ff-only
```

有文件监听，`pull` 之后目录自动刷新，无需重启。

注意：

- 只扫描 `skills/<名字>/SKILL.md` 这一层；`references/source-original/SKILL.md` 不会被当成独立技能。
- 同名技能按来源优先级取胜：项目 `.dsh/skills`(100) > `.agents/skills`(200) > 自定义目录(300，即本仓库) > `~/.dsh/skills`(400) > `~/.agents/skills`(500) > 内置(600)。
- **成本提示**：91 个技能的 description 合计约 23 KB（≈7–8K tokens），会进入每次请求的技能目录。觉得太重可以精简 `<repo>/skills/*/SKILL.md` 的 description。
- 换设备若不想克隆到 `~/dsh-skills`，改 `cordis.patch.yml` 里那条 `!!js` 的路径即可。

## 新增一个 MCP（3 步）

1. 在 `cordis.patch.yml` 的 `servers:` 下加一块：

```yaml
      newsource:
        transport: streamable-http
        url: https://example.com/mcp
        headers:
          Authorization: 'Bearer ${credential:NEWSOURCE_TOKEN}'
```

2. 在 `keys.env.example` 加一行 `NEWSOURCE_TOKEN=`，并在本机 `keys.env` 填值；
3. 提交推送，各设备更新插件 + 跑一次 `set-keys.sh`。工具会以 `mcp__newsource__*` 出现。

stdin 型的 MCP 用 `transport: stdio` + `command` / `args` / `env` 代替 `url` / `headers`。

xlsx-for-ai 使用固定 npm 版本 `xlsx-for-ai@3.2.5`，需要 Node.js 22 或以上和 npm；首次启动需要访问 npm。现有 DSH 凭据脚本支持新增的 `XYDC_MCP_TOKEN` 和 `SIF_MCP_TOKEN`，不用改脚本。Sif 使用认证头，不在 URL 中附加密钥。Node REPL、Codex App、电脑控制及托管应用由 Codex 管理，迁移说明见 `codex/README.md`，不放入 DSH 的服务器声明。

## 密钥与本机状态

| 内容 | 是否跟随设备 | 做法 |
|---|---|---|
| 服务器声明（本仓库） | 跟随 | 新设备装一次插件 |
| 各服务器密钥 | 不跟随 | `keys.env` + `set-keys.sh`，或手动写 `~/.dsh/.credentials.yaml` |
| 插件启用状态、会话历史 | 不跟随 | DSH 本地状态，一般无需迁移 |

密钥与账号绑定、不绑定设备，可在多台设备复用。若在服务方后台重新生成密钥，**所有设备上的旧值同时失效**，需逐台更新 `keys.env` 后重跑脚本。

## 密钥备份与恢复

本机已生成一份填好的 `~/keys.env`（权限 600）。**建议整段存进密码管理器后删除本地文件**：

1. 打开 `~/keys.env`，把 `NAME=VALUE` 行存进 1Password / 备忘录等安全条目（标题可用 `dsh-mcp-kit keys`）；
2. 删除本地副本：`rm ~/keys.env`；
3. 新设备上把内容另存为 `keys.env`，跑一次 `set-keys.sh` 即可。

macOS 不想装 1Password CLI 时，可以用系统钥匙串：

```bash
# 存入（首次执行会要求输入登录密码）
security add-generic-password -a "$USER" -s "dsh-mcp-kit" -w "$(cat ~/keys.env)" -U
# 取出
security find-generic-password -a "$USER" -s "dsh-mcp-kit" -w > ~/keys.env
```

装了 1Password CLI（`op`）后，也可以按需 `op read op://<vault>/<item>/<field>` 取单个值再写入。

### keys.env 丢了怎么办

它只是副本，**不影响正在运行的连接**（DSH 实际读的是 `~/.dsh/.credentials.yaml`）。按情况恢复：

```bash
# 机器还在：从凭据库一条命令重建
PKG=$(ls -d ~/.dsh/profiles/*/node_modules/@local/dsh-mcp-kit | head -1)
"$PKG/scripts/export-keys.sh" ~/keys.env
```

- 连机器也没了 / 换了新设备：去领星后台「AI 助手 → MCP → 复制密钥」重新拿一次即可（密钥绑账号，随时可取），再跑 `set-keys.sh`。
- 优先用「复制密钥」而不是「重新生成」：后者会让**所有设备**上的旧值同时失效。

## 更新与回滚

- 更新：改完推送，各设备在插件页更新套件；
- 回滚：`git revert` 后同样更新插件；
- 改变某个服务器的 `serverName` 会改变工具名；删除一块 `servers` 会断开该服务器。

## 注意与限制

- `servers` 是**整表声明**：不要在 profile 的 `cordis.patch.yml` 里手工再加服务器，统一改本仓库；临时停用某项写 `enabled: false`。
- 管理器条目没有 `failOnStartupError`：密钥错时表现为该服务器连接失败、状态可见，而不是启动即报错。
- 数据范围等于各服务账号自身的权限；领星限速 100 次/分钟。
- 写类操作可能触发服务方审批，用对应工具查询结果。
