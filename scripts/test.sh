#!/bin/bash

# Polyglot App Framework Testing Script
# Runs tests across all languages and provides unified reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE="appfusion.json"
TEST_DIR="tests"
REPORT_DIR="test-reports"
COVERAGE_DIR="coverage"
LOG_DIR="logs"

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Function to create test report
create_test_report() {
    local test_type="$1"
    local language="$2"
    local result="$3"
    local output="$4"
    local duration="$5"
    
    mkdir -p "$REPORT_DIR"
    
    cat >> "$REPORT_DIR/test-report.json" << EOF
{
  "test_type": "$test_type",
  "language": "$language",
  "result": "$result",
  "duration": "$duration",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "output": "$output"
}
EOF
}

# Function to run TypeScript tests
run_typescript_tests() {
    echo -e "${BLUE}Running TypeScript tests...${NC}"
    
    cd logic/typescript
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}TypeScript project not initialized. Skipping...${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        cd ../..
        return
    fi
    
    # Install test dependencies if not present
    if ! npm list jest >/dev/null 2>&1; then
        npm install --save-dev jest @types/jest ts-jest
    fi
    
    # Create Jest config if not present
    if [ ! -f "jest.config.js" ]; then
        cat > jest.config.js << EOF
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: ['src/**/*.ts'],
  coverageDirectory: '../coverage/typescript',
  coverageReporters: ['text', 'lcov', 'html']
};
EOF
    fi
    
    # Create sample test if no tests exist
    if [ ! -f "tests" ] && [ ! -f "src/__tests__" ]; then
        mkdir -p tests
        cat > tests/sample.test.ts << EOF
describe('Sample Test', () => {
  test('should pass', () => {
    expect(1 + 1).toBe(2);
  });
  
  test('should handle async operations', async () => {
    const result = await Promise.resolve('success');
    expect(result).toBe('success');
  });
});
EOF
    fi
    
    start_time=$(date +%s)
    
    if npm test -- --coverage --json --outputFile=test-results.json; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✓ TypeScript tests passed in ${duration}s${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        create_test_report "unit" "typescript" "passed" "All tests passed" "$duration"
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}✗ TypeScript tests failed in ${duration}s${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        create_test_report "unit" "typescript" "failed" "Tests failed" "$duration"
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    cd ../..
}

