#!/bin/bash
#
# Install git hooks for PacerID
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing git hooks...${NC}"

# Get the root directory of the git repository
GIT_ROOT=$(git rev-parse --show-toplevel)

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_ROOT/.git/hooks"

# Copy pre-commit hook
cp "$GIT_ROOT/scripts/pre-commit" "$GIT_ROOT/.git/hooks/pre-commit"
chmod +x "$GIT_ROOT/.git/hooks/pre-commit"

echo -e "${GREEN}✓ Pre-commit hook installed${NC}"
echo ""
echo "The pre-commit hook will now:"
echo "  • Format Swift code with SwiftFormat"
echo "  • Lint Swift code with SwiftLint"
echo "  • Run automatically on 'git commit'"
echo ""
echo "To bypass: git commit --no-verify"
