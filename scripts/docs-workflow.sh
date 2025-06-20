#!/bin/bash

# 🔄 Comprehensive Documentation Workflow
# Automatically updates ARCHITECTURE.md based on actual project structure

set -e

echo "🔄 Starting documentation workflow..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Backup original file
print_status "Creating backup of ARCHITECTURE.md..."
cp docs/development/ARCHITECTURE.md docs/development/ARCHITECTURE.md.backup

# Generate new structure
print_status "Generating new project structure..."
TEMP_STRUCTURE=$(mktemp)

# Function to generate tree with emojis
generate_tree_with_emojis() {
    local dir="$1"
    local indent="$2"
    local max_depth="${3:-4}"
    local current_depth="${4:-0}"
    
    if [ $current_depth -ge $max_depth ]; then
        return
    fi
    
    if [ -d "$dir" ]; then
        local items=($(ls -A "$dir" | sort))
        local count=${#items[@]}
        local index=0
        
        for item in "${items[@]}"; do
            local path="$dir/$item"
            local emoji=""
            local is_last=$((index == count - 1))
            local connector="├──"
            
            if [ $is_last -eq 1 ]; then
                connector="└──"
            fi
            
            # Add emojis based on file/directory type
            if [ -d "$path" ]; then
                case "$item" in
                    "ui") emoji="📱" ;;
                    "logic") emoji="🧠" ;;
                    "ai") emoji="🤖" ;;
                    "db-layer") emoji="🗄️" ;;
                    "scripts") emoji="🚀" ;;
                    "tests") emoji="🧪" ;;
                    "deploy") emoji="🚀" ;;
                    "meta") emoji="🔧" ;;
                    "docs") emoji="📚" ;;
                    "examples") emoji="🎯" ;;
                    "web") emoji="🌐" ;;
                    "mobile") emoji="📱" ;;
                    "typescript") emoji="🔷" ;;
                    "kotlin") emoji="🔶" ;;
                    "go") emoji="🔵" ;;
                    "node") emoji="🟡" ;;
                    "docker") emoji="🐳" ;;
                    "kubernetes") emoji="☸️" ;;
                    "aws") emoji="☁️" ;;
                    "src") emoji="📁" ;;
                    "lib") emoji="📁" ;;
                    "public") emoji="🌐" ;;
                    "components") emoji="🧩" ;;
                    "services") emoji="⚙️" ;;
                    "utils") emoji="🔧" ;;
                    "models") emoji="📊" ;;
                    "migrations") emoji="🔄" ;;
                    "lambda") emoji="⚡" ;;
                    *) emoji="📁" ;;
                esac
                echo "${indent}${connector} $emoji $item/" >> "$TEMP_STRUCTURE"
                local next_indent="$indent"
                if [ $is_last -eq 0 ]; then
                    next_indent="${indent}│   "
                else
                    next_indent="${indent}    "
                fi
                generate_tree_with_emojis "$path" "$next_indent" "$max_depth" $((current_depth + 1))
            else
                case "$item" in
                    *.js) emoji="📄" ;;
                    *.ts) emoji="📄" ;;
                    *.py) emoji="🐍" ;;
                    *.go) emoji="🔵" ;;
                    *.kt) emoji="🔶" ;;
                    *.json) emoji="⚙️" ;;
                    *.md) emoji="📝" ;;
                    *.yml|*.yaml) emoji="⚙️" ;;
                    *.sh) emoji="🚀" ;;
                    *.html) emoji="🌐" ;;
                    *.css) emoji="🎨" ;;
                    *.dart) emoji="🎯" ;;
                    *.xml) emoji="📱" ;;
                    *.gradle) emoji="🔶" ;;
                    *.mod) emoji="🔵" ;;
                    *.sum) emoji="🔵" ;;
                    *.lock) emoji="🔒" ;;
                    *) emoji="📄" ;;
                esac
                echo "${indent}${connector} $emoji $item" >> "$TEMP_STRUCTURE"
            fi
            ((index++))
        done
    fi
}

# Generate the structure
echo "```" > "$TEMP_STRUCTURE"
generate_tree_with_emojis "." "" 4
echo "```" >> "$TEMP_STRUCTURE"

# Update ARCHITECTURE.md
print_status "Updating ARCHITECTURE.md..."

# Find the section to replace (between the first ``` and the next major section)
ARCHITECTURE_START=$(grep -n "^## 📁 Complete Project Structure" docs/development/ARCHITECTURE.md | cut -d: -f1)
if [ -z "$ARCHITECTURE_START" ]; then
    print_error "Could not find 'Complete Project Structure' section in docs/development/ARCHITECTURE.md"
    exit 1
fi

# Find the end of the structure section (next ## heading)
ARCHITECTURE_END=$(tail -n +$((ARCHITECTURE_START + 1)) docs/development/ARCHITECTURE.md | grep -n "^## " | head -1 | cut -d: -f1)
if [ -z "$ARCHITECTURE_END" ]; then
    # If no next section, go to end of file
    ARCHITECTURE_END=$(wc -l < docs/development/ARCHITECTURE.md)
else
    ARCHITECTURE_END=$((ARCHITECTURE_START + ARCHITECTURE_END))
fi

# Create new file
head -n $ARCHITECTURE_START docs/development/ARCHITECTURE.md > docs/development/ARCHITECTURE.md.new
echo "" >> docs/development/ARCHITECTURE.md.new
cat "$TEMP_STRUCTURE" >> docs/development/ARCHITECTURE.md.new
echo "" >> docs/development/ARCHITECTURE.md.new
tail -n +$((ARCHITECTURE_END + 1)) docs/development/ARCHITECTURE.md >> docs/development/ARCHITECTURE.md.new

# Replace original file
mv docs/development/ARCHITECTURE.md.new docs/development/ARCHITECTURE.md

# Clean up
rm "$TEMP_STRUCTURE"

print_success "Documentation updated successfully!"
print_status "Backup saved as docs/development/ARCHITECTURE.md.backup"

# Show diff
print_status "Showing changes:"
if command -v diff &> /dev/null; then
    diff docs/development/ARCHITECTURE.md.backup docs/development/ARCHITECTURE.md || true
else
    print_warning "diff command not available - cannot show changes"
fi

print_success "Documentation workflow complete!" 