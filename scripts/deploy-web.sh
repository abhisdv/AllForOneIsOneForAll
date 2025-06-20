#!/bin/bash

# 🚀 Web UI Deployment Script
# Deploys the AllForOneIsOneForAll intro page to various platforms

set -e

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  github     Deploy to GitHub Pages"
    echo "  netlify    Deploy to Netlify (requires netlify-cli)"
    echo "  vercel     Deploy to Vercel (requires vercel-cli)"
    echo "  firebase   Deploy to Firebase (requires firebase-tools)"
    echo "  build      Only build the project (no deploy)"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 github    # Deploy to GitHub Pages"
    echo "  $0 build     # Build for production"
}

# Function to build the project
build_project() {
    print_status "Building the web UI..."
    
    cd ui/web
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies..."
        npm install
    fi
    
    # Build the project
    print_status "Creating production build..."
    npm run build
    
    print_success "Build completed successfully!"
    print_status "Build files are in: ui/web/build/"
    
    cd ../..
}

# Function to deploy to GitHub Pages
deploy_github() {
    print_status "Deploying to GitHub Pages..."
    
    cd ui/web
    
    # Check if gh-pages is installed
    if ! npm list gh-pages > /dev/null 2>&1; then
        print_status "Installing gh-pages..."
        npm install gh-pages --save-dev
    fi
    
    # Deploy
    npm run deploy
    
    cd ../..
    
    print_success "Deployed to GitHub Pages!"
    print_status "Your website will be available at: https://abhishek.dharmman.github.io/my-polyglot-app"
    print_warning "It may take a few minutes for changes to appear."
}

# Function to deploy to Netlify
deploy_netlify() {
    print_status "Deploying to Netlify..."
    
    # Check if netlify-cli is installed
    if ! command -v netlify &> /dev/null; then
        print_error "netlify-cli is not installed. Please install it first:"
        echo "npm install -g netlify-cli"
        exit 1
    fi
    
    # Build the project
    build_project
    
    # Deploy to Netlify
    cd ui/web/build
    
    netlify deploy --prod --dir=.
    
    cd ../../..
    
    print_success "Deployed to Netlify!"
}

# Function to deploy to Vercel
deploy_vercel() {
    print_status "Deploying to Vercel..."
    
    # Check if vercel-cli is installed
    if ! command -v vercel &> /dev/null; then
        print_error "vercel-cli is not installed. Please install it first:"
        echo "npm install -g vercel"
        exit 1
    fi
    
    cd ui/web
    
    # Deploy to Vercel
    vercel --prod
    
    cd ../..
    
    print_success "Deployed to Vercel!"
}

# Function to deploy to Firebase
deploy_firebase() {
    print_status "Deploying to Firebase..."
    
    # Check if firebase-tools is installed
    if ! command -v firebase &> /dev/null; then
        print_error "firebase-tools is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Build the project
    build_project
    
    # Deploy to Firebase
    firebase deploy --only hosting
    
    print_success "Deployed to Firebase!"
}

# Main script logic
case "${1:-help}" in
    "github")
        build_project
        deploy_github
        ;;
    "netlify")
        deploy_netlify
        ;;
    "vercel")
        deploy_vercel
        ;;
    "firebase")
        deploy_firebase
        ;;
    "build")
        build_project
        ;;
    "help"|*)
        show_usage
        ;;
esac 