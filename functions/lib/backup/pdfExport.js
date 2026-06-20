"use strict";
/**
 * PDF Export Cloud Function
 * Point 115: Export conversation to PDF
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupExpiredExports = exports.listPDFExports = exports.exportConversationToPDF = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const storage_1 = require("@google-cloud/storage");
const pdfkit_1 = __importDefault(require("pdfkit"));
const firestore = admin.firestore();
const storage = new storage_1.Storage();
const EXPORT_BUCKET = process.env.BACKUP_BUCKET || 'greengo-chat-backups';
/**
 * Format date based on user preference
 */
function formatDate(date, format) {
    if (format === 'short') {
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit',
        });
    }
    else {
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
exports.exportConversationToPDF = functions
    .runWith({ memory: '1GB', timeoutSeconds: 300 })
    .https.onCall(async (data, context) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId, options = {
        includeTimestamps: true,
        includeMedia: true,
        includeReactions: true,
        dateFormat: 'short',
    }, } = data;
    if (!conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
    }
    const userId = context.auth.uid;
    const exportOptions = {
        includeTimestamps: (_a = options.includeTimestamps) !== null && _a !== void 0 ? _a : true,
        includeMedia: (_b = options.includeMedia) !== null && _b !== void 0 ? _b : true,
        includeReactions: (_c = options.includeReactions) !== null && _c !== void 0 ? _c : true,
        dateFormat: (_d = options.dateFormat) !== null && _d !== void 0 ? _d : 'short',
    };
    try {
        // Verify user has access to conversation
        const conversationRef = firestore.collection('conversations').doc(conversationId);
        const conversationDoc = await conversationRef.get();
        if (!conversationDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Conversation not found');
        }
        const conversation = conversationDoc.data();
        if (conversation.user1Id !== userId &&
            conversation.user2Id !== userId) {
            throw new functions.https.HttpsError('permission-denied', 'User does not have access to this conversation');
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
        const messages = messagesSnapshot.docs.map((doc) => (Object.assign({ messageId: doc.id }, doc.data())));
        console.log(`Exporting ${messages.length} messages to PDF for user ${userId}`);
        // Create PDF document
        const doc = new pdfkit_1.default({
            size: 'A4',
            margin: 50,
            info: {
                Title: `Conversation Export - ${(otherUser === null || otherUser === void 0 ? void 0 : otherUser.name) || 'Unknown'}`,
                Author: 'GreenGoChat',
                Subject: 'Chat Transcript',
                Creator: 'GreenGoChat PDF Exporter',
                CreationDate: new Date(),
            },
        });
        const chunks = [];
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
            .text(`Conversation with: ${(otherUser === null || otherUser === void 0 ? void 0 : otherUser.name) || 'Unknown'}`, {
            align: 'center',
        });
        doc
            .fontSize(10)
            .fillColor('#666666')
            .text(`Exported on: ${formatDate(new Date(), exportOptions.dateFormat)}`, { align: 'center' });
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
                ? (currentUser === null || currentUser === void 0 ? void 0 : currentUser.name) || 'You'
                : (otherUser === null || otherUser === void 0 ? void 0 : otherUser.name) || 'Unknown';
            const sentAt = (_e = message.sentAt) === null || _e === void 0 ? void 0 : _e.toDate();
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
            }
            else if (message.type === 'image' && exportOptions.includeMedia) {
                doc
                    .fontSize(9)
                    .fillColor('#666666')
                    .text('[Image]', { indent: 10 });
                if ((_f = message.metadata) === null || _f === void 0 ? void 0 : _f.caption) {
                    doc.text(`Caption: ${message.metadata.caption}`, { indent: 10 });
                }
            }
            else if (message.type === 'video' && exportOptions.includeMedia) {
                doc
                    .fontSize(9)
                    .fillColor('#666666')
                    .text('[Video]', { indent: 10 });
                if ((_g = message.metadata) === null || _g === void 0 ? void 0 : _g.caption) {
                    doc.text(`Caption: ${message.metadata.caption}`, { indent: 10 });
                }
            }
            else if (message.type === 'voiceNote' && exportOptions.includeMedia) {
                doc
                    .fontSize(9)
                    .fillColor('#666666')
                    .text('[Voice Note]', { indent: 10 });
                if ((_h = message.metadata) === null || _h === void 0 ? void 0 : _h.transcription) {
                    doc.text(`Transcription: ${message.metadata.transcription}`, {
                        indent: 10,
                    });
                }
            }
            else if (message.type === 'gif' && exportOptions.includeMedia) {
                doc
                    .fontSize(9)
                    .fillColor('#666666')
                    .text('[GIF]', { indent: 10 });
            }
            else if (message.type === 'sticker' && exportOptions.includeMedia) {
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
            if (exportOptions.includeReactions &&
                message.reactions &&
                Object.keys(message.reactions).length > 0) {
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
            }
            else if (message.status === 'delivered') {
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
        await new Promise((resolve, reject) => {
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
        console.log(`PDF export complete for conversation ${conversationId} (${pdfBuffer.length} bytes)`);
        return {
            success: true,
            downloadUrl: url,
            fileName,
            fileSize: pdfBuffer.length,
            messageCount: messages.length,
            expiresIn: '7 days',
        };
    }
    catch (error) {
        console.error('Error exporting conversation to PDF:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * List all PDF exports for a user
 * HTTP Callable Function
 */
exports.listPDFExports = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
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
        const exports = exportsSnapshot.docs.map((doc) => {
            var _a, _b;
            return (Object.assign(Object.assign({ exportId: doc.id }, doc.data()), { createdAt: (_a = doc.data().createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), expiresAt: (_b = doc.data().expiresAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString() }));
        });
        return {
            success: true,
            exports,
            count: exports.length,
        };
    }
    catch (error) {
        console.error('Error listing PDF exports:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Delete expired PDF exports
 * Scheduled to run daily
 */
exports.cleanupExpiredExports = functions.pubsub
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
            }
            catch (error) {
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
    }
    catch (error) {
        console.error('Error in cleanup:', error);
        throw error;
    }
});
//# sourceMappingURL=pdfExport.js.map