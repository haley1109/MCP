# 新设备恢复口令

换设备后，把下面整段复制给新设备上的 DSH 智能体即可。它包含：装什么、密钥怎么给、怎么验收、失败怎么办。

---

```
请在这台设备上恢复我的 DSH 环境，按顺序执行，不要跳步，也不要新建重复插件。

1) 安装插件（用插件管理的 install_bundle，target 填）：
   - github:haley1109/MCP
   然后克隆技能仓库到固定位置（这个插件会扫描它）：
   - git clone git@github.com:haley1109/Skills.git ~/dsh-skills
   注意：克隆 Skills 需要该设备已配置 GitHub SSH key 或用 HTTPS。

2) 恢复密钥：我会把密钥或 keys.env 给你。拿到后执行：
   PKG=$(ls -d ~/.dsh/profiles/*/node_modules/@local/dsh-mcp-kit | head -1)
   "$PKG/scripts/set-keys.sh" <我给的 keys.env 路径>
   或者把单行 NAME=VALUE 直接交给脚本。密钥只写入 ~/.dsh/.credentials.yaml，
   不要在对话里回显，也不要写进任何仓库或文件。

3) 验收，两项都通过才算完成：
   - 调用 mcp__lingxing__help，应返回 700+ 个工具；
   - 技能目录里应出现我自定义的 skill（名字见 skills 仓库 README）。

4) 任何一步失败：保留完整错误原文，按对应仓库 README 的排错段落处理；
   不要重复安装、不要重复建仓库、不要改密钥以外的配置。
```

---

## 你这边的实际动作（人只做 2 件）

1. 复制上面那段发给新设备的智能体；
2. 从领星后台（或密码管理器）把密钥给它。

其余安装、写凭据、验证都由那台设备的智能体完成。

## 前提

- 新设备装好 DSH 并登录 DeepSeek 账号；
- 两个仓库都是公开的（否则新设备还要配 GitHub 认证）；
- 密钥与账号绑定：领星后台「AI 助手 → MCP → 复制密钥」随时可取，不用担心丢。

## 如果智能体没有插件管理工具

说明该会话的预设没有开 `plugin_manager`。此时手动走界面：**插件 → 添加插件**，分别填 `github:haley1109/MCP` 和 `github:haley1109/skills`，再让智能体执行第 2、3 步。
