#!/bin/bash

###############################################################################
# GreenGoChat - Test Environment Setup with Mock Servers
# This script sets up a complete mock testing environment for the app
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOCK_SERVER_PORT=8080
FIREBASE_EMULATOR_PORT=9099
FIRESTORE_EMULATOR_PORT=8081
AUTH_EMULATOR_PORT=9099
STORAGE_EMULATOR_PORT=9199

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        return 1
    else
        print_success "$1 is installed"
        return 0
    fi
}

###############################################################################
# Prerequisites Check
###############################################################################

print_header "Checking Prerequisites"

MISSING_TOOLS=0

# Check Flutter
if check_command flutter; then
    flutter --version | head -n 1
else
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
fi

# Check Node.js (for Firebase Emulator)
if check_command node; then
    node --version
else
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
    print_warning "Install Node.js from: https://nodejs.org/"
fi

# Check npm
if check_command npm; then
    npm --version
else
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
fi

# Check Firebase CLI
if check_command firebase; then
    firebase --version
else
    print_warning "Installing Firebase CLI..."
    npm install -g firebase-tools || {
        print_error "Failed to install Firebase CLI"
        MISSING_TOOLS=$((MISSING_TOOLS + 1))
    }
fi

# Check Java (for Firebase Emulator)
if check_command java; then
    java -version 2>&1 | head -n 1
else
    print_warning "Java is required for Firebase Emulators"
    print_warning "Install Java from: https://adoptium.net/"
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
fi

if [ $MISSING_TOOLS -gt 0 ]; then
    print_error "Missing $MISSING_TOOLS required tools. Please install them first."
    exit 1
fi

print_success "All prerequisites are installed"
echo ""

###############################################################################
# Firebase Emulator Setup
###############################################################################

print_header "Setting up Firebase Emulators"

cd "$PROJECT_DIR"

# Initialize Firebase if not already done
if [ ! -f "firebase.json" ]; then
    print_info "Creating firebase.json configuration..."
    cat > firebase.json <<EOF
{
  "emulators": {
    "auth": {
      "port": $AUTH_EMULATOR_PORT
    },
    "firestore": {
      "port": $FIRESTORE_EMULATOR_PORT
    },
    "storage": {
      "port": $STORAGE_EMULATOR_PORT
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
EOF
    print_success "Created firebase.json"
fi

# Create Firestore rules for testing
if [ ! -f "firestore.rules" ]; then
    print_info "Creating firestore.rules..."
    cat > firestore.rules <<EOF
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads and writes in test mode
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
EOF
    print_success "Created firestore.rules (permissive for testing)"
fi

# Create Storage rules for testing
if [ ! -f "storage.rules" ]; then
    print_info "Creating storage.rules..."
    cat > storage.rules <<EOF
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
EOF
    print_success "Created storage.rules (permissive for testing)"
fi

# Create firestore indexes
if [ ! -f "firestore.indexes.json" ]; then
    print_info "Creating firestore.indexes.json..."
    cat > firestore.indexes.json <<EOF
{
  "indexes": [],
  "fieldOverrides": []
}
EOF
    print_success "Created firestore.indexes.json"
fi

print_success "Firebase emulator configuration ready"
echo ""

###############################################################################
# Mock API Server Setup
###############################################################################

print_header "Setting up Mock API Server"

MOCK_SERVER_DIR="$PROJECT_DIR/test/mock_server"
mkdir -p "$MOCK_SERVER_DIR"

# Create mock server using Node.js/Express
cat > "$MOCK_SERVER_DIR/package.json" <<EOF
{
  "name": "greengo-mock-server",
  "version": "1.0.0",
  "description": "Mock API server for GreenGoChat testing",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2"
  }
}
EOF

cat > "$MOCK_SERVER_DIR/server.js" <<'EOF'
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Mock data
const mockUsers = [
  { id: '1', email: 'test@example.com', displayName: 'Test User' },
  { id: '2', email: 'demo@example.com', displayName: 'Demo User' }
];

const mockProfiles = [
  {
    id: '1',
    userId: '1',
    displayName: 'Test User',
    age: 25,
    bio: 'Test bio',
    photos: ['photo1.jpg'],
    location: { lat: 40.7128, lng: -74.0060, city: 'New York', country: 'USA' }
  }
];

const mockMatches = [];
const mockMessages = [];

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Mock server is running' });
});

// User endpoints
app.get('/api/users/:id', (req, res) => {
  const user = mockUsers.find(u => u.id === req.params.id);
  if (user) {
    res.json(user);
  } else {
    res.status(404).json({ error: 'User not found' });
  }
});

app.post('/api/users', (req, res) => {
  const newUser = {
    id: String(mockUsers.length + 1),
    ...req.body,
    createdAt: new Date().toISOString()
  };
  mockUsers.push(newUser);
  res.status(201).json(newUser);
});

