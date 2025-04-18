#!/bin/bash

set -e

echo "Running pre-commit checks..."

# Store the current working directory
CWD=$(pwd)

# Run tests
echo "Running tests..."
forge test

# Run linting
echo "Running linting..."
forge fmt --check

# Run slither if available
if command -v slither &> /dev/null; then
    echo "Running Slither..."
    slither . --filter-paths "test/" --exclude naming-convention
fi

# Run static analysis
echo "Running static analysis..."
forge analyze

# Check for formatting
echo "Checking formatting..."
if ! forge fmt --check; then
    echo "❌ Code is not properly formatted. Run 'forge fmt' to fix."
    exit 1
fi

# Run gas snapshot if changed
if git diff --cached --name-only | grep -q ".sol$"; then
    echo "Generating gas snapshot..."
    forge snapshot --check
fi

# Return to original directory
cd "$CWD"

echo "✅ All pre-commit checks passed!"