# Quickstart: OpenClaw Task Dispatch Plugin

## Installation

```bash
cd ~/.openclaw/plugins
git clone <repo-url> task-dispatch
cd task-dispatch
npm install
npm run build
```

## Configuration

Edit `~/.openclaw/openclaw.json`:

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
        }
      },
      {
        "id": "orchestrator",
        "tools": {
          "allow": ["task_sync", "task_async", "task_check"]
        }
      }
    ]
  }
}
```

## Basic Usage

### Synchronous Task (Orchestrator only)

```typescript
// Blocks until complete
task_sync({ 
  agent: "professor", 
  task: "Research OpenClaw architecture" 
})
```

### Asynchronous Task

```typescript
// Returns immediately with task ID
task_async({ 
  agent: "professor", 
  task: "Research topic X" 
})

// Check status later
task_check({ task_id: "task-123..." })
```

### Coder with Project

```typescript
task_async({ 
  agent: "coder", 
  task: "Implement authentication",
  project_root: "/path/to/project",
  model: "openai/gpt-4"
})
```

## Migration from Current Setup

See FINAL-SOLUTION.md section 八 for detailed migration guide.

## Troubleshooting

- **Tool not found**: Ensure plugin is enabled in openclaw.json
- **Permission denied**: Check agent's tool allow/deny lists
- **Task timeout**: Increase timeout_ms parameter or plugin config
