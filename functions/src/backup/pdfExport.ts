/**
 * PDF Export Cloud Function
 * Point 115: Export conversation to PDF
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { Storage } from '@google-cloud/storage';
import PDFDocument from 'pdfkit';
import { Readable } from 'stream';

const firestore = admin.firestore();
const storage = new Storage();

const EXPORT_BUCKET = process.env.BACKUP_BUCKET || 'greengo-chat-backups';

interface ExportOptions {
  includeTimestamps: boolean;
  includeMedia: boolean;
  includeReactions: boolean;
  dateFormat: 'short' | 'long';
}

/**
 * Format date based on user preference
 */
function formatDate(date: Date, format: 'short' | 'long'): string {
  if (format === 'short') {
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    });
  } else {
    return date.toLocaleString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  }
}

/**
 * Export conversation to PDF
 * HTTP Callable Function
 */
export const exportConversationToPDF = functions
  .runWith({ memory: '1GB', timeoutSeconds: 300 })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const {
      conversationId,
      options = {
        includeTimestamps: true,
        includeMedia: true,
        includeReactions: true,
        dateFormat: 'short',
      },
    }: { conversationId: string; options?: Partial<ExportOptions> } = data;

    if (!conversationId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'conversationId is required'
      );
    }

    const userId = context.auth.uid;

    const exportOptions: ExportOptions = {
      includeTimestamps: options.includeTimestamps ?? true,
      includeMedia: options.includeMedia ?? true,
      includeReactions: options.includeReactions ?? true,
      dateFormat: options.dateFormat ?? 'short',
    };

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

      // Fetch user profiles
      const user1Snapshot = await firestore
        .collection('users')
        .doc(conversation.user1Id)
        .get();
      const user2Snapshot = await firestore
        .collection('users')
        .doc(conversation.user2Id)
        .get();

      const user1 = user1Snapshot.data();
      const user2 = user2Snapshot.data();

      const currentUser = userId === conversation.user1Id ? user1 : user2;
      const otherUser = userId === conversation.user1Id ? user2 : user1;

      // Fetch all messages
      const messagesSnapshot = await conversationRef
        .collection('messages')
        .orderBy('sentAt', 'asc')
        .get();

      const messages = messagesSnapshot.docs.map((doc) => ({
        messageId: doc.id,
        ...(doc.data() as any),
      })) as any[];

      console.log(`Exporting ${messages.length} messages to PDF for user ${userId}`);

      // Create PDF document
      const doc = new PDFDocument({
        size: 'A4',
        margin: 50,
        info: {
          Title: `Conversation Export - ${otherUser?.name || 'Unknown'}`,
          Author: 'GreenGoChat',
          Subject: 'Chat Transcript',
          Creator: 'GreenGoChat PDF Exporter',
          CreationDate: new Date(),
        },
      });

      const chunks: Buffer[] = [];
      doc.on('data', (chunk) => chunks.push(chunk));

      // Header
      doc
        .fontSize(20)
        .fillColor('#D4AF37') // Gold color
        .text('GreenGoChat Conversation Export', { align: 'center' });

      doc.moveDown(0.5);

      doc
        .fontSize(12)
        .fillColor('#000000')
        .text(`Conversation with: ${otherUser?.name || 'Unknown'}`, {
          align: 'center',
        });

      doc
        .fontSize(10)
        .fillColor('#666666')
        .text(
          `Exported on: ${formatDate(new Date(), exportOptions.dateFormat)}`,
          { align: 'center' }
        );

      doc
        .text(`Total Messages: ${messages.length}`, { align: 'center' });

      doc.moveDown(1);

      // Divider
      doc
        .strokeColor('#D4AF37')
        .lineWidth(2)
        .moveTo(50, doc.y)
        .lineTo(545, doc.y)
        .stroke();

      doc.moveDown(1);

      // Messages
      for (const message of messages) {
        const isCurrentUser = message.senderId === userId;
        const senderName = isCurrentUser
          ? currentUser?.name || 'You'
          : otherUser?.name || 'Unknown';

        const sentAt = message.sentAt?.toDate();

        // Check if we need a new page
        if (doc.y > 700) {
          doc.addPage();
        }

        // Sender name
        doc
          .fontSize(11)
          .fillColor(isCurrentUser ? '#D4AF37' : '#333333')
          .text(senderName, { continued: false });

        // Timestamp
        if (exportOptions.includeTimestamps && sentAt) {
          doc
            .fontSize(8)
            .fillColor('#999999')
            .text(`  ${formatDate(sentAt, exportOptions.dateFormat)}`, {
              continued: false,
            });
        }

        doc.moveDown(0.3);

        // Message content
        if (message.type === 'text') {
          doc
            .fontSize(10)
            .fillColor('#000000')
            .text(message.content, {
              indent: 10,
              align: 'left',
            });
        } else if (message.type === 'image' && exportOptions.includeMedia) {
          doc
            .fontSize(9)
            .fillColor('#666666')
            .text('[Image]', { indent: 10 });
          if (message.metadata?.caption) {
            doc.text(`Caption: ${message.metadata.caption}`, { indent: 10 });
          }
        } else if (message.type === 'video' && exportOptions.includeMedia) {
          doc
            .fontSize(9)
            .fillColor('#666666')
            .text('[Video]', { indent: 10 });
          if (message.metadata?.caption) {
            doc.text(`Caption: ${message.metadata.caption}`, { indent: 10 });
          }
        } else if (message.type === 'voiceNote' && exportOptions.includeMedia) {
          doc
            .fontSize(9)
            .fillColor('#666666')
            .text('[Voice Note]', { indent: 10 });
          if (message.metadata?.transcription) {
            doc.text(`Transcription: ${message.metadata.transcription}`, {
              indent: 10,
            });
          }
        } else if (message.type === 'gif' && exportOptions.includeMedia) {
          doc
            .fontSize(9)
            .fillColor('#666666')
            .text('[GIF]', { indent: 10 });
        } else if (message.type === 'sticker' && exportOptions.includeMedia) {
          doc
            .fontSize(9)
            .fillColor('#666666')
            .text('[Sticker]', { indent: 10 });
        }

        // Translation
        if (message.translatedContent) {
          doc.moveDown(0.2);
          doc
            .fontSize(9)
            .fillColor('#0066CC')
            .text(`Translation: ${message.translatedContent}`, { indent: 10 });
        }

        // Reactions
        if (
          exportOptions.includeReactions &&
          message.reactions &&
          Object.keys(message.reactions).length > 0
        ) {
          doc.moveDown(0.2);
          const reactions = Object.values(message.reactions).join(' ');
          doc
            .fontSize(9)
            .fillColor('#FF6B6B')
            .text(`Reactions: ${reactions}`, { indent: 10 });
        }

        // Status indicator
        if (message.status === 'read') {
          doc
            .fontSize(8)
            .fillColor('#4CAF50')
            .text('✓✓ Read', { indent: 10 });
        } else if (message.status === 'delivered') {
          doc
            .fontSize(8)
            .fillColor('#999999')
            .text('✓✓ Delivered', { indent: 10 });
        }

        doc.moveDown(0.8);

        // Light divider between messages
        doc
          .strokeColor('#EEEEEE')
          .lineWidth(0.5)
          .moveTo(60, doc.y)
          .lineTo(535, doc.y)
          .stroke();

        doc.moveDown(0.5);
      }

      // Footer on last page
      doc.moveDown(2);
      doc
        .fontSize(8)
        .fillColor('#999999')
        .text('End of conversation', { align: 'center' });

      doc
        .text('Generated by GreenGoChat - Your Dating App', {
          align: 'center',
        });

      // Finalize PDF
      doc.end();

      // Wait for PDF to be generated
      await new Promise<void>((resolve, reject) => {
        doc.on('end', () => resolve());
        doc.on('error', reject);
      });

      const pdfBuffer = Buffer.concat(chunks);

      // Upload to Cloud Storage
      const timestamp = Date.now();
      const fileName = `exports/${userId}/${conversationId}/${timestamp}.pdf`;
      const bucket = storage.bucket(EXPORT_BUCKET);
      const file = bucket.file(fileName);

      await file.save(pdfBuffer, {
        metadata: {
          contentType: 'application/pdf',
          metadata: {
            userId,
            conversationId,
            messageCount: messages.length.toString(),
            exportDate: new Date().toISOString(),
          },
        },
      });

      // Generate signed URL (valid for 7 days)
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
      });

      // Store export metadata in Firestore
      await firestore.collection('conversation_exports').add({
        userId,
        conversationId,
        fileName,
        fileSize: pdfBuffer.length,
        messageCount: messages.length,
        options: exportOptions,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      });

      console.log(
        `PDF export complete for conversation ${conversationId} (${pdfBuffer.length} bytes)`
      );

      return {
        success: true,
        downloadUrl: url,
        fileName,
        fileSize: pdfBuffer.length,
        messageCount: messages.length,
        expiresIn: '7 days',
      };
    } catch (error) {
      console.error('Error exporting conversation to PDF:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * List all PDF exports for a user
 * HTTP Callable Function
 */
export const listPDFExports = functions.https.onCall(async (data, context) => {
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
      .collection('conversation_exports')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc');

    if (conversationId) {
      query = query.where('conversationId', '==', conversationId);
    }

    const exportsSnapshot = await query.get();

    const exports = exportsSnapshot.docs.map((doc) => ({
      exportId: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate().toISOString(),
      expiresAt: doc.data().expiresAt?.toDate().toISOString(),
    }));

    return {
      success: true,
      exports,
      count: exports.length,
    };
  } catch (error) {
    console.error('Error listing PDF exports:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Delete expired PDF exports
 * Scheduled to run daily
 */
export const cleanupExpiredExports = functions.pubsub
  .schedule('every day 03:00')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting cleanup of expired PDF exports...');

    try {
      const now = new Date();

      const expiredExportsSnapshot = await firestore
        .collection('conversation_exports')
        .where('expiresAt', '<=', now)
        .get();

      console.log(`Found ${expiredExportsSnapshot.size} expired exports to delete`);

      const bucket = storage.bucket(EXPORT_BUCKET);
      let deleted = 0;
      let failed = 0;

      for (const exportDoc of expiredExportsSnapshot.docs) {
        try {
          const exportData = exportDoc.data();
          const file = bucket.file(exportData.fileName);

          // Delete file from storage
          await file.delete();

          // Delete metadata from Firestore
          await exportDoc.ref.delete();

          deleted++;
          console.log(`Deleted expired export: ${exportData.fileName}`);
        } catch (error) {
          console.error(`Error deleting export ${exportDoc.id}:`, error);
          failed++;
        }
      }

      console.log(`Cleanup complete: ${deleted} deleted, ${failed} failed`);

      return {
        success: true,
        deleted,
        failed,
      };
    } catch (error) {
      console.error('Error in cleanup:', error);
      throw error;
    }
  });
