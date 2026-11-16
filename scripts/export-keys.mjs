#!/usr/bin/env node
// 从 DSH 凭据库反向导出 keys.env（用于备份或换设备）。与 export-keys.sh 行为一致。
// 用法: node scripts/export-keys.mjs [输出路径]   默认 ~/keys.env
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const out = process.argv[2] || path.join(os.homedir(), 'keys.env');
const store = path.join(process.env.DSH_HOME || path.join(os.homedir(), '.dsh'), '.credentials.yaml');

if (!fs.existsSync(store)) {
  console.error(`找不到凭据库: ${store}`);
  process.exit(2);
}

const lines = fs.readFileSync(store, 'utf8').split('\n');
const refsIdx = lines.findIndex((l) => /^refs:[ \t]*$/.test(l));
if (refsIdx < 0) {
  console.error('凭据库里没有 refs 段，无需导出。');
  process.exit(1);
}

const unquote = (raw) => {
  const v = raw.trim();
  if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) {
    return v.slice(1, -1).replace(/\\\\/g, '\\').replace(/\\"/g, '"');
  }
  return v;
};

const rows = [];
for (let i = refsIdx + 1; i < lines.length; i += 1) {
  const line = lines[i];
  if (/^[^ \t]/.test(line)) break;
  const m = /^  ([A-Za-z_][A-Za-z0-9_]*):(.*)$/.exec(line);
  if (m) rows.push(`${m[1]}=${unquote(m[2])}`);
}

if (!rows.length) {
  console.error('refs 段为空，无需导出。');
  process.exit(1);
}

const body = [
  `# DSH MCP 套件凭据 — 导出于 ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`,
  '# 请存入密码管理器后删除本文件。',
  ...rows,
  '',
].join('\n');

fs.writeFileSync(out, body, { mode: 0o600 });
fs.chmodSync(out, 0o600);

console.log(`已导出到 ${out}（权限 600），包含：`);
for (const r of rows) console.log(`  - ${r.split('=')[0]}`);
