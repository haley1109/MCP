#!/usr/bin/env node
// 批量把 keys.env 里的凭据写入 DSH 凭据库（幂等，保留其它记录）。与 set-keys.sh 行为一致。
// 用法: node scripts/set-keys.mjs <keys.env>
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const file = process.argv[2];
if (!file) {
  console.error('用法: node scripts/set-keys.mjs <keys.env>');
  process.exit(2);
}
if (!fs.existsSync(file)) {
  console.error(`找不到文件: ${file}`);
  process.exit(2);
}

const home = process.env.DSH_HOME || path.join(os.homedir(), '.dsh');
const store = path.join(home, '.credentials.yaml');
fs.mkdirSync(home, { recursive: true });
if (!fs.existsSync(store)) {
  fs.writeFileSync(store, 'version: 1\n', { mode: 0o600 });
} else {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backup = `${store}.bak-${stamp}`;
  fs.copyFileSync(store, backup);
  fs.chmodSync(backup, 0o600);
}

let text = fs.readFileSync(store, 'utf8');
const yamlValue = (v) => `"${v.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
const unquote = (v) => {
  if (v.length >= 2 && ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'")))) {
    return v.slice(1, -1);
  }
  return v;
};

function setRef(name, value) {
  const entry = `  ${name}: ${yamlValue(value)}`;
  const lines = text.split('\n');

  const existing = lines.findIndex((l) => new RegExp(`^\\s*${name}:`).test(l));
  if (existing >= 0) {
    lines[existing] = entry;
    text = lines.join('\n');
    return;
  }

  const refsIdx = lines.findIndex((l) => /^refs:[ \t]*$/.test(l));
  if (refsIdx >= 0) {
    let end = refsIdx + 1;
    while (end < lines.length && (lines[end].trim() === '' || /^[ \t]/.test(lines[end]))) end += 1;
    lines.splice(end, 0, entry);
    text = lines.join('\n');
    return;
  }

  const versionIdx = lines.findIndex((l) => /^version:/.test(l));
  const at = versionIdx >= 0 ? versionIdx + 1 : 0;
  lines.splice(at, 0, 'refs:', entry);
  text = lines.join('\n');
}

let written = 0;
let skipped = 0;
for (const raw of fs.readFileSync(file, 'utf8').split('\n')) {
  const line = raw.trim();
  if (!line || line.startsWith('#')) continue;
  const at = line.indexOf('=');
  if (at < 0) {
    console.error(`跳过（缺少 =）: ${line}`);
    skipped += 1;
    continue;
  }
  const name = line.slice(0, at).trim();
  const value = unquote(line.slice(at + 1).trim());
  if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) {
    console.error(`跳过（名字不合法）: ${name}`);
    skipped += 1;
    continue;
  }
  if (!value) {
    console.error(`跳过（值为空）: ${name}`);
    skipped += 1;
    continue;
  }
  setRef(name, value);
  console.log(`已写入 ${name}`);
  written += 1;
}

fs.writeFileSync(store, text, { mode: 0o600 });
fs.chmodSync(store, 0o600);
console.log(`完成：写入 ${written} 个凭据，跳过 ${skipped} 个。凭据库：${store}`);
