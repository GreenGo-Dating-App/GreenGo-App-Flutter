#!/bin/bash

# GreenGo Cloud Functions - Comprehensive Test Runner
# Runs all tests and generates detailed reports

echo "======================================"
echo "  GreenGo Cloud Functions Test Suite"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the functions directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: Please run this script from the functions directory${NC}"
    exit 1
fi

echo "📦 Step 1: Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

echo "🔨 Step 2: Building TypeScript..."
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ TypeScript build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ TypeScript built successfully${NC}"
echo ""

echo "🧪 Step 3: Running all tests with coverage..."
npm run test:coverage

TEST_EXIT_CODE=$?

echo ""
echo "======================================"
echo "  Test Results"
echo "======================================"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed${NC}"
fi

echo ""
echo "📊 Coverage report generated in: coverage/index.html"
echo "📄 Detailed report available in: coverage/lcov-report/index.html"
echo ""

echo "🔍 To view the HTML coverage report:"
echo "   - Windows: start coverage/index.html"
echo "   - Mac: open coverage/index.html"
echo "   - Linux: xdg-open coverage/index.html"
echo ""

echo "📋 Test Summary:"
npm test -- --verbose --passWithNoTests | grep -E "(PASS|FAIL|Test Suites|Tests:)"

echo ""
echo "======================================"
echo "  Additional Commands"
echo "======================================"
echo "  npm test                    - Run all tests"
echo "  npm run test:watch          - Run tests in watch mode"
echo "  npm run test:unit           - Run only unit tests"
echo "  npm run test:integration    - Run only integration tests"
echo "  npm run test:coverage       - Run with coverage report"
echo "======================================"

exit $TEST_EXIT_CODE
