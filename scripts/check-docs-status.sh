#!/bin/bash

# 📊 Documentation Status Checker
# Compares actual project structure with documented structure

echo "🔍 Checking documentation status..."

# Get actual project structure (simplified)
ACTUAL_STRUCTURE=$(find . -type d -not -path "./.git*" -not -path "./node_modules*" | sort | head -20)

# Check for common discrepancies
echo "📋 Checking for common documentation issues:"

# Check if documented directories exist
DOCUMENTED_DIRS=("ui" "logic" "ai" "db-layer" "scripts" "tests" "deploy" "meta" "docs" "examples")

for dir in "${DOCUMENTED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir - exists"
    else
        echo "❌ $dir - documented but missing"
    fi
done

# Check for undocumented directories
echo ""
echo "🔍 Looking for undocumented directories:"
UNDOCUMENTED=$(find . -maxdepth 1 -type d -not -path "." -not -path "./.git" -not -path "./node_modules" | sed 's|./||' | grep -v -E "^(ui|logic|ai|db-layer|scripts|tests|deploy|meta|docs|examples)$")

if [ -n "$UNDOCUMENTED" ]; then
    echo "⚠️  Undocumented directories found:"
    echo "$UNDOCUMENTED"
    echo ""
    echo "💡 Consider adding these to docs/development/ARCHITECTURE.md"
else
    echo "✅ All top-level directories are documented"
fi

# Check for recent changes that might need documentation updates
echo ""
echo "📅 Recent changes that might need documentation updates:"
RECENT_CHANGES=$(git log --since="1 week ago" --name-only --pretty=format: | grep -E '^(ui|logic|ai|db-layer|scripts|tests|deploy|meta)/' | sort | uniq)

if [ -n "$RECENT_CHANGES" ]; then
    echo "$RECENT_CHANGES"
    echo ""
    echo "💡 Consider running: ./scripts/update-docs.sh"
else
    echo "✅ No recent structural changes detected"
fi

echo ""
echo "📝 Documentation status check complete!" 