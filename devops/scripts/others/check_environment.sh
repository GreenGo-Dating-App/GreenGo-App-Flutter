#!/bin/bash

# ============================================================================
# Environment Verification Script
# ============================================================================
# Checks all prerequisites for Firebase Test Lab testing
# ============================================================================

echo ""
echo "============================================================================"
echo "GreenGo App - Environment Verification"
echo "============================================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Node.js Check
echo "[1/12] Checking Node.js..."
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ PASS: Node.js is installed${NC}"
    node --version
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: Node.js not found${NC}"
    echo "  Install from: https://nodejs.org/"
    ((FAIL_COUNT++))
fi
echo ""

# npm Check
echo "[2/12] Checking npm..."
if command -v npm &> /dev/null; then
    echo -e "${GREEN}✓ PASS: npm is installed${NC}"
    npm --version
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: npm not found${NC}"
    ((FAIL_COUNT++))
fi
echo ""

# Flutter Check
echo "[3/12] Checking Flutter..."
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✓ PASS: Flutter is installed${NC}"
    flutter --version | grep "Flutter"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: Flutter not found${NC}"
    echo "  Install from: https://flutter.dev/docs/get-started/install"
    ((FAIL_COUNT++))
fi
echo ""

# Firebase CLI Check
echo "[4/12] Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    echo -e "${GREEN}✓ PASS: Firebase CLI is installed${NC}"
    firebase --version
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠ WARN: Firebase CLI not found${NC}"
    echo "  Will be installed by setup script"
    ((WARN_COUNT++))
fi
echo ""

# Google Cloud SDK Check
echo "[5/12] Checking Google Cloud SDK..."
if command -v gcloud &> /dev/null; then
    echo -e "${GREEN}✓ PASS: Google Cloud SDK is installed${NC}"
    gcloud --version | grep "Google Cloud SDK"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: Google Cloud SDK not found${NC}"
    echo "  REQUIRED: Install from https://cloud.google.com/sdk/docs/install"
    ((FAIL_COUNT++))
fi
echo ""

# TypeScript Check
echo "[6/12] Checking TypeScript..."
if command -v tsc &> /dev/null; then
    echo -e "${GREEN}✓ PASS: TypeScript is installed globally${NC}"
    tsc --version
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠ WARN: TypeScript not found globally${NC}"
    echo "  Will be installed locally in functions/"
    ((WARN_COUNT++))
fi
echo ""

# Git Check
echo "[7/12] Checking Git..."
if command -v git &> /dev/null; then
    echo -e "${GREEN}✓ PASS: Git is installed${NC}"
    git --version
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠ WARN: Git not found${NC}"
    echo "  Recommended for version control"
    ((WARN_COUNT++))
fi
echo ""

# Check functions directory
echo "[8/12] Checking functions directory..."
if [ -d "functions" ]; then
    echo -e "${GREEN}✓ PASS: functions/ directory exists${NC}"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: functions/ directory not found${NC}"
    ((FAIL_COUNT++))
fi
echo ""

# Check package.json
echo "[9/12] Checking functions/package.json..."
if [ -f "functions/package.json" ]; then
    echo -e "${GREEN}✓ PASS: package.json exists${NC}"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: package.json not found${NC}"
    ((FAIL_COUNT++))
fi
echo ""

# Check lib directory
echo "[10/12] Checking Flutter lib directory..."
if [ -d "lib" ]; then
    echo -e "${GREEN}✓ PASS: lib/ directory exists${NC}"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: lib/ directory not found${NC}"
    ((FAIL_COUNT++))
fi
echo ""

# Check pubspec.yaml
echo "[11/12] Checking pubspec.yaml..."
if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✓ PASS: pubspec.yaml exists${NC}"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL: pubspec.yaml not found${NC}"
    ((FAIL_COUNT++))
fi
echo ""

# Check Firebase authentication
echo "[12/12] Checking Firebase authentication..."
if firebase projects:list &> /dev/null; then
    echo -e "${GREEN}✓ PASS: Firebase authenticated${NC}"
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠ WARN: Not authenticated with Firebase${NC}"
    echo "  Run: firebase login"
    ((WARN_COUNT++))
fi
echo ""

# Summary
echo "============================================================================"
echo "Environment Check Summary"
echo "============================================================================"
echo ""
echo -e "${GREEN}✓ Passed:  $PASS_COUNT${NC}"
echo -e "${YELLOW}⚠ Warnings: $WARN_COUNT${NC}"
echo -e "${RED}✗ Failed:  $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Status: ❌ NOT READY - Please install missing dependencies${NC}"
    echo ""
    echo "Required Actions:"
    if ! command -v gcloud &> /dev/null; then
        echo "1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    fi
    echo ""
elif [ $WARN_COUNT -gt 0 ]; then
    echo -e "${YELLOW}Status: ⚠ MOSTLY READY - Some optional components missing${NC}"
    echo ""
    echo "You can proceed with ./setup_and_test.sh"
    echo ""
else
    echo -e "${GREEN}Status: ✅ READY - All prerequisites met!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Run: ./setup_and_test.sh"
    echo "2. Run: ./firebase_test_lab.sh"
    echo ""
fi

echo "============================================================================"
