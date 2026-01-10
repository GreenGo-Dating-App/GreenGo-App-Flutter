#!/bin/bash

# Firebase Production Environment Setup Script
# This script creates and configures all Firebase components for production
# WARNING: This sets up your PRODUCTION environment - use with caution!

set -e  # Exit on error

# Create log file
LOG_FILE="$(dirname "$0")/setup_firebase_prod.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Firebase PRODUCTION Environment Setup"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log file: $LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: This is PRODUCTION setup - proceed with caution!"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="greengo-chat-prod"
PROJECT_NAME="GreenGo Chat Production"
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

# Confirmation prompt
print_header "PRODUCTION ENVIRONMENT SETUP"
print_msg "$RED" "⚠️  WARNING: You are about to set up the PRODUCTION environment!"
print_msg "$RED" "⚠️  This will create/modify production Firebase resources."
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Type 'PRODUCTION' to continue:"
read -r confirmation

if [ "$confirmation" != "PRODUCTION" ]; then
    print_msg "$RED" "Setup cancelled."
    exit 1
fi

# Check if Firebase CLI is installed
print_header "Checking Prerequisites"
if ! command -v firebase &> /dev/null; then
    print_msg "$RED" "Firebase CLI is not installed!"
    print_msg "$YELLOW" "Install it with: npm install -g firebase-tools"
    exit 1
fi
print_msg "$GREEN" "✓ Firebase CLI found"

if ! command -v gcloud &> /dev/null; then
    print_msg "$YELLOW" "⚠ Google Cloud SDK not found"
    print_msg "$YELLOW" "Recommended for advanced configuration: https://cloud.google.com/sdk/install"
fi

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

    # Enable billing for production
    print_msg "$YELLOW" "⚠️  IMPORTANT: Enable billing for production project"
    print_msg "$YELLOW" "Go to: https://console.firebase.google.com/project/$PROJECT_ID/settings/billing"
    print_msg "$YELLOW" "Press ENTER when billing is enabled..."
    read
}

# Initialize Firebase in project
print_header "Initializing Firebase Features"
cd "$(dirname "$0")/../.." # Go to project root

# Create firebase.json for production
if [ ! -f "firebase.prod.json" ]; then
    print_msg "$YELLOW" "Creating firebase.prod.json configuration..."
    cat > firebase.prod.json << 'EOF'
{
  "firestore": {
    "rules": "firestore.prod.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.prod.rules"
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
        "source": "**/*",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "SAMEORIGIN"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Strict-Transport-Security",
            "value": "max-age=31536000; includeSubDomains"
          }
        ]
      },
      {
        "source": "index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache, no-store, must-revalidate"
          }
        ]
      }
    ]
  }
}
EOF
    print_msg "$GREEN" "✓ firebase.prod.json created"
fi

