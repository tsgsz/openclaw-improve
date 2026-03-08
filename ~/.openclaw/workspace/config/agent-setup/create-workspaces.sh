#!/bin/bash
# Agent Workspace Configuration Script
# Creates workspace structure following ~/.openclaw/workspace conventions

set -e

WORKSPACE_ROOT="$HOME/.openclaw/workspace"
CONFIG_DIR="$WORKSPACE_ROOT/config/agent-setup"

echo "=== Creating Agent Workspace Structure ==="

# Create main agent workspace
mkdir -p "$WORKSPACE_ROOT/main/skills"
echo "✓ Created main agent workspace"

# Create orchestrator workspace
mkdir -p "$WORKSPACE_ROOT/orchestrator"
echo "✓ Created orchestrator workspace"

# Create domain agent workspaces
mkdir -p "$WORKSPACE_ROOT/domains/finance"
mkdir -p "$WORKSPACE_ROOT/domains/creative"
echo "✓ Created domain agent workspaces"

# Create functional agent workspaces
mkdir -p "$WORKSPACE_ROOT/functional/coder"
mkdir -p "$WORKSPACE_ROOT/functional/professor"
mkdir -p "$WORKSPACE_ROOT/functional/sculpture"
mkdir -p "$WORKSPACE_ROOT/functional/writter"
mkdir -p "$WORKSPACE_ROOT/functional/geek"
mkdir -p "$WORKSPACE_ROOT/functional/reviewer"
echo "✓ Created functional agent workspaces"

echo ""
echo "=== Workspace Structure Created ==="
tree -L 3 "$WORKSPACE_ROOT" 2>/dev/null || find "$WORKSPACE_ROOT" -type d -maxdepth 3 | sort
