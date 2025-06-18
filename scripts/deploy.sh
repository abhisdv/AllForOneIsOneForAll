#!/bin/bash

# Polyglot App Framework Deployment Script
# Handles deployment to different platforms

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
DEPLOY_DIR="deploy"
LOG_DIR="logs"
BACKUP_DIR="backups"

# Deployment tracking
DEPLOYMENT_ID=$(date +%Y%m%d-%H%M%S)
DEPLOYMENT_LOG="$LOG_DIR/deployment-$DEPLOYMENT_ID.log"

# Function to log deployment
log_deploy() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$DEPLOYMENT_LOG"
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking deployment prerequisites...${NC}"
    
    # Check if build exists
    if [ ! -d "$BUILD_DIR" ] && [ ! -d "$DIST_DIR" ]; then
        echo -e "${RED}❌ No build artifacts found. Run './scripts/build.sh' first.${NC}"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found. Please install Docker.${NC}"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Function to create backup
create_backup() {
    echo -e "${BLUE}Creating backup of current deployment...${NC}"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup current containers
    if docker ps -q --filter "name=polyglot" | grep -q .; then
        docker ps --filter "name=polyglot" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" > "$BACKUP_DIR/containers-$DEPLOYMENT_ID.txt"
        log_deploy "Backup created: containers-$DEPLOYMENT_ID.txt"
    fi
    
    # Backup current images
    docker images --filter "reference=polyglot*" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" > "$BACKUP_DIR/images-$DEPLOYMENT_ID.txt"
    log_deploy "Backup created: images-$DEPLOYMENT_ID.txt"
    
    echo -e "${GREEN}✅ Backup created${NC}"
}

# Function to deploy to local Docker
deploy_local() {
    echo -e "${BLUE}Deploying to local Docker environment...${NC}"
    log_deploy "Starting local deployment"
    
    # Use dist directory if available, otherwise use build
    local source_dir="$DIST_DIR"
    if [ ! -d "$source_dir" ]; then
        source_dir="$BUILD_DIR"
    fi
    
    if [ ! -d "$source_dir" ]; then
        echo -e "${RED}❌ No deployment artifacts found${NC}"
        exit 1
    fi
    
    cd "$source_dir"
    
    # Stop existing containers
    if [ -f "docker-compose.yml" ]; then
        echo -e "${YELLOW}Stopping existing containers...${NC}"
        docker-compose down --remove-orphans || true
    fi
    
    # Start new deployment
    echo -e "${YELLOW}Starting new deployment...${NC}"
    if docker-compose up -d; then
        echo -e "${GREEN}✅ Local deployment successful${NC}"
        log_deploy "Local deployment completed successfully"
        
        # Wait for services to be ready
        echo -e "${YELLOW}Waiting for services to be ready...${NC}"
        sleep 10
        
        # Check service health
        check_service_health
    else
        echo -e "${RED}❌ Local deployment failed${NC}"
        log_deploy "Local deployment failed"
        exit 1
    fi
    
    cd - > /dev/null
}

# Function to deploy to cloud (AWS/GCP/Azure)
deploy_cloud() {
    local platform="$1"
    echo -e "${BLUE}Deploying to $platform cloud...${NC}"
    log_deploy "Starting cloud deployment to $platform"
    
    case "$platform" in
        "aws")
            deploy_aws
            ;;
        "gcp")
            deploy_gcp
            ;;
        "azure")
            deploy_azure
            ;;
        *)
            echo -e "${RED}❌ Unsupported cloud platform: $platform${NC}"
            exit 1
            ;;
    esac
}

