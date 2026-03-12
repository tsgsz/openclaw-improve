# 项目管理系统

## 目标

管理永久项目和临时项目，自动匹配和 git 管理。

## 数据结构

### project.json

位置: `~/.openclaw/workspace/projects/project.json`

```json
{
  "projects": {
    "my-app": {
      "name": "my-app",
      "path": "/Users/user/workspace/my-app",
      "type": "permanent",
      "createdAt": "2026-03-10T10:00:00Z",
      "description": "My web app"
    },
    "tmp-20260310-test": {
      "name": "tmp-20260310-test",
      "path": "/Users/user/.openclaw/workspace/projects/tmp-projects/tmp-20260310-test",
      "type": "temporary",
      "createdAt": "2026-03-10T10:00:00Z",
      "description": "Quick test"
    }
  }
}
```

## 目录结构

```
~/workspace/                    # 永久项目
└── <project-name>/

~/.openclaw/workspace/projects/
├── project.json               # 项目注册表
└── tmp-projects/              # 临时项目
    └── <project-name>/
```

## 项目管理脚本

位置: `~/.openclaw/bin/project-manager.py`

功能:
- `create` - 创建项目
- `list` - 列出所有项目（返回 JSON）
- `get` - 获取项目详情
- `delete` - 删除项目
- `cleanup` - 清理旧临时项目

**不包含 query 功能** - 项目匹配由 agent 完成

---

## 项目匹配流程

### 方案：orchestrator 判断项目

orchestrator 被 main spawn 后，自己判断项目归属。

#### orchestrator 工作流程

在 `~/.openclaw/agents/orchestrator/agent/AGENTS.md` 中定义：

```markdown
## 启动流程

1. 使用 `get_parent_context` 获取 main 的上下文
2. 使用 `get_main_memory` 获取 main 的 memory
3. **读取项目列表**: `python3 ~/.openclaw/bin/project-manager.py list --json`
4. **判断项目归属**:
   - 分析用户消息内容
   - 对比项目列表（名称 + 描述 + 创建时间）
   - 判断规则：
     - 用户明确指定项目名/路径 → 直接匹配
     - 语义上属于某个永久项目 → 匹配该项目
     - 语义上属于临时项目（1天内） → 匹配该项目
     - 语义上属于临时项目（超过1天） → 创建新临时项目
     - 完全无关 → 创建新临时项目或 no-project
5. **设置工作目录**: 根据判断结果设置后续 sub-agent 的 workspaceDir
6. 分析任务复杂度

## 项目判断示例

用户消息: "修复登录页面的bug"

项目列表:
- my-app: My web app (永久项目)
- data-analysis: Data analysis scripts (永久项目)
- tmp-20260310-test: Quick test (临时项目，创建于1天前)

判断: 属于 my-app → 使用 ~/workspace/my-app

用户消息: "写个脚本测试一下"

判断: 不属于任何项目 → 创建新临时项目 tmp-20260311-script-test
```

#### 后续 sub-agent spawn

orchestrator spawn 其他 agent 时，传递 workspaceDir：

```typescript
await sessions_spawn({
  agentId: "professor",
  task: "研究 JWT 最佳实践",
  workspaceDir: "/Users/user/workspace/my-app"  // 使用判断出的项目目录
});
```

## Plugin: project-loader

位置: `~/.openclaw/plugins/project-loader/`

**功能**: 提供项目和 agent 查询工具

```typescript
import { PluginRegistry } from "@openclaw/plugin-sdk";
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

export function onLoad(registry: PluginRegistry) {
  // 工具1: 获取项目列表
  registry.registerTool({
    name: "get_project_list",
    description: "获取所有项目列表（用于判断项目归属）",
    inputSchema: {
      type: "object",
      properties: {},
    },
    handler: async () => {
      const output = execSync(
        "python3 ~/.openclaw/bin/project-manager.py list --json"
      ).toString();
      return JSON.parse(output);
    }
  });

  // 工具2: 获取 functional agent 列表
  registry.registerTool({
    name: "get_functional_agents",
    description: "获取所有 functional agent 及其技能（用于规划调用哪些 sub-agent）",
    inputSchema: {
      type: "object",
      properties: {},
    },
    handler: async () => {
      const agentsDir = path.join(
        process.env.HOME || "",
        ".openclaw/agents"
      );
      
      const functionalAgents = [
        "professor", "systemhelper", 
        "scriptproducer", "reviewer", "watchdog"
      ];
      
      const result = {};
      
      // Native sub-agents
      for (const agentName of functionalAgents) {
        const agentMdPath = path.join(
          agentsDir, agentName, "agent/AGENTS.md"
        );
        
        if (fs.existsSync(agentMdPath)) {
          const content = fs.readFileSync(agentMdPath, "utf-8");
          
          // 提取职责和特点
          const lines = content.split("\n");
          let description = "";
          let skills = [];
          
          for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes("## 职责")) {
              description = lines[i + 1]?.trim() || "";
            }
            if (lines[i].includes("## 特点") || lines[i].includes("## 特有")) {
              // 提取后续的列表项
              for (let j = i + 1; j < Math.min(i + 10, lines.length); j++) {
                if (lines[j].startsWith("- ")) {
                  skills.push(lines[j].substring(2).trim());
                } else if (lines[j].startsWith("##")) {
                  break;
                }
              }
            }
          }
          
          result[agentName] = {
            type: "native",
            description,
            skills: skills.length > 0 ? skills : ["通用能力"]
          };
        }
      }
      
      // ACP agents
      result["opencode"] = {
        type: "acp",
        description: "大段编码、重构任务",
        skills: [
          "完整的代码编辑能力",
          "多文件重构",
          "代码生成"
        ],
        usage: "使用 sessions_spawn({ runtime: 'acp', agentId: 'opencode', ... })"
      };
      
      return result;
    }
  });
}
```
