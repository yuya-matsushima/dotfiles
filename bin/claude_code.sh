#!/bin/sh
set -e

echo "Installing Claude CLI..."

# Check if npm is installed
if ! command -v npm >/dev/null 2>&1; then
    echo "Error: npm is not installed. Please install Node.js and npm first."
    exit 1
fi

# Install Claude CLI globally
npm install -g @anthropic-ai/claude-cli

# Verify Claude CLI installation
if command -v claude >/dev/null 2>&1; then
    echo "Claude CLI installed successfully!"
    claude --version
else
    echo "Error: Claude CLI installation failed."
    exit 1
fi

# Install ccusage tool
echo "Installing ccusage (Claude Code usage tracker)..."
npm install -g ccusage@latest

# Verify ccusage installation
if command -v ccusage >/dev/null 2>&1; then
    echo "ccusage installed successfully!"
    ccusage --version
else
    echo "Error: ccusage installation failed."
    exit 1
fi