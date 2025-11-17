/**
 * Conversation Backup Cloud Functions
 * Point 114: Backup conversations to Cloud Storage
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Storage } from '@google-cloud/storage';
import * as crypto from 'crypto';

const firestore = admin.firestore();
const storage = new Storage();

const BACKUP_BUCKET = process.env.BACKUP_BUCKET || 'greengo-chat-backups';
const ENCRYPTION_ALGORITHM = 'aes-256-gcm';

interface BackupMetadata {
  userId: string;
  conversationId: string;
  backupDate: Date;
  messageCount: number;
  encrypted: boolean;
  fileSize: number;
}

/**
 * Encrypts data using AES-256-GCM
 */
function encryptData(data: string, encryptionKey: string): {
  encrypted: string;
  iv: string;
  authTag: string;
} {
  const iv = crypto.randomBytes(16);
  const key = crypto.scryptSync(encryptionKey, 'salt', 32);
  const cipher = crypto.createCipheriv(ENCRYPTION_ALGORITHM, key, iv);

  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  const authTag = cipher.getAuthTag();

  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex'),
  };
}

/**
 * Decrypts data using AES-256-GCM
 */
function decryptData(
  encrypted: string,
  iv: string,
  authTag: string,
  encryptionKey: string
): string {
  const key = crypto.scryptSync(encryptionKey, 'salt', 32);
  const decipher = crypto.createDecipheriv(
    ENCRYPTION_ALGORITHM,
    key,
    Buffer.from(iv, 'hex')
  );

  decipher.setAuthTag(Buffer.from(authTag, 'hex'));

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}

/**
 * Backup a conversation to Cloud Storage
 * HTTP Callable Function
 */
export const backupConversation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { conversationId, encryptionKey } = data;

  if (!conversationId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'conversationId is required'
    );
  }

  const userId = context.auth.uid;

  try {
    // Verify user has access to conversation
    const conversationRef = firestore.collection('conversations').doc(conversationId);
    const conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Conversation not found');
    }

    const conversation = conversationDoc.data();

    if (
      conversation.user1Id !== userId &&
      conversation.user2Id !== userId
    ) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'User does not have access to this conversation'
      );
    }

    // Fetch all messages in the conversation
    const messagesSnapshot = await conversationRef
      .collection('messages')
      .orderBy('sentAt', 'asc')
      .get();

    const messages = messagesSnapshot.docs.map((doc) => ({
      messageId: doc.id,
      ...doc.data(),
      sentAt: doc.data().sentAt?.toDate().toISOString(),
      readAt: doc.data().readAt?.toDate().toISOString(),
      deliveredAt: doc.data().deliveredAt?.toDate().toISOString(),
    }));

    // Create backup data
    const backupData = {
      conversation: {
        conversationId,
        ...conversation,
        createdAt: conversation.createdAt?.toDate().toISOString(),
        lastMessageAt: conversation.lastMessageAt?.toDate().toISOString(),
      },
      messages,
      metadata: {
        backupDate: new Date().toISOString(),
        messageCount: messages.length,
        userId,
      },
    };

    const jsonData = JSON.stringify(backupData, null, 2);

    // Encrypt if encryption key provided
    let finalData = jsonData;
    let encrypted = false;
    let iv = '';
    let authTag = '';

    if (encryptionKey) {
      const encryptedData = encryptData(jsonData, encryptionKey);
      finalData = encryptedData.encrypted;
      iv = encryptedData.iv;
      authTag = encryptedData.authTag;
      encrypted = true;
    }

    // Upload to Cloud Storage
    const timestamp = Date.now();
    const fileName = `backups/${userId}/${conversationId}/${timestamp}.json${
      encrypted ? '.enc' : ''
    }`;
    const bucket = storage.bucket(BACKUP_BUCKET);
    const file = bucket.file(fileName);

    await file.save(finalData, {
      metadata: {
        contentType: 'application/json',
        metadata: {
          userId,
          conversationId,
          messageCount: messages.length.toString(),
          encrypted: encrypted.toString(),
          iv: encrypted ? iv : '',
          authTag: encrypted ? authTag : '',
          backupDate: new Date().toISOString(),
        },
      },
    });

    // Store backup metadata in Firestore
    const backupMetadata: BackupMetadata = {
      userId,
      conversationId,
      backupDate: new Date(),
      messageCount: messages.length,
      encrypted,
      fileSize: Buffer.byteLength(finalData, 'utf8'),
    };

    await firestore.collection('conversation_backups').add({
      ...backupMetadata,
      fileName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `Backup created for conversation ${conversationId} by user ${userId}`
    );

    return {
      success: true,
      fileName,
      messageCount: messages.length,
      encrypted,
      fileSize: backupMetadata.fileSize,
      backupDate: backupMetadata.backupDate.toISOString(),
    };
  } catch (error) {
    console.error('Error backing up conversation:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Restore a conversation from Cloud Storage backup
 * HTTP Callable Function
 */
export const restoreConversation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { fileName, encryptionKey } = data;

  if (!fileName) {
    throw new functions.https.HttpsError('invalid-argument', 'fileName is required');
  }

  const userId = context.auth.uid;

  try {
    // Verify file belongs to user
    if (!fileName.startsWith(`backups/${userId}/`)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot restore backup from another user'
      );
    }

    // Download backup file
    const bucket = storage.bucket(BACKUP_BUCKET);
    const file = bucket.file(fileName);

    const [exists] = await file.exists();
    if (!exists) {
      throw new functions.https.HttpsError('not-found', 'Backup file not found');
    }

    const [fileContent] = await file.download();
    const [metadata] = await file.getMetadata();

    let jsonData = fileContent.toString('utf8');

    // Decrypt if encrypted
    if (metadata.metadata?.encrypted === 'true') {
      if (!encryptionKey) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Encryption key is required for encrypted backup'
        );
      }

      const iv = metadata.metadata.iv;
      const authTag = metadata.metadata.authTag;

      try {
        jsonData = decryptData(jsonData, iv, authTag, encryptionKey);
      } catch (error) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid encryption key or corrupted backup'
        );
      }
    }

    const backupData = JSON.parse(jsonData);

    // Verify ownership
    if (backupData.metadata.userId !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Backup belongs to another user'
      );
    }

    const conversationId = backupData.conversation.conversationId;

    console.log(
      `Restoring conversation ${conversationId} for user ${userId} (${backupData.messages.length} messages)`
    );

    return {
      success: true,
      conversationId,
      messageCount: backupData.messages.length,
      backupDate: backupData.metadata.backupDate,
      preview: backupData.messages.slice(0, 5), // First 5 messages as preview
    };
  } catch (error) {
    console.error('Error restoring conversation:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * List all backups for a user
 * HTTP Callable Function
 */
export const listBackups = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { conversationId } = data;

  try {
    let query = firestore
      .collection('conversation_backups')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc');

    if (conversationId) {
      query = query.where('conversationId', '==', conversationId);
    }

    const backupsSnapshot = await query.get();

    const backups = backupsSnapshot.docs.map((doc) => ({
      backupId: doc.id,
      ...doc.data(),
      backupDate: doc.data().backupDate?.toDate().toISOString(),
      createdAt: doc.data().createdAt?.toDate().toISOString(),
    }));

    return {
      success: true,
      backups,
      count: backups.length,
    };
  } catch (error) {
    console.error('Error listing backups:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Delete a backup from Cloud Storage
 * HTTP Callable Function
 */
export const deleteBackup = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { backupId } = data;

  if (!backupId) {
    throw new functions.https.HttpsError('invalid-argument', 'backupId is required');
  }

  const userId = context.auth.uid;

  try {
    const backupDoc = await firestore
      .collection('conversation_backups')
      .doc(backupId)
      .get();

    if (!backupDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Backup not found');
    }

    const backup = backupDoc.data();

    // Verify ownership
    if (backup.userId !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot delete backup belonging to another user'
      );
    }

    // Delete from Cloud Storage
    const bucket = storage.bucket(BACKUP_BUCKET);
    const file = bucket.file(backup.fileName);

    await file.delete();

    // Delete metadata from Firestore
    await backupDoc.ref.delete();

    console.log(`Backup ${backupId} deleted by user ${userId}`);

    return {
      success: true,
      backupId,
    };
  } catch (error) {
    console.error('Error deleting backup:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Scheduled function to auto-backup active conversations
 * Runs weekly
 */
export const autoBackupConversations = functions.pubsub
  .schedule('every sunday 02:00')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting automatic conversation backups...');

    try {
      // Find conversations with recent activity (last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const activeConversationsSnapshot = await firestore
        .collection('conversations')
        .where('lastMessageAt', '>=', thirtyDaysAgo)
        .get();

      console.log(
        `Found ${activeConversationsSnapshot.size} active conversations to backup`
      );

      let backedUp = 0;
      let failed = 0;

      for (const conversationDoc of activeConversationsSnapshot.docs) {
        try {
          const conversationId = conversationDoc.id;
          const conversation = conversationDoc.data();

          // Check if backup already exists for this week
          const weekAgo = new Date();
          weekAgo.setDate(weekAgo.getDate() - 7);

          const recentBackupSnapshot = await firestore
            .collection('conversation_backups')
            .where('conversationId', '==', conversationId)
            .where('backupDate', '>=', weekAgo)
            .limit(1)
            .get();

          if (!recentBackupSnapshot.empty) {
            console.log(`Conversation ${conversationId} already backed up this week`);
            continue;
          }

          // Fetch messages
          const messagesSnapshot = await conversationDoc.ref
            .collection('messages')
            .orderBy('sentAt', 'asc')
            .get();

          const messages = messagesSnapshot.docs.map((doc) => ({
            messageId: doc.id,
            ...doc.data(),
            sentAt: doc.data().sentAt?.toDate().toISOString(),
            readAt: doc.data().readAt?.toDate().toISOString(),
            deliveredAt: doc.data().deliveredAt?.toDate().toISOString(),
          }));

          // Create backup
          const backupData = {
            conversation: {
              conversationId,
              ...conversation,
              createdAt: conversation.createdAt?.toDate().toISOString(),
              lastMessageAt: conversation.lastMessageAt?.toDate().toISOString(),
            },
            messages,
            metadata: {
              backupDate: new Date().toISOString(),
              messageCount: messages.length,
              automated: true,
            },
          };

          const jsonData = JSON.stringify(backupData, null, 2);

          // Upload to Cloud Storage
          const timestamp = Date.now();
          const fileName = `backups/auto/${conversationId}/${timestamp}.json`;
          const bucket = storage.bucket(BACKUP_BUCKET);
          const file = bucket.file(fileName);

          await file.save(jsonData, {
            metadata: {
              contentType: 'application/json',
              metadata: {
                conversationId,
                messageCount: messages.length.toString(),
                automated: 'true',
                backupDate: new Date().toISOString(),
              },
            },
          });

          // Store metadata
          await firestore.collection('conversation_backups').add({
            conversationId,
            backupDate: admin.firestore.FieldValue.serverTimestamp(),
            messageCount: messages.length,
            encrypted: false,
            fileName,
            automated: true,
            fileSize: Buffer.byteLength(jsonData, 'utf8'),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          backedUp++;
          console.log(`Backed up conversation ${conversationId}`);
        } catch (error) {
          console.error(
            `Error backing up conversation ${conversationDoc.id}:`,
            error
          );
          failed++;
        }
      }

      console.log(
        `Auto-backup complete: ${backedUp} successful, ${failed} failed`
      );

      return {
        success: true,
        backedUp,
        failed,
      };
    } catch (error) {
      console.error('Error in auto-backup:', error);
      throw error;
    }
  });
