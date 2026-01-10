#!/bin/bash

# Firebase Development Environment Setup Script
# This script creates and configures all Firebase components for development

set -e  # Exit on error

# Create log file
LOG_FILE="$(dirname "$0")/setup_firebase_dev.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Firebase Development Environment Setup"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log file: $LOG_FILE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="greengo-chat-dev"
PROJECT_NAME="GreenGo Chat Development"
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

if ! command -v gcloud &> /dev/null; then
    print_msg "$YELLOW" "⚠ Google Cloud SDK not found (optional but recommended)"
else
    print_msg "$GREEN" "✓ Google Cloud SDK found"
fi

# Login to Firebase
print_header "Firebase Authentication"
print_msg "$YELLOW" "Logging in to Firebase..."
firebase login --reauth

# Create or select Firebase project
print_header "Setting Up Firebase Project"
print_msg "$YELLOW" "Creating/selecting project: $PROJECT_ID"

# Try to use existing project or create new one
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

# Set configuration directory
CONFIG_DIR="$(dirname "$0")"  # devops/scripts/firebase/
cd "$(dirname "$0")/../.." # Go to project root for firebase commands
PROJECT_ROOT="$(pwd)"

# Create firebase.json in the firebase config folder
if [ ! -f "$CONFIG_DIR/firebase.json" ]; then
    print_msg "$YELLOW" "Creating firebase.json configuration..."
    cat > "$CONFIG_DIR/firebase.json" << 'EOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
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
    ]
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
EOF
    print_msg "$GREEN" "✓ firebase.json created"
fi

# Create Firestore rules
print_header "Setting Up Firestore Rules"
if [ ! -f "$CONFIG_DIR/firestore.rules" ]; then
    cat > "$CONFIG_DIR/firestore.rules" << 'EOF'
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

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);

      // User's private data
      match /private/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }

    // Matches collection
    match /matches/{matchId} {
      allow read: if isAuthenticated() &&
                     (request.auth.uid == resource.data.user1Id ||
                      request.auth.uid == resource.data.user2Id);
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() &&
                       (request.auth.uid == resource.data.user1Id ||
                        request.auth.uid == resource.data.user2Id);
    }

    // Messages collection
    match /messages/{messageId} {
      allow read: if isAuthenticated() &&
                     (request.auth.uid == resource.data.senderId ||
                      request.auth.uid == resource.data.receiverId);
      allow create: if isAuthenticated() && request.auth.uid == request.resource.data.senderId;
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && request.auth.uid == resource.data.userId;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && request.auth.uid == resource.data.userId;
    }

    // Development only: Allow all access for testing
    // TODO: Remove this in production!
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
EOF
    print_msg "$GREEN" "✓ firestore.rules created"
fi

# Create Firestore indexes
if [ ! -f "$CONFIG_DIR/firestore.indexes.json" ]; then
    cat > "$CONFIG_DIR/firestore.indexes.json" << 'EOF'
{
  "indexes": [
    {
      "collectionGroup": "messages",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "chatId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
EOF
    print_msg "$GREEN" "✓ firestore.indexes.json created"
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

# Create Storage rules
print_header "Setting Up Storage Rules"
if [ ! -f "$CONFIG_DIR/storage.rules" ]; then
    cat > "$CONFIG_DIR/storage.rules" << 'EOF'
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

    // User profile images
    match /users/{userId}/profile/{imageId} {
      allow read: if true; // Public read
      allow write: if isAuthenticated() &&
                      request.auth.uid == userId &&
                      isImageFile() &&
                      isUnder5MB();
    }

    // Chat images
    match /chats/{chatId}/images/{imageId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && isImageFile() && isUnder5MB();
    }

    // Development only: Allow all access for testing
    // TODO: Remove this in production!
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
EOF
    print_msg "$GREEN" "✓ storage.rules created"
fi

# Deploy Firestore rules and indexes
print_header "Deploying Firestore Configuration"
firebase deploy --only firestore:rules,firestore:indexes --project "$PROJECT_ID"
print_msg "$GREEN" "✓ Firestore rules and indexes deployed"

# Deploy Storage rules
print_header "Deploying Storage Configuration"
firebase deploy --only storage:rules --project "$PROJECT_ID"
print_msg "$GREEN" "✓ Storage rules deployed"

# Enable Authentication methods
print_header "Configuring Authentication"
print_msg "$YELLOW" "Please enable these authentication methods manually in Firebase Console:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
print_msg "$YELLOW" "  2. Enable Email/Password"
print_msg "$YELLOW" "  3. Enable Google Sign-In"
print_msg "$YELLOW" "  4. Enable Facebook Login (optional)"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Press ENTER when done..."
read

# Initialize FlutterFire CLI configuration
print_header "Configuring FlutterFire"
if command -v flutterfire &> /dev/null; then
    print_msg "$YELLOW" "Running FlutterFire configure..."
    flutterfire configure --project="$PROJECT_ID"
    print_msg "$GREEN" "✓ FlutterFire configured"
else
    print_msg "$YELLOW" "⚠ FlutterFire CLI not found"
    print_msg "$YELLOW" "Install it with: dart pub global activate flutterfire_cli"
    print_msg "$YELLOW" "Then run: flutterfire configure --project=$PROJECT_ID"
fi

# Create Remote Config defaults
print_header "Setting Up Remote Config"
print_msg "$YELLOW" "Creating Remote Config template..."
cat > "$CONFIG_DIR/remote_config_template.json" << 'EOF'
{
  "parameters": {
    "maintenance_mode": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Enable maintenance mode"
    },
    "min_app_version": {
      "defaultValue": {
        "value": "1.0.0"
      },
      "description": "Minimum required app version"
    },
    "feature_chat_enabled": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Enable chat feature"
    },
    "feature_video_call_enabled": {
      "defaultValue": {
        "value": "false"
      },
      "description": "Enable video call feature"
    }
  }
}
EOF
print_msg "$GREEN" "✓ Remote Config template created: $CONFIG_DIR/remote_config_template.json"
print_msg "$YELLOW" "Upload this manually in Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/config"

# Copy config files to project root for Firebase CLI
print_msg "$YELLOW" "Copying configuration files to project root for Firebase deployment..."
cp "$CONFIG_DIR/firebase.json" "$PROJECT_ROOT/firebase.json"
cp "$CONFIG_DIR/firestore.rules" "$PROJECT_ROOT/firestore.rules"
cp "$CONFIG_DIR/firestore.indexes.json" "$PROJECT_ROOT/firestore.indexes.json"
cp "$CONFIG_DIR/storage.rules" "$PROJECT_ROOT/storage.rules"
print_msg "$GREEN" "✓ Configuration files copied to project root"

# Summary
print_header "Firebase Development Environment Setup Complete!"
print_msg "$GREEN" "Project ID: $PROJECT_ID"
print_msg "$GREEN" "Region: $REGION"
print_msg "$GREEN" ""
print_msg "$YELLOW" "Next Steps:"
print_msg "$YELLOW" "  1. Enable authentication methods in Firebase Console"
print_msg "$YELLOW" "  2. Upload Remote Config template if needed"
print_msg "$YELLOW" "  3. Run: ./deploy.sh dev android"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
print_msg "$YELLOW" "Emulators: Run 'firebase emulators:start' to start local development"
print_msg "$GREEN" ""
print_msg "$GREEN" "✓ Setup complete!"

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Firebase Development Environment Setup COMPLETED"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] All logs saved to: $LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Configuration files saved in: $CONFIG_DIR"
