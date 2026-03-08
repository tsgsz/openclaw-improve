# Feature Specification: OpenClaw Task Dispatch Plugin

**Feature Branch**: `001-task-dispatch-plugin`  
**Created**: 2026-03-08  
**Status**: Draft  
**Input**: User description: "根据 FINAL-SOLUTION.md 中的内容，完成plugin的开发和测试"

## Clarifications

### Session 2026-03-08

- Q: When should completed tasks be removed from the registry? → A: Automatic LRU eviction when registry exceeds max size (applies to tasks only; projects follow different rules: main projects with GitHub are kept permanently, other projects use same LRU strategy as tasks)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reliable Synchronous Task Delegation (Priority: P1)

Orchestrator agent needs to delegate a task to a functional agent (e.g., professor, coder) and wait for the result before proceeding with the next step. The result must be guaranteed to return without loss.

**Why this priority**: Core functionality - without reliable sync delegation, the entire multi-agent workflow breaks down. This is the foundation for all orchestration patterns.

**Independent Test**: Can be fully tested by having orchestrator call `task_sync({ agent: "professor", task: "research topic X" })` and verify the result is returned inline. Delivers immediate value for sequential workflows.

**Acceptance Scenarios**:

1. **Given** orchestrator has a task requiring research, **When** it calls `task_sync({ agent: "professor", task: "analyze payment flow" })`, **Then** orchestrator receives the research result inline and can proceed
2. **Given** a sync task is running, **When** the functional agent completes successfully, **Then** the result is returned to the caller without requiring manual status checks
3. **Given** a sync task times out, **When** timeout threshold is exceeded, **Then** caller receives timeout error with partial results if available

---

### User Story 2 - Asynchronous Task Tracking (Priority: P1)

Main agent or orchestrator needs to spawn multiple tasks in parallel without blocking, then check their status and collect results when ready.

**Why this priority**: Essential for parallel execution patterns. Without this, agents are forced into sequential execution, severely limiting throughput.

**Independent Test**: Can be tested by spawning 3 parallel tasks via `task_async()`, receiving task IDs immediately, then using `task_check()` to verify all complete successfully. Delivers value for concurrent workflows.

**Acceptance Scenarios**:

1. **Given** orchestrator needs to run 3 research tasks in parallel, **When** it calls `task_async()` three times, **Then** it receives 3 task IDs immediately and can continue other work
2. **Given** multiple async tasks are running, **When** orchestrator calls `task_check()`, **Then** it receives current status of all tasks (running/completed/failed)
3. **Given** an async task completes, **When** the subagent_ended hook fires, **Then** task registry is updated with result and status changes to "completed"

---

### User Story 3 - Dynamic Project and Model Support (Priority: P2)

Orchestrator needs to delegate coding tasks to different projects with different AI models based on task requirements.

**Why this priority**: Critical for multi-project environments but can work with defaults initially. Enables flexibility without being a blocker for basic functionality.

**Independent Test**: Can be tested by calling `task_async({ agent: "coder", task: "implement auth", project_root: "/project-a", model: "gpt-4" })` and verifying coder works in the specified project with specified model.

**Acceptance Scenarios**:

1. **Given** orchestrator manages multiple projects, **When** it delegates a coding task with `project_root: "/path/to/project-a"`, **Then** coder agent executes in that project directory
2. **Given** a task requires a specific model, **When** orchestrator specifies `model: "google/gemini-2.0-flash-exp:free"`, **Then** the agent uses that model for execution
3. **Given** no project_root is specified, **When** coder agent is invoked, **Then** it uses the default workspace directory

---

### User Story 4 - Tool Access Control (Priority: P2)

System administrator needs to configure which agents can use which tools to enforce security boundaries and prevent unauthorized operations.

**Why this priority**: Important for production safety but not required for initial development/testing. Can start with permissive defaults.

**Independent Test**: Can be tested by configuring main agent to deny `sessions_spawn`, attempting to call it, and verifying the call is blocked.

**Acceptance Scenarios**:

1. **Given** main agent is configured with `deny: ["sessions_spawn"]`, **When** main tries to call sessions_spawn directly, **Then** the call is blocked with permission error
2. **Given** orchestrator is configured with `allow: ["task_sync", "task_async"]`, **When** orchestrator calls these tools, **Then** calls succeed

---

### User Story 5 - Migration from Current Setup (Priority: P3)

Existing OpenClaw user needs to migrate from current agent configuration to the new plugin-based dispatch system without breaking existing workflows.

**Why this priority**: Important for adoption but not required for greenfield setups. Can be documented separately from core implementation.

**Independent Test**: Can be tested by following migration guide with a test OpenClaw installation and verifying all existing workflows continue to function.

**Acceptance Scenarios**:

1. **Given** user has existing AGENTS.md configuration, **When** they follow migration guide, **Then** they can identify which agents to keep/remove/reconfigure
2. **Given** user installs the plugin, **When** they update openclaw.json with new tool permissions, **Then** existing agents gain access to task_sync/task_async tools

### Edge Cases

- What happens when a sync task exceeds timeout threshold?
- How does system handle subagent crash during async task execution?
- What happens when task registry exceeds max size? (Resolved: LRU eviction removes oldest completed tasks)
- How does system handle concurrent task_check calls on same task?
- What happens when subagent_ended hook fires for unknown sessionKey?
- How does system handle malformed task parameters (missing agent, empty task)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Plugin MUST provide `task_sync` tool that blocks until subagent completes and returns result inline
- **FR-002**: Plugin MUST provide `task_async` tool that returns task ID immediately and tracks execution asynchronously
- **FR-003**: Plugin MUST provide `task_check` tool that returns status of one or all async tasks
- **FR-004**: Plugin MUST register `subagent_ended` hook to capture task completion events
- **FR-005**: Plugin MUST maintain task registry mapping task IDs to session keys, status, and results
- **FR-006**: Plugin MUST support dynamic `project_root` parameter for coder agent via ACP runtime
- **FR-007**: Plugin MUST support dynamic `model` parameter for any agent
- **FR-008**: Plugin MUST handle timeout for both sync and async tasks with configurable thresholds
- **FR-009**: Plugin MUST extract final result from subagent message history
- **FR-010**: Plugin MUST distinguish between coder agent (ACP runtime) and regular subagents
- **FR-011**: Plugin MUST NOT modify any OpenClaw core code (zero-invasion principle)
- **FR-012**: Plugin MUST integrate via OpenClaw Plugin API only
- **FR-013**: System MUST allow tool access control via agent configuration (allow/deny lists)
- **FR-014**: Plugin MUST handle subagent failures gracefully and update task status to "failed"
- **FR-015**: Plugin MUST support configurable task timeout and max concurrent tasks via plugin config
- **FR-016**: Plugin MUST implement LRU eviction for completed tasks when registry exceeds maxRegistrySize, preserving running tasks

### Key Entities

- **Task**: Represents an async task execution with fields: taskId, sessionKey, runId, status (running/completed/failed), agent, result, error
- **TaskRegistry**: In-memory Map storing all active and completed tasks, keyed by taskId
- **PluginConfig**: Configuration object with taskTimeout (default 300000ms) and maxConcurrentTasks (default 10)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Orchestrator can delegate 10 sequential tasks via task_sync with 100% result delivery (no lost responses)
- **SC-002**: Orchestrator can spawn 5 parallel tasks via task_async and collect all results within 10 seconds of completion
- **SC-003**: Plugin handles subagent crashes without crashing the main agent (graceful failure)
- **SC-004**: Migration guide enables existing users to adopt plugin within 30 minutes
- **SC-005**: Plugin adds zero latency overhead to direct subagent calls (measured via benchmarks)
- **SC-006**: Task registry memory usage remains bounded under 100MB for 1000 completed tasks
