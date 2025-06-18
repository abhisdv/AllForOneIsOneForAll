#!/bin/bash

# Polyglot App Framework Build Script
# Builds all modules for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="build"
DIST_DIR="dist"
CACHE_DIR=".cache"
LOG_DIR="logs"

# Build tracking
TOTAL_MODULES=0
BUILT_MODULES=0
FAILED_MODULES=0

# Function to log build output
log_build() {
    local module="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$module] $message" >> "$LOG_DIR/build.log"
}

# Function to build TypeScript module
build_typescript() {
    local module_name="typescript"
    echo -e "${BLUE}Building TypeScript module...${NC}"
    log_build "$module_name" "Starting build"
    
    cd logic/typescript
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}TypeScript project not initialized. Skipping...${NC}"
        log_build "$module_name" "Project not initialized, skipping"
        cd ../..
        return
    fi
    
    # Install dependencies
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        npm install
    fi
    
    # Create build script if not exists
    if ! grep -q '"build"' package.json; then
        echo -e "${YELLOW}Adding build script...${NC}"
        npm pkg set scripts.build="tsc"
    fi
    
    # Create tsconfig for production if not exists
    if [ ! -f "tsconfig.prod.json" ]; then
        cat > tsconfig.prod.json << EOF
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "sourceMap": false,
    "declaration": false,
    "removeComments": true,
    "noEmitOnError": true
  },
  "exclude": ["node_modules", "tests", "**/*.test.ts", "**/*.spec.ts"]
}
EOF
    fi
    
    # Build the project
    echo -e "${YELLOW}Compiling TypeScript...${NC}"
    if npm run build; then
        echo -e "${GREEN}✓ TypeScript module built successfully${NC}"
        log_build "$module_name" "Build successful"
        BUILT_MODULES=$((BUILT_MODULES + 1))
        
        # Copy to build directory
        mkdir -p "../../$BUILD_DIR/typescript"
        cp -r dist/* "../../$BUILD_DIR/typescript/"
        cp package.json "../../$BUILD_DIR/typescript/"
    else
        echo -e "${RED}✗ TypeScript module build failed${NC}"
        log_build "$module_name" "Build failed"
        FAILED_MODULES=$((FAILED_MODULES + 1))
    fi
    
    TOTAL_MODULES=$((TOTAL_MODULES + 1))
    cd ../..
}

# Function to build Python module
build_python() {
    local module_name="python"
    echo -e "${BLUE}Building Python module...${NC}"
    log_build "$module_name" "Starting build"
    
    cd ai
    
    if [ ! -f "requirements.txt" ]; then
        echo -e "${YELLOW}Python project not initialized. Skipping...${NC}"
        log_build "$module_name" "Project not initialized, skipping"
        cd ..
        return
    fi
    
    # Create virtual environment if not exists
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Install dependencies
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip install -r requirements.txt
    
    # Create build directory
    mkdir -p "../$BUILD_DIR/python"
    
    # Copy source files
    echo -e "${YELLOW}Copying Python files...${NC}"
    cp -r *.py "../$BUILD_DIR/python/"
    cp requirements.txt "../$BUILD_DIR/python/"
    
    # Create Dockerfile for Python
    cat > "../$BUILD_DIR/python/Dockerfile" << EOF
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
EOF
    
    # Create .dockerignore
    cat > "../$BUILD_DIR/python/.dockerignore" << EOF
__pycache__
*.pyc
*.pyo
*.pyd
.Python
env
pip-log.txt
pip-delete-this-directory.txt
.tox
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.mypy_cache
.pytest_cache
.hypothesis
EOF
    
    deactivate
    
    echo -e "${GREEN}✓ Python module built successfully${NC}"
    log_build "$module_name" "Build successful"
    BUILT_MODULES=$((BUILT_MODULES + 1))
    TOTAL_MODULES=$((TOTAL_MODULES + 1))
    cd ..
}

# Function to build Go module
build_go() {
    local module_name="go"
    echo -e "${BLUE}Building Go module...${NC}"
    log_build "$module_name" "Starting build"
    
    cd db-layer/go
    
    if [ ! -f "go.mod" ]; then
        echo -e "${YELLOW}Go project not initialized. Skipping...${NC}"
        log_build "$module_name" "Project not initialized, skipping"
        cd ../..
        return
    fi
    
    # Download dependencies
    echo -e "${YELLOW}Downloading Go dependencies...${NC}"
    go mod download
    
    # Build for multiple platforms
    echo -e "${YELLOW}Building Go binaries...${NC}"
    
    # Linux
    GOOS=linux GOARCH=amd64 go build -o "../../$BUILD_DIR/go/app-linux-amd64" .
    
    # macOS
    GOOS=darwin GOARCH=amd64 go build -o "../../$BUILD_DIR/go/app-darwin-amd64" .
    
    # Windows
    GOOS=windows GOARCH=amd64 go build -o "../../$BUILD_DIR/go/app-windows-amd64.exe" .
    
    # Create Dockerfile for Go
    cat > "../../$BUILD_DIR/go/Dockerfile" << EOF
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/main .
EXPOSE 8080

CMD ["./main"]
EOF
    
    # Copy go.mod and go.sum
    cp go.mod "../../$BUILD_DIR/go/"
    cp go.sum "../../$BUILD_DIR/go/" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Go module built successfully${NC}"
    log_build "$module_name" "Build successful"
    BUILT_MODULES=$((BUILT_MODULES + 1))
    TOTAL_MODULES=$((TOTAL_MODULES + 1))
    cd ../..
}

# Function to build React web app
build_react() {
    local module_name="react"
    echo -e "${BLUE}Building React web app...${NC}"
    log_build "$module_name" "Starting build"
    
    cd ui/web
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}React project not initialized. Skipping...${NC}"
        log_build "$module_name" "Project not initialized, skipping"
        cd ../..
        return
    fi
    
    # Install dependencies
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Installing React dependencies...${NC}"
        npm install
    fi
    
    # Create build script if not exists
    if ! grep -q '"build"' package.json; then
        echo -e "${YELLOW}Adding build script...${NC}"
        npm pkg set scripts.build="react-scripts build"
    fi
    
    # Build the React app
    echo -e "${YELLOW}Building React app...${NC}"
    if npm run build; then
        echo -e "${GREEN}✓ React app built successfully${NC}"
        log_build "$module_name" "Build successful"
        BUILT_MODULES=$((BUILT_MODULES + 1))
        
        # Copy to build directory
        mkdir -p "../../$BUILD_DIR/web"
        cp -r build/* "../../$BUILD_DIR/web/"
    else
        echo -e "${RED}✗ React app build failed${NC}"
        log_build "$module_name" "Build failed"
        FAILED_MODULES=$((FAILED_MODULES + 1))
    fi
    
    TOTAL_MODULES=$((TOTAL_MODULES + 1))
    cd ../..
}

# Function to build Flutter mobile app
build_flutter() {
    local module_name="flutter"
    echo -e "${BLUE}Building Flutter mobile app...${NC}"
    log_build "$module_name" "Starting build"
    
    cd ui/mobile
    
    if [ ! -f "pubspec.yaml" ]; then
        echo -e "${YELLOW}Flutter project not initialized. Skipping...${NC}"
        log_build "$module_name" "Project not initialized, skipping"
        cd ../..
        return
    fi
    
    # Get dependencies
    echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
    flutter pub get
    
    # Build for web
    echo -e "${YELLOW}Building Flutter web app...${NC}"
    if flutter build web; then
        echo -e "${GREEN}✓ Flutter web app built successfully${NC}"
        log_build "$module_name" "Web build successful"
        
        # Copy to build directory
        mkdir -p "../../$BUILD_DIR/mobile-web"
        cp -r build/web/* "../../$BUILD_DIR/mobile-web/"
    else
        echo -e "${RED}✗ Flutter web app build failed${NC}"
        log_build "$module_name" "Web build failed"
        FAILED_MODULES=$((FAILED_MODULES + 1))
    fi
    
    # Build for Android (if possible)
    if command -v flutter >/dev/null 2>&1 && flutter doctor | grep -q "Android toolchain"; then
        echo -e "${YELLOW}Building Flutter Android app...${NC}"
        if flutter build apk --release; then
            echo -e "${GREEN}✓ Flutter Android app built successfully${NC}"
            log_build "$module_name" "Android build successful"
            
            # Copy APK to build directory
            mkdir -p "../../$BUILD_DIR/mobile-android"
            cp build/app/outputs/flutter-apk/app-release.apk "../../$BUILD_DIR/mobile-android/"
        else
            echo -e "${RED}✗ Flutter Android app build failed${NC}"
            log_build "$module_name" "Android build failed"
        fi
    else
        echo -e "${YELLOW}Android toolchain not available, skipping Android build${NC}"
    fi
    
    TOTAL_MODULES=$((TOTAL_MODULES + 1))
    cd ../..
}

# Function to build Docker images
build_docker() {
    echo -e "${BLUE}Building Docker images...${NC}"
    
    # Build Python image
    if [ -d "$BUILD_DIR/python" ]; then
        echo -e "${YELLOW}Building Python Docker image...${NC}"
        cd "$BUILD_DIR/python"
        docker build -t polyglot-python:latest .
        cd ../..
        echo -e "${GREEN}✓ Python Docker image built${NC}"
    fi
    
    # Build Go image
    if [ -d "$BUILD_DIR/go" ]; then
        echo -e "${YELLOW}Building Go Docker image...${NC}"
        cd "$BUILD_DIR/go"
        docker build -t polyglot-go:latest .
        cd ../..
        echo -e "${GREEN}✓ Go Docker image built${NC}"
    fi
    
    # Build web image
    if [ -d "$BUILD_DIR/web" ]; then
        echo -e "${YELLOW}Building Web Docker image...${NC}"
        cat > "$BUILD_DIR/web/Dockerfile" << EOF
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
        cd "$BUILD_DIR/web"
        docker build -t polyglot-web:latest .
        cd ../..
        echo -e "${GREEN}✓ Web Docker image built${NC}"
    fi
}

# Function to create deployment package
create_deployment_package() {
    echo -e "${BLUE}Creating deployment package...${NC}"
    
    mkdir -p "$DIST_DIR"
    
    # Create deployment manifest
    cat > "$DIST_DIR/deployment.json" << EOF
{
  "name": "polyglot-app",
  "version": "$(date +%Y%m%d-%H%M%S)",
  "buildDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "modules": {
    "typescript": "$([ -d "$BUILD_DIR/typescript" ] && echo "built" || echo "not-built")",
    "python": "$([ -d "$BUILD_DIR/python" ] && echo "built" || echo "not-built")",
    "go": "$([ -d "$BUILD_DIR/go" ] && echo "built" || echo "not-built")",
    "react": "$([ -d "$BUILD_DIR/web" ] && echo "built" || echo "not-built")",
    "flutter": "$([ -d "$BUILD_DIR/mobile-web" ] && echo "built" || echo "not-built")"
  },
  "dockerImages": [
    "polyglot-python:latest",
    "polyglot-go:latest",
    "polyglot-web:latest"
  ]
}
EOF
    
    # Copy build artifacts
    if [ -d "$BUILD_DIR" ]; then
        cp -r "$BUILD_DIR" "$DIST_DIR/"
    fi
    
    # Create deployment scripts
    cat > "$DIST_DIR/deploy.sh" << 'EOF'
#!/bin/bash
# Deployment script for Polyglot App

set -e

echo "🚀 Deploying Polyglot App..."

# Deploy Docker containers
docker-compose up -d

echo "✅ Deployment complete!"
echo "🌐 Web app: http://localhost:3000"
echo "🔧 API: http://localhost:3001"
echo "🤖 AI: http://localhost:5000"
echo "🗄️  DB: http://localhost:8080"
EOF
    
    chmod +x "$DIST_DIR/deploy.sh"
    
    # Create docker-compose.yml
    cat > "$DIST_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  web:
    image: polyglot-web:latest
    ports:
      - "3000:80"
    depends_on:
      - api
      - ai
      - db
  
  api:
    image: polyglot-go:latest
    ports:
      - "3001:8080"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
  
  ai:
    image: polyglot-python:latest
    ports:
      - "5000:5000"
    environment:
      - API_HOST=api
      - API_PORT=8080
  
  db:
    image: postgres:13
    environment:
      - POSTGRES_DB=polyglot
      - POSTGRES_USER=polyglot
      - POSTGRES_PASSWORD=polyglot
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF
    
    echo -e "${GREEN}✓ Deployment package created in $DIST_DIR${NC}"
}

# Function to show build summary
show_build_summary() {
    echo -e "${BLUE}Build Summary:${NC}"
    echo "----------------------------------------"
    echo -e "Total modules: ${YELLOW}$TOTAL_MODULES${NC}"
    echo -e "Built successfully: ${GREEN}$BUILT_MODULES${NC}"
    echo -e "Failed: ${RED}$FAILED_MODULES${NC}"
    echo "----------------------------------------"
    
    if [ $FAILED_MODULES -gt 0 ]; then
        echo -e "${RED}❌ Some builds failed! Check logs for details.${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ All builds completed successfully!${NC}"
    fi
}

# Main script logic
case "${1:-all}" in
    "typescript"|"ts")
        build_typescript
        ;;
    "python"|"py")
        build_python
        ;;
    "go")
        build_go
        ;;
    "react"|"web")
        build_react
        ;;
    "flutter"|"mobile")
        build_flutter
        ;;
    "docker")
        build_docker
        ;;
    "package")
        create_deployment_package
        ;;
    "all")
        echo -e "${BLUE}Building all modules...${NC}"
        
        # Create necessary directories
        mkdir -p "$BUILD_DIR"
        mkdir -p "$DIST_DIR"
        mkdir -p "$LOG_DIR"
        
        # Clear previous build log
        > "$LOG_DIR/build.log"
        
        # Build all modules
        build_typescript
        build_python
        build_go
        build_react
        build_flutter
        
        # Build Docker images
        build_docker
        
        # Create deployment package
        create_deployment_package
        
        # Show summary
        show_build_summary
        
        echo -e "${BLUE}Build artifacts:${NC}"
        echo -e "  Build directory: ${YELLOW}$BUILD_DIR${NC}"
        echo -e "  Distribution: ${YELLOW}$DIST_DIR${NC}"
        echo -e "  Logs: ${YELLOW}$LOG_DIR/build.log${NC}"
        ;;
    *)
        echo -e "${RED}Usage: $0 [all|typescript|python|go|react|flutter|docker|package]${NC}"
        echo -e "${BLUE}Examples:${NC}"
        echo -e "  $0 all              # Build all modules"
        echo -e "  $0 typescript       # Build TypeScript module only"
        echo -e "  $0 python           # Build Python module only"
        echo -e "  $0 go               # Build Go module only"
        echo -e "  $0 react            # Build React web app only"
        echo -e "  $0 flutter          # Build Flutter mobile app only"
        echo -e "  $0 docker           # Build Docker images only"
        echo -e "  $0 package          # Create deployment package only"
        exit 1
        ;;
esac 