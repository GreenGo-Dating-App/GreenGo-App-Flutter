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
