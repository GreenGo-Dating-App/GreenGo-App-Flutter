#!/bin/bash

echo "Starting Firebase Emulators..."
firebase emulators:start --only auth,firestore,storage &
FIREBASE_PID=$!

echo "Waiting for Firebase Emulators to start..."
sleep 5

echo "Starting Mock API Server..."
cd "/c/Users/Software Engineering/GreenGo App/test/mock_server"
npm start &
API_PID=$!

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Mock Servers are Running!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "  Firebase Emulator UI:    http://localhost:4000"
echo "  Firestore Emulator:      http://localhost:8081"
echo "  Auth Emulator:           http://localhost:9099"
echo "  Storage Emulator:        http://localhost:9199"
echo "  Mock API Server:         http://localhost:8080"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "Press Ctrl+C to stop all servers"
echo ""

# Save PIDs
echo $FIREBASE_PID > /tmp/greengo_firebase_pid
echo $API_PID > /tmp/greengo_api_pid

# Wait for user interrupt
trap "kill $FIREBASE_PID $API_PID 2>/dev/null; echo 'Servers stopped'; exit" INT TERM

wait
