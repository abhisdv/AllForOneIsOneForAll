#!/bin/bash

# Polyglot App Framework Development Script
# Starts development servers for all modules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE="appfusion.json"
LOG_DIR="logs"
CACHE_DIR=".cache"

# Function to parse JSON (simple implementation)
get_json_value() {
    local json_file="$1"
    local key="$2"
    grep -o "\"$key\":[^,}]*" "$json_file" | sed 's/.*"'"$key"'": *"*\([^",}]*\)"*/\1/'
}

# Function to check if port is available
check_port() {
    local port="$1"
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Function to start web UI development server
start_web_ui() {
    echo -e "${BLUE}Starting Web UI development server...${NC}"
    cd ui/web
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Initializing React TypeScript project...${NC}"
        npx create-react-app . --template typescript --yes
    fi
    
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        npm install
    fi
    
    echo -e "${GREEN}Starting React development server on port 3000...${NC}"
    npm start &
    echo $! > "$CACHE_DIR/web_ui.pid"
    cd ../..
}

# Function to start mobile UI development server
start_mobile_ui() {
    echo -e "${BLUE}Starting Mobile UI development server...${NC}"
    cd ui/mobile
    
    if [ ! -f "pubspec.yaml" ]; then
        echo -e "${YELLOW}Initializing Flutter project...${NC}"
        flutter create . --platforms=android,ios
    fi
    
    echo -e "${GREEN}Starting Flutter development server...${NC}"
    flutter run --hot &
    echo $! > "$CACHE_DIR/mobile_ui.pid"
    cd ../..
}

# Function to start TypeScript logic server
start_typescript_logic() {
    echo -e "${BLUE}Starting TypeScript logic server...${NC}"
    cd logic/typescript
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Initializing TypeScript project...${NC}"
        npm init -y
        npm install typescript @types/node ts-node nodemon express @types/express
        cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
    fi
    
    if [ ! -d "node_modules" ]; then
        npm install
    fi
    
    echo -e "${GREEN}Starting TypeScript logic server on port 3001...${NC}"
    npx nodemon src/server.ts &
    echo $! > "$CACHE_DIR/typescript_logic.pid"
    cd ../..
}

# Function to start Python AI server
start_python_ai() {
    echo -e "${BLUE}Starting Python AI server...${NC}"
    cd ai
    
    if [ ! -f "requirements.txt" ]; then
        echo -e "${YELLOW}Creating requirements.txt...${NC}"
        cat > requirements.txt << EOF
flask==2.3.3
flask-cors==4.0.0
numpy==1.24.3
pandas==2.0.3
scikit-learn==1.3.0
pytest==7.4.0
black==23.7.0
flake8==6.0.0
EOF
    fi
    
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}Creating Python virtual environment...${NC}"
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -r requirements.txt
    
    echo -e "${GREEN}Starting Python AI server on port 5000...${NC}"
    python app.py &
    echo $! > "$CACHE_DIR/python_ai.pid"
    deactivate
    cd ..
}

# Function to start Go database server
start_go_db() {
    echo -e "${BLUE}Starting Go database server...${NC}"
    cd db-layer/go
    
    if [ ! -f "go.mod" ]; then
        echo -e "${YELLOW}Initializing Go module...${NC}"
        go mod init polyglot-db
        go get github.com/gin-gonic/gin github.com/gin-contrib/cors
    fi
    
    echo -e "${GREEN}Starting Go database server on port 8080...${NC}"
    go run main.go &
    echo $! > "$CACHE_DIR/go_db.pid"
    cd ../..
}

# Function to start interop server
start_interop() {
    echo -e "${BLUE}Starting Interop server...${NC}"
    cd meta/interop
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Initializing Interop server...${NC}"
        npm init -y
        npm install express @types/express cors @types/cors ws @types/ws
    fi
    
    echo -e "${GREEN}Starting Interop server on port 4000...${NC}"
    node server.js &
    echo $! > "$CACHE_DIR/interop.pid"
    cd ../..
}

