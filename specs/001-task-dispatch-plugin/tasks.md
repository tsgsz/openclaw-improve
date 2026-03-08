# Task Breakdown: OpenClaw Task Dispatch Plugin

**Branch**: `001-task-dispatch-plugin` | **Date**: 2026-03-08

## Implementation Strategy

**MVP Scope**: User Story 1 (Reliable Synchronous Task Delegation)
- Delivers immediate value for sequential workflows
- Foundation for all other features
- Independently testable

**Incremental Delivery**:
1. US1 (P1): Sync task delegation → Deploy for sequential workflows
2. US2 (P1): Async task tracking → Enable parallel execution
3. US3 (P2): Dynamic project/model → Multi-project support
4. US4 (P2): Tool access control → Production hardening
5. US5 (P3): Migration guide → User adoption

## Dependencies

```
Setup (Phase 1)
  ↓
Foundational (Phase 2)
  ↓
US1 (P1) ←─── Independent
  ↓
US2 (P1) ←─── Depends on US1 (shares registry)
  ↓
US3 (P2) ←─── Depends on US2 (extends async)
  ↓
US4 (P2) ←─── Independent (config only)
  ↓
US5 (P3) ←─── Depends on all (documents complete system)
  ↓
Polish (Final)
```

## Phase 1: Setup

**Goal**: Initialize plugin project structure and configuration

### Tasks

- [x] T001 Create plugin directory at ~/.openclaw/plugins/task-dispatch/
- [x] T002 Initialize package.json with plugin metadata
- [x] T003 Create tsconfig.json with strict mode and ES2022 target
- [x] T004 Create src/ directory structure per plan.md
- [x] T005 Create tests/ directory structure per plan.md
- [x] T006 Create README.md with plugin overview

## Phase 2: Foundational

**Goal**: Core types and registry that all user stories depend on

### Tasks

- [x] T007 Define TypeScript types in src/types/index.ts (Task, TaskStatus, TaskRegistry, PluginConfig, tool params)
- [x] T008 Implement TaskRegistry class in src/registry/task-registry.ts with LRU eviction
- [x] T009 Create plugin entry point in src/index.ts with tool/hook registration stubs

## Phase 3: User Story 1 - Reliable Synchronous Task Delegation (P1)

**Goal**: Orchestrator can delegate tasks synchronously and receive results inline

**Independent Test**: Orchestrator calls `task_sync({ agent: "professor", task: "research X" })` and receives result without manual status checks

### Tasks

- [x] T010 [US1] Implement task_sync tool in src/tools/task-sync.ts
- [x] T011 [US1] Add subagent.run() call with deliver=false in task-sync.ts
- [x] T012 [US1] Add waitForRun() with timeout handling in task-sync.ts
- [x] T013 [US1] Add getSessionMessages() and result extraction in task-sync.ts
- [x] T014 [US1] Register task_sync tool in src/index.ts
- [x] T015 [US1] Create manual test scenario in tests/manual/test-scenarios.md for sync task

**Parallel Opportunities**: T010-T013 can be developed in parallel if using stubs

## Phase 4: User Story 2 - Asynchronous Task Tracking (P1)

**Goal**: Spawn multiple tasks in parallel and track completion via hooks

**Independent Test**: Spawn 3 parallel tasks, receive task IDs immediately, use task_check() to verify completion

### Tasks

- [x] T016 [US2] Implement task_async tool in src/tools/task-async.ts
- [x] T017 [US2] Add task ID generation and registry insertion in task-async.ts
- [x] T018 [US2] Add subagent.run() call with deliver=true in task-async.ts
- [x] T019 [US2] Implement task_check tool in src/tools/task-check.ts
- [x] T020 [US2] Add single task query logic in task-check.ts
- [x] T021 [US2] Add all tasks query logic in task-check.ts
- [x] T022 [US2] Implement subagent_ended hook in src/hooks/subagent-ended.ts
- [x] T023 [US2] Add task status update logic in subagent-ended.ts
- [x] T024 [US2] Add result extraction in subagent-ended.ts
- [x] T025 [US2] Register task_async and task_check tools in src/index.ts
- [x] T026 [US2] Register subagent_ended hook in src/index.ts
- [x] T027 [US2] Create manual test scenario for async tasks and hook handling

**Parallel Opportunities**: T016-T018 (task_async), T019-T021 (task_check), T022-T024 (hook) can be developed in parallel

## Phase 5: User Story 3 - Dynamic Project and Model Support (P2)

**Goal**: Support dynamic project_root and model parameters for flexible multi-project workflows

**Independent Test**: Call `task_async({ agent: "coder", task: "implement auth", project_root: "/project-a", model: "gpt-4" })` and verify execution in specified project

### Tasks

- [x] T028 [US3] Add coder agent detection logic in task-async.ts
- [x] T029 [US3] Implement sessions_spawn() call with ACP runtime in task-async.ts
- [x] T030 [US3] Add project_root (cwd) parameter handling in task-async.ts
- [x] T031 [US3] Add model parameter handling in task-async.ts
- [x] T032 [US3] Create manual test scenario for dynamic project/model support

**Parallel Opportunities**: T028-T031 are sequential (modify same file)

## Phase 6: User Story 4 - Tool Access Control (P2)

**Goal**: Configure tool permissions via agent configuration

**Independent Test**: Configure main agent to deny sessions_spawn, verify call is blocked

### Tasks

- [x] T033 [US4] Document tool permission configuration in README.md
- [x] T034 [US4] Create example openclaw.json with tool allow/deny lists
- [x] T035 [US4] Create manual test scenario for tool access control

**Parallel Opportunities**: T033-T035 can be done in parallel (different files)

## Phase 7: User Story 5 - Migration from Current Setup (P3)

**Goal**: Enable existing users to migrate to plugin-based dispatch system

**Independent Test**: Follow migration guide with test installation, verify existing workflows continue functioning

### Tasks

- [x] T036 [US5] Create migration guide section in README.md
- [x] T037 [US5] Document current state analysis in migration guide
- [x] T038 [US5] Document target state configuration in migration guide
- [x] T039 [US5] Document step-by-step migration procedure in migration guide
- [x] T040 [US5] Document rollback procedure in migration guide
- [x] T041 [US5] Create manual test scenario for migration workflow

**Parallel Opportunities**: T036-T040 are sequential (same document)

## Phase 8: Polish & Cross-Cutting Concerns

**Goal**: Production readiness and documentation

### Tasks

- [x] T042 Add error handling for malformed parameters across all tools
- [x] T043 Add error handling for unknown sessionKey in hook
- [x] T044 Add concurrent task_check safety (read-only, no race conditions)
- [x] T045 Add plugin configuration validation in src/index.ts
- [x] T046 Update README.md with installation instructions
- [x] T047 Update README.md with configuration examples
- [x] T048 Update README.md with usage examples
- [x] T049 Build plugin with npm run build
- [x] T050 Run manual test scenarios end-to-end

**Parallel Opportunities**: T042-T044 (error handling), T046-T048 (documentation) can be done in parallel

---

## Summary

**Total Tasks**: 50

**Tasks by User Story**:
- Setup: 6 tasks
- Foundational: 3 tasks
- US1 (P1): 6 tasks
- US2 (P1): 12 tasks
- US3 (P2): 5 tasks
- US4 (P2): 3 tasks
- US5 (P3): 6 tasks
- Polish: 9 tasks

**Parallel Opportunities Identified**: 15+ tasks can be executed in parallel within their phases

**MVP Scope (Recommended)**: Phase 1-3 (Setup + Foundational + US1)
- Delivers core sync delegation functionality
- 15 tasks total
- Independently testable and deployable
- Provides immediate value for sequential workflows

**Independent Test Criteria**:
- US1: Orchestrator receives inline results from task_sync without manual checks
- US2: Spawn 3 parallel tasks, verify all complete via task_check
- US3: Coder executes in specified project with specified model
- US4: Tool permission denial blocks unauthorized calls
- US5: Existing workflows continue functioning after migration