// Profile endpoints
app.get('/api/profiles/:id', (req, res) => {
  const profile = mockProfiles.find(p => p.id === req.params.id);
  if (profile) {
    res.json(profile);
  } else {
    res.status(404).json({ error: 'Profile not found' });
  }
});

app.get('/api/profiles', (req, res) => {
  res.json(mockProfiles);
});

app.post('/api/profiles', (req, res) => {
  const newProfile = {
    id: String(mockProfiles.length + 1),
    ...req.body,
    createdAt: new Date().toISOString()
  };
  mockProfiles.push(newProfile);
  res.status(201).json(newProfile);
});

// Match endpoints
app.get('/api/matches', (req, res) => {
  res.json(mockMatches);
});

app.post('/api/matches', (req, res) => {
  const newMatch = {
    id: String(mockMatches.length + 1),
    ...req.body,
    createdAt: new Date().toISOString()
  };
  mockMatches.push(newMatch);
  res.status(201).json(newMatch);
});

// Message endpoints
app.get('/api/messages', (req, res) => {
  const { matchId } = req.query;
  const messages = matchId
    ? mockMessages.filter(m => m.matchId === matchId)
    : mockMessages;
  res.json(messages);
});

app.post('/api/messages', (req, res) => {
  const newMessage = {
    id: String(mockMessages.length + 1),
    ...req.body,
    createdAt: new Date().toISOString()
  };
  mockMessages.push(newMessage);
  res.status(201).json(newMessage);
});

// Discovery endpoint
app.get('/api/discovery', (req, res) => {
  const { userId, maxDistance, minAge, maxAge } = req.query;
  // Return mock profiles excluding the requesting user
  const profiles = mockProfiles.filter(p => p.userId !== userId);
  res.json(profiles);
});

