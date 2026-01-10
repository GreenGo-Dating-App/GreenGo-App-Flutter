"use strict";
/**
 * Security Audit Cloud Functions
 * Run comprehensive security audits and generate reports
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
exports.cleanupOldAuditReports = exports.listSecurityAuditReports = exports.getSecurityAuditReport = exports.scheduledSecurityAudit = exports.runSecurityAudit = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const security_test_suite_1 = require("../../../security_audit/security_test_suite");
const firestore = admin.firestore();
const storage = admin.storage();
/**
 * Run Security Audit
 * Comprehensive security testing with 500+ tests
 */
exports.runSecurityAudit = functions
    .runWith({
    timeoutSeconds: 540, // 9 minutes
    memory: '2GB',
})
    .https.onCall(async (data, context) => {
    // Verify admin access
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const adminDoc = await firestore.collection('admin_users').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can run security audits');
    }
    const adminData = adminDoc.data();
    if (!adminData.permissions.includes('run_security_audit')) {
        throw new functions.https.HttpsError('permission-denied', 'Insufficient permissions to run security audit');
    }
    try {
        console.log('Starting security audit...');
        // Initialize audit suite
        const auditSuite = new security_test_suite_1.SecurityAuditSuite();
        console.log(`Initialized ${auditSuite.getTestCount()} security tests`);
        // Run audit
        const report = await auditSuite.runAudit();
        // Save report to Firestore
        const reportRef = firestore.collection('security_audit_reports').doc();
        await reportRef.set(Object.assign({ reportId: reportRef.id, timestamp: admin.firestore.FieldValue.serverTimestamp(), runBy: context.auth.uid }, report));
        // Generate PDF report
        const pdfUrl = await generatePDFReport(report, reportRef.id);
        // Send notification to admins if critical issues found
        if (report.criticalIssues > 0) {
            await notifyAdminsOfCriticalIssues(report);
        }
        console.log('Security audit completed successfully');
        return {
            success: true,
            reportId: reportRef.id,
            pdfUrl,
            summary: {
                totalTests: report.totalTests,
                passedTests: report.passedTests,
                failedTests: report.failedTests,
                criticalIssues: report.criticalIssues,
                highIssues: report.highIssues,
                mediumIssues: report.mediumIssues,
                lowIssues: report.lowIssues,
            },
        };
    }
    catch (error) {
        console.error('Error running security audit:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Schedule Weekly Security Audit
 * Run audit every Monday at 2 AM
 */
exports.scheduledSecurityAudit = functions.pubsub
    .schedule('0 2 * * 1') // Every Monday at 2 AM
    .timeZone('America/New_York')
    .onRun(async (context) => {
    try {
        console.log('Running scheduled security audit...');
        const auditSuite = new security_test_suite_1.SecurityAuditSuite();
        const report = await auditSuite.runAudit();
        // Save report
        const reportRef = firestore.collection('security_audit_reports').doc();
        await reportRef.set(Object.assign({ reportId: reportRef.id, timestamp: admin.firestore.FieldValue.serverTimestamp(), runBy: 'system', type: 'scheduled' }, report));
        // Generate PDF
        await generatePDFReport(report, reportRef.id);
        // Notify admins of results
        await notifyAdminsOfAuditResults(report, reportRef.id);
        console.log(`Scheduled security audit completed: ${reportRef.id}`);
    }
    catch (error) {
        console.error('Error in scheduled security audit:', error);
    }
});
/**
 * Get Security Audit Report
 */
exports.getSecurityAuditReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { reportId } = data;
    try {
        // Verify admin access
        const adminDoc = await firestore.collection('admin_users').doc(context.auth.uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can view security audit reports');
        }
        const reportDoc = await firestore
            .collection('security_audit_reports')
            .doc(reportId)
            .get();
        if (!reportDoc.exists) {
            throw new Error('Report not found');
        }
        return {
            success: true,
            report: reportDoc.data(),
        };
    }
    catch (error) {
        console.error('Error getting security audit report:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * List Security Audit Reports
 */
exports.listSecurityAuditReports = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    try {
        // Verify admin access
        const adminDoc = await firestore.collection('admin_users').doc(context.auth.uid).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can view security audit reports');
        }
        const { limit = 10 } = data;
        const reportsSnapshot = await firestore
            .collection('security_audit_reports')
            .orderBy('timestamp', 'desc')
            .limit(limit)
            .get();
        const reports = reportsSnapshot.docs.map(doc => (Object.assign({ reportId: doc.id }, doc.data())));
        return {
            success: true,
            reports,
        };
    }
    catch (error) {
        console.error('Error listing security audit reports:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Generate PDF Report
 */
async function generatePDFReport(report, reportId) {
    try {
        // In production, use a PDF generation library like PDFKit or Puppeteer
        // For now, generate a simple text report and save as JSON
        const reportContent = {
            title: 'GreenGo Security Audit Report',
            reportId,
            timestamp: report.timestamp,
            summary: {
                totalTests: report.totalTests,
                passedTests: report.passedTests,
                failedTests: report.failedTests,
                passRate: ((report.passedTests / report.totalTests) * 100).toFixed(1) + '%',
            },
            issuesBySeverity: {
                critical: report.criticalIssues,
                high: report.highIssues,
                medium: report.mediumIssues,
                low: report.lowIssues,
            },
            categoriesBreakdown: report.categories,
            failedTests: report.failedTests,
        };
        // Save to Cloud Storage
        const bucket = storage.bucket();
        const fileName = `security_audit_reports/${reportId}.json`;
        const file = bucket.file(fileName);
        await file.save(JSON.stringify(reportContent, null, 2), {
            contentType: 'application/json',
            metadata: {
                reportId,
                timestamp: new Date().toISOString(),
            },
        });
        // Make file accessible to admins only (do not make public)
        const [url] = await file.getSignedUrl({
            action: 'read',
            expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
        });
        return url;
    }
    catch (error) {
        console.error('Error generating PDF report:', error);
        return '';
    }
}
/**
 * Notify Admins of Critical Issues
 */
async function notifyAdminsOfCriticalIssues(report) {
    try {
        const adminsSnapshot = await firestore
            .collection('admin_users')
            .where('role', 'in', ['super_admin', 'admin'])
            .get();
        const notifications = adminsSnapshot.docs.map(async (adminDoc) => {
            const adminData = adminDoc.data();
            const userId = adminDoc.id;
            // Create in-app notification
            await firestore.collection('notifications').add({
                userId,
                type: 'security_alert',
                title: '🚨 Critical Security Issues Detected',
                message: `Security audit found ${report.criticalIssues} critical issues and ${report.highIssues} high-severity issues. Immediate action required!`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                priority: 'critical',
                data: {
                    reportId: report.reportId,
                    criticalIssues: report.criticalIssues,
                    highIssues: report.highIssues,
                },
            });
            // Send push notification if FCM token exists
            if (adminData.fcmToken) {
                await admin.messaging().send({
                    token: adminData.fcmToken,
                    notification: {
                        title: '🚨 Critical Security Alert',
                        body: `${report.criticalIssues} critical security issues detected`,
                    },
                    data: {
                        type: 'security_alert',
                        reportId: report.reportId,
                    },
                    android: {
                        priority: 'high',
                        notification: {
                            sound: 'alert',
                            priority: 'max',
                        },
                    },
                });
            }
        });
        await Promise.all(notifications);
    }
    catch (error) {
        console.error('Error notifying admins:', error);
    }
}
/**
 * Notify Admins of Audit Results
 */
async function notifyAdminsOfAuditResults(report, reportId) {
    try {
        const adminsSnapshot = await firestore
            .collection('admin_users')
            .where('role', 'in', ['super_admin', 'admin'])
            .get();
        const passRate = ((report.passedTests / report.totalTests) * 100).toFixed(1);
        const severity = report.criticalIssues > 0 ? 'critical' : report.highIssues > 0 ? 'warning' : 'info';
        const notifications = adminsSnapshot.docs.map(async (adminDoc) => {
            const userId = adminDoc.id;
            await firestore.collection('notifications').add({
                userId,
                type: 'security_audit_complete',
                title: 'Weekly Security Audit Complete',
                message: `Audit passed ${passRate}% of tests. ${report.failedTests} issues found (${report.criticalIssues} critical, ${report.highIssues} high).`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                priority: severity,
                data: {
                    reportId,
                    passRate,
                    totalTests: report.totalTests,
                    failedTests: report.failedTests,
                },
            });
        });
        await Promise.all(notifications);
    }
    catch (error) {
        console.error('Error notifying admins:', error);
    }
}
/**
 * Delete Old Audit Reports
 * Keep only last 12 reports (3 months of weekly audits)
 */
exports.cleanupOldAuditReports = functions.pubsub
    .schedule('0 3 * * 1') // Every Monday at 3 AM (after audit)
    .onRun(async (context) => {
    try {
        const reportsSnapshot = await firestore
            .collection('security_audit_reports')
            .orderBy('timestamp', 'desc')
            .get();
        if (reportsSnapshot.size <= 12) {
            console.log('No old reports to delete');
            return;
        }
        // Delete reports beyond the last 12
        const reportsToDelete = reportsSnapshot.docs.slice(12);
        const batch = firestore.batch();
        for (const doc of reportsToDelete) {
            batch.delete(doc.ref);
            // Also delete the file from Cloud Storage
            const fileName = `security_audit_reports/${doc.id}.json`;
            try {
                await storage.bucket().file(fileName).delete();
            }
            catch (error) {
                console.error(`Error deleting file ${fileName}:`, error);
            }
        }
        await batch.commit();
        console.log(`Deleted ${reportsToDelete.length} old audit reports`);
    }
    catch (error) {
        console.error('Error cleaning up old audit reports:', error);
    }
});
//# sourceMappingURL=securityAudit.js.map