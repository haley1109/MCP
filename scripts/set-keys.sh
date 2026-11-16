#!/usr/bin/env bash
# 批量把 keys.env 里的凭据写入 DSH 凭据库（幂等，保留其它记录，权限 600）。
# 用法: ./scripts/set-keys.sh <keys.env>
set -euo pipefail

file="${1:-}"
if [ -z "$file" ]; then
  echo "用法: ./scripts/set-keys.sh <keys.env>" >&2
  exit 2
fi
if [ ! -f "$file" ]; then
  echo "找不到文件: $file" >&2
  exit 2
fi

dsh_home="${DSH_HOME:-$HOME/.dsh}"
store="$dsh_home/.credentials.yaml"
mkdir -p "$dsh_home"

if [ -f "$store" ]; then
  bak="$store.bak-$(date +%Y%m%d-%H%M%S)"
  cp -p "$store" "$bak"
  chmod 600 "$bak"
else
  printf 'version: 1\n' > "$store"
fi

tmp="$(mktemp "$dsh_home/.credentials.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
cp "$store" "$tmp"

trim() { printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }
unquote() {
  local v="$1"
  case "$v" in
    \"*\") if [ "${#v}" -ge 2 ]; then v="${v#\"}"; v="${v%\"}"; fi ;;
    \'*\') if [ "${#v}" -ge 2 ]; then v="${v#\'}"; v="${v%\'}"; fi ;;
  esac
  printf '%s' "$v"
}
yaml_value() { printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"; }

# 写一个 ref：存在则原位替换；有 refs 段则追加到该段末尾；否则新开一段。
set_ref() {
  local name="$1" value="$2" keyline next
  keyline="  ${name}: $(yaml_value "$value")"
  next="$(mktemp "$dsh_home/.credentials.XXXXXX")"
  if grep -qE "^[[:space:]]*${name}:" "$tmp"; then
    K="$keyline" awk -v n="$name" 'BEGIN { k = ENVIRON["K"] }
      $0 ~ "^[[:space:]]*" n ":" { print k; next }
      { print }' "$tmp" > "$next"
  elif grep -qE '^refs:[[:space:]]*$' "$tmp"; then
    K="$keyline" awk 'BEGIN { k = ENVIRON["K"] }
      /^refs:[[:space:]]*$/ { print; inrefs = 1; next }
      inrefs && /^[^[:space:]]/ { print k; inrefs = 0 }
      { print }
      END { if (inrefs) print k }
    ' "$tmp" > "$next"
  else
    K="$keyline" awk 'BEGIN { k = ENVIRON["K"]; d = 0 }
      { if (!d && $0 ~ /^version:/) { print; print "refs:"; print k; d = 1; next } print }
      END { if (!d) { print "refs:"; print k } }' "$tmp" > "$next"
  fi
  mv "$next" "$tmp"
}

count=0
skipped=0
while IFS= read -r raw || [ -n "$raw" ]; do
  line="$(trim "$raw")"
  case "$line" in
    '' | \#*) continue ;;
  esac
  case "$line" in
    *=*) ;;
    *) echo "跳过（缺少 =）: $line" >&2; skipped=$((skipped + 1)); continue ;;
  esac
  name="$(trim "${line%%=*}")"
  value="$(unquote "$(trim "${line#*=}")")"
  if ! [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "跳过（名字不合法）: $name" >&2; skipped=$((skipped + 1)); continue
  fi
  if [ -z "$value" ]; then
    echo "跳过（值为空）: $name" >&2; skipped=$((skipped + 1)); continue
  fi
  set_ref "$name" "$value"
  echo "已写入 $name"
  count=$((count + 1))
done < "$file"

chmod 600 "$tmp"
mv "$tmp" "$store"
chmod 600 "$store"
trap - EXIT

echo "完成：写入 $count 个凭据，跳过 $skipped 个。凭据库：$store"
