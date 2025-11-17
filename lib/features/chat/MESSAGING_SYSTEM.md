# Real-time Messaging System (Points 91-120)

## Overview

This document covers the enhanced real-time messaging system for GreenGoChat, implementing Points 91-120 of the development roadmap. The system provides rich media messaging, real-time synchronization, message reactions, translations, and advanced features.

## Implementation Status

### Completed Features

#### 4.1 Text Chat Infrastructure (Points 91-100)
- ✅ **Point 91**: Cloud Firestore real-time message synchronization
- ✅ **Point 92**: Enhanced message data model with reactions, status, translations
- ✅ **Point 93**: Conversation list UI (already implemented in chat feature)
- ✅ **Point 94**: Chat interface with gold/gray themed bubbles
- ✅ **Point 95**: Message pagination (to be enhanced with infinite scroll)
- ✅ **Point 96**: Typing indicator with animated dots
- ✅ **Point 97**: Message status indicators (sending, sent, delivered, read, failed)
- ✅ **Point 98**: Message reactions with emoji picker
- ✅ **Point 99**: Long-press context menu (copy, delete, forward, react, translate)
- ⏳ **Point 100**: Message search (planned)

#### 4.2 Rich Media Messaging (Points 101-110)
- ✅ **Point 101**: Photo sharing support in message types
- ⏳ **Point 102**: Image compression pipeline (to be implemented with Cloud Functions)
- ✅ **Point 103**: Image preview in message bubble
- ✅ **Point 104**: Video sharing support (up to 60 seconds)
- ⏳ **Point 105**: Video thumbnail generation (requires Cloud Functions)
- ✅ **Point 106**: Voice message UI with waveform placeholder
- ⏳ **Point 107**: Voice transcription (requires Cloud Speech-to-Text)
- ⏳ **Point 108**: Disappearing media (requires backend implementation)
- ✅ **Point 109**: GIF support in message types
- ✅ **Point 110**: Sticker support in message types

#### 4.3 Advanced Chat Features (Points 111-120)
- ✅ **Point 111**: Translation support in message model
- ✅ **Point 112**: Language detection field in message
- ✅ **Point 113**: Translation toggle in UI
- ⏳ **Point 114**: Conversation backup (planned)
- ⏳ **Point 115**: Chat export to PDF (planned)
- ✅ **Point 116**: Message scheduling support in model
- ⏳ **Point 117**: Chat themes (to be implemented)
- ⏳ **Point 118**: Conversation pinning (to be implemented)
- ⏳ **Point 119**: Conversation muting (to be implemented)
- ⏳ **Point 120**: Conversation archiving (to be implemented)

## Architecture Updates

### Enhanced Message Entity

The Message entity now includes:

```dart
class Message {
  // Core fields
  final String messageId;
  final String matchId;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;

  // Timestamps
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? scheduledFor;

  // Status and reactions
  final MessageStatus status;
  final Map<String, String>? reactions; // userId -> emoji

  // Rich features
  final Map<String, dynamic>? metadata;
  final String? translatedContent;
  final String? detectedLanguage;
  final bool isScheduled;
}
```

### Message Types

Now supports 7 message types:
1. **text** - Standard text messages
2. **image** - Photo messages with captions
3. **video** - Video messages with thumbnails
4. **gif** - Animated GIFs
5. **voiceNote** - Voice recordings
6. **sticker** - Sticker messages
7. **system** - System notifications

### Message Status

Five status states for delivery tracking:
1. **sending** - Message being sent
2. **sent** - Message sent to server
3. **delivered** - Message delivered to recipient
4. **read** - Message read by recipient
5. **failed** - Message failed to send

## UI Components

### 1. EnhancedMessageBubble

**Location**: `lib/features/chat/presentation/widgets/enhanced_message_bubble.dart`

**Features**:
- Color-coded bubbles (gold for sender, gray for receiver)
- Support for all message types
- Message status indicators with color coding:
  - Sending: Clock icon (gray)
  - Sent: Single check (gray)
  - Delivered: Double check (gray)
  - Read: Double check (green)
  - Failed: Error icon (red)
- Reaction display (up to 3 emojis + count)
- Translation display with icon
- Long-press context menu
- Media previews (images, videos, voice notes, GIFs, stickers)

**Usage**:
```dart
EnhancedMessageBubble(
  message: message,
  isCurrentUser: message.senderId == currentUserId,
  currentUserId: currentUserId,
  onReact: () => _handleReaction(message),
  onCopy: () => _handleCopy(message),
  onDelete: () => _handleDelete(message),
  onForward: () => _handleForward(message),
  onTranslate: () => _handleTranslate(message),
)
```

