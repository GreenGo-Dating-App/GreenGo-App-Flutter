"use strict";
/**
 * Conversation Backup Cloud Functions
 * Point 114: Backup conversations to Cloud Storage
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.autoBackupConversations = exports.deleteBackup = exports.listBackups = exports.restoreConversation = exports.backupConversation = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const storage_1 = require("@google-cloud/storage");
const crypto = __importStar(require("crypto"));
const firestore = admin.firestore();
const storage = new storage_1.Storage();
const BACKUP_BUCKET = process.env.BACKUP_BUCKET || 'greengo-chat-backups';
const ENCRYPTION_ALGORITHM = 'aes-256-gcm';
/**
 * Encrypts data using AES-256-GCM
 */
function encryptData(data, encryptionKey) {
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
function decryptData(encrypted, iv, authTag, encryptionKey) {
    const key = crypto.scryptSync(encryptionKey, 'salt', 32);
    const decipher = crypto.createDecipheriv(ENCRYPTION_ALGORITHM, key, Buffer.from(iv, 'hex'));
    decipher.setAuthTag(Buffer.from(authTag, 'hex'));
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}
/**
 * Backup a conversation to Cloud Storage
 * HTTP Callable Function
 */
exports.backupConversation = functions.https.onCall(async (data, context) => {
    var _a, _b;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId, encryptionKey } = data;
    if (!conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
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
        if (conversation.user1Id !== userId &&
            conversation.user2Id !== userId) {
            throw new functions.https.HttpsError('permission-denied', 'User does not have access to this conversation');
        }
        // Fetch all messages in the conversation
        const messagesSnapshot = await conversationRef
            .collection('messages')
            .orderBy('sentAt', 'asc')
            .get();
        const messages = messagesSnapshot.docs.map((doc) => {
            var _a, _b, _c;
            return (Object.assign(Object.assign({ messageId: doc.id }, doc.data()), { sentAt: (_a = doc.data().sentAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), readAt: (_b = doc.data().readAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString(), deliveredAt: (_c = doc.data().deliveredAt) === null || _c === void 0 ? void 0 : _c.toDate().toISOString() }));
        });
        // Create backup data
        const backupData = {
            conversation: Object.assign(Object.assign({ conversationId }, conversation), { createdAt: (_a = conversation.createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), lastMessageAt: (_b = conversation.lastMessageAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString() }),
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
        const fileName = `backups/${userId}/${conversationId}/${timestamp}.json${encrypted ? '.enc' : ''}`;
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
        const backupMetadata = {
            userId,
            conversationId,
            backupDate: new Date(),
            messageCount: messages.length,
            encrypted,
            fileSize: Buffer.byteLength(finalData, 'utf8'),
        };
        await firestore.collection('conversation_backups').add(Object.assign(Object.assign({}, backupMetadata), { fileName, createdAt: admin.firestore.FieldValue.serverTimestamp() }));
        console.log(`Backup created for conversation ${conversationId} by user ${userId}`);
        return {
            success: true,
            fileName,
            messageCount: messages.length,
            encrypted,
            fileSize: backupMetadata.fileSize,
            backupDate: backupMetadata.backupDate.toISOString(),
        };
    }
    catch (error) {
        console.error('Error backing up conversation:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Restore a conversation from Cloud Storage backup
 * HTTP Callable Function
 */
exports.restoreConversation = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { fileName, encryptionKey } = data;
    if (!fileName) {
        throw new functions.https.HttpsError('invalid-argument', 'fileName is required');
    }
    const userId = context.auth.uid;
    try {
        // Verify file belongs to user
        if (!fileName.startsWith(`backups/${userId}/`)) {
            throw new functions.https.HttpsError('permission-denied', 'Cannot restore backup from another user');
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
        if (((_a = metadata.metadata) === null || _a === void 0 ? void 0 : _a.encrypted) === 'true') {
            if (!encryptionKey) {
                throw new functions.https.HttpsError('invalid-argument', 'Encryption key is required for encrypted backup');
            }
            const iv = metadata.metadata.iv;
            const authTag = metadata.metadata.authTag;
            try {
                jsonData = decryptData(jsonData, String(iv), String(authTag), encryptionKey);
            }
            catch (error) {
                throw new functions.https.HttpsError('invalid-argument', 'Invalid encryption key or corrupted backup');
            }
        }
        const backupData = JSON.parse(jsonData);
        // Verify ownership
        if (backupData.metadata.userId !== userId) {
            throw new functions.https.HttpsError('permission-denied', 'Backup belongs to another user');
        }
        const conversationId = backupData.conversation.conversationId;
        console.log(`Restoring conversation ${conversationId} for user ${userId} (${backupData.messages.length} messages)`);
        return {
            success: true,
            conversationId,
            messageCount: backupData.messages.length,
            backupDate: backupData.metadata.backupDate,
            preview: backupData.messages.slice(0, 5), // First 5 messages as preview
        };
    }
    catch (error) {
        console.error('Error restoring conversation:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * List all backups for a user
 * HTTP Callable Function
 */
exports.listBackups = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
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
        const backups = backupsSnapshot.docs.map((doc) => {
            var _a, _b;
            return (Object.assign(Object.assign({ backupId: doc.id }, doc.data()), { backupDate: (_a = doc.data().backupDate) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), createdAt: (_b = doc.data().createdAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString() }));
        });
        return {
            success: true,
            backups,
            count: backups.length,
        };
    }
    catch (error) {
        console.error('Error listing backups:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Delete a backup from Cloud Storage
 * HTTP Callable Function
 */
exports.deleteBackup = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
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
            throw new functions.https.HttpsError('permission-denied', 'Cannot delete backup belonging to another user');
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
    }
    catch (error) {
        console.error('Error deleting backup:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Scheduled function to auto-backup active conversations
 * Runs weekly
 */
exports.autoBackupConversations = functions.pubsub
    .schedule('every sunday 02:00')
    .timeZone('UTC')
    .onRun(async (context) => {
    var _a, _b;
    console.log('Starting automatic conversation backups...');
    try {
        // Find conversations with recent activity (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const activeConversationsSnapshot = await firestore
            .collection('conversations')
            .where('lastMessageAt', '>=', thirtyDaysAgo)
            .get();
        console.log(`Found ${activeConversationsSnapshot.size} active conversations to backup`);
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
                const messages = messagesSnapshot.docs.map((doc) => {
                    var _a, _b, _c;
                    return (Object.assign(Object.assign({ messageId: doc.id }, doc.data()), { sentAt: (_a = doc.data().sentAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), readAt: (_b = doc.data().readAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString(), deliveredAt: (_c = doc.data().deliveredAt) === null || _c === void 0 ? void 0 : _c.toDate().toISOString() }));
                });
                // Create backup
                const backupData = {
                    conversation: Object.assign(Object.assign({ conversationId }, conversation), { createdAt: (_a = conversation.createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), lastMessageAt: (_b = conversation.lastMessageAt) === null || _b === void 0 ? void 0 : _b.toDate().toISOString() }),
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
            }
            catch (error) {
                console.error(`Error backing up conversation ${conversationDoc.id}:`, error);
                failed++;
            }
        }
        console.log(`Auto-backup complete: ${backedUp} successful, ${failed} failed`);
        return {
            success: true,
            backedUp,
            failed,
        };
    }
    catch (error) {
        console.error('Error in auto-backup:', error);
        throw error;
    }
});
//# sourceMappingURL=conversationBackup.js.map