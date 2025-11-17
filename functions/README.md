# GreenGoChat Cloud Functions

Backend Cloud Functions for the GreenGoChat dating app, implementing all server-side features including media processing, translation, scheduling, and backups.

## Features

### Media Processing
- **Image Compression** - Automatically compress images to <2MB using Sharp
- **Video Processing** - Generate thumbnails and validate video duration (max 60s)
- **Voice Transcription** - Transcribe voice messages using Cloud Speech-to-Text
- **Disappearing Media** - Auto-delete media after 24 hours

### Messaging
- **Translation** - Translate messages using Cloud Translation API
- **Scheduled Messages** - Send messages at specified future times
- **Auto-Translation** - Automatically translate messages based on user preferences

### Backup & Export
- **Conversation Backup** - Encrypted backups to Cloud Storage
- **PDF Export** - Beautiful PDF transcripts with themes
- **Auto Backup** - Weekly automated backups of active conversations

## Function List

### Storage-Triggered Functions

#### `compressUploadedImage`
- **Trigger:** Cloud Storage object upload
- **Purpose:** Compress images to max 2MB and generate 200x200 thumbnails
- **Input:** Image file uploaded to storage
- **Output:** Compressed image and thumbnail URLs in Firestore
- **Memory:** 512MB
- **Timeout:** 300s

```typescript
// Auto-triggered on upload
// Updates message document with:
{
  imageUrl: "gs://bucket/compressed/image.jpg",
  thumbnailUrl: "gs://bucket/thumbnails/image.jpg",
  metadata: {
    originalSize: 5242880,
    compressedSize: 1800000,
    compressionRatio: 0.34
  }
}
```

#### `processUploadedVideo`
- **Trigger:** Cloud Storage object upload (videos/* path)
- **Purpose:** Generate video thumbnails and validate duration
- **Input:** Video file uploaded to storage
- **Output:** Thumbnail URL and video metadata
- **Memory:** 2GB
- **Timeout:** 540s

```typescript
// Auto-triggered on video upload
// Validates max 60 second duration
// Generates thumbnail at 1 second
// Updates message with metadata
```

#### `transcribeVoiceMessage`
- **Trigger:** Cloud Storage object upload (voice/* path)
- **Purpose:** Transcribe audio to text using Cloud Speech-to-Text
- **Input:** Audio file (mp3, wav, m4a)
- **Output:** Transcription text and detected language
- **Memory:** 1GB
- **Timeout:** 300s

```typescript
// Supports languages: en, es, fr, de, pt, it
// Returns confidence score
// Updates message with transcription
```

### HTTP Callable Functions

#### `translateMessage`
- **Type:** HTTP Callable
- **Purpose:** Translate message content to target language
- **Authentication:** Required

**Request:**
```typescript
{
  messageId: string;
  conversationId: string;
  targetLanguage: string;
}
```

**Response:**
```typescript
{
  success: true,
  translatedContent: string,
  detectedLanguage: string,
  confidence: number
}
```

**Example:**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('translateMessage')
  .call({
    'messageId': 'msg-123',
    'conversationId': 'conv-456',
    'targetLanguage': 'es',
  });
```

#### `scheduleMessage`
- **Type:** HTTP Callable
- **Purpose:** Schedule a message for future delivery
- **Authentication:** Required

**Request:**
```typescript
{
  conversationId: string;
  matchId: string;
  senderId: string;
  receiverId: string;
  content: string;
  type?: string;
  scheduledFor: string; // ISO 8601 date
}
```

**Validation:**
- Scheduled time must be in the future
- Maximum 30 days in advance
- User must be authenticated sender

**Example:**
```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('scheduleMessage')
  .call({
    'conversationId': 'conv-123',
    'matchId': 'match-456',
    'senderId': currentUserId,
    'receiverId': otherUserId,
    'content': 'Happy Birthday!',
    'scheduledFor': DateTime.now().add(Duration(days: 1)).toIso8601String(),
  });
```

#### `cancelScheduledMessage`
- **Type:** HTTP Callable
- **Purpose:** Cancel a scheduled message
- **Authentication:** Required

**Request:**
```typescript
{
  conversationId: string;
  messageId: string;
}
```

#### `backupConversation`
- **Type:** HTTP Callable
- **Purpose:** Create encrypted backup of conversation
- **Authentication:** Required

**Request:**
```typescript
{
  conversationId: string;
  encryptionKey?: string; // Optional encryption
}
```

**Response:**
```typescript
{
  success: true,
  fileName: string,
  messageCount: number,
  encrypted: boolean,
  fileSize: number,
  backupDate: string
}
```

**Features:**
- AES-256-GCM encryption
- Includes all messages and metadata
- Stored in Cloud Storage
- 7-day retention policy

#### `restoreConversation`
- **Type:** HTTP Callable
- **Purpose:** Restore conversation from backup
- **Authentication:** Required

**Request:**
```typescript
{
  fileName: string;
  encryptionKey?: string; // Required if backup is encrypted
}
```

**Response:**
```typescript
{
  success: true,
  conversationId: string,
  messageCount: number,
  backupDate: string,
  preview: Message[] // First 5 messages
}
```

#### `exportConversationToPDF`
- **Type:** HTTP Callable
- **Purpose:** Generate PDF transcript of conversation
- **Authentication:** Required
- **Memory:** 1GB
- **Timeout:** 300s

**Request:**
```typescript
{
  conversationId: string;
  options?: {
    includeTimestamps?: boolean;
    includeMedia?: boolean;
    includeReactions?: boolean;
    dateFormat?: 'short' | 'long';
  }
}
```

**Response:**
```typescript
{
  success: true,
  downloadUrl: string, // 7-day signed URL
  fileName: string,
  fileSize: number,
  messageCount: number,
  expiresIn: '7 days'
}
```

**PDF Features:**
- Gold-themed header
- Conversation metadata
- Message bubbles with timestamps
- Reaction displays
- Translation displays
- Media placeholders ([Image], [Video], etc.)
- Voice note transcriptions
- Read receipts and status indicators

### Scheduled Functions (Pub/Sub)

#### `sendScheduledMessages`
- **Trigger:** Cloud Scheduler (every 1 minute)
- **Purpose:** Send messages that have reached their scheduled time
- **Batch Size:** 50 messages per run

**Process:**
1. Query messages where `scheduledFor <= now`
2. Update status to 'sent'
3. Update conversation lastMessage
4. Create notification for receiver
5. Commit batch write

#### `cleanupDisappearingMedia`
- **Trigger:** Cloud Scheduler (every 1 hour)
- **Purpose:** Delete media files older than 24 hours
- **TTL:** 24 hours

**Process:**
1. Find messages with `isDisappearing = true` and `expiresAt <= now`
2. Delete files from Cloud Storage
3. Update message content to '[Media expired]'
4. Mark as `disappearingMediaDeleted = true`

#### `autoBackupConversations`
- **Trigger:** Cloud Scheduler (every Sunday 02:00 UTC)
- **Purpose:** Automatically backup active conversations

**Process:**
1. Find conversations with activity in last 30 days
2. Skip if backup exists from last 7 days
3. Create JSON backup
4. Upload to Cloud Storage
5. Store metadata in Firestore

#### `cleanupExpiredExports`
- **Trigger:** Cloud Scheduler (every day 03:00 UTC)
- **Purpose:** Delete expired PDF exports (>7 days old)

## Installation

### Prerequisites
- Node.js v18 or higher
- Firebase CLI: `npm install -g firebase-tools`
- Google Cloud SDK

### Install Dependencies
```bash
cd functions
npm install
```

### Build TypeScript
```bash
npm run build
```

### Deploy All Functions
```bash
firebase deploy --only functions
```

### Deploy Specific Function
```bash
firebase deploy --only functions:compressUploadedImage
```

## Configuration

### Environment Variables
Set via Firebase config:

```bash
firebase functions:config:set \
  storage.bucket="your-bucket-name" \
  backup.bucket="your-backup-bucket" \
  max.image_size_mb=2 \
  max.video_duration=60 \
  disappearing.ttl_hours=24
```

### Required APIs
Enable in Google Cloud Console:
- Cloud Translation API
- Cloud Speech-to-Text API
- Cloud Storage API
- Cloud Scheduler API
- Cloud Pub/Sub API

### IAM Permissions
Service account needs:
- `roles/datastore.user` - Firestore access
- `roles/storage.objectAdmin` - Cloud Storage access
- `roles/cloudtranslate.user` - Translation API
- `roles/speech.client` - Speech-to-Text API

## Testing

### Local Emulator
```bash
firebase emulators:start --only functions,firestore,storage
```

### Test Image Compression
```bash
gsutil cp test-image.jpg gs://your-bucket/images/test.jpg
```

### Test Translation (via emulator)
```bash
curl -X POST http://localhost:5001/your-project/us-central1/translateMessage \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "messageId": "test",
      "conversationId": "test",
      "targetLanguage": "es"
    }
  }'
```

### View Logs
```bash
firebase functions:log
```

## Performance

### Memory Allocation
- Image compression: 512MB
- Video processing: 2GB
- Voice transcription: 1GB
- Translation: 256MB
- PDF export: 1GB
- Scheduled messages: 256MB

### Concurrency
- Image compression: Max 100 instances
- Video processing: Max 50 instances
- Translation: Max 100 instances
- Scheduled functions: Max 10 instances

### Optimization Tips
1. **Image Compression:** Uses iterative quality reduction to meet size target
2. **Video Processing:** Generates thumbnail at 1 second mark for speed
3. **Batch Operations:** Scheduled messages process 50 at a time
4. **Caching:** Translation results cached in message documents

## Cost Estimates

**Per 1,000 invocations:**
- Image compression: $0.40 (512MB, 5s avg)
- Video processing: $1.60 (2GB, 20s avg)
- Translation: $0.05 + $20 per 1M characters
- Speech-to-Text: $0.024 per minute of audio
- Scheduled messages: $0.10 (256MB, 2s avg)

**Monthly fixed costs:**
- Cloud Scheduler: $0.10 per job ($0.30 total)

## Monitoring

### View Function Metrics
```bash
gcloud functions describe functionName --region=us-central1
```

### Check Error Rate
```bash
gcloud logging read "resource.type=cloud_function AND severity>=ERROR" --limit=50
```

### Set Up Alerts
Configure in GCP Console:
- **Monitoring > Alerting**
- Alert on error rate > 1%
- Alert on execution time > timeout

## Troubleshooting

### Function Timeout
Increase timeout in function config:
```typescript
export const myFunction = functions
  .runWith({ timeoutSeconds: 540, memory: '2GB' })
  .https.onCall(async (data, context) => {
    // ...
  });
```

### Out of Memory
Increase memory allocation:
```typescript
.runWith({ memory: '2GB' })
```

### Translation Quota Exceeded
Increase quota in GCP Console or implement caching.

### FFmpeg Not Found
Ensure using Node.js 18 runtime (FFmpeg included).

## Security

### Authentication
All HTTP callable functions require authentication:
```typescript
if (!context.auth) {
  throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
}
```

### Authorization
Verify user owns resources:
```typescript
if (message.senderId !== context.auth.uid) {
  throw new functions.https.HttpsError('permission-denied', 'Access denied');
}
```

### Encryption
Backups use AES-256-GCM encryption with user-provided keys.

### Data Validation
All inputs validated before processing:
```typescript
if (!conversationId || typeof conversationId !== 'string') {
  throw new functions.https.HttpsError('invalid-argument', 'Invalid conversationId');
}
```

## Architecture

```
functions/
├── src/
│   ├── media/
│   │   ├── imageCompression.ts      # Image processing
│   │   ├── videoProcessing.ts       # Video thumbnails
│   │   ├── voiceTranscription.ts    # Speech-to-text
│   │   └── disappearingMedia.ts     # Media cleanup
│   ├── messaging/
│   │   ├── translation.ts           # Message translation
│   │   └── scheduledMessages.ts     # Scheduled delivery
│   ├── backup/
│   │   ├── conversationBackup.ts    # Backup/restore
│   │   └── pdfExport.ts             # PDF generation
│   └── index.ts                     # Function exports
├── package.json
├── tsconfig.json
└── README.md
```

## Support

For issues or questions:
- Check logs: `firebase functions:log`
- Review documentation: [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- GCP Console: https://console.cloud.google.com

## License

Proprietary - GreenGoChat Dating App
