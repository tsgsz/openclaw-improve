import { TaskRegistry } from '../registry/task-registry';

export function createSubagentEndedHandler(api: any, registry: TaskRegistry) {
  return async (event: any) => {
    if (!event.targetSessionKey) {
      console.warn('[task-dispatch] subagent_ended: missing targetSessionKey');
      return;
    }

    let found = false;
    for (const task of registry.getAll()) {
      if (task.sessionKey === event.targetSessionKey) {
        found = true;
        if (event.outcome === "success") {
          const { messages } = await api.runtime.subagent.getSessionMessages({
            sessionKey: event.targetSessionKey,
            limit: 100
          });
          
          const reversed = [...messages].reverse();
          const lastAssistant = reversed.find((m: any) => m.role === "assistant");
          const result = lastAssistant?.content || "No result";

          registry.set(task.taskId, {
            ...task,
            status: "completed",
            result,
            completedAt: Date.now()
          });
        } else {
          registry.set(task.taskId, {
            ...task,
            status: "failed",
            error: event.error || "Unknown error",
            completedAt: Date.now()
          });
        }
        break;
      }
    }

    if (!found) {
      console.warn(`[task-dispatch] subagent_ended: unknown sessionKey ${event.targetSessionKey}`);
    }
  };
}
