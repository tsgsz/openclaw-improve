import { PluginRegistry } from "@openclaw/plugin-sdk";
import { execSync } from "child_process";

export function onLoad(registry: PluginRegistry) {
  registry.registerHook({
    name: "subagent_spawning",
    handler: async (event: any) => {
      const project = event.params.workspaceDir ? "detected" : "none";
      const eta = event.params.runTimeoutSeconds || 300;
      const timeout = 0;
      
      try {
        execSync(
          `python3 ~/.openclaw/workspace/scripts/runtime-monitor.py record "${event.childRunId}" "${event.sessionKey}" "${project}" ${eta} ${timeout}`,
          { encoding: "utf-8" }
        );
      } catch (err) {
        console.error("Failed to record spawn:", err);
      }
    }
  });
  
  registry.registerHook({
    name: "subagent_ended",
    handler: async (event: any) => {
      try {
        execSync(
          `python3 ~/.openclaw/workspace/scripts/runtime-monitor.py complete "${event.runId}"`,
          { encoding: "utf-8" }
        );
      } catch (err) {
        console.error("Failed to mark complete:", err);
      }
    }
  });
}
