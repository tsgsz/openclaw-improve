# Tool Contracts: task_sync

## Purpose

Synchronous task delegation - blocks until subagent completes and returns result inline.

## Input Schema

```typescript
{
  agent: string;        // Required: Target agent name
  task: string;         // Required: Task description
  timeout_ms?: number;  // Optional: Timeout in milliseconds (default: 300000)
}
```

## Output Schema

```typescript
{
  content: [
    {
      type: "text";
      text: string;  // Result from subagent
    }
  ]
}
```

## Error Cases

- **Timeout**: Returns error message after timeout_ms exceeded
- **Agent not found**: Returns error if agent doesn't exist
- **Subagent crash**: Returns error with crash details
- **Invalid params**: Returns error if agent or task is empty

## Example Usage

```typescript
// Success case
task_sync({ 
  agent: "professor", 
  task: "Research OpenClaw plugin architecture" 
})
// Returns: { content: [{ type: "text", text: "Research findings..." }] }

// Timeout case
task_sync({ 
  agent: "professor", 
  task: "Long running task",
  timeout_ms: 5000
})
// Returns: { content: [{ type: "text", text: "Error: Task timeout after 5000ms" }] }
```

## Behavioral Contract

1. MUST block until subagent completes or timeout
2. MUST return result inline (no task ID)
3. MUST NOT deliver result to main session
4. MUST extract final assistant message from subagent history
