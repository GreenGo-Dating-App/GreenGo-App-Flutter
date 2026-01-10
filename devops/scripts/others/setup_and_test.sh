#!/bin/bash

# ============================================================================
# GreenGo App - Complete Setup and Firebase Test Lab Testing Script
# ============================================================================
# This script will:
# 1. Install all dependencies
# 2. Build TypeScript Cloud Functions
# 3. Set up Firebase environment
# 4. Build Flutter app for testing
# 5. Run app on Firebase Test Lab (Google Cloud Beta Testing)
# ============================================================================

set -e  # Exit on any error

echo ""
echo "============================================================================"
echo "GreenGo Dating App - Setup and Test Lab Deployment"
echo "============================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Node.js installation
echo "[1/10] Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}ERROR: Node.js is not installed!${NC}"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi
echo -e "${GREEN}✓ Node.js is installed${NC}"
node --version
echo ""

# Check Flutter installation
echo "[2/10] Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter is not installed!${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo -e "${GREEN}✓ Flutter is installed${NC}"
flutter --version | grep "Flutter"
echo ""

# Check Firebase CLI
echo "[3/10] Checking Firebase CLI installation..."
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}WARNING: Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
fi
echo -e "${GREEN}✓ Firebase CLI is installed${NC}"
firebase --version
echo ""

# Check gcloud CLI
echo "[4/10] Checking Google Cloud SDK installation..."
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}ERROR: Google Cloud SDK is not installed!${NC}"
    echo "Please install from: https://cloud.google.com/sdk/docs/install"
    echo "After installation, run: gcloud init"
    exit 1
fi
echo -e "${GREEN}✓ Google Cloud SDK is installed${NC}"
gcloud --version | grep "Google Cloud SDK"
echo ""

# Install Cloud Functions dependencies
echo "[5/10] Installing Cloud Functions dependencies..."
cd functions
echo "Installing dependencies (this may take 2-3 minutes)..."
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to install dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
cd ..
echo ""

# Build TypeScript
echo "[6/10] Building TypeScript Cloud Functions..."
cd functions
npm run build
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: TypeScript compilation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ TypeScript compiled successfully${NC}"
cd ..
echo ""

# Install Flutter dependencies
echo "[7/10] Installing Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to install Flutter dependencies${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter dependencies installed${NC}"
echo ""

# Firebase login check
echo "[8/10] Checking Firebase authentication..."
if ! firebase projects:list &> /dev/null; then
    echo "You need to login to Firebase..."
    firebase login
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Firebase login failed${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Firebase authentication verified${NC}"
echo ""

# Google Cloud authentication check
echo "[9/10] Checking Google Cloud authentication..."
if ! gcloud auth list &> /dev/null; then
    echo "You need to login to Google Cloud..."
    gcloud auth login
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Google Cloud login failed${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Google Cloud authentication verified${NC}"
echo ""

# Build Flutter APK for testing
echo "[10/10] Building Flutter APK for Firebase Test Lab..."
echo "This may take 3-5 minutes..."
flutter build apk --debug
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Flutter APK build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ APK built successfully${NC}"
echo ""

echo "============================================================================"
echo "Setup Complete! All environment settings are configured."
echo "============================================================================"
echo ""
echo "APK Location: build/app/outputs/flutter-apk/app-debug.apk"
echo ""
echo "Next Steps:"
echo "1. Review firebase_test_lab.sh to configure test devices"
echo "2. Run: ./firebase_test_lab.sh to start testing"
echo ""
echo "============================================================================"
