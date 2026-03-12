import { PluginRegistry } from "@openclaw/plugin-sdk";
import { execSync } from "child_process";

export function onLoad(registry: PluginRegistry) {
  registry.registerTool({
    name: "get_project_list",
    description: "获取所有项目列表（用于判断项目归属）",
    inputSchema: {
      type: "object",
      properties: {},
    },
    handler: async () => {
      const output = execSync(
        "python3 ~/.openclaw/workspace/scripts/project-manager.py list --json",
        { encoding: "utf-8" }
      );
      return JSON.parse(output);
    }
  });
}
