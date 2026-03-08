# Implementation Plan: OpenClaw Task Dispatch Plugin

**Branch**: `001-task-dispatch-plugin` | **Date**: 2026-03-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-task-dispatch-plugin/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement an OpenClaw plugin that provides reliable task delegation tools (task_sync, task_async, task_check) to solve subagent communication failures. The plugin uses OpenClaw's native hook system (subagent_ended) and runtime APIs to track task execution without modifying core code. Supports dynamic project_root and model parameters for flexible multi-project workflows.

## Technical Context

**Language/Version**: TypeScript 5.x (OpenClaw plugin standard)
**Primary Dependencies**: OpenClaw Plugin API, OpenClaw Runtime API
**Storage**: In-memory Map (task registry), no persistent storage required
**Testing**: Manual integration tests with OpenClaw installation
**Target Platform**: Node.js (OpenClaw runtime environment)
**Project Type**: OpenClaw plugin (npm package)
**Performance Goals**: Zero latency overhead on task dispatch, <10ms hook processing
**Constraints**: Zero-invasion (no OpenClaw core modifications), plugin-only implementation
**Scale/Scope**: Support 10+ concurrent async tasks, handle 1000+ task registry entries

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Zero-Invasion Principle
- ✅ **PASS**: Plugin-only implementation, no OpenClaw core modifications
- ✅ **PASS**: Uses only OpenClaw Plugin API (tools, hooks, runtime APIs)
- ✅ **PASS**: No monkey-patching or internal access

### II. Migration-First Principle
- ✅ **PASS**: Migration guide included in spec (User Story 5)
- ✅ **PASS**: Current state documented in FINAL-SOLUTION.md
- ✅ **PASS**: Target state clearly defined with agent configurations
- ⚠️ **PENDING**: Rollback procedure to be documented in Phase 1

### III. Test-Driven Simplicity
- ✅ **PASS**: Reuses OpenClaw primitives (hooks, runtime APIs, agent configs)
- ✅ **PASS**: Simple mechanism (Map-based registry + event hooks)
- ⚠️ **PENDING**: Test cases to be written in Phase 2
- ✅ **PASS**: No unnecessary complexity introduced

**Overall Status**: ✅ PASS (2 items pending for later phases)

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Plugin structure (to be created in ~/.openclaw/plugins/task-dispatch/)
src/
├── index.ts              # Plugin entry point, tool registration
├── tools/
│   ├── task-sync.ts      # Synchronous task delegation
│   ├── task-async.ts     # Asynchronous task delegation
│   └── task-check.ts     # Task status query
├── hooks/
│   └── subagent-ended.ts # Hook handler for task completion
├── registry/
│   └── task-registry.ts  # In-memory task tracking
└── types/
    └── index.ts          # TypeScript type definitions

tests/
├── integration/
│   ├── sync-task.test.ts
│   ├── async-task.test.ts
│   └── hook-handling.test.ts
└── manual/
    └── test-scenarios.md  # Manual test procedures

package.json              # Plugin metadata and dependencies
tsconfig.json             # TypeScript configuration
README.md                 # Plugin documentation
```

**Structure Decision**: Single plugin package structure. All code lives in the plugin directory, no modifications to OpenClaw core. Tests are split into automated integration tests and manual test scenarios due to OpenClaw's runtime requirements.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