# Function to run Python tests
run_python_tests() {
    echo -e "${BLUE}Running Python tests...${NC}"
    
    cd ai
    
    if [ ! -f "requirements.txt" ]; then
        echo -e "${YELLOW}Python project not initialized. Skipping...${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        cd ..
        return
    fi
    
    # Create virtual environment if not exists
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Install test dependencies
    pip install pytest pytest-cov pytest-asyncio
    
    # Create sample test if no tests exist
    if [ ! -f "tests" ]; then
        mkdir -p tests
        cat > tests/test_sample.py << EOF
import pytest

def test_basic():
    assert 1 + 1 == 2

def test_string():
    assert "hello" + " world" == "hello world"

@pytest.mark.asyncio
async def test_async():
    result = await asyncio.sleep(0.1)
    assert result is None
EOF
    fi
    
    start_time=$(date +%s)
    
    if python -m pytest tests/ -v --cov=. --cov-report=html:../coverage/python --cov-report=term; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✓ Python tests passed in ${duration}s${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        create_test_report "unit" "python" "passed" "All tests passed" "$duration"
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}✗ Python tests failed in ${duration}s${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        create_test_report "unit" "python" "failed" "Tests failed" "$duration"
    fi
    
    deactivate
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    cd ..
}

# Function to run Go tests
run_go_tests() {
    echo -e "${BLUE}Running Go tests...${NC}"
    
    cd db-layer/go
    
    if [ ! -f "go.mod" ]; then
        echo -e "${YELLOW}Go project not initialized. Skipping...${NC}"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        cd ../..
        return
    fi
    
    # Create sample test if no tests exist
    if [ ! -f "*_test.go" ]; then
        cat > sample_test.go << EOF
package main

import (
	"testing"
)

func TestBasic(t *testing.T) {
	if 1+1 != 2 {
		t.Errorf("Expected 2, got %d", 1+1)
	}
}

func TestString(t *testing.T) {
	result := "hello" + " world"
	expected := "hello world"
	if result != expected {
		t.Errorf("Expected %s, got %s", expected, result)
	}
}
EOF
    fi
    
    start_time=$(date +%s)
    
    if go test -v -coverprofile=coverage.out ./...; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✓ Go tests passed in ${duration}s${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        create_test_report "unit" "go" "passed" "All tests passed" "$duration"
        
        # Generate coverage report
        go tool cover -html=coverage.out -o ../../coverage/go/coverage.html
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}✗ Go tests failed in ${duration}s${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        create_test_report "unit" "go" "failed" "Tests failed" "$duration"
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    cd ../..
}

# Function to run integration tests
run_integration_tests() {
    echo -e "${BLUE}Running integration tests...${NC}"
    
    cd tests/integration
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Initializing integration test suite...${NC}"
        npm init -y
        npm install --save-dev jest supertest @types/jest @types/supertest
    fi
    
    # Create integration test if not exists
    if [ ! -f "api.test.js" ]; then
        cat > api.test.js << EOF
const request = require('supertest');

describe('API Integration Tests', () => {
  test('should connect to TypeScript API', async () => {
    const response = await request('http://localhost:3001')
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('ok');
  });
  
  test('should connect to Python AI API', async () => {
    const response = await request('http://localhost:5000')
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('ok');
  });
  
  test('should connect to Go DB API', async () => {
    const response = await request('http://localhost:8080')
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('ok');
  });
});
EOF
    fi
    
    start_time=$(date +%s)
    
    if npm test; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✓ Integration tests passed in ${duration}s${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        create_test_report "integration" "all" "passed" "All integration tests passed" "$duration"
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}✗ Integration tests failed in ${duration}s${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        create_test_report "integration" "all" "failed" "Integration tests failed" "$duration"
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    cd ../..
}

# Function to run E2E tests
run_e2e_tests() {
    echo -e "${BLUE}Running E2E tests...${NC}"
    
    cd tests/e2e
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}Initializing E2E test suite...${NC}"
        npm init -y
        npm install --save-dev playwright
        npx playwright install
    fi
    
    # Create E2E test if not exists
    if [ ! -f "e2e.spec.js" ]; then
        cat > e2e.spec.js << EOF
const { test, expect } = require('@playwright/test');

test('should load web application', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await expect(page).toHaveTitle(/Polyglot App/);
});

test('should interact with API', async ({ page }) => {
  const response = await page.request.get('http://localhost:3001/health');
  expect(response.status()).toBe(200);
  
  const data = await response.json();
  expect(data.status).toBe('ok');
});
EOF
    fi
    
    start_time=$(date +%s)
    
    if npx playwright test; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${GREEN}✓ E2E tests passed in ${duration}s${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        create_test_report "e2e" "all" "passed" "All E2E tests passed" "$duration"
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        echo -e "${RED}✗ E2E tests failed in ${duration}s${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        create_test_report "e2e" "all" "failed" "E2E tests failed" "$duration"
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    cd ../..
}

# Function to generate test report
generate_test_report() {
    echo -e "${BLUE}Generating test report...${NC}"
    
    mkdir -p "$REPORT_DIR"
    
    cat > "$REPORT_DIR/summary.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Polyglot App Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .stats { display: flex; gap: 20px; margin: 20px 0; }
        .stat { padding: 10px; border-radius: 5px; text-align: center; }
        .passed { background: #d4edda; color: #155724; }
        .failed { background: #f8d7da; color: #721c24; }
        .skipped { background: #fff3cd; color: #856404; }
        .total { background: #d1ecf1; color: #0c5460; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Polyglot App Test Report</h1>
        <p>Generated on: $(date)</p>
    </div>
    
    <div class="stats">
        <div class="stat total">
            <h3>Total</h3>
            <h2>$TOTAL_TESTS</h2>
        </div>
        <div class="stat passed">
            <h3>Passed</h3>
            <h2>$PASSED_TESTS</h2>
        </div>
        <div class="stat failed">
            <h3>Failed</h3>
            <h2>$FAILED_TESTS</h2>
        </div>
        <div class="stat skipped">
            <h3>Skipped</h3>
            <h2>$SKIPPED_TESTS</h2>
        </div>
    </div>
    
    <h2>Test Results</h2>
    <table>
        <tr>
            <th>Type</th>
            <th>Language</th>
            <th>Result</th>
            <th>Duration</th>
            <th>Timestamp</th>
        </tr>
EOF
    
    if [ -f "$REPORT_DIR/test-report.json" ]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                test_type=$(echo "$line" | grep -o '"test_type":"[^"]*"' | cut -d'"' -f4)
                language=$(echo "$line" | grep -o '"language":"[^"]*"' | cut -d'"' -f4)
                result=$(echo "$line" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
                duration=$(echo "$line" | grep -o '"duration":"[^"]*"' | cut -d'"' -f4)
                timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
                
                echo "        <tr>" >> "$REPORT_DIR/summary.html"
                echo "            <td>$test_type</td>" >> "$REPORT_DIR/summary.html"
                echo "            <td>$language</td>" >> "$REPORT_DIR/summary.html"
                echo "            <td>$result</td>" >> "$REPORT_DIR/summary.html"
                echo "            <td>${duration}s</td>" >> "$REPORT_DIR/summary.html"
                echo "            <td>$timestamp</td>" >> "$REPORT_DIR/summary.html"
                echo "        </tr>" >> "$REPORT_DIR/summary.html"
            fi
        done < "$REPORT_DIR/test-report.json"
    fi
    
    cat >> "$REPORT_DIR/summary.html" << EOF
    </table>
</body>
</html>
EOF
    
    echo -e "${GREEN}Test report generated: $REPORT_DIR/summary.html${NC}"
}

# Function to show test coverage
show_coverage() {
    echo -e "${BLUE}Test Coverage Summary:${NC}"
    echo "----------------------------------------"
    
    if [ -d "$COVERAGE_DIR/typescript" ]; then
        echo -e "${GREEN}TypeScript Coverage:${NC}"
        cat "$COVERAGE_DIR/typescript/coverage-summary.json" 2>/dev/null || echo "No coverage data"
    fi
    
    if [ -d "$COVERAGE_DIR/python" ]; then
        echo -e "${GREEN}Python Coverage:${NC}"
        echo "HTML report: $COVERAGE_DIR/python/index.html"
    fi
    
    if [ -d "$COVERAGE_DIR/go" ]; then
        echo -e "${GREEN}Go Coverage:${NC}"
        echo "HTML report: $COVERAGE_DIR/go/coverage.html"
    fi
    
    echo "----------------------------------------"
}

# Main script logic
case "${1:-all}" in
    "unit")
        echo -e "${BLUE}Running unit tests...${NC}"
        run_typescript_tests
        run_python_tests
        run_go_tests
        ;;
    "integration")
        echo -e "${BLUE}Running integration tests...${NC}"
        run_integration_tests
        ;;
    "e2e")
        echo -e "${BLUE}Running E2E tests...${NC}"
        run_e2e_tests
        ;;
    "coverage")
        show_coverage
        exit 0
        ;;
    "report")
        generate_test_report
        exit 0
        ;;
    "all")
        echo -e "${BLUE}Running all tests...${NC}"
        
        # Create necessary directories
        mkdir -p "$REPORT_DIR"
        mkdir -p "$COVERAGE_DIR"
        mkdir -p "$LOG_DIR"
        
        # Clear previous test report
        > "$REPORT_DIR/test-report.json"
        
        # Run all test types
        run_typescript_tests
        run_python_tests
        run_go_tests
        run_integration_tests
        run_e2e_tests
        
        # Generate final report
        generate_test_report
        show_coverage
        
        # Print summary
        echo -e "${BLUE}Test Summary:${NC}"
        echo "----------------------------------------"
        echo -e "Total: ${YELLOW}$TOTAL_TESTS${NC}"
        echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
        echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
        echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
        echo "----------------------------------------"
        
        if [ $FAILED_TESTS -gt 0 ]; then
            echo -e "${RED}❌ Some tests failed!${NC}"
            exit 1
        else
            echo -e "${GREEN}✅ All tests passed!${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Usage: $0 [all|unit|integration|e2e|coverage|report]${NC}"
        echo -e "${BLUE}Examples:${NC}"
        echo -e "  $0 all              # Run all tests"
        echo -e "  $0 unit             # Run unit tests only"
        echo -e "  $0 integration      # Run integration tests only"
        echo -e "  $0 e2e              # Run E2E tests only"
        echo -e "  $0 coverage         # Show coverage report"
        echo -e "  $0 report           # Generate test report"
        exit 1
        ;;
esac 