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
