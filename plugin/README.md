# OpenClaw Task Dispatch Plugin

Reliable task delegation plugin for OpenClaw with synchronous and asynchronous support.

## Features

- **task_sync**: Synchronous task delegation with guaranteed result delivery
- **task_async**: Asynchronous task tracking with parallel execution support
- **task_check**: Query task status and results
- **Dynamic project/model support**: Flexible multi-project workflows
- **LRU task registry**: Bounded memory usage with automatic cleanup

## Installation

```bash
cd ~/.openclaw/plugins
git clone <repo-url> task-dispatch
cd task-dispatch
npm install
npm run build
```

## Quick Start

### Basic Usage

**Synchronous task (Orchestrator)**:
```typescript
task_sync({ agent: "professor", task: "research OpenClaw architecture" })
```

**Asynchronous task**:
```typescript
task_async({ agent: "professor", task: "research topic X" })
task_check({ task_id: "task-..." })
```

**Coder with project**:
```typescript
task_async({ 
  agent: "coder", 
  task: "implement auth",
  project_root: "/path/to/project",
  model: "openai/gpt-4"
})
```

## Configuration

Add to `~/.openclaw/openclaw.json`:

```json
{
  "plugins": {
    "task-dispatch": {
      "enabled": true,
      "config": {
        "taskTimeout": 300000,
        "maxConcurrentTasks": 10,
        "maxRegistrySize": 1000
      }
    }
  },
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "tools": {
          "allow": ["task_async"],
          "deny": ["task_sync", "sessions_spawn"]
        },
        "subagents": { "allowAgents": ["orchestrator"] }
      },
      {
        "id": "orchestrator",
        "tools": {
          "allow": ["task_sync", "task_async", "task_check"]
        },
        "subagents": { "allowAgents": ["professor", "coder"] }
      }
    ]
  }
}
```

### Tool Access Control

Configure which agents can use which tools via the `tools` section:

- **allow**: Whitelist of allowed tools
- **deny**: Blacklist of denied tools (takes precedence)

Example: Main agent can only use `task_async`, cannot use `task_sync` or `sessions_spawn` directly.

## Usage

See quickstart guide in project documentation.

## Migration Guide

### Current State Analysis

If you're currently using:
- Direct `sessions_spawn` calls from main agent
- Custom subagent management without guaranteed delivery
- Manual task tracking without centralized registry

### Target State

After migration:
- Main agent uses `task_async` for delegation
- Orchestrator uses `task_sync`/`task_async` for coordination
- Automatic task tracking via plugin registry
- Guaranteed result delivery via hooks

### Migration Steps

1. **Install Plugin**:
   ```bash
   cd ~/.openclaw/plugins/task-dispatch
   npm install && npm run build
   ```

2. **Update openclaw.json**:
   - Add plugin configuration (see Configuration section)
   - Update agent tool permissions
   - Configure main agent: `allow: ["task_async"]`, `deny: ["sessions_spawn"]`
   - Configure orchestrator: `allow: ["task_sync", "task_async", "task_check"]`

3. **Update Agent Prompts**:
   - Replace `sessions_spawn` calls with `task_async`
   - Add `task_check` for status queries
   - Use `task_sync` in orchestrator for sequential workflows

4. **Test Migration**:
   - Run existing workflows
   - Verify task delegation works
   - Check task tracking via `task_check`

### Rollback Procedure

If issues occur:
1. Disable plugin in openclaw.json: `"enabled": false`
2. Revert agent tool permissions
3. Restart OpenClaw
4. Original `sessions_spawn` behavior restored