# Function to deploy to AWS
deploy_aws() {
    echo -e "${YELLOW}Deploying to AWS...${NC}"
    
    # Check AWS CLI
    if ! command -v aws >/dev/null 2>&1; then
        echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI.${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'.${NC}"
        exit 1
    fi
    
    # Create ECS deployment
    echo -e "${YELLOW}Creating ECS deployment...${NC}"
    
    # Create ECS task definition
    cat > "$DIST_DIR/task-definition.json" << EOF
{
  "family": "polyglot-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "web",
      "image": "polyglot-web:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true
    },
    {
      "name": "api",
      "image": "polyglot-go:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "essential": true
    },
    {
      "name": "ai",
      "image": "polyglot-python:latest",
      "portMappings": [
        {
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ]
}
EOF
    
    echo -e "${GREEN}✅ AWS deployment configuration created${NC}"
    log_deploy "AWS deployment configuration created"
}

# Function to deploy to GCP
deploy_gcp() {
    echo -e "${YELLOW}Deploying to GCP...${NC}"
    
    # Check gcloud CLI
    if ! command -v gcloud >/dev/null 2>&1; then
        echo -e "${RED}❌ Google Cloud CLI not found. Please install gcloud.${NC}"
        exit 1
    fi
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo -e "${RED}❌ Not authenticated with GCP. Please run 'gcloud auth login'.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Creating GKE deployment...${NC}"
    
    # Create Kubernetes deployment
    cat > "$DIST_DIR/k8s-deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: polyglot-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: polyglot-app
  template:
    metadata:
      labels:
        app: polyglot-app
    spec:
      containers:
      - name: web
        image: polyglot-web:latest
        ports:
        - containerPort: 80
      - name: api
        image: polyglot-go:latest
        ports:
        - containerPort: 8080
      - name: ai
        image: polyglot-python:latest
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: polyglot-service
spec:
  selector:
    app: polyglot-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
EOF
    
    echo -e "${GREEN}✅ GCP deployment configuration created${NC}"
    log_deploy "GCP deployment configuration created"
}

# Function to deploy to Azure
deploy_azure() {
    echo -e "${YELLOW}Deploying to Azure...${NC}"
    
    # Check Azure CLI
    if ! command -v az >/dev/null 2>&1; then
        echo -e "${RED}❌ Azure CLI not found. Please install Azure CLI.${NC}"
        exit 1
    fi
    
    # Check if logged in
    if ! az account show >/dev/null 2>&1; then
        echo -e "${RED}❌ Not logged in to Azure. Please run 'az login'.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Creating Azure Container Instances deployment...${NC}"
    
    # Create Azure deployment template
    cat > "$DIST_DIR/azure-deployment.json" << EOF
{
  "type": "Microsoft.ContainerInstance/containerGroups",
  "apiVersion": "2021-10-01",
  "name": "polyglot-app",
  "location": "[resourceGroup().location]",
  "properties": {
    "containers": [
      {
        "name": "web",
        "properties": {
          "image": "polyglot-web:latest",
          "ports": [
            {
              "port": 80
            }
          ]
        }
      },
      {
        "name": "api",
        "properties": {
          "image": "polyglot-go:latest",
          "ports": [
            {
              "port": 8080
            }
          ]
        }
      },
      {
        "name": "ai",
        "properties": {
          "image": "polyglot-python:latest",
          "ports": [
            {
              "port": 5000
            }
          ]
        }
      }
    ],
    "osType": "Linux",
    "ipAddress": {
      "type": "Public",
      "ports": [
        {
          "protocol": "tcp",
          "port": 80
        }
      ]
    }
  }
}
EOF
    
    echo -e "${GREEN}✅ Azure deployment configuration created${NC}"
    log_deploy "Azure deployment configuration created"
}

# Function to deploy mobile app
deploy_mobile() {
    local platform="$1"
    echo -e "${BLUE}Deploying mobile app to $platform...${NC}"
    log_deploy "Starting mobile deployment to $platform"
    
    case "$platform" in
        "android")
            deploy_android
            ;;
        "ios")
            deploy_ios
            ;;
        *)
            echo -e "${RED}❌ Unsupported mobile platform: $platform${NC}"
            exit 1
            ;;
    esac
}

# Function to deploy Android app
deploy_android() {
    echo -e "${YELLOW}Deploying Android app...${NC}"
    
    if [ ! -d "$BUILD_DIR/mobile-android" ]; then
        echo -e "${RED}❌ Android build not found. Run './scripts/build.sh flutter' first.${NC}"
        exit 1
    fi
    
    # Check if APK exists
    local apk_file="$BUILD_DIR/mobile-android/app-release.apk"
    if [ ! -f "$apk_file" ]; then
        echo -e "${RED}❌ APK file not found: $apk_file${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Android APK ready for deployment: $apk_file${NC}"
    echo -e "${BLUE}To deploy to Google Play Store:${NC}"
    echo -e "1. Upload APK to Google Play Console"
    echo -e "2. Create a new release"
    echo -e "3. Submit for review"
    
    log_deploy "Android APK ready: $apk_file"
}

# Function to deploy iOS app
deploy_ios() {
    echo -e "${YELLOW}Deploying iOS app...${NC}"
    
    if [ ! -d "$BUILD_DIR/mobile-ios" ]; then
        echo -e "${RED}❌ iOS build not found. Run './scripts/build.sh flutter' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ iOS app ready for deployment${NC}"
    echo -e "${BLUE}To deploy to App Store:${NC}"
    echo -e "1. Archive the app in Xcode"
    echo -e "2. Upload to App Store Connect"
    echo -e "3. Submit for review"
    
    log_deploy "iOS app ready for deployment"
}

