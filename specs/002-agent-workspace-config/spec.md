# Feature Specification: Agent Workspace Configuration

**Feature Branch**: `002-agent-workspace-config`  
**Created**: 2026-03-08  
**Status**: Draft  
**Input**: Configure OpenClaw agents hierarchy and workspace structure following ~/.openclaw/workspace rules

## User Scenarios & Testing

### User Story 1 - Configure Agent Hierarchy (Priority: P1)

System administrator configures a three-tier agent hierarchy (Main → Orchestrator → Functional) with proper tool permissions and subagent relationships to enable reliable task delegation.

**Why this priority**: Core infrastructure required for all other features. Without proper agent hierarchy, task dispatch plugin cannot function correctly.

**Independent Test**: Can be fully tested by verifying agent configuration in openclaw.json and confirming agents can call their designated subagents with correct tool access.

**Acceptance Scenarios**:

1. **Given** openclaw.json exists, **When** admin adds agent hierarchy configuration, **Then** main agent can only use task_async and call orchestrator
2. **Given** agent hierarchy is configured, **When** orchestrator receives task, **Then** it can use task_sync/task_async/task_check and call functional agents
3. **Given** functional agents are configured, **When** they receive tasks, **Then** they have appropriate tool access (professor: web_search, coder: ACP runtime, etc.)

---

### User Story 2 - Setup Workspace Structure (Priority: P2)

System administrator creates workspace directories following ~/.openclaw/workspace conventions to organize agent-specific files, skills, and session data.

**Why this priority**: Required for agents to function properly with isolated workspaces and skills.

**Independent Test**: Can be tested by creating workspace directories and verifying agents use correct workspace paths for their operations.

**Acceptance Scenarios**:

1. **Given** workspace root exists, **When** admin creates agent workspaces, **Then** directories follow pattern ~/.openclaw/workspace/{agent-type}/{agent-id}
2. **Given** workspace directories exist, **When** agents run, **Then** they store session data in their designated workspace
3. **Given** domain agent workspace exists, **When** skills are added, **Then** main agent can trigger domain agents via skills

---

### User Story 3 - Create Domain Agent Skills (Priority: P3)

System administrator creates skill files for domain agents (finance, creative) to enable main agent to delegate domain-specific tasks.

**Why this priority**: Enables advanced use cases but not required for basic task delegation.

**Independent Test**: Can be tested by creating skill files and verifying main agent can invoke domain agents through skills.

**Acceptance Scenarios**:

1. **Given** domain-finance skill exists, **When** main agent needs financial analysis, **Then** it can invoke domain-finance agent via skill
2. **Given** domain-creative skill exists, **When** main agent needs design work, **Then** it can invoke domain-creative agent via skill

---

### Edge Cases

- What happens when agent tries to call subagent not in allowAgents list?
- How does system handle workspace directory creation failures?
- What if agent workspace already contains conflicting files?
- How to handle migration from existing agent configuration?

## Requirements

### Functional Requirements

- **FR-001**: System MUST configure main agent with task_async tool only and deny task_sync/sessions_spawn
- **FR-002**: System MUST configure orchestrator agent with task_sync, task_async, task_check tools
- **FR-003**: System MUST configure functional agents (professor, sculpture, writter, geek, coder, reviewer) with appropriate tool access
- **FR-004**: System MUST create workspace directory structure under ~/.openclaw/workspace following pattern: {agent-type}/{agent-id}
- **FR-005**: System MUST configure agent subagent relationships (main → orchestrator → functional)
- **FR-006**: System MUST create domain agent configurations (domain-finance, domain-creative) with workspace paths
- **FR-007**: System MUST create skill files for domain agents in main agent workspace
- **FR-008**: System MUST backup existing openclaw.json before modifications
- **FR-009**: System MUST validate agent configuration after changes
- **FR-010**: System MUST configure coder agent with ACP runtime and workspace path

### Key Entities

- **Agent Configuration**: Defines agent ID, workspace path, tool permissions, subagent relationships, runtime settings
- **Workspace Directory**: Physical directory structure organizing agent-specific files, skills, and session data
- **Skill File**: Markdown document describing domain agent capabilities and invocation patterns
- **Tool Permission**: Allow/deny lists controlling which tools each agent can access

## Success Criteria

### Measurable Outcomes

- **SC-001**: All agents defined in FINAL-SOLUTION.md are configured in openclaw.json
- **SC-002**: Workspace directory structure exists and follows ~/.openclaw/workspace conventions
- **SC-003**: Main agent can successfully delegate tasks to orchestrator using task_async
- **SC-004**: Orchestrator can successfully delegate tasks to functional agents using task_sync/task_async
- **SC-005**: Domain agent skills are created and main agent can invoke them
- **SC-006**: Gateway restarts without errors after configuration changes
- **SC-007**: Agent tool permissions are enforced (main cannot use task_sync, orchestrator can)
