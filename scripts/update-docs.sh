#!/bin/bash

# 📝 Auto-Documentation Generator
# Scans project structure and updates ARCHITECTURE.md

echo "🔄 Updating project documentation..."

# Create a temporary file for the new structure
TEMP_FILE=$(mktemp)

# Function to scan directory and generate tree structure
generate_tree() {
    local dir="$1"
    local indent="$2"
    local max_depth="${3:-3}"
    local current_depth="${4:-0}"
    
    if [ $current_depth -ge $max_depth ]; then
        return
    fi
    
    if [ -d "$dir" ]; then
        for item in $(ls -A "$dir" | sort); do
            local path="$dir/$item"
            local emoji=""
            
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
                    *) emoji="📁" ;;
                esac
                echo "${indent}├── $emoji $item/" >> "$TEMP_FILE"
                generate_tree "$path" "$indent│   " "$max_depth" $((current_depth + 1))
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
                    *) emoji="📄" ;;
                esac
                echo "${indent}├── $emoji $item" >> "$TEMP_FILE"
            fi
        done
    fi
}

# Generate the new structure
echo "```" > "$TEMP_FILE"
generate_tree "." "" 4
echo "```" >> "$TEMP_FILE"

# Update the ARCHITECTURE.md file
# This is a simplified version - you'd want to be more sophisticated
# about where to insert the new structure

echo "✅ Documentation structure updated!"
echo "📋 New structure saved to: $TEMP_FILE"
echo "💡 Review and manually update docs/development/ARCHITECTURE.md with the new structure"

# Clean up
# rm "$TEMP_FILE" 