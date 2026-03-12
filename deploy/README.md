# 部署脚本

本目录包含 Openclaw 增强形态的部署脚本。

## 使用方法

### 基本安装
```bash
# 默认安装到 ~/.openclaw
./deploy/install.sh

# 指定安装目录
./deploy/install.sh --openclaw-home /custom/path

# 使用环境变量
export OPENCLAW_HOME=/custom/path
./deploy/install.sh
```

### 测试环境安装（推荐）
```bash
# 使用独立测试目录，不影响生产环境
export OPENCLAW_HOME=/tmp/openclaw-test
./deploy/install.sh
# 测试...
./deploy/uninstall.sh
```

### 创建 Agents
```bash
./deploy/create-agents.sh
```

### 更新
```bash
./deploy/update.sh
```

### 卸载
```bash
# 默认卸载 ~/.openclaw
./deploy/uninstall.sh

# 指定目录卸载
./deploy/uninstall.sh --openclaw-home /custom/path
```

## 部署目标

- `~/.openclaw/workspace/system/openclaw-enhance/` - 独立系统目录（所有实际内容）
- `~/.openclaw/workspace/skills/` - Skills 软链
- `~/.openclaw/hooks/` - Hooks 软链
- `~/.openclaw/plugins/` - Plugins 链接安装
- `~/.openclaw/workspace/functional-workspace/` - Agent 引用配置
- `~/.openclaw/workspace/domain-workspace/` - Agent 引用配置

## 部署架构

### 独立系统目录
```
~/.openclaw/workspace/system/openclaw-enhance/
├── agents/              # agent 配置
├── skills/              # skills 实际内容
├── hooks/               # hooks 实际内容
├── plugins/             # plugins 实际内容
├── backups/             # 冲突备份
│   ├── skills/
│   ├── hooks/
│   └── plugins/
└── manifest.json        # 安装清单
```

### 部署策略

**Agents**: 文件引用
- 修改 AGENTS.md 添加引用行（只修改一次）
- 实际配置在 `system/openclaw-enhance/agents/`

**Skills/Hooks**: 软链
- 检测冲突 → 询问用户
- 覆盖：备份原文件到 `backups/` → 创建软链
- 跳过：记录到 manifest

**Plugins**: 链接安装
- 检测冲突 → 询问用户
- 使用 `openclaw plugins install --link`

### Manifest 记录
- 所有部署项（agents/skills/hooks/plugins）
- 冲突和备份信息
- 升级时保留历史记录

### 安全保证

**AGENTS.md 保护**
- 已有内容：备份后追加引用（不覆盖）
- 新创建：直接写入，卸载时删除
- 卸载：还原备份或删除新建文件

**冲突处理**
- 检测已存在的 skills/hooks/plugins
- 询问用户是否覆盖
- 覆盖前自动备份到 `backups/<type>/<name>-<timestamp>`

**完整还原**
1. 删除所有软链
2. 还原所有备份
3. 卸载 plugins/hooks（使用官方命令）
4. 删除系统目录
5. 完全还原，无残留

**注意事项**
- ⚠️ 不要手动删除 `system/openclaw-enhance/` 目录
- ✅ 始终使用 `uninstall.sh` 卸载
- ✅ 测试时使用独立目录

## 完整部署流程

1. 安装组件: `./deploy/install.sh`
   - 部署脚本到 ~/.openclaw/workspace/scripts/
   - 使用 `openclaw plugins install --link` 安装插件
   - 部署 agent 配置文件
2. 创建 agents: `./deploy/create-agents.sh`
3. 重启 OpenClaw Gateway
4. 测试验证

## 开发流程

1. 在 `/src/` 目录开发
2. 运行 `./tests/run-all-tests.sh` 测试
3. 运行 `./deploy/install.sh` 部署
4. 运行 `./deploy/create-agents.sh` 创建 agents
5. 测试部署效果
6. 迭代开发