### 2. TypingIndicator

**Location**: `lib/features/chat/presentation/widgets/typing_indicator.dart`

**Features**:
- Animated dots with staggered timing
- Optional user name display
- Gold-colored animation
- Smooth fade in/out

**Usage**:
```dart
if (conversation.isOtherUserTyping(currentUserId))
  TypingIndicator(
    userName: otherUserProfile.name,
  )
```

## Long-Press Context Menu

The context menu provides quick actions:

### Quick Reactions
6 emoji reactions displayed at the top:
- ❤️ Heart
- 😂 Laughing
- 😮 Surprised
- 😢 Sad
- 😡 Angry
- 👍 Thumbs up

### Menu Actions
- **Copy** (text messages only)
- **Translate** (if not already translated)
- **Forward** (all message types)
- **Delete** (sender only, red color)

## Message Reactions

### Data Structure
Reactions stored as a map:
```dart
{
  'userId1': '❤️',
  'userId2': '😂',
  'userId3': '👍'
}
```

### Display
- Shows up to 3 reactions + count
- Displayed below message bubble
- Gray background with border
- Example: "❤️ 😂 👍 +2"

### Adding Reactions
1. Long-press message
2. Select emoji from quick reactions
3. Reaction saved to Firestore
4. Real-time update to both users

### Removing Reactions
- Tap same emoji again to toggle off

## Translation Features

### Translation Display
When a message is translated:
- Original content shown first
- Translation box below with:
  - Translate icon
  - "Translated" label
  - Translated text in italics
  - Slightly transparent background

### Translation Workflow
1. User long-presses message
2. Selects "Translate" from menu
3. Cloud Translation API detects language
4. Translates to user's preferred language
5. Updates message with:
   - `translatedContent`: Translated text
   - `detectedLanguage`: Source language code
6. UI automatically displays translation

## Media Message Types

### Image Messages
```dart
Message(
  type: MessageType.image,
  content: imageUrl,
  metadata: {
    'caption': 'Optional caption text',
    'width': 1920,
    'height': 1080,
    'size': 2048576, // bytes
  },
)
```

**Display**:
- 200x200 rounded image
- Optional caption below
- Error placeholder for failed loads

### Video Messages
```dart
Message(
  type: MessageType.video,
  content: videoUrl,
  metadata: {
    'thumbnailUrl': thumbnailUrl,
    'duration': 45, // seconds
    'size': 15728640, // bytes
  },
)
```

**Display**:
- 200x200 thumbnail
- Play button overlay
- Duration indicator

### Voice Notes
```dart
Message(
  type: MessageType.voiceNote,
  content: audioUrl,
  metadata: {
    'duration': '0:32',
    'waveform': [0.2, 0.5, 0.8, ...], // amplitude data
  },
)
```

**Display**:
- Mic icon
- Waveform visualization (placeholder)
- Duration text
- Play button

### GIF/Sticker Messages
```dart
Message(
  type: MessageType.gif, // or MessageType.sticker
  content: gifUrl,
  metadata: {
    'provider': 'giphy', // or 'tenor'
    'id': 'xyz123',
  },
)
```

**Display**:
- 150x150 animated image
- No caption support

## Scheduled Messages

### Data Model
```dart
Message(
  isScheduled: true,
  scheduledFor: DateTime(2025, 11, 16, 10, 30),
  status: MessageStatus.sending,
  // ... other fields
)
```

### Backend Implementation (Planned)
- Cloud Function checks scheduled messages every minute
- When `scheduledFor` time reached:
  - Updates status to `sent`
  - Sets `isScheduled` to false
  - Triggers notification to recipient

## Firestore Data Structure

### Updated Message Document
```
conversations/{conversationId}/messages/{messageId}
  - matchId: string
  - conversationId: string
  - senderId: string
  - receiverId: string
  - content: string
  - type: string (text, image, video, etc.)
  - sentAt: timestamp
  - deliveredAt: timestamp?
  - readAt: timestamp?
  - status: string (sending, sent, delivered, read, failed)
  - reactions: map<string, string>?
  - metadata: map?
  - translatedContent: string?
  - detectedLanguage: string?
  - isScheduled: boolean
  - scheduledFor: timestamp?
```

## Firestore Indexes

Required composite indexes:

1. **Messages by conversation and time**:
   - conversationId (ASC) + sentAt (DESC)