// Remote config endpoint
app.get('/api/config', (req, res) => {
  res.json({
    feature_video_calls_enabled: true,
    feature_voice_messages_enabled: true,
    max_photos_per_profile: 6,
    max_distance_km: 100,
    subscription_prices_usd: {
      basic: 0,
      silver: 9.99,
      gold: 19.99
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Mock API server is running on http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
EOF

print_success "Mock API server created"
echo ""

###############################################################################
# Install Mock Server Dependencies
###############################################################################

print_header "Installing Mock Server Dependencies"

cd "$MOCK_SERVER_DIR"
if [ ! -d "node_modules" ]; then
    print_info "Installing npm packages..."
    npm install
    print_success "Dependencies installed"
else
    print_success "Dependencies already installed"
fi
cd "$PROJECT_DIR"
echo ""

###############################################################################
# Create Test Data Seed Script
###############################################################################

print_header "Creating Test Data Seed Script"

cat > "$MOCK_SERVER_DIR/seed_data.sh" <<'EOF'
#!/bin/bash

API_URL="http://localhost:8080"

echo "Seeding test data..."

# Create test users
curl -X POST "$API_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@test.com",
    "displayName": "Alice Johnson"
  }'

curl -X POST "$API_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "bob@test.com",
    "displayName": "Bob Smith"
  }'

# Create test profiles
curl -X POST "$API_URL/api/profiles" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "3",
    "displayName": "Alice Johnson",
    "age": 28,
    "bio": "Love hiking and coffee",
    "interests": ["hiking", "coffee", "travel"],
    "photos": ["alice1.jpg", "alice2.jpg"],
    "location": {
      "lat": 40.7128,
      "lng": -74.0060,
      "city": "New York",
      "country": "USA"
    }
  }'

curl -X POST "$API_URL/api/profiles" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "4",
    "displayName": "Bob Smith",
    "age": 30,
    "bio": "Tech enthusiast and gamer",
    "interests": ["gaming", "technology", "music"],
    "photos": ["bob1.jpg", "bob2.jpg"],
    "location": {
      "lat": 40.7589,
      "lng": -73.9851,
      "city": "New York",
      "country": "USA"
    }
  }'

echo "Test data seeded successfully!"
EOF

chmod +x "$MOCK_SERVER_DIR/seed_data.sh"
print_success "Test data seed script created"
echo ""

###############################################################################
# Flutter Test Configuration
###############################################################################

print_header "Configuring Flutter for Mock Testing"

# Create test configuration file
mkdir -p "$PROJECT_DIR/lib/core/config"
cat > "$PROJECT_DIR/lib/core/config/test_config.dart" <<'EOF'
class TestConfig {
  static const bool useMockData = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const String mockApiUrl = 'http://localhost:8080';

  static const String firestoreEmulatorHost = 'localhost';
  static const int firestoreEmulatorPort = 8081;

  static const String authEmulatorHost = 'localhost';
  static const int authEmulatorPort = 9099;

  static const String storageEmulatorHost = 'localhost';
  static const int storageEmulatorPort = 9199;
}
EOF

print_success "Flutter test configuration created"
echo ""

###############################################################################
# Create Start/Stop Scripts
###############################################################################

print_header "Creating Control Scripts"

# Start script
cat > "$PROJECT_DIR/start_mock_servers.sh" <<EOF
#!/bin/bash

echo "Starting Firebase Emulators..."
firebase emulators:start --only auth,firestore,storage &
FIREBASE_PID=\$!

echo "Waiting for Firebase Emulators to start..."
sleep 5

echo "Starting Mock API Server..."
cd "$MOCK_SERVER_DIR"
npm start &
API_PID=\$!

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Mock Servers are Running!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  Firebase Emulator UI:    http://localhost:4000"
echo "  Firestore Emulator:      http://localhost:$FIRESTORE_EMULATOR_PORT"
echo "  Auth Emulator:           http://localhost:$AUTH_EMULATOR_PORT"
echo "  Storage Emulator:        http://localhost:$STORAGE_EMULATOR_PORT"
echo "  Mock API Server:         http://localhost:$MOCK_SERVER_PORT"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "Press Ctrl+C to stop all servers"
echo ""

# Save PIDs
echo \$FIREBASE_PID > /tmp/greengo_firebase_pid
echo \$API_PID > /tmp/greengo_api_pid

# Wait for user interrupt
trap "kill \$FIREBASE_PID \$API_PID 2>/dev/null; echo 'Servers stopped'; exit" INT TERM

wait
EOF

chmod +x "$PROJECT_DIR/start_mock_servers.sh"
print_success "Start script created: start_mock_servers.sh"

# Stop script
cat > "$PROJECT_DIR/stop_mock_servers.sh" <<'EOF'
#!/bin/bash

echo "Stopping Mock Servers..."

if [ -f /tmp/greengo_firebase_pid ]; then
    FIREBASE_PID=$(cat /tmp/greengo_firebase_pid)
    kill $FIREBASE_PID 2>/dev/null && echo "✓ Firebase Emulators stopped"
    rm /tmp/greengo_firebase_pid
fi

if [ -f /tmp/greengo_api_pid ]; then
    API_PID=$(cat /tmp/greengo_api_pid)
    kill $API_PID 2>/dev/null && echo "✓ Mock API Server stopped"
    rm /tmp/greengo_api_pid
fi

# Also kill any remaining processes on the ports
lsof -ti:4000,8080,8081,9099,9199 | xargs kill -9 2>/dev/null

echo "All servers stopped"
EOF

chmod +x "$PROJECT_DIR/stop_mock_servers.sh"
print_success "Stop script created: stop_mock_servers.sh"

echo ""

###############################################################################
# Create Test Runner Script
###############################################################################

print_header "Creating Test Runner Script"

cat > "$PROJECT_DIR/run_tests.sh" <<'EOF'
#!/bin/bash

set -e

echo "═══════════════════════════════════════════════════════"
echo "  Running GreenGoChat Tests"
echo "═══════════════════════════════════════════════════════"
echo ""

# Ensure mock servers are running
if ! nc -z localhost 8080 2>/dev/null; then
    echo "Mock servers are not running. Starting them now..."
    ./start_mock_servers.sh &
    sleep 10
fi

echo "Running Flutter tests..."
flutter test

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Tests Complete!"
echo "═══════════════════════════════════════════════════════"
EOF

chmod +x "$PROJECT_DIR/run_tests.sh"
print_success "Test runner script created: run_tests.sh"

echo ""

###############################################################################
# Summary
###############################################################################

print_header "Setup Complete!"

echo ""
print_info "Mock testing environment has been set up successfully!"
echo ""
echo "Quick Start Commands:"
echo ""
echo "  1. Start mock servers:"
echo "     ${GREEN}./start_mock_servers.sh${NC}"
echo ""
echo "  2. Run tests:"
echo "     ${GREEN}./run_tests.sh${NC}"
echo ""
echo "  3. Run app with mock data:"
echo "     ${GREEN}flutter run --dart-define=USE_MOCK=true${NC}"
echo ""
echo "  4. Stop mock servers:"
echo "     ${GREEN}./stop_mock_servers.sh${NC}"
echo ""
echo "  5. Seed test data:"
echo "     ${GREEN}cd test/mock_server && ./seed_data.sh${NC}"
echo ""
echo "Mock Server Endpoints:"
echo "  • Firebase Emulator UI:    ${BLUE}http://localhost:4000${NC}"
echo "  • Mock API Server:         ${BLUE}http://localhost:8080${NC}"
echo "  • Health Check:            ${BLUE}http://localhost:8080/health${NC}"
echo ""
print_success "You're all set! Happy testing! 🚀"
echo ""
