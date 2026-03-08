# Research: OpenClaw Task Dispatch Plugin

**Date**: 2026-03-08
**Status**: Complete

## Research Questions

### Q1: OpenClaw Plugin API Structure

**Question**: What is the exact API surface for OpenClaw plugins to register tools and hooks?

**Decision**: Use standard OpenClaw Plugin API with `api.tools.register()` and `api.hooks.on()`

**Rationale**: 
- FINAL-SOLUTION.md already documents the API patterns
- `api.runtime.subagent.run()`, `waitForRun()`, `getSessionMessages()` are confirmed available
- `api.hooks.on("subagent_ended")` is confirmed to exist and fire on completion

**Alternatives considered**:
- Custom event emitter: Rejected - doesn't integrate with OpenClaw's native event system
- Polling-based status check: Rejected - wasteful, adds latency, violates simplicity principle

**References**: 
- FINAL-SOLUTION.md sections 四、五
- opencode-subagent-analysis.md (confirmed hook existence)

---

### Q2: Task Registry Memory Management

**Question**: How to prevent unbounded memory growth in task registry?

**Decision**: Implement LRU eviction with configurable max size (default 1000 entries)

**Rationale**:
- Success criteria SC-006 requires bounded memory (<100MB for 1000 tasks)
- Completed tasks should be retained for status queries but eventually evicted
- LRU ensures recent tasks remain accessible

**Alternatives considered**:
- Time-based expiration: Rejected - tasks may complete at different rates
- Manual cleanup API: Rejected - adds complexity, easy to forget
- Unlimited storage: Rejected - violates SC-006

**Implementation approach**:
- Use Map with insertion order tracking
- On new task: if size > maxSize, delete oldest completed task
- Keep running tasks indefinitely until completion

---

### Q3: ACP Runtime Integration

**Question**: How to properly invoke coder agent with dynamic project_root and model?

**Decision**: Use `sessions_spawn()` with `runtime: "acp"`, `cwd`, and `model` parameters

**Rationale**:
- FINAL-SOLUTION.md confirms ACP supports dynamic cwd and model
- sessions_spawn parameters verified: runtime, agentId, task, cwd, model, runTimeoutSeconds
- One session = one process, provides isolation

**Alternatives considered**:
- api.runtime.subagent.run(): Rejected - doesn't support workspace/model parameters
- Environment variables: Rejected - not supported by OpenClaw plugin API

**References**:
- FINAL-SOLUTION.md section 七 "为什么 Coder 用 ACP"
- Verified sessions_spawn parameter list

---

### Q4: Error Handling Strategy

**Question**: How to handle subagent failures, timeouts, and crashes gracefully?

**Decision**: Three-tier error handling:
1. Timeout: Return error after threshold, mark task as "timeout"
2. Subagent crash: Hook captures failure, mark task as "failed" with error message
3. Unknown sessionKey: Log warning, ignore (defensive programming)

**Rationale**:
- Edge cases identified in spec require explicit handling
- Graceful degradation prevents cascading failures (SC-003)
- Defensive programming for production robustness

**Implementation approach**:
- task_sync: Use waitForRun() with timeout, catch exceptions
- task_async: Hook updates status on failure
- task_check: Return current status regardless of completion state

---

### Q5: Testing Strategy

**Question**: How to test plugin without modifying OpenClaw core?

**Decision**: Two-tier testing:
1. Integration tests: Automated tests using OpenClaw test harness (if available)
2. Manual tests: Step-by-step scenarios with real OpenClaw installation

**Rationale**:
- Zero-invasion principle prevents test hooks in OpenClaw core
- Manual testing required for end-to-end validation
- Integration tests provide regression coverage where possible

**Test scenarios** (from spec edge cases):
- Sync task timeout
- Async task completion tracking
- Subagent crash handling
- Concurrent task_check calls
- Unknown sessionKey in hook
- Malformed parameters

---

## Technology Decisions

### TypeScript Configuration

**Decision**: Use TypeScript 5.x with strict mode, target ES2022

**Rationale**: 
- OpenClaw plugin standard
- Strict mode catches errors early
- ES2022 provides modern features (top-level await, etc.)

---

### Dependencies

**Decision**: Zero external dependencies beyond OpenClaw Plugin API

**Rationale**:
- Simplicity principle
- Reduces plugin size and installation complexity
- All required functionality available in Node.js stdlib + OpenClaw API

---

## Open Questions

None - all technical unknowns resolved.
