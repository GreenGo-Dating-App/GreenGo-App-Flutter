#!/bin/bash

# Firebase Test/Staging Environment Setup Script
# This script creates and configures all Firebase components for staging/testing

set -e  # Exit on error

# Create log file
LOG_FILE="$(dirname "$0")/setup_firebase_test.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Firebase Test/Staging Environment Setup"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log file: $LOG_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="greengo-chat-staging"
PROJECT_NAME="GreenGo Chat Staging"
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}.appspot.com"

# Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "============================================"
    print_msg "$BLUE" "$@"
    print_msg "$BLUE" "============================================"
    echo ""
}

# Check if Firebase CLI is installed
print_header "Checking Prerequisites"
if ! command -v firebase &> /dev/null; then
    print_msg "$RED" "Firebase CLI is not installed!"
    print_msg "$YELLOW" "Install it with: npm install -g firebase-tools"
    exit 1
fi
print_msg "$GREEN" "✓ Firebase CLI found"

# Login to Firebase
print_header "Firebase Authentication"
print_msg "$YELLOW" "Logging in to Firebase..."
firebase login --reauth

# Create or select Firebase project
print_header "Setting Up Firebase Project"
print_msg "$YELLOW" "Creating/selecting project: $PROJECT_ID"

firebase projects:list | grep -q "$PROJECT_ID" && {
    print_msg "$GREEN" "✓ Project already exists: $PROJECT_ID"
    firebase use "$PROJECT_ID"
} || {
    print_msg "$YELLOW" "Creating new Firebase project..."
    firebase projects:create "$PROJECT_ID" --display-name "$PROJECT_NAME"
    firebase use "$PROJECT_ID"
    print_msg "$GREEN" "✓ Project created: $PROJECT_ID"
}

# Initialize Firebase in project
print_header "Initializing Firebase Features"
cd "$(dirname "$0")/../.." # Go to project root

# Create firebase.json if it doesn't exist
if [ ! -f "firebase.test.json" ]; then
    print_msg "$YELLOW" "Creating firebase.test.json configuration..."
    cat > firebase.test.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.staging.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.staging.rules"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Environment",
            "value": "staging"
          }
        ]
      }
    ]
  }
}
EOF
    print_msg "$GREEN" "✓ firebase.test.json created"
fi

# Create Firestore rules (stricter for staging)
print_header "Setting Up Firestore Rules"
if [ ! -f "firestore.staging.rules" ]; then
    cat > firestore.staging.rules << 'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidUser() {
      return isAuthenticated() &&
             exists(/databases/$(database)/documents/users/$(request.auth.uid));
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if false; // Prevent deletion

      // User's private data
      match /private/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }

    // Matches collection
    match /matches/{matchId} {
      allow read: if isValidUser() &&
                     (request.auth.uid == resource.data.user1Id ||
                      request.auth.uid == resource.data.user2Id);
      allow create: if isValidUser();
      allow update: if isValidUser() &&
                       (request.auth.uid == resource.data.user1Id ||
                        request.auth.uid == resource.data.user2Id);
      allow delete: if false;
    }

    // Messages collection
    match /messages/{messageId} {
      allow read: if isValidUser() &&
                     (request.auth.uid == resource.data.senderId ||
                      request.auth.uid == resource.data.receiverId);
      allow create: if isValidUser() &&
                       request.auth.uid == request.resource.data.senderId &&
                       request.resource.data.senderId != request.resource.data.receiverId;
      allow update: if false; // Messages are immutable
      allow delete: if isOwner(resource.data.senderId);
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isValidUser() && request.auth.uid == resource.data.userId;
      allow create: if isValidUser();
      allow update, delete: if isValidUser() && request.auth.uid == resource.data.userId;
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
EOF
    print_msg "$GREEN" "✓ firestore.staging.rules created"
fi

# Create Storage rules (stricter for staging)
print_header "Setting Up Storage Rules"
if [ ! -f "storage.staging.rules" ]; then
    cat > storage.staging.rules << 'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isImageFile() {
      return request.resource.contentType.matches('image/.*');
    }

    function isUnder5MB() {
      return request.resource.size < 5 * 1024 * 1024;
    }

    function isValidUser() {
      return isAuthenticated() &&
             firestore.exists(/databases/(default)/documents/users/$(request.auth.uid));
    }

    // User profile images
    match /users/{userId}/profile/{imageId} {
      allow read: if true; // Public read
      allow write: if isValidUser() &&
                      request.auth.uid == userId &&
                      isImageFile() &&
                      isUnder5MB();
      allow delete: if isValidUser() && request.auth.uid == userId;
    }

    // Chat images
    match /chats/{chatId}/images/{imageId} {
      allow read: if isValidUser();
      allow write: if isValidUser() && isImageFile() && isUnder5MB();
      allow delete: if isValidUser();
    }

    // Deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
