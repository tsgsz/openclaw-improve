#!/bin/bash
set -e

echo "Installing OpenClaw Task Dispatch Plugin..."

PLUGIN_DIR="$HOME/.openclaw/plugins/task-dispatch"

# Create plugin directory
mkdir -p "$PLUGIN_DIR"

# Copy files
cp -r src dist package.json tsconfig.json openclaw.plugin.json README.md "$PLUGIN_DIR/"

# Install dependencies if needed
cd "$PLUGIN_DIR"
if [ ! -d "node_modules" ]; then
    npm install
fi

# Build if dist is missing
if [ ! -f "dist/index.js" ]; then
    npm run build
fi

echo "✓ Plugin installed to $PLUGIN_DIR"
echo ""
echo "Next steps:"
echo "1. Add to ~/.openclaw/openclaw.json:"
echo '   "plugins": { "allow": ["task-dispatch"], "entries": { "task-dispatch": { "enabled": true } } }'
echo "2. Restart OpenClaw: pkill openclaw && openclaw gateway start"
