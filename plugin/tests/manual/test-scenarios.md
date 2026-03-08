# Manual Test Scenarios

## Test Scenario 1: Synchronous Task Delegation

**Goal**: Verify task_sync returns result inline without manual status checks

**Prerequisites**:
- Plugin installed and enabled
- Orchestrator agent configured with task_sync tool access

**Steps**:
1. Start OpenClaw with orchestrator agent
2. Execute: `task_sync({ agent: "professor", task: "research OpenClaw plugin architecture" })`
3. Wait for response

**Expected Result**:
- Response received inline (no task ID)
- Response contains research findings
- No manual status check required

**Success Criteria**: ✓ Result delivered inline, ✓ No lost responses

---

## Test Scenario 2: Sync Task Timeout

**Goal**: Verify timeout handling returns error after threshold

**Steps**:
1. Execute: `task_sync({ agent: "professor", task: "long running task", timeout_ms: 5000 })`
2. Wait for timeout

**Expected Result**:
- Error message: "Error: Task timeout after 5000ms"
- Partial results if available

**Success Criteria**: ✓ Timeout error returned, ✓ No hang

---

## Test Scenario 3: Asynchronous Task Tracking

**Goal**: Verify task_async returns task ID immediately and tracks completion

**Steps**:
1. Execute: `task_async({ agent: "professor", task: "research topic A" })`
2. Note the returned task_id
3. Execute: `task_check({ task_id: "<task_id>" })`
4. Wait for completion
5. Execute: `task_check({ task_id: "<task_id>" })` again

**Expected Result**:
- Step 1: Returns task ID immediately (format: "Task started: task-...")
- Step 3: Status shows "running"
- Step 5: Status shows "completed" with result

**Success Criteria**: ✓ Immediate task ID, ✓ Status tracking works

---

## Test Scenario 4: Parallel Task Execution

**Goal**: Verify multiple async tasks run in parallel

**Steps**:
1. Execute: `task_async({ agent: "professor", task: "research topic A" })`
2. Execute: `task_async({ agent: "professor", task: "research topic B" })`
3. Execute: `task_async({ agent: "professor", task: "research topic C" })`
4. Execute: `task_check()` (no task_id)

**Expected Result**:
- All 3 tasks show status "running" or "completed"
- All tasks tracked in registry

**Success Criteria**: ✓ Parallel execution, ✓ All tasks tracked

---

## Test Scenario 5: Dynamic Project and Model Support

**Goal**: Verify coder agent executes in specified project with specified model

**Steps**:
1. Execute: `task_async({ agent: "coder", task: "implement auth", project_root: "/path/to/project-a", model: "openai/gpt-4" })`
2. Verify coder works in project-a directory
3. Execute: `task_async({ agent: "coder", task: "add tests", project_root: "/path/to/project-b" })`
4. Verify coder works in project-b directory

**Expected Result**:
- Coder executes in specified project directories
- Model parameter is respected
- Default workspace used when project_root not specified

**Success Criteria**: ✓ Dynamic project support, ✓ Model parameter works

---

## Test Scenario 6: Tool Access Control

**Goal**: Verify tool permissions are enforced via agent configuration

**Prerequisites**:
- Main agent configured with `deny: ["sessions_spawn"]`
- Orchestrator configured with `allow: ["task_sync", "task_async"]`

**Steps**:
1. As main agent, attempt: `sessions_spawn({ ... })`
2. As orchestrator, execute: `task_sync({ agent: "professor", task: "test" })`

**Expected Result**:
- Step 1: Permission error (blocked)
- Step 2: Success (allowed)

**Success Criteria**: ✓ Deny list blocks calls, ✓ Allow list permits calls

---

## Test Scenario 7: Migration Workflow

**Goal**: Verify existing workflows continue functioning after migration

**Prerequisites**:
- Existing OpenClaw installation with working agents
- Plugin installed but not yet enabled

**Steps**:
1. Document current workflow behavior
2. Enable plugin and update openclaw.json
3. Restart OpenClaw
4. Execute same workflow
5. Compare results

**Expected Result**:
- Workflow produces same results
- Task delegation more reliable
- No functionality lost

**Success Criteria**: ✓ Existing workflows work, ✓ Migration under 30 minutes
