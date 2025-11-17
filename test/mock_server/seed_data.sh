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