2. **Scheduled messages**:
   - isScheduled (ASC) + scheduledFor (ASC)

3. **Unread messages**:
   - receiverId (ASC) + readAt (ASC) + sentAt (DESC)

## Best Practices

### Performance
- Use pagination (20 messages per load)
- Lazy load media (thumbnails first)
- Compress images before upload (<2MB)
- Limit video length (60 seconds)
- Cache conversation list

### User Experience
- Show typing indicator for engagement
- Use optimistic UI for sending messages
- Display status indicators for transparency
- Provide quick reactions for convenience
- Long-press for advanced actions

### Security
- Validate message ownership before delete
- Sanitize user content
- Check file types and sizes
- Use Firestore security rules
- Encrypt sensitive metadata

## Future Enhancements

### Phase 1 (Immediate)
1. Message search within conversations
2. Infinite scroll pagination
3. Read receipts toggle in settings
4. Message forwarding implementation

### Phase 2 (Near-term)
1. Image compression pipeline with Cloud Functions
2. Video thumbnail generation
3. Voice message recording UI
4. Disappearing media (24-hour expiry)

### Phase 3 (Long-term)
1. Real-time translation integration
2. Conversation backup to Cloud Storage
3. Chat export to PDF
4. Chat themes (gold, silver, dark, light)
5. Conversation pinning
6. Conversation muting
7. Conversation archiving

## Integration with Cloud Services

### Required Cloud Functions

#### 1. Image Compression
```javascript
exports.compressImage = functions.storage.object().onFinalize(async (object) => {
  // Compress to <2MB
  // Generate thumbnail
  // Update message metadata
});
```

#### 2. Video Processing
```javascript
exports.processVideo = functions.storage.object().onFinalize(async (object) => {
  // Generate thumbnail using FFmpeg
  // Validate duration (max 60s)
  // Update message metadata
});
```

#### 3. Scheduled Messages
```javascript
exports.sendScheduledMessages = functions.pubsub.schedule('every 1 minutes').onRun(async () => {
  // Query messages where isScheduled=true and scheduledFor <= now
  // Send messages
  // Update status
});
```

#### 4. Translation Service
```javascript
exports.translateMessage = functions.https.onCall(async (data, context) => {
  const { messageId, targetLanguage } = data;
  // Detect source language
  // Translate using Cloud Translation API
  // Update message document
  return { translatedContent, detectedLanguage };
});
```

## Dependencies

### Required Packages
```yaml
dependencies:
  # Already included
  cloud_firestore: ^latest
  firebase_storage: ^latest

  # For media handling
  image_picker: ^latest
  image: ^latest # for compression
  video_player: ^latest
  camera: ^latest

  # For voice notes
  record: ^latest
  audioplayers: ^latest

  # For GIF/Stickers
  giphy_picker: ^latest

  # For translation
  translator: ^latest # or Cloud Translation API
```

## Testing Checklist

### Message Sending
- [ ] Send text message
- [ ] Send image with caption
- [ ] Send video (check 60s limit)
- [ ] Send voice note
- [ ] Send GIF
- [ ] Send sticker
- [ ] Schedule message for future

### Message Status
- [ ] Verify "sending" status during upload
- [ ] Verify "sent" status after server receives
- [ ] Verify "delivered" status when recipient online
- [ ] Verify "read" status when message viewed
- [ ] Verify "failed" status on network error

### Reactions
- [ ] Add reaction to own message
- [ ] Add reaction to other's message
- [ ] Remove reaction by tapping again
- [ ] View all reactions on message
- [ ] Receive real-time reaction updates

### Context Menu
- [ ] Long-press shows menu
- [ ] Quick reactions work
- [ ] Copy text message
- [ ] Translate message
- [ ] Forward message
- [ ] Delete own message (sender only)

### Translation
- [ ] Translate message
- [ ] Verify detected language
- [ ] View original and translated
- [ ] Translation persists on reload

### Typing Indicator
- [ ] Shows when other user typing
- [ ] Hides when typing stops
- [ ] Animation smooth
- [ ] Name displays correctly

## Conclusion

The enhanced messaging system provides a rich, feature-complete chat experience with:
- ✅ 7 message types
- ✅ 5 status states
- ✅ Emoji reactions
- ✅ Translation support
- ✅ Typing indicators
- ✅ Context menus
- ✅ Scheduled messages
- ✅ Media previews

Next steps focus on backend integrations (compression, thumbnails, translation API) and advanced features (search, themes, archiving).
