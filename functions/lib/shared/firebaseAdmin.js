"use strict";
/**
 * Firebase Admin SDK initialization
 * This module ensures Firebase Admin is initialized before any services are used
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
exports.auth = exports.storage = exports.db = exports.getMessaging = exports.getAuth = exports.getStorage = exports.getFirestore = exports.admin = void 0;
const admin = __importStar(require("firebase-admin"));
exports.admin = admin;
// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
    admin.initializeApp();
}
// Lazy getters for Firebase services to avoid initialization order issues
const getFirestore = () => admin.firestore();
exports.getFirestore = getFirestore;
const getStorage = () => admin.storage();
exports.getStorage = getStorage;
const getAuth = () => admin.auth();
exports.getAuth = getAuth;
const getMessaging = () => admin.messaging();
exports.getMessaging = getMessaging;
// For backwards compatibility, also export the db and storage directly
// These are safe to use after this module is imported
exports.db = admin.firestore();
exports.storage = admin.storage();
exports.auth = admin.auth();
//# sourceMappingURL=firebaseAdmin.js.map