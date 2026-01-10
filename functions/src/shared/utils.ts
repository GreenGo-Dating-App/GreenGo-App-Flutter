/**
 * Shared utility functions for all microservices
 */

import * as admin from 'firebase-admin';
import { https } from 'firebase-functions/v2';
import { ApiResponse, ApiError } from './types';

// Initialize Firebase Admin (should only be done once)
if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const storage = admin.storage();
export const auth = admin.auth();
export const FieldValue = admin.firestore.FieldValue;

// ========== ERROR HANDLING ==========

export class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 400,
    public details?: any
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export function handleError(error: any): https.HttpsError {
  if (error instanceof AppError) {
    return new https.HttpsError(
      getHttpsErrorCode(error.statusCode) as any,
      error.message,
      { code: error.code, details: error.details }
    );
  }

  console.error('Unexpected error:', error);
  return new https.HttpsError(
    'internal',
    'An unexpected error occurred',
    { originalError: error.message }
  );
}

function getHttpsErrorCode(statusCode: number): string {
  const codeMap: Record<number, string> = {
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

export function createSuccessResponse<T>(data: T, message?: string): ApiResponse<T> {
  return {
    success: true,
    data,
    message,
  };
}

export function createErrorResponse(code: string, message: string, details?: any): ApiResponse {
  return {
    success: false,
    error: {
      code,
      message,
      details,
    },
  };
}

// ========== AUTHENTICATION ==========

export async function verifyAuth(context: https.CallableRequest['auth']): Promise<string> {
  if (!context || !context.uid) {
    throw new AppError('UNAUTHENTICATED', 'User must be authenticated', 401);
  }
  return context.uid;
}

export async function verifyAdminAuth(context: https.CallableRequest['auth']): Promise<string> {
  const uid = await verifyAuth(context);

  const userDoc = await db.collection('users').doc(uid).get();
  const userData = userDoc.data();

  if (!userData?.isAdmin) {
    throw new AppError('PERMISSION_DENIED', 'User must be an admin', 403);
  }

  return uid;
}

// ========== VALIDATION ==========

export function validateRequired(params: any, fields: string[]): void {
  for (const field of fields) {
    if (params[field] === undefined || params[field] === null) {
      throw new AppError(
        'MISSING_FIELD',
        `Required field '${field}' is missing`,
        400
      );
    }
  }
}

export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function validateURL(url: string): boolean {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
}

// ========== FIRESTORE HELPERS ==========

export async function getDocument<T>(collection: string, docId: string): Promise<T> {
  const doc = await db.collection(collection).doc(docId).get();

  if (!doc.exists) {
    throw new AppError('NOT_FOUND', `Document not found: ${collection}/${docId}`, 404);
  }

  return { id: doc.id, ...doc.data() } as T;
}

export async function updateDocument(
  collection: string,
  docId: string,
  data: any
): Promise<void> {
  await db.collection(collection).doc(docId).update({
    ...data,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function createDocument(
  collection: string,
  data: any,
  docId?: string
): Promise<string> {
  const docData = {
    ...data,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (docId) {
    await db.collection(collection).doc(docId).set(docData);
    return docId;
  }

  const docRef = await db.collection(collection).add(docData);
  return docRef.id;
}

export async function deleteDocument(collection: string, docId: string): Promise<void> {
  await db.collection(collection).doc(docId).delete();
}

export async function batchUpdate(updates: Array<{ collection: string; docId: string; data: any }>): Promise<void> {
  const batch = db.batch();

  for (const update of updates) {
    const docRef = db.collection(update.collection).doc(update.docId);
    batch.update(docRef, {
      ...update.data,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}

// ========== STORAGE HELPERS ==========

export async function uploadFile(
  bucket: string,
  filePath: string,
  buffer: Buffer,
  contentType: string
): Promise<string> {
  const file = storage.bucket(bucket).file(filePath);

  await file.save(buffer, {
    contentType,
    metadata: {
      cacheControl: 'public, max-age=31536000',
    },
  });

  await file.makePublic();

  return `https://storage.googleapis.com/${bucket}/${filePath}`;
}

export async function deleteFile(bucket: string, filePath: string): Promise<void> {
  await storage.bucket(bucket).file(filePath).delete();
}

export async function getSignedUrl(
  bucket: string,
  filePath: string,
  expiresIn: number = 3600
): Promise<string> {
  const [url] = await storage
    .bucket(bucket)
    .file(filePath)
    .getSignedUrl({
      action: 'read',
      expires: Date.now() + expiresIn * 1000,
    });

  return url;
}

// ========== DATE/TIME HELPERS ==========

export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

export function addMonths(date: Date, months: number): Date {
  const result = new Date(date);
  result.setMonth(result.getMonth() + months);
  return result;
}

export function formatDate(date: Date): string {
  return date.toISOString().split('T')[0];
}

export function isExpired(date: Date | admin.firestore.Timestamp): boolean {
  const expiryDate = date instanceof admin.firestore.Timestamp ? date.toDate() : date;
  return expiryDate < new Date();
}

// ========== PAGINATION HELPERS ==========

export function createPaginationParams(
  page: number = 1,
  pageSize: number = 20
): { limit: number; offset: number } {
  const limit = Math.min(Math.max(pageSize, 1), 100); // Max 100 items per page
  const offset = (Math.max(page, 1) - 1) * limit;
  return { limit, offset };
}

// ========== RETRY LOGIC ==========

export async function retry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  delayMs: number = 1000
): Promise<T> {
  let lastError: Error;

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, delayMs * (i + 1)));
      }
    }
  }

  throw lastError!;
}

// ========== LOGGING ==========

export function logInfo(message: string, data?: any): void {
  console.log(`[INFO] ${message}`, data || '');
}

export function logError(message: string, error?: any): void {
  console.error(`[ERROR] ${message}`, error || '');
}

export function logWarning(message: string, data?: any): void {
  console.warn(`[WARN] ${message}`, data || '');
}

// ========== RANDOM GENERATORS ==========

export function generateId(length: number = 20): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// ========== ARRAY HELPERS ==========

export function chunk<T>(array: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

export function unique<T>(array: T[]): T[] {
  return [...new Set(array)];
}

// ========== OBJECT HELPERS ==========

export function pick<T extends object, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  const result = {} as Pick<T, K>;
  for (const key of keys) {
    if (key in obj) {
      result[key] = obj[key];
    }
  }
  return result;
}

export function omit<T, K extends keyof T>(obj: T, keys: K[]): Omit<T, K> {
  const result = { ...obj };
  for (const key of keys) {
    delete result[key];
  }
  return result;
}