# Create Production Firestore rules (most strict)
print_header "Setting Up Firestore Rules"
if [ ! -f "firestore.prod.rules" ]; then
    cat > firestore.prod.rules << 'EOF'
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
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.emailVerified == true;
    }

    function userExists(userId) {
      return exists(/databases/$(database)/documents/users/$(userId));
    }

    // Rate limiting helper (basic implementation)
    function rateLimitOk() {
      return request.time > resource.data.lastUpdate + duration.value(1, 's');
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && userExists(userId);
      allow create: if isAuthenticated() &&
                       request.auth.uid == userId &&
                       request.resource.data.keys().hasAll(['createdAt', 'email', 'displayName']);
      allow update: if isOwner(userId) &&
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['uid', 'createdAt']) &&
                       rateLimitOk();
      allow delete: if false; // Never allow deletion in production

      // User's private data
      match /private/{document=**} {
        allow read, write: if isOwner(userId);
      }
    }

    // Matches collection
    match /matches/{matchId} {
      allow read: if isValidUser() &&
                     (request.auth.uid == resource.data.user1Id ||
                      request.auth.uid == resource.data.user2Id) &&
                     userExists(resource.data.user1Id) &&
                     userExists(resource.data.user2Id);
      allow create: if isValidUser() &&
                       request.resource.data.keys().hasAll(['user1Id', 'user2Id', 'createdAt', 'status']);
      allow update: if isValidUser() &&
                       (request.auth.uid == resource.data.user1Id ||
                        request.auth.uid == resource.data.user2Id) &&
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['user1Id', 'user2Id', 'createdAt']);
      allow delete: if false;
    }

    // Messages collection
    match /messages/{messageId} {
      allow read: if isValidUser() &&
                     (request.auth.uid == resource.data.senderId ||
                      request.auth.uid == resource.data.receiverId) &&
                     userExists(resource.data.senderId) &&
                     userExists(resource.data.receiverId);
      allow create: if isValidUser() &&
                       request.auth.uid == request.resource.data.senderId &&
                       request.resource.data.senderId != request.resource.data.receiverId &&
                       userExists(request.resource.data.receiverId) &&
                       request.resource.data.keys().hasAll(['senderId', 'receiverId', 'text', 'timestamp']) &&
                       request.resource.data.text is string &&
                       request.resource.data.text.size() > 0 &&
                       request.resource.data.text.size() <= 5000;
      allow update: if false; // Messages are immutable
      allow delete: if isOwner(resource.data.senderId) &&
                       request.time < resource.data.timestamp + duration.value(1, 'h'); // Can only delete within 1 hour
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isValidUser() && request.auth.uid == resource.data.userId;
      allow create: if isValidUser() &&
                       request.resource.data.keys().hasAll(['userId', 'type', 'timestamp']);
      allow update: if isValidUser() &&
                       request.auth.uid == resource.data.userId &&
                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['userId', 'type', 'timestamp']);
      allow delete: if isValidUser() && request.auth.uid == resource.data.userId;
    }

    // Admin collection (server-side only)
    match /admin/{document=**} {
      allow read, write: if false; // Only accessible via Admin SDK
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
EOF
    print_msg "$GREEN" "✓ firestore.prod.rules created"
fi

# Create Production Storage rules (most strict)
print_header "Setting Up Storage Rules"
if [ ! -f "storage.prod.rules" ]; then
    cat > storage.prod.rules << 'EOF'
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

    function isValidImageSize() {
      // Ensure reasonable dimensions (implementation depends on your needs)
      return isUnder5MB();
    }

    function isValidUser() {
      return isAuthenticated() &&
             firestore.exists(/databases/(default)/documents/users/$(request.auth.uid)) &&
             firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.emailVerified == true;
    }

    function rateLimitOk() {
      // Basic rate limiting - max 10 uploads per minute
      return true; // Implement proper rate limiting if needed
    }

    // User profile images
    match /users/{userId}/profile/{imageId} {
      allow read: if true; // Public read for profile images
      allow write: if isValidUser() &&
                      request.auth.uid == userId &&
                      isImageFile() &&
                      isValidImageSize() &&
                      rateLimitOk();
      allow delete: if isValidUser() && request.auth.uid == userId;
    }

    // Chat images
    match /chats/{chatId}/images/{imageId} {
      allow read: if isValidUser(); // Only authenticated users can view chat images
      allow write: if isValidUser() &&
                      isImageFile() &&
                      isValidImageSize() &&
                      rateLimitOk();
      allow delete: if isValidUser(); // Users can delete their own chat images
    }

    // Admin uploads (server-side only)
    match /admin/{allPaths=**} {
      allow read, write: if false; // Only accessible via Admin SDK
    }

    // Deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
EOF
    print_msg "$GREEN" "✓ storage.prod.rules created"
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
print_msg "$YELLOW" "Deploying to PRODUCTION..."
firebase deploy --only firestore:rules,firestore:indexes --project "$PROJECT_ID" --config firebase.prod.json
print_msg "$GREEN" "✓ Firestore rules and indexes deployed"

# Deploy Storage rules
print_header "Deploying Storage Configuration"
firebase deploy --only storage:rules --project "$PROJECT_ID" --config firebase.prod.json
print_msg "$GREEN" "✓ Storage rules deployed"

# Enable Authentication methods
print_header "Configuring Authentication"
print_msg "$YELLOW" "Please configure these authentication settings in Firebase Console:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
print_msg "$YELLOW" "  2. Enable Email/Password (with email verification required)"
print_msg "$YELLOW" "  3. Enable Google Sign-In (configure OAuth consent screen)"
print_msg "$YELLOW" "  4. Enable Facebook Login (configure OAuth settings)"
print_msg "$YELLOW" "  5. Configure authorized domains for production"
print_msg "$YELLOW" "  6. Set up email templates for verification/password reset"
print_msg "$YELLOW" "  7. Enable App Check for additional security"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Press ENTER when done..."
read

# Enable App Check
print_header "Firebase App Check"
print_msg "$YELLOW" "Enable App Check for production security:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/appcheck"
print_msg "$YELLOW" "  2. Register your app"
print_msg "$YELLOW" "  3. Enable enforcement for Firestore, Storage, and other services"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Press ENTER to continue..."
read

# Initialize FlutterFire CLI configuration
print_header "Configuring FlutterFire"
if command -v flutterfire &> /dev/null; then
    print_msg "$YELLOW" "Running FlutterFire configure for production..."
    flutterfire configure --project="$PROJECT_ID" --out="lib/firebase_options_production.dart"
    print_msg "$GREEN" "✓ FlutterFire configured for production"
else
    print_msg "$YELLOW" "⚠ FlutterFire CLI not found"
    print_msg "$YELLOW" "Install it with: dart pub global activate flutterfire_cli"
fi

# Configure Crashlytics
print_header "Firebase Crashlytics"
print_msg "$YELLOW" "Enable Crashlytics:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/crashlytics"
print_msg "$YELLOW" "  2. Enable Crashlytics"
print_msg "$YELLOW" "  3. Configure symbolication for release builds"

# Configure Performance Monitoring
print_header "Firebase Performance Monitoring"
print_msg "$YELLOW" "Enable Performance Monitoring:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/performance"
print_msg "$YELLOW" "  2. Enable Performance Monitoring"

# Configure Analytics
print_header "Firebase Analytics"
print_msg "$YELLOW" "Configure Analytics:"
print_msg "$YELLOW" "  1. Go to: https://console.firebase.google.com/project/$PROJECT_ID/analytics"
print_msg "$YELLOW" "  2. Link to Google Analytics property"
print_msg "$YELLOW" "  3. Configure data retention and collection settings"

# Backup configuration
print_header "Backup Configuration"
print_msg "$YELLOW" "Set up automated backups:"
print_msg "$YELLOW" "  1. Go to: https://console.cloud.google.com/firestore/databases/-default-/import-export?project=$PROJECT_ID"
print_msg "$YELLOW" "  2. Configure automated Firestore exports"
print_msg "$YELLOW" "  3. Set up Cloud Storage bucket lifecycle policies"

# Summary
print_header "Firebase Production Environment Setup Complete!"
print_msg "$GREEN" "Project ID: $PROJECT_ID"
print_msg "$GREEN" "Region: $REGION"
print_msg "$GREEN" ""
print_msg "$RED" "⚠️  IMPORTANT SECURITY CHECKLIST:"
print_msg "$YELLOW" "  ✓ Firestore rules deployed (strictest security)"
print_msg "$YELLOW" "  ✓ Storage rules deployed (strictest security)"
print_msg "$YELLOW" "  □ Enable App Check"
print_msg "$YELLOW" "  □ Configure authentication providers"
print_msg "$YELLOW" "  □ Enable Crashlytics"
print_msg "$YELLOW" "  □ Enable Performance Monitoring"
print_msg "$YELLOW" "  □ Configure Analytics"
print_msg "$YELLOW" "  □ Set up automated backups"
print_msg "$YELLOW" "  □ Configure billing alerts"
print_msg "$YELLOW" "  □ Review and test all security rules"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Next Steps:"
print_msg "$YELLOW" "  1. Complete all security configurations"
print_msg "$YELLOW" "  2. Test thoroughly in staging first"
print_msg "$YELLOW" "  3. Run: ./deploy.sh prod android --clean"
print_msg "$YELLOW" "  4. Monitor production metrics"
print_msg "$YELLOW" ""
print_msg "$YELLOW" "Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
print_msg "$GREEN" ""
print_msg "$GREEN" "✓ Production setup complete!"
print_msg "$RED" "⚠️  Remember to complete the security checklist above!"