# Function to stop all servers
stop_all() {
    echo -e "${YELLOW}Stopping all development servers...${NC}"
    
    for pid_file in "$CACHE_DIR"/*.pid; do
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "${BLUE}Stopping process $pid...${NC}"
                kill "$pid"
            fi
            rm "$pid_file"
        fi
    done
    
    echo -e "${GREEN}All servers stopped.${NC}"
}

# Function to show status
show_status() {
    echo -e "${BLUE}Development Server Status:${NC}"
    echo "----------------------------------------"
    
    # Check web UI
    if check_port 3000; then
        echo -e "${GREEN}✓ Web UI (React) - http://localhost:3000${NC}"
    else
        echo -e "${RED}✗ Web UI (React) - Not running${NC}"
    fi
    
    # Check TypeScript logic
    if check_port 3001; then
        echo -e "${GREEN}✓ TypeScript Logic - http://localhost:3001${NC}"
    else
        echo -e "${RED}✗ TypeScript Logic - Not running${NC}"
    fi
    
    # Check Python AI
    if check_port 5000; then
        echo -e "${GREEN}✓ Python AI - http://localhost:5000${NC}"
    else
        echo -e "${RED}✗ Python AI - Not running${NC}"
    fi
    
    # Check Go DB
    if check_port 8080; then
        echo -e "${GREEN}✓ Go Database - http://localhost:8080${NC}"
    else
        echo -e "${RED}✗ Go Database - Not running${NC}"
    fi
    
    # Check Interop
    if check_port 4000; then
        echo -e "${GREEN}✓ Interop Server - http://localhost:4000${NC}"
    else
        echo -e "${RED}✗ Interop Server - Not running${NC}"
    fi
    
    echo "----------------------------------------"
}

# Main script logic
case "${1:-all}" in
    "web-ui"|"ui-web")
        start_web_ui
        ;;
    "mobile-ui"|"ui-mobile")
        start_mobile_ui
        ;;
    "typescript"|"ts")
        start_typescript_logic
        ;;
    "python"|"ai")
        start_python_ai
        ;;
    "go"|"db")
        start_go_db
        ;;
    "interop")
        start_interop
        ;;
    "stop")
        stop_all
        exit 0
        ;;
    "status")
        show_status
        exit 0
        ;;
    "all")
        echo -e "${BLUE}Starting all development servers...${NC}"
        
        # Create necessary directories
        mkdir -p "$LOG_DIR"
        mkdir -p "$CACHE_DIR"
        
        # Start servers
        start_web_ui
        sleep 2
        start_typescript_logic
        sleep 2
        start_python_ai
        sleep 2
        start_go_db
        sleep 2
        start_interop
        
        echo -e "${GREEN}✅ All development servers started!${NC}"
        echo -e "${BLUE}Access your application at:${NC}"
        echo -e "  Web UI: ${YELLOW}http://localhost:3000${NC}"
        echo -e "  API: ${YELLOW}http://localhost:3001${NC}"
        echo -e "  AI: ${YELLOW}http://localhost:5000${NC}"
        echo -e "  DB: ${YELLOW}http://localhost:8080${NC}"
        echo -e "  Interop: ${YELLOW}http://localhost:4000${NC}"
        echo ""
        echo -e "${BLUE}Useful commands:${NC}"
        echo -e "  Status: ${YELLOW}./scripts/dev.sh status${NC}"
        echo -e "  Stop all: ${YELLOW}./scripts/dev.sh stop${NC}"
        echo -e "  Logs: ${YELLOW}tail -f logs/*.log${NC}"
        ;;
    *)
        echo -e "${RED}Usage: $0 [all|web-ui|mobile-ui|typescript|python|go|interop|stop|status]${NC}"
        echo -e "${BLUE}Examples:${NC}"
        echo -e "  $0 all              # Start all servers"
        echo -e "  $0 web-ui           # Start only web UI"
        echo -e "  $0 python           # Start only Python AI"
        echo -e "  $0 stop             # Stop all servers"
        echo -e "  $0 status           # Show server status"
        exit 1
        ;;
esac

# Wait for user interrupt
if [ "${1:-all}" != "stop" ] && [ "${1:-all}" != "status" ]; then
    echo -e "${BLUE}Press Ctrl+C to stop all servers${NC}"
    trap stop_all INT
    wait
fi 