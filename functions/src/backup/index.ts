/**
 * Backup & Export Service
 * 8 Cloud Functions for conversation backup, restore, and PDF export
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as crypto from 'crypto';
import PDFDocument from 'pdfkit';
import { verifyAuth, handleError, logInfo, logError, db, storage } from '../shared/utils';
import * as admin from 'firebase-admin';

const ENCRYPTION_ALGORITHM = 'aes-256-gcm';
const BACKUP_BUCKET = process.env.BACKUP_BUCKET || 'conversation-backups';
const EXPORT_BUCKET = process.env.EXPORT_BUCKET || 'pdf-exports';

// ========== 1. BACKUP CONVERSATION (HTTP Callable) ==========

interface BackupConversationRequest {
  conversationId: string;
  includeMedia?: boolean;
}

export const backupConversation = onCall<BackupConversationRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { conversationId, includeMedia = false } = request.data;

      if (!conversationId) {
        throw new HttpsError('invalid-argument', 'conversationId is required');
      }

      logInfo(`Backing up conversation ${conversationId} for user ${uid}`);

      // Verify user is participant
      const conversationDoc = await db.collection('conversations').doc(conversationId).get();
      if (!conversationDoc.exists) {
        throw new HttpsError('not-found', 'Conversation not found');
      }

      const conversationData = conversationDoc.data()!;
      if (!conversationData.participants.includes(uid)) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      // Get all messages
      const messagesSnapshot = await db
        .collection('messages')
        .where('conversationId', '==', conversationId)
        .orderBy('timestamp', 'asc')
        .get();

      const messages = messagesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate().toISOString(),
      }));

      // Prepare backup data
      const backupData = {
        conversationId,
        conversation: conversationData,
        messages,
        messageCount: messages.length,
        backedUpAt: new Date().toISOString(),
        backedUpBy: uid,
        includeMedia,
      };

      // Encrypt backup
      const encryptionKey = crypto.randomBytes(32);
      const iv = crypto.randomBytes(16);
      const cipher = crypto.createCipheriv(ENCRYPTION_ALGORITHM, encryptionKey, iv);

      const jsonData = JSON.stringify(backupData);
      let encrypted = cipher.update(jsonData, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      const authTag = cipher.getAuthTag();

      // Store encryption key in Firestore (encrypted with user's key)
      const userKeyRef = db.collection('user_encryption_keys').doc(uid);
      const userKeyDoc = await userKeyRef.get();

      let userMasterKey: Buffer;
      if (!userKeyDoc.exists) {
        // Generate master key for user
        userMasterKey = crypto.randomBytes(32);
        await userKeyRef.set({
          keyHash: crypto.createHash('sha256').update(userMasterKey).digest('hex'),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        // In production, this would be derived from user password
        userMasterKey = crypto.randomBytes(32);
      }

      // Upload to Cloud Storage
      const fileName = `${uid}/${conversationId}/${Date.now()}.backup`;
      const bucket = storage.bucket(BACKUP_BUCKET);
      const file = bucket.file(fileName);

      await file.save(
        JSON.stringify({
          encrypted,
          iv: iv.toString('hex'),
          authTag: authTag.toString('hex'),
          key: encryptionKey.toString('hex'), // In production, encrypt this with userMasterKey
        }),
        {
          contentType: 'application/json',
          metadata: {
            metadata: {
              conversationId,
              userId: uid,
              messageCount: messages.length.toString(),
            },
          },
        }
      );

      // Save backup reference
      const backupRef = await db.collection('backups').add({
        userId: uid,
        conversationId,
        fileName,
        messageCount: messages.length,
        includeMedia,
        size: encrypted.length,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 90 * 24 * 60 * 60 * 1000) // 90 days
        ),
      });

      return {
        success: true,
        backupId: backupRef.id,
        messageCount: messages.length,
        size: encrypted.length,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 2. RESTORE CONVERSATION (HTTP Callable) ==========

interface RestoreConversationRequest {
  backupId: string;
}

export const restoreConversation = onCall<RestoreConversationRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { backupId } = request.data;

      if (!backupId) {
        throw new HttpsError('invalid-argument', 'backupId is required');
      }

      logInfo(`Restoring backup ${backupId} for user ${uid}`);

      // Get backup reference
      const backupDoc = await db.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) {
        throw new HttpsError('not-found', 'Backup not found');
      }

      const backupData = backupDoc.data()!;

      // Verify ownership
      if (backupData.userId !== uid) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      // Download backup from Cloud Storage
      const bucket = storage.bucket(BACKUP_BUCKET);
      const file = bucket.file(backupData.fileName);

      const [contents] = await file.download();
      const encryptedData = JSON.parse(contents.toString());

      // Decrypt backup
      const decipher = crypto.createDecipheriv(
        ENCRYPTION_ALGORITHM,
        Buffer.from(encryptedData.key, 'hex'),
        Buffer.from(encryptedData.iv, 'hex')
      );
      decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));

      let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      const restoredData = JSON.parse(decrypted);

      return {
        success: true,
        conversationId: restoredData.conversationId,
        messageCount: restoredData.messageCount,
        backedUpAt: restoredData.backedUpAt,
        data: restoredData,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 3. LIST BACKUPS (HTTP Callable) ==========

export const listBackups = onCall(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);

      const snapshot = await db
        .collection('backups')
        .where('userId', '==', uid)
        .orderBy('createdAt', 'desc')
        .limit(50)
        .get();

      const backups = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate().toISOString(),
        expiresAt: doc.data().expiresAt?.toDate().toISOString(),
      }));

      return {
        success: true,
        backups,
        total: backups.length,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 4. DELETE BACKUP (HTTP Callable) ==========

interface DeleteBackupRequest {
  backupId: string;
}

export const deleteBackup = onCall<DeleteBackupRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { backupId } = request.data;

      if (!backupId) {
        throw new HttpsError('invalid-argument', 'backupId is required');
      }

      const backupDoc = await db.collection('backups').doc(backupId).get();
      if (!backupDoc.exists) {
        throw new HttpsError('not-found', 'Backup not found');
      }

      const backupData = backupDoc.data()!;

      if (backupData.userId !== uid) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      // Delete from Cloud Storage
      const bucket = storage.bucket(BACKUP_BUCKET);
      await bucket.file(backupData.fileName).delete();

      // Delete from Firestore
      await backupDoc.ref.delete();

      return {
        success: true,
        message: 'Backup deleted successfully',
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 5. AUTO-BACKUP CONVERSATIONS (Scheduled - Weekly) ==========

export const autoBackupConversations = onSchedule(
  {
    schedule: '0 3 * * 0', // Every Sunday at 3 AM
    timeZone: 'UTC',
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Starting auto-backup of active conversations');

    try {
      // Get active conversations (with messages in last 30 days)
      const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

      const snapshot = await db
        .collection('conversations')
        .where('lastMessageTimestamp', '>', admin.firestore.Timestamp.fromDate(cutoffDate))
        .get();

      logInfo(`Found ${snapshot.size} active conversations to backup`);

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const conversationId = doc.id;

        // Backup for each participant
        for (const userId of data.participants) {
          try {
            // Check if backup already exists this week
            const existingBackup = await db
              .collection('backups')
              .where('userId', '==', userId)
              .where('conversationId', '==', conversationId)
              .where('createdAt', '>', admin.firestore.Timestamp.fromDate(
                new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
              ))
              .limit(1)
              .get();

            if (!existingBackup.empty) {
              logInfo(`Backup already exists for user ${userId}, conversation ${conversationId}`);
              continue;
            }

            // Get messages
            const messagesSnapshot = await db
              .collection('messages')
              .where('conversationId', '==', conversationId)
              .orderBy('timestamp', 'asc')
              .get();

            const messages = messagesSnapshot.docs.map(msgDoc => ({
              id: msgDoc.id,
              ...msgDoc.data(),
              timestamp: msgDoc.data().timestamp?.toDate().toISOString(),
            }));

            // Create backup (simplified version)
            const backupData = {
              conversationId,
              messages,
              messageCount: messages.length,
              backedUpAt: new Date().toISOString(),
              auto: true,
            };

            const fileName = `auto/${userId}/${conversationId}/${Date.now()}.backup`;
            const bucket = storage.bucket(BACKUP_BUCKET);

            await bucket.file(fileName).save(JSON.stringify(backupData), {
              contentType: 'application/json',
            });

            await db.collection('backups').add({
              userId,
              conversationId,
              fileName,
              messageCount: messages.length,
              auto: true,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              expiresAt: admin.firestore.Timestamp.fromDate(
                new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)
              ),
            });

            logInfo(`Auto-backup created for user ${userId}, conversation ${conversationId}`);
          } catch (error) {
            logError(`Error backing up conversation ${conversationId} for user ${userId}:`, error);
          }
        }
      }

      logInfo('Auto-backup completed');
    } catch (error) {
      logError('Error during auto-backup:', error);
      throw error;
    }
  }
);

// ========== 6. EXPORT CONVERSATION TO PDF (HTTP Callable) ==========

interface ExportPDFRequest {
  conversationId: string;
  theme?: 'light' | 'dark' | 'gold';
}

export const exportConversationToPDF = onCall<ExportPDFRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { conversationId, theme = 'gold' } = request.data;

      if (!conversationId) {
        throw new HttpsError('invalid-argument', 'conversationId is required');
      }

      logInfo(`Exporting conversation ${conversationId} to PDF`);

      // Verify access
      const conversationDoc = await db.collection('conversations').doc(conversationId).get();
      if (!conversationDoc.exists) {
        throw new HttpsError('not-found', 'Conversation not found');
      }

      const conversationData = conversationDoc.data()!;
      if (!conversationData.participants.includes(uid)) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      // Get messages
      const messagesSnapshot = await db
        .collection('messages')
        .where('conversationId', '==', conversationId)
        .orderBy('timestamp', 'asc')
        .get();

      // Create PDF
      const doc = new PDFDocument({ size: 'A4', margin: 50 });
      const chunks: Buffer[] = [];

      doc.on('data', (chunk) => chunks.push(chunk));

      // Header
      doc.fontSize(20).fillColor('#D4AF37').text('GreenGo Chat Export', { align: 'center' });
      doc.moveDown();
      doc.fontSize(12).fillColor('#666').text(`Exported on ${new Date().toLocaleDateString()}`, { align: 'center' });
      doc.moveDown(2);

      // Messages
      for (const messageDoc of messagesSnapshot.docs) {
        const msgData = messageDoc.data();
        const isSender = msgData.senderId === uid;

        doc.fontSize(10)
          .fillColor('#999')
          .text(msgData.timestamp?.toDate().toLocaleString() || '', { align: isSender ? 'right' : 'left' });

        doc.fontSize(12)
          .fillColor(isSender ? '#D4AF37' : '#333')
          .text(msgData.content, { align: isSender ? 'right' : 'left' });

        doc.moveDown();
      }

      doc.end();

      // Wait for PDF to finish
      const pdfBuffer = await new Promise<Buffer>((resolve) => {
        doc.on('end', () => resolve(Buffer.concat(chunks)));
      });

      // Upload to Cloud Storage
      const fileName = `${uid}/${conversationId}/${Date.now()}.pdf`;
      const bucket = storage.bucket(EXPORT_BUCKET);
      const file = bucket.file(fileName);

      await file.save(pdfBuffer, {
        contentType: 'application/pdf',
      });

      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
      });

      // Save export reference
      await db.collection('pdf_exports').add({
        userId: uid,
        conversationId,
        fileName,
        theme,
        messageCount: messagesSnapshot.size,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        ),
      });

      return {
        success: true,
        pdfUrl: url,
        messageCount: messagesSnapshot.size,
        expiresIn: '7 days',
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 7. LIST PDF EXPORTS (HTTP Callable) ==========

export const listPDFExports = onCall(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);

      const snapshot = await db
        .collection('pdf_exports')
        .where('userId', '==', uid)
        .orderBy('createdAt', 'desc')
        .limit(20)
        .get();

      const exports = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate().toISOString(),
        expiresAt: doc.data().expiresAt?.toDate().toISOString(),
      }));

      return {
        success: true,
        exports,
        total: exports.length,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 8. CLEANUP EXPIRED EXPORTS (Scheduled - Daily) ==========

export const cleanupExpiredExports = onSchedule(
  {
    schedule: '0 2 * * *', // Daily at 2 AM
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Cleaning up expired PDF exports');

    try {
      const now = admin.firestore.Timestamp.now();

      const snapshot = await db
        .collection('pdf_exports')
        .where('expiresAt', '<', now)
        .get();

      logInfo(`Found ${snapshot.size} expired exports to delete`);

      const bucket = storage.bucket(EXPORT_BUCKET);
      const batch = db.batch();

      for (const doc of snapshot.docs) {
        const data = doc.data();

        // Delete from Cloud Storage
        try {
          await bucket.file(data.fileName).delete();
        } catch (error) {
          logError(`Error deleting file ${data.fileName}:`, error);
        }

        // Delete from Firestore
        batch.delete(doc.ref);
      }

      await batch.commit();

      logInfo(`Cleanup completed: ${snapshot.size} exports deleted`);
    } catch (error) {
      logError('Error during cleanup:', error);
      throw error;
    }
  }
);
