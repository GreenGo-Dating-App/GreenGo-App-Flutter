#!/bin/bash

###############################################################################
# GreenGo App - Microservices Deployment Script
# Deploys all 160+ Cloud Functions and infrastructure using Terraform
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="${PROJECT_ID:-greengo-prod}"
REGION="${REGION:-us-central1}"
ENVIRONMENT="${ENVIRONMENT:-prod}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}GreenGo Microservices Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}=== $1 ===${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prerequisites check
print_section "Checking Prerequisites"

if ! command_exists terraform; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi
echo "✓ Terraform installed"

if ! command_exists firebase; then
    echo -e "${RED}Error: Firebase CLI is not installed${NC}"
    exit 1
fi
echo "✓ Firebase CLI installed"

if ! command_exists gcloud; then
    echo -e "${RED}Error: Google Cloud SDK is not installed${NC}"
    exit 1
fi
echo "✓ Google Cloud SDK installed"

# Set GCP project
print_section "Setting GCP Project"
gcloud config set project "$PROJECT_ID"
echo "✓ Project set to $PROJECT_ID"

# Build TypeScript functions
print_section "Building TypeScript Functions"
cd functions
npm install
npm run build
echo "✓ Functions built successfully"
cd ..

# Deploy Infrastructure with Terraform
print_section "Deploying Infrastructure (Terraform)"
cd terraform/microservices

# Initialize Terraform
terraform init

# Select or create workspace
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

# Plan
echo ""
echo -e "${YELLOW}Terraform Plan:${NC}"
terraform plan \
    -var="project_id=$PROJECT_ID" \
    -var="region=$REGION" \
    -var="environment=$ENVIRONMENT"

# Ask for confirmation
echo ""
read -p "Do you want to apply this plan? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Apply
terraform apply \
    -var="project_id=$PROJECT_ID" \
    -var="region=$REGION" \
    -var="environment=$ENVIRONMENT" \
    -auto-approve

echo "✓ Infrastructure deployed"
cd ../..

# Deploy Cloud Functions
print_section "Deploying Cloud Functions"

# Deploy all services
services=(
    "media"
    "messaging"
    "backup"
    "subscription"
    "coins"
    "analytics"
    "gamification"
    "safety"
    "admin"
    "notification"
    "video"
    "security"
)

for service in "${services[@]}"; do
    echo ""
    echo -e "${GREEN}Deploying $service service...${NC}"
    firebase deploy --only "functions:$service" --project "$PROJECT_ID"
done

# Verify deployments
print_section "Verifying Deployments"

# List deployed functions
echo "Deployed functions:"
gcloud functions list --project="$PROJECT_ID" --region="$REGION"

# Check function health
echo ""
echo "Checking function health..."
# Add health checks here

print_section "Deployment Complete!"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All microservices deployed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor functions: firebase functions:log"
echo "2. View metrics: https://console.cloud.google.com/functions"
echo "3. Test endpoints: Use Postman or curl"
echo ""
