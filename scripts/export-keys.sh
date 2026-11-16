#!/usr/bin/env bash
# 从 DSH 凭据库反向导出 keys.env（用于备份或换设备）。
# 用法: ./scripts/export-keys.sh [输出路径]   默认 ~/keys.env
set -euo pipefail

out="${1:-$HOME/keys.env}"
store="${DSH_HOME:-$HOME/.dsh}/.credentials.yaml"

if [ ! -f "$store" ]; then
  echo "找不到凭据库: $store" >&2
  exit 2
fi

rows="$(
  awk '
    /^refs:[[:space:]]*$/ { inrefs = 1; next }
    inrefs && /^[^[:space:]]/ { exit }
    inrefs && /^  [A-Za-z_][A-Za-z0-9_]*:/ {
      line = $0
      sub(/^  /, "", line)
      name = line
      sub(/:.*$/, "", name)
      val = line
      sub(/^[^:]*:[[:space:]]*/, "", val)
      if (val ~ /^".*"$/) {
        val = substr(val, 2, length(val) - 2)
        gsub(/\\\\/, "\\", val)
        gsub(/\\"/, "\"", val)
      }
      print name "=" val
    }
  ' "$store"
)"

if [ -z "$rows" ]; then
  echo "凭据库里没有 refs 条目，无需导出。" >&2
  exit 1
fi

umask 077
{
  echo "# DSH MCP 套件凭据 — 导出于 $(date '+%Y-%m-%d %H:%M')"
  echo "# 请存入密码管理器后删除本文件。"
  printf '%s\n' "$rows"
} > "$out"
chmod 600 "$out"

echo "已导出到 $out（权限 600），包含："
printf '%s\n' "$rows" | cut -d= -f1 | sed 's/^/  - /'
