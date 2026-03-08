# Tool Contracts: task_check

## Purpose

Query status of async tasks - returns current state and results.

## Input Schema

```typescript
{
  task_id?: string;  // Optional: Specific task ID to check
}
```

## Output Schema

```typescript
// Single task query
{
  content: [
    {
      type: "text";
      text: string;  // JSON stringified Task object
    }
  ]
}

// All tasks query (no task_id provided)
{
  content: [
    {
      type: "text";
      text: string;  // JSON stringified array of Task objects
    }
  ]
}
```

## Error Cases

- **Task not found**: Returns error message if task_id doesn't exist

## Example Usage

```typescript
// Check specific task
task_check({ task_id: "task-1234567890-abc123" })
// Returns: { content: [{ type: "text", text: '{"taskId":"task-1234567890-abc123","status":"completed",...}' }] }

// Check all tasks
task_check()
// Returns: { content: [{ type: "text", text: '[{"taskId":"task-123","status":"running"},...}]' }] }
```

## Behavioral Contract

1. MUST return current status without blocking
2. MUST return all tasks if no task_id provided
3. MUST return JSON formatted output
4. MUST include result field if task completed
5. MUST include error field if task failed