EOF
    print_msg "$GREEN" "✓ storage.staging.rules created"
fi

# Enable required Google Cloud APIs
print_header "Enabling Firebase APIs"
if command -v gcloud &> /dev/null; then
    print_msg "$YELLOW" "Enabling required Google Cloud APIs..."

    gcloud services enable firestore.googleapis.com --project="$PROJECT_ID" 2>&1 | grep -v "already enabled" || true
    print_msg "$GREEN" "✓ Firestore API enabled"

    gcloud services enable firebaserules.googleapis.com --project="$PROJECT_ID" 2>&1 | grep -v "already enabled" || true
    print_msg "$GREEN" "✓ Firebase Rules API enabled"

    gcloud services enable storage.googleapis.com --project="$PROJECT_ID" 2>&1 | grep -v "already enabled" || true
    print_msg "$GREEN" "✓ Cloud Storage API enabled"

    gcloud services enable firebasestorage.googleapis.com --project="$PROJECT_ID" 2>&1 | grep -v "already enabled" || true
    print_msg "$GREEN" "✓ Firebase Storage API enabled"

    print_msg "$GREEN" "✓ All required APIs enabled"
else
    print_msg "$YELLOW" "⚠ gcloud not found - skipping API enablement"
    print_msg "$YELLOW" "You may need to enable APIs manually in Google Cloud Console"
fi

# Deploy Firestore rules and indexes
print_header "Deploying Firestore Configuration"
firebase deploy --only firestore:rules,firestore:indexes --project "$PROJECT_ID" --config firebase.test.json
print_msg "$GREEN" "✓ Firestore rules and indexes deployed"

# Deploy Storage rules
print_header "Deploying Storage Configuration"
firebase deploy --only storage:rules --project "$PROJECT_ID" --config firebase.test.json
print_msg "$GREEN" "✓ Storage rules deployed"

# Enable Authentication methods
print_header "Configuring Authentication"
print_msg "$YELLOW" "Please enable these authentication methods manually in Firebase Console:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
print_msg "$YELLOW" "  2. Enable Email/Password"
print_msg "$YELLOW" "  3. Enable Google Sign-In"
print_msg "$YELLOW" "  4. Enable Facebook Login"
print_msg "$YELLOW" "  5. Configure authorized domains for staging"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Press ENTER when done..."
read

# Initialize FlutterFire CLI configuration
print_header "Configuring FlutterFire"
if command -v flutterfire &> /dev/null; then
    print_msg "$YELLOW" "Running FlutterFire configure..."
    flutterfire configure --project="$PROJECT_ID" --out="lib/firebase_options_staging.dart"
    print_msg "$GREEN" "✓ FlutterFire configured for staging"
else
    print_msg "$YELLOW" "⚠ FlutterFire CLI not found"
    print_msg "$YELLOW" "Install it with: dart pub global activate flutterfire_cli"
fi

# Summary
print_header "Firebase Staging Environment Setup Complete!"
print_msg "$GREEN" "Project ID: $PROJECT_ID"
print_msg "$GREEN" "Region: $REGION"
print_msg "$GREEN" ""
print_msg "$YELLOW" "Next Steps:"
print_msg "$YELLOW" "  1. Test authentication flows"
print_msg "$YELLOW" "  2. Run: ./deploy.sh test android"
print_msg "$YELLOW" "  3. Perform QA testing"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
print_msg "$GREEN" ""
print_msg "$GREEN" "✓ Setup complete!"
