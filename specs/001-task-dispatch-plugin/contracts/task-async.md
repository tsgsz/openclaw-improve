# Tool Contracts: task_async

## Purpose

Asynchronous task delegation - returns task ID immediately, tracks execution in background.

## Input Schema

```typescript
{
  agent: string;          // Required: Target agent name
  task: string;           // Required: Task description
  project_root?: string;  // Optional: Project directory (for coder agent)
  model?: string;         // Optional: AI model to use
  timeout_ms?: number;    // Optional: Timeout in milliseconds
}
```

## Output Schema

```typescript
{
  content: [
    {
      type: "text";
      text: string;  // Format: "Task started: {taskId}"
    }
  ]
}
```

## Error Cases

- **Agent not found**: Returns error if agent doesn't exist
- **Max concurrent reached**: Returns error if too many tasks running
- **Invalid params**: Returns error if agent or task is empty

## Example Usage

```typescript
// Regular subagent
task_async({ 
  agent: "professor", 
  task: "Research topic X" 
})
// Returns: { content: [{ type: "text", text: "Task started: task-1234567890-abc123" }] }

// Coder with project_root
task_async({ 
  agent: "coder", 
  task: "Implement auth",
  project_root: "/path/to/project",
  model: "openai/gpt-4"
})
// Returns: { content: [{ type: "text", text: "Task started: task-1234567891-def456" }] }
```

## Behavioral Contract

1. MUST return immediately with task ID
2. MUST register task in task registry
3. MUST use sessions_spawn for coder agent with ACP runtime
4. MUST use api.runtime.subagent.run for other agents
5. MUST set deliver=true for subagent.run (allows hook to fire)
