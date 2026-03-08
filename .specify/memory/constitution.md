# OpenClaw Task Dispatch Plugin Constitution

<!--
Sync Impact Report:
- Version change: [TEMPLATE] → 1.0.0
- New principles added: Zero-Invasion, Migration-First, Test-Driven Simplicity
- Templates requiring updates: ⚠ pending review of plan/spec/tasks templates
- Ratification: 2026-03-08 (initial constitution)
-->

## Core Principles

### I. Zero-Invasion Principle (NON-NEGOTIABLE)

**Rule**: All enhancements MUST be implemented as external OpenClaw plugins. Direct modification of OpenClaw core code is strictly forbidden.

**Rationale**: 
- Maintains upgrade path for OpenClaw updates
- Ensures modularity and clean separation of concerns
- Allows independent versioning and distribution
- Reduces maintenance burden and conflict risk

**Enforcement**: Any PR or implementation that modifies OpenClaw source code will be rejected immediately.

### II. Migration-First Principle

**Rule**: Every feature implementation MUST include:
1. Current state analysis (what exists now)
2. Target state specification (what will exist after)
3. Migration plan with concrete steps
4. Rollback procedure if migration fails

**Rationale**:
- Users have existing configurations and workflows
- Breaking changes without migration path cause adoption failure
- Clear migration reduces support burden
- Rollback capability ensures safety

**Enforcement**: No feature is considered complete without documented migration path from current state.

### III. Test-Driven Simplicity

**Rule**: Every implementation MUST:
1. Use the simplest mechanism that solves the problem
2. Reuse existing OpenClaw primitives (hooks, runtime APIs, agent configs)
3. Include test cases before implementation
4. Verify tests pass after implementation

**Rationale**:
- Simple mechanisms are easier to maintain and debug
- Reusing existing primitives ensures compatibility
- Tests prevent regressions and validate correctness
- Test-first ensures testability by design

**Enforcement**: 
- Complexity must be justified with concrete rationale
- Test coverage required for all new tools and hooks
- Manual testing steps documented for integration scenarios

## Development Workflow

### Implementation Cycle

1. **Design Phase**: Document current state, target state, migration plan
2. **Test Phase**: Write test cases that validate the feature
3. **Implementation Phase**: Write minimal code to pass tests
4. **Verification Phase**: Run tests, verify migration works
5. **Documentation Phase**: Update user-facing docs with migration guide

### Code Review Requirements

- Zero-Invasion check: No OpenClaw core modifications
- Migration plan review: Clear path from current to target state
- Test coverage review: All critical paths tested
- Simplicity review: Justify any complexity introduced

## Plugin Architecture Constraints

### Allowed Mechanisms

- OpenClaw Plugin API (tools, hooks, runtime APIs)
- Agent configuration via openclaw.json
- Workspace-based skills and prompts
- External npm packages for plugin dependencies

### Forbidden Mechanisms

- Monkey-patching OpenClaw internals
- Direct database access bypassing OpenClaw APIs
- File system modifications outside plugin workspace
- Network interception or proxy injection

## Governance

**Authority**: This constitution supersedes all other development practices and guidelines.

**Amendment Process**:
1. Propose amendment with rationale
2. Document impact on existing features
3. Update affected templates and documentation
4. Increment version according to semantic versioning

**Compliance Review**: All implementations must pass constitution compliance check before merge.

**Version**: 1.0.0 | **Ratified**: 2026-03-08 | **Last Amended**: 2026-03-08
