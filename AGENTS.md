# AGENTS.md - OpenClaw Improve Project

## Project Overview

This is the **OpenClaw Enhanced Edition** (Openclaw 增强形态) - a plugin-based enhancement system for OpenClaw that adds spawn monitoring, project management, and multi-agent orchestration capabilities.

**CRITICAL**: This project follows a **Zero-Invasion Principle** - all enhancements MUST be implemented as external OpenClaw plugins. Direct modification of OpenClaw core code is strictly forbidden.

## Build/Test/Lint Commands

This is a documentation and design project with no build system. The implementation will be done through:

- **Plugin Development**: Uses `@opencode-ai/plugin` (v1.2.24) from `.opencode/package.json`
- **Hook Development**: TypeScript handlers in `~/.openclaw/hooks/<hook-name>/handler.ts`
- **Script Development**: Bash/Python scripts for monitoring and project management

### Testing Approach

Since this is a plugin/hook system:
- Manual testing via OpenClaw CLI commands
- Integration testing by spawning agents and observing behavior
- Hook testing by triggering events and verifying handler execution

## Code Style Guidelines

### Language & Format

- **Primary Languages**: TypeScript (plugins/hooks), Bash/Python (scripts), Markdown (documentation)
- **Documentation Language**: Chinese (中文) for user-facing docs, English for code comments
- **File Organization**: 
  - `/docs/` - Design documentation
  - `/.specify/` - Templates and scripts for feature development
  - `/AGENTS.md` - This file (agent guidelines)
  - `/README.md` - Project overview


### Documentation Style

- Use Markdown for all documentation
- Chinese for design docs (README.md, docs/)
- English for code comments and technical specs
- Include examples for all APIs and tools


## Development Workflow

### Using .specify Templates

This project uses the `.specify/` system for structured feature development:

1. **Create Feature Spec**: Use `/speckit.specify` to create `spec.md`
2. **Generate Plan**: Use `/speckit.plan` to create `plan.md`
3. **Generate Tasks**: Use `/speckit.tasks` to create `tasks.md`
4. **Implement**: Use `/speckit.implement` to execute tasks

### Constitution Compliance

All implementations MUST comply with `.specify/memory/constitution.md`:

1. **Zero-Invasion**: No OpenClaw core modifications
2. **Migration-First**: Include migration plan for existing users
3. **Test-Driven Simplicity**: Write tests first, use simplest mechanism

## References

- **OpenClaw Docs**: Check official documentation: https://docs.openclaw.ai/start/getting-started
- **Openclaw Source**: Check official sourcecode of Openclaw in https://github.com/openclaw/openclaw/tree/main/src
- **Hook Events**: See `docs/00-overview.md` for complete hook list
- **Agent Configs**: See `docs/03-agent-design.md` for agent setup details
- **Constitution**: See `.specify/memory/constitution.md` for development principles

## Scripts 组织规范

参考 ~/.openclaw/workspace/scripts/README.md：
- scripts/ 顶层不放脚本文件
- 按功能分组：tools/, governance/, services/, tunnels/
- skill 专属脚本放在 skills/<name>/ 目录下

## Skills 组织规范

SKILL.md 必须包含 YAML frontmatter：name, description, user-invocable, allowed-tools, metadata
