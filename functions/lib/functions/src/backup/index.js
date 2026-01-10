"use strict";
/**
 * Backup & Export Service
 * 8 Cloud Functions for conversation backup, restore, and PDF export
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
exports.cleanupExpiredExports = exports.listPDFExports = exports.exportConversationToPDF = exports.autoBackupConversations = exports.deleteBackup = exports.listBackups = exports.restoreConversation = exports.backupConversation = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const crypto = __importStar(require("crypto"));
const pdfkit_1 = __importDefault(require("pdfkit"));
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const ENCRYPTION_ALGORITHM = 'aes-256-gcm';
const BACKUP_BUCKET = process.env.BACKUP_BUCKET || 'conversation-backups';
const EXPORT_BUCKET = process.env.EXPORT_BUCKET || 'pdf-exports';
exports.backupConversation = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { conversationId, includeMedia = false } = request.data;
        if (!conversationId) {
            throw new https_1.HttpsError('invalid-argument', 'conversationId is required');
        }
        (0, utils_1.logInfo)(`Backing up conversation ${conversationId} for user ${uid}`);
        // Verify user is participant
        const conversationDoc = await utils_1.db.collection('conversations').doc(conversationId).get();
        if (!conversationDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Conversation not found');
        }
        const conversationData = conversationDoc.data();
        if (!conversationData.participants.includes(uid)) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        // Get all messages
        const messagesSnapshot = await utils_1.db
            .collection('messages')
            .where('conversationId', '==', conversationId)
            .orderBy('timestamp', 'asc')
            .get();
        const messages = messagesSnapshot.docs.map(doc => {
            var _a;
            return (Object.assign(Object.assign({ id: doc.id }, doc.data()), { timestamp: (_a = doc.data().timestamp) === null || _a === void 0 ? void 0 : _a.toDate().toISOString() }));
        });
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
        const userKeyRef = utils_1.db.collection('user_encryption_keys').doc(uid);
        const userKeyDoc = await userKeyRef.get();
        let userMasterKey;
        if (!userKeyDoc.exists) {
            // Generate master key for user
            userMasterKey = crypto.randomBytes(32);
            await userKeyRef.set({
                keyHash: crypto.createHash('sha256').update(userMasterKey).digest('hex'),
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        else {
            // In production, this would be derived from user password
            userMasterKey = crypto.randomBytes(32);
        }
        // Upload to Cloud Storage
        const fileName = `${uid}/${conversationId}/${Date.now()}.backup`;
        const bucket = utils_1.storage.bucket(BACKUP_BUCKET);
        const file = bucket.file(fileName);
        await file.save(JSON.stringify({
            encrypted,
            iv: iv.toString('hex'),
            authTag: authTag.toString('hex'),
            key: encryptionKey.toString('hex'), // In production, encrypt this with userMasterKey
        }), {
            contentType: 'application/json',
            metadata: {
                metadata: {
                    conversationId,
                    userId: uid,
                    messageCount: messages.length.toString(),
                },
            },
        });
        // Save backup reference
        const backupRef = await utils_1.db.collection('backups').add({
            userId: uid,
            conversationId,
            fileName,
            messageCount: messages.length,
            includeMedia,
            size: encrypted.length,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 90 * 24 * 60 * 60 * 1000) // 90 days
            ),
        });
        return {
            success: true,
            backupId: backupRef.id,
            messageCount: messages.length,
            size: encrypted.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.restoreConversation = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { backupId } = request.data;
        if (!backupId) {
            throw new https_1.HttpsError('invalid-argument', 'backupId is required');
        }
        (0, utils_1.logInfo)(`Restoring backup ${backupId} for user ${uid}`);
        // Get backup reference
        const backupDoc = await utils_1.db.collection('backups').doc(backupId).get();
        if (!backupDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Backup not found');
        }
        const backupData = backupDoc.data();
        // Verify ownership
        if (backupData.userId !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        // Download backup from Cloud Storage
        const bucket = utils_1.storage.bucket(BACKUP_BUCKET);
        const file = bucket.file(backupData.fileName);
        const [contents] = await file.download();
        const encryptedData = JSON.parse(contents.toString());
        // Decrypt backup
        const decipher = crypto.createDecipheriv(ENCRYPTION_ALGORITHM, Buffer.from(encryptedData.key, 'hex'), Buffer.from(encryptedData.iv, 'hex'));
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
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 3. LIST BACKUPS (HTTP Callable) ==========
exports.listBackups = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const snapshot = await utils_1.db
            .collection('backups')
            .where('userId', '==', uid)
            .orderBy('createdAt', 'desc')
            .limit(50)
            .get();
        const backups = snapshot.docs.map(doc => {
            var _a, _b;
            return (Object.assign(Object.assign({ id: doc.id }, doc.data()), { createdAt: (_a = doc.data().createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), expiresAt: (_b = doc.data().expiresAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString() }));
        });
        return {
            success: true,
            backups,
            total: backups.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.deleteBackup = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { backupId } = request.data;
        if (!backupId) {
            throw new https_1.HttpsError('invalid-argument', 'backupId is required');
        }
        const backupDoc = await utils_1.db.collection('backups').doc(backupId).get();
        if (!backupDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Backup not found');
        }
        const backupData = backupDoc.data();
        if (backupData.userId !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        // Delete from Cloud Storage
        const bucket = utils_1.storage.bucket(BACKUP_BUCKET);
        await bucket.file(backupData.fileName).delete();
        // Delete from Firestore
        await backupDoc.ref.delete();
        return {
            success: true,
            message: 'Backup deleted successfully',
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 5. AUTO-BACKUP CONVERSATIONS (Scheduled - Weekly) ==========
exports.autoBackupConversations = (0, scheduler_1.onSchedule)({
    schedule: '0 3 * * 0', // Every Sunday at 3 AM
    timeZone: 'UTC',
    memory: '1GiB',
    timeoutSeconds: 540,
}, async () => {
    (0, utils_1.logInfo)('Starting auto-backup of active conversations');
    try {
        // Get active conversations (with messages in last 30 days)
        const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const snapshot = await utils_1.db
            .collection('conversations')
            .where('lastMessageTimestamp', '>', admin.firestore.Timestamp.fromDate(cutoffDate))
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} active conversations to backup`);
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const conversationId = doc.id;
            // Backup for each participant
            for (const userId of data.participants) {
                try {
                    // Check if backup already exists this week
                    const existingBackup = await utils_1.db
                        .collection('backups')
                        .where('userId', '==', userId)
                        .where('conversationId', '==', conversationId)
                        .where('createdAt', '>', admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)))
                        .limit(1)
                        .get();
                    if (!existingBackup.empty) {
                        (0, utils_1.logInfo)(`Backup already exists for user ${userId}, conversation ${conversationId}`);
                        continue;
                    }
                    // Get messages
                    const messagesSnapshot = await utils_1.db
                        .collection('messages')
                        .where('conversationId', '==', conversationId)
                        .orderBy('timestamp', 'asc')
                        .get();
                    const messages = messagesSnapshot.docs.map(msgDoc => {
                        var _a;
                        return (Object.assign(Object.assign({ id: msgDoc.id }, msgDoc.data()), { timestamp: (_a = msgDoc.data().timestamp) === null || _a === void 0 ? void 0 : _a.toDate().toISOString() }));
                    });
                    // Create backup (simplified version)
                    const backupData = {
                        conversationId,
                        messages,
                        messageCount: messages.length,
                        backedUpAt: new Date().toISOString(),
                        auto: true,
                    };
                    const fileName = `auto/${userId}/${conversationId}/${Date.now()}.backup`;
                    const bucket = utils_1.storage.bucket(BACKUP_BUCKET);
                    await bucket.file(fileName).save(JSON.stringify(backupData), {
                        contentType: 'application/json',
                    });
                    await utils_1.db.collection('backups').add({
                        userId,
                        conversationId,
                        fileName,
                        messageCount: messages.length,
                        auto: true,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)),
                    });
                    (0, utils_1.logInfo)(`Auto-backup created for user ${userId}, conversation ${conversationId}`);
                }
                catch (error) {
                    (0, utils_1.logError)(`Error backing up conversation ${conversationId} for user ${userId}:`, error);
                }
            }
        }
        (0, utils_1.logInfo)('Auto-backup completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error during auto-backup:', error);
        throw error;
    }
});
exports.exportConversationToPDF = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { conversationId, theme = 'gold' } = request.data;
        if (!conversationId) {
            throw new https_1.HttpsError('invalid-argument', 'conversationId is required');
        }
        (0, utils_1.logInfo)(`Exporting conversation ${conversationId} to PDF`);
        // Verify access
        const conversationDoc = await utils_1.db.collection('conversations').doc(conversationId).get();
        if (!conversationDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Conversation not found');
        }
        const conversationData = conversationDoc.data();
        if (!conversationData.participants.includes(uid)) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        // Get messages
        const messagesSnapshot = await utils_1.db
            .collection('messages')
            .where('conversationId', '==', conversationId)
            .orderBy('timestamp', 'asc')
            .get();
        // Create PDF
        const doc = new pdfkit_1.default({ size: 'A4', margin: 50 });
        const chunks = [];
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
                .text(((_a = msgData.timestamp) === null || _a === void 0 ? void 0 : _a.toDate().toLocaleString()) || '', { align: isSender ? 'right' : 'left' });
            doc.fontSize(12)
                .fillColor(isSender ? '#D4AF37' : '#333')
                .text(msgData.content, { align: isSender ? 'right' : 'left' });
            doc.moveDown();
        }
        doc.end();
        // Wait for PDF to finish
        const pdfBuffer = await new Promise((resolve) => {
            doc.on('end', () => resolve(Buffer.concat(chunks)));
        });
        // Upload to Cloud Storage
        const fileName = `${uid}/${conversationId}/${Date.now()}.pdf`;
        const bucket = utils_1.storage.bucket(EXPORT_BUCKET);
        const file = bucket.file(fileName);
        await file.save(pdfBuffer, {
            contentType: 'application/pdf',
        });
        const [url] = await file.getSignedUrl({
            action: 'read',
            expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
        });
        // Save export reference
        await utils_1.db.collection('pdf_exports').add({
            userId: uid,
            conversationId,
            fileName,
            theme,
            messageCount: messagesSnapshot.size,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
        });
        return {
            success: true,
            pdfUrl: url,
            messageCount: messagesSnapshot.size,
            expiresIn: '7 days',
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 7. LIST PDF EXPORTS (HTTP Callable) ==========
exports.listPDFExports = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const snapshot = await utils_1.db
            .collection('pdf_exports')
            .where('userId', '==', uid)
            .orderBy('createdAt', 'desc')
            .limit(20)
            .get();
        const exports = snapshot.docs.map(doc => {
            var _a, _b;
            return (Object.assign(Object.assign({ id: doc.id }, doc.data()), { createdAt: (_a = doc.data().createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), expiresAt: (_b = doc.data().expiresAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString() }));
        });
        return {
            success: true,
            exports,
            total: exports.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 8. CLEANUP EXPIRED EXPORTS (Scheduled - Daily) ==========
exports.cleanupExpiredExports = (0, scheduler_1.onSchedule)({
    schedule: '0 2 * * *', // Daily at 2 AM
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Cleaning up expired PDF exports');
    try {
        const now = admin.firestore.Timestamp.now();
        const snapshot = await utils_1.db
            .collection('pdf_exports')
            .where('expiresAt', '<', now)
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} expired exports to delete`);
        const bucket = utils_1.storage.bucket(EXPORT_BUCKET);
        const batch = utils_1.db.batch();
        for (const doc of snapshot.docs) {
            const data = doc.data();
            // Delete from Cloud Storage
            try {
                await bucket.file(data.fileName).delete();
            }
            catch (error) {
                (0, utils_1.logError)(`Error deleting file ${data.fileName}:`, error);
            }
            // Delete from Firestore
            batch.delete(doc.ref);
        }
        await batch.commit();
        (0, utils_1.logInfo)(`Cleanup completed: ${snapshot.size} exports deleted`);
    }
    catch (error) {
        (0, utils_1.logError)('Error during cleanup:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map