---
name: benboerba-backup
description: 执行型技能（Runner）：benboerba-backup
---

> 运行说明：本技能为执行型技能，按当前 Runner 架构使用。

# Benboerba 备份技能

调用 benboerba-eternal 备份工具进行 backup 和 restore 操作。

## 用途

- **backup**: 备份 OpenClaw workspace 到 GitHub（benboerba）和本地 artifacts
- **restore**: 从 GitHub benboerba 仓库恢复备份

## 命令

### backup - 执行备份

```bash
python3 scripts/backup.py [--manifest <path>]
```

**参数**:
- `--manifest`: manifest.json 路径（默认: `~/workspace/benboerba-eternal/manifest.json`）

**流程**:
1. 执行 `benboerba_eternal.py backup` → 生成 artifacts 备份
2. 解压 artifacts → 重新加密 private 文件
3. 复制到 benboerba 仓库
4. git add/commit/push 到 GitHub

**输出**:
- ✅ 备份成功 → GitHub commit SHA
- ❌ 失败 → 错误信息

### restore - 恢复备份

```bash
python3 scripts/restore.py --repo <git-url> [--age-key <path>] [--dry-run]
```

**参数**:
- `--repo`: Git 仓库 URL 或本地路径（默认: `~/workspace/benboerba`）
- `--age-key`: age private key 路径（默认: `~/.openclaw/age.key`）
- `--dry-run`: 预览恢复内容，不实际执行

**流程**:
1. 克隆/拉取 benboerba 仓库
2. 解密并解压 private 文件
3. 对比文件差异（dry-run 时）
4. 执行恢复（需确认）

**输出**:
- dry-run: 显示哪些文件会被恢复
- 恢复: ✅ 完成

## 文件位置

- **主脚本**: `scripts/backup.py`, `scripts/restore.py`
- **benboerba-eternal**: `~/workspace/benboerba-eternal/`
- **备份仓库**: `~/workspace/benboerba/`

## 前置条件

1. `benboerba-eternal` 项目已配置（manifest.json 正确）
2. age key 已配置（`~/.openclaw/age.key`）
3. GitHub SSH key 已配置（有 push 权限）

## 示例

```bash
# 执行备份
python3 ~/.openclaw/workspace/skill-catalog/project/benboerba-backup/scripts/backup.py

# 预览恢复（不执行）
python3 ~/.openclaw/workspace/skill-catalog/project/benboerba-backup/scripts/restore.py --repo ~/workspace/benboerba --dry-run

# 从 GitHub 恢复
python3 ~/.openclaw/workspace/skill-catalog/project/benboerba-backup/scripts/restore.py --repo git@github.com:tsgsz/benboerba.git
```
