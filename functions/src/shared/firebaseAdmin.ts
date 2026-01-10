/**
 * Firebase Admin SDK initialization
 * This module ensures Firebase Admin is initialized before any services are used
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Export the initialized admin instance and commonly used services
export { admin };

// Lazy getters for Firebase services to avoid initialization order issues
export const getFirestore = () => admin.firestore();
export const getStorage = () => admin.storage();
export const getAuth = () => admin.auth();
export const getMessaging = () => admin.messaging();

// For backwards compatibility, also export the db and storage directly
// These are safe to use after this module is imported
export const db = admin.firestore();
export const storage = admin.storage();
export const auth = admin.auth();