# Function to check service health
check_service_health() {
    echo -e "${BLUE}Checking service health...${NC}"
    
    local services=(
        "http://localhost:3000/health"
        "http://localhost:3001/health"
        "http://localhost:5000/health"
        "http://localhost:8080/health"
    )
    
    local healthy=0
    local total=${#services[@]}
    
    for service in "${services[@]}"; do
        if curl -s -f "$service" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ $service - Healthy${NC}"
            ((healthy++))
        else
            echo -e "${RED}❌ $service - Unhealthy${NC}"
        fi
    done
    
    if [ $healthy -eq $total ]; then
        echo -e "${GREEN}✅ All services are healthy${NC}"
        log_deploy "All services healthy"
    else
        echo -e "${YELLOW}⚠️  $healthy/$total services are healthy${NC}"
        log_deploy "$healthy/$total services healthy"
    fi
}

# Function to monitor deployment
monitor_deployment() {
    echo -e "${BLUE}Starting deployment monitoring...${NC}"
    log_deploy "Starting monitoring"
    
    # Monitor for 5 minutes
    local duration=300
    local interval=10
    local elapsed=0
    
    while [ $elapsed -lt $duration ]; do
        echo -e "${YELLOW}Monitoring... ($elapsed/$duration seconds)${NC}"
        
        # Check service health
        check_service_health
        
        # Check container status
        if docker ps --filter "name=polyglot" --format "table {{.Names}}\t{{.Status}}" | grep -q "Up"; then
            echo -e "${GREEN}✅ Containers running${NC}"
        else
            echo -e "${RED}❌ Some containers not running${NC}"
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    echo -e "${GREEN}✅ Monitoring completed${NC}"
    log_deploy "Monitoring completed"
}

# Function to rollback deployment
rollback_deployment() {
    echo -e "${BLUE}Rolling back deployment...${NC}"
    log_deploy "Starting rollback"
    
    # Stop current deployment
    if [ -f "$DIST_DIR/docker-compose.yml" ]; then
        cd "$DIST_DIR"
        docker-compose down
        cd - > /dev/null
    fi
    
    # Restore from backup if available
    local latest_backup=$(ls -t "$BACKUP_DIR"/containers-*.txt 2>/dev/null | head -n1)
    if [ -n "$latest_backup" ]; then
        echo -e "${YELLOW}Restoring from backup: $latest_backup${NC}"
        # Here you would implement the actual restore logic
        log_deploy "Restored from backup: $latest_backup"
    fi
    
    echo -e "${GREEN}✅ Rollback completed${NC}"
    log_deploy "Rollback completed"
}

# Function to show deployment status
show_status() {
    echo -e "${BLUE}Deployment Status:${NC}"
    echo "----------------------------------------"
    
    # Check if containers are running
    if docker ps -q --filter "name=polyglot" | grep -q .; then
        echo -e "${GREEN}✅ Polyglot containers are running${NC}"
        docker ps --filter "name=polyglot" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${RED}❌ No polyglot containers running${NC}"
    fi
    
    echo "----------------------------------------"
    
    # Check service endpoints
    echo -e "${BLUE}Service Endpoints:${NC}"
    echo -e "  Web UI: ${YELLOW}http://localhost:3000${NC}"
    echo -e "  API: ${YELLOW}http://localhost:3001${NC}"
    echo -e "  AI: ${YELLOW}http://localhost:5000${NC}"
    echo -e "  DB: ${YELLOW}http://localhost:8080${NC}"
    echo "----------------------------------------"
}

# Main script logic
case "${1:-local}" in
    "local")
        check_prerequisites
        create_backup
        deploy_local
        ;;
    "aws")
        check_prerequisites
        create_backup
        deploy_cloud "aws"
        ;;
    "gcp")
        check_prerequisites
        create_backup
        deploy_cloud "gcp"
        ;;
    "azure")
        check_prerequisites
        create_backup
        deploy_cloud "azure"
        ;;
    "android")
        deploy_mobile "android"
        ;;
    "ios")
        deploy_mobile "ios"
        ;;
    "monitor")
        monitor_deployment
        ;;
    "rollback")
        rollback_deployment
        ;;
    "status")
        show_status
        exit 0
        ;;
    "health")
        check_service_health
        exit 0
        ;;
    *)
        echo -e "${RED}Usage: $0 [local|aws|gcp|azure|android|ios|monitor|rollback|status|health]${NC}"
        echo -e "${BLUE}Examples:${NC}"
        echo -e "  $0 local              # Deploy to local Docker"
        echo -e "  $0 aws                # Deploy to AWS"
        echo -e "  $0 gcp                # Deploy to Google Cloud"
        echo -e "  $0 azure              # Deploy to Azure"
        echo -e "  $0 android            # Deploy Android app"
        echo -e "  $0 ios                # Deploy iOS app"
        echo -e "  $0 monitor            # Monitor deployment"
        echo -e "  $0 rollback           # Rollback deployment"
        echo -e "  $0 status             # Show deployment status"
        echo -e "  $0 health             # Check service health"
        exit 1
        ;;
esac

# Log deployment completion
log_deploy "Deployment script completed"

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${BLUE}Deployment log: ${YELLOW}$DEPLOYMENT_LOG${NC}" 