# DSH MCP 套件

一个 DSH 插件，集中声明并管理你使用的**所有** MCP 服务器。装一次，之后新增 MCP 只改配置、不用再装插件。

- 当前包含：领星 ERP 官方 MCP（`mcp__lingxing__*`）
- 承载方式：`@deepseek-ai/dsh-mcp-manager`，每个 MCP 是 `servers` 下的一项
- 鉴权：每个服务器用自己的凭据引用（`${credential:名字}`），**仓库内无任何密钥**

## 新设备安装（2 步）

### 1. 安装套件

DSH **插件 → 添加插件**，填：

```
github:haley1109/MCP
```

公开仓库无需认证；私有仓库需要该设备能访问仓库（SSH key 或 token）。

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

## 更新与回滚

- 更新：改完推送，各设备在插件页更新套件；
- 回滚：`git revert` 后同样更新插件；
- 改变某个服务器的 `serverName` 会改变工具名；删除一块 `servers` 会断开该服务器。

## 注意与限制

- `servers` 是**整表声明**：不要在 profile 的 `cordis.patch.yml` 里手工再加服务器，统一改本仓库；临时停用某项写 `enabled: false`。
- 管理器条目没有 `failOnStartupError`：密钥错时表现为该服务器连接失败、状态可见，而不是启动即报错。
- 数据范围等于各服务账号自身的权限；领星限速 100 次/分钟。
- 写类操作可能触发服务方审批，用对应工具查询结果。
