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
