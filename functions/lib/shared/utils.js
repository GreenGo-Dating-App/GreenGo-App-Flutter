"use strict";
/**
 * Shared utility functions for all microservices
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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.omit = exports.pick = exports.unique = exports.chunk = exports.generateId = exports.logWarning = exports.logError = exports.logInfo = exports.retry = exports.createPaginationParams = exports.isExpired = exports.formatDate = exports.addMonths = exports.addDays = exports.getSignedUrl = exports.deleteFile = exports.uploadFile = exports.batchUpdate = exports.deleteDocument = exports.createDocument = exports.updateDocument = exports.getDocument = exports.validateURL = exports.validateEmail = exports.validateRequired = exports.verifyAdminAuth = exports.verifyAuth = exports.createErrorResponse = exports.createSuccessResponse = exports.handleError = exports.AppError = exports.FieldValue = exports.auth = exports.storage = exports.db = void 0;
const admin = __importStar(require("firebase-admin"));
const v2_1 = require("firebase-functions/v2");
// Initialize Firebase Admin (should only be done once)
if (!admin.apps.length) {
    admin.initializeApp();
}
exports.db = admin.firestore();
exports.storage = admin.storage();
exports.auth = admin.auth();
exports.FieldValue = admin.firestore.FieldValue;
// ========== ERROR HANDLING ==========
class AppError extends Error {
    constructor(code, message, statusCode = 400, details) {
        super(message);
        this.code = code;
        this.statusCode = statusCode;
        this.details = details;
        this.name = 'AppError';
    }
}
exports.AppError = AppError;
function handleError(error) {
    if (error instanceof AppError) {
        return new v2_1.https.HttpsError(getHttpsErrorCode(error.statusCode), error.message, { code: error.code, details: error.details });
    }
    console.error('Unexpected error:', error);
    return new v2_1.https.HttpsError('internal', 'An unexpected error occurred', { originalError: error.message });
}
exports.handleError = handleError;
function getHttpsErrorCode(statusCode) {
    const codeMap = {
        400: 'invalid-argument',
        401: 'unauthenticated',
        403: 'permission-denied',
        404: 'not-found',
        409: 'already-exists',
        429: 'resource-exhausted',
        500: 'internal',
        503: 'unavailable',
    };
    return codeMap[statusCode] || 'unknown';
}
function createSuccessResponse(data, message) {
    return {
        success: true,
        data,
        message,
    };
}
exports.createSuccessResponse = createSuccessResponse;
function createErrorResponse(code, message, details) {
    return {
        success: false,
        error: {
            code,
            message,
            details,
        },
    };
}
exports.createErrorResponse = createErrorResponse;
// ========== AUTHENTICATION ==========
async function verifyAuth(context) {
    if (!context || !context.uid) {
        throw new AppError('UNAUTHENTICATED', 'User must be authenticated', 401);
    }
    return context.uid;
}
exports.verifyAuth = verifyAuth;
async function verifyAdminAuth(context) {
    const uid = await verifyAuth(context);
    const userDoc = await exports.db.collection('users').doc(uid).get();
    const userData = userDoc.data();
    if (!(userData === null || userData === void 0 ? void 0 : userData.isAdmin)) {
        throw new AppError('PERMISSION_DENIED', 'User must be an admin', 403);
    }
    return uid;
}
exports.verifyAdminAuth = verifyAdminAuth;
// ========== VALIDATION ==========
function validateRequired(params, fields) {
    for (const field of fields) {
        if (params[field] === undefined || params[field] === null) {
            throw new AppError('MISSING_FIELD', `Required field '${field}' is missing`, 400);
        }
    }
}
exports.validateRequired = validateRequired;
function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}
exports.validateEmail = validateEmail;
function validateURL(url) {
    try {
        new URL(url);
        return true;
    }
    catch (_a) {
        return false;
    }
}
exports.validateURL = validateURL;
// ========== FIRESTORE HELPERS ==========
async function getDocument(collection, docId) {
    const doc = await exports.db.collection(collection).doc(docId).get();
    if (!doc.exists) {
        throw new AppError('NOT_FOUND', `Document not found: ${collection}/${docId}`, 404);
    }
    return Object.assign({ id: doc.id }, doc.data());
}
exports.getDocument = getDocument;
async function updateDocument(collection, docId, data) {
    await exports.db.collection(collection).doc(docId).update(Object.assign(Object.assign({}, data), { updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
}
exports.updateDocument = updateDocument;
async function createDocument(collection, data, docId) {
    const docData = Object.assign(Object.assign({}, data), { createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    if (docId) {
        await exports.db.collection(collection).doc(docId).set(docData);
        return docId;
    }
    const docRef = await exports.db.collection(collection).add(docData);
    return docRef.id;
}
exports.createDocument = createDocument;
async function deleteDocument(collection, docId) {
    await exports.db.collection(collection).doc(docId).delete();
}
exports.deleteDocument = deleteDocument;
async function batchUpdate(updates) {
    const batch = exports.db.batch();
    for (const update of updates) {
        const docRef = exports.db.collection(update.collection).doc(update.docId);
        batch.update(docRef, Object.assign(Object.assign({}, update.data), { updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
    }
    await batch.commit();
}
exports.batchUpdate = batchUpdate;
// ========== STORAGE HELPERS ==========
async function uploadFile(bucket, filePath, buffer, contentType) {
    const file = exports.storage.bucket(bucket).file(filePath);
    await file.save(buffer, {
        contentType,
        metadata: {
            cacheControl: 'public, max-age=31536000',
        },
    });
    await file.makePublic();
    return `https://storage.googleapis.com/${bucket}/${filePath}`;
}
exports.uploadFile = uploadFile;
async function deleteFile(bucket, filePath) {
    await exports.storage.bucket(bucket).file(filePath).delete();
}
exports.deleteFile = deleteFile;
async function getSignedUrl(bucket, filePath, expiresIn = 3600) {
    const [url] = await exports.storage
        .bucket(bucket)
        .file(filePath)
        .getSignedUrl({
        action: 'read',
        expires: Date.now() + expiresIn * 1000,
    });
    return url;
}
exports.getSignedUrl = getSignedUrl;
// ========== DATE/TIME HELPERS ==========
function addDays(date, days) {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
}
exports.addDays = addDays;
function addMonths(date, months) {
    const result = new Date(date);
    result.setMonth(result.getMonth() + months);
    return result;
}
exports.addMonths = addMonths;
function formatDate(date) {
    return date.toISOString().split('T')[0];
}
exports.formatDate = formatDate;
function isExpired(date) {
    const expiryDate = date instanceof admin.firestore.Timestamp ? date.toDate() : date;
    return expiryDate < new Date();
}
exports.isExpired = isExpired;
// ========== PAGINATION HELPERS ==========
function createPaginationParams(page = 1, pageSize = 20) {
    const limit = Math.min(Math.max(pageSize, 1), 100); // Max 100 items per page
    const offset = (Math.max(page, 1) - 1) * limit;
    return { limit, offset };
}
exports.createPaginationParams = createPaginationParams;
// ========== RETRY LOGIC ==========
async function retry(fn, maxRetries = 3, delayMs = 1000) {
    let lastError;
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fn();
        }
        catch (error) {
            lastError = error;
            if (i < maxRetries - 1) {
                await new Promise(resolve => setTimeout(resolve, delayMs * (i + 1)));
            }
        }
    }
    throw lastError;
}
exports.retry = retry;
// ========== LOGGING ==========
function logInfo(message, data) {
    console.log(`[INFO] ${message}`, data || '');
}
exports.logInfo = logInfo;
function logError(message, error) {
    console.error(`[ERROR] ${message}`, error || '');
}
exports.logError = logError;
function logWarning(message, data) {
    console.warn(`[WARN] ${message}`, data || '');
}
exports.logWarning = logWarning;
// ========== RANDOM GENERATORS ==========
function generateId(length = 20) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}
exports.generateId = generateId;
// ========== ARRAY HELPERS ==========
function chunk(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
        chunks.push(array.slice(i, i + size));
    }
    return chunks;
}
exports.chunk = chunk;
function unique(array) {
    return [...new Set(array)];
}
exports.unique = unique;
// ========== OBJECT HELPERS ==========
function pick(obj, keys) {
    const result = {};
    for (const key of keys) {
        if (key in obj) {
            result[key] = obj[key];
        }
    }
    return result;
}
exports.pick = pick;
function omit(obj, keys) {
    const result = Object.assign({}, obj);
    for (const key of keys) {
        delete result[key];
    }
    return result;
}
exports.omit = omit;
//# sourceMappingURL=utils.js.map