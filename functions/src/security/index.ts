/**
 * Security Service
 * 5 Cloud Functions for security audits and compliance monitoring
 */

import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { verifyAdminAuth, handleError, logInfo, logError, db, FieldValue } from '../shared/utils';
import * as admin from 'firebase-admin';

// Security check types
enum SecurityCheckType {
  USER_DATA_ACCESS = 'user_data_access',
  ADMIN_ACTIONS = 'admin_actions',
  AUTHENTICATION_FAILURES = 'authentication_failures',
  SUSPICIOUS_ACTIVITY = 'suspicious_activity',
  DATA_INTEGRITY = 'data_integrity',
  GDPR_COMPLIANCE = 'gdpr_compliance',
  PAYMENT_SECURITY = 'payment_security',
}

// Severity levels
enum SeverityLevel {
  INFO = 'info',
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

// Interfaces
interface RunSecurityAuditRequest {
  auditType?: SecurityCheckType;
  startDate?: string;
  endDate?: string;
}

interface GetSecurityAuditReportRequest {
  reportId: string;
}

interface ListSecurityAuditReportsRequest {
  limit?: number;
  startAfter?: string;
  severityFilter?: SeverityLevel;
}

interface AuditFinding {
  type: SecurityCheckType;
  severity: SeverityLevel;
  description: string;
  affectedUsers?: string[];
  affectedResources?: string[];
  timestamp: admin.firestore.Timestamp;
  metadata?: Record<string, any>;
}

// ========== 1. RUN SECURITY AUDIT (HTTP Callable - Admin Only) ==========

export const runSecurityAudit = onCall<RunSecurityAuditRequest>(
  {
    memory: '1GiB',
    timeoutSeconds: 540, // 9 minutes
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { auditType, startDate, endDate } = request.data;

      logInfo('Running security audit', { auditType, startDate, endDate });

      const findings: AuditFinding[] = [];
      const auditStartTime = Date.now();

      // Date range for audit
      const start = startDate ? new Date(startDate) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // Last 7 days
      const end = endDate ? new Date(endDate) : new Date();

      const startTimestamp = admin.firestore.Timestamp.fromDate(start);
      const endTimestamp = admin.firestore.Timestamp.fromDate(end);

      // Run different audit checks based on type
      const auditTypes = auditType ? [auditType] : Object.values(SecurityCheckType);

      for (const type of auditTypes) {
        switch (type) {
          case SecurityCheckType.USER_DATA_ACCESS:
            findings.push(...await auditUserDataAccess(startTimestamp, endTimestamp));
            break;

          case SecurityCheckType.ADMIN_ACTIONS:
            findings.push(...await auditAdminActions(startTimestamp, endTimestamp));
            break;

          case SecurityCheckType.AUTHENTICATION_FAILURES:
            findings.push(...await auditAuthenticationFailures(startTimestamp, endTimestamp));
            break;

          case SecurityCheckType.SUSPICIOUS_ACTIVITY:
            findings.push(...await auditSuspiciousActivity(startTimestamp, endTimestamp));
            break;

          case SecurityCheckType.DATA_INTEGRITY:
            findings.push(...await auditDataIntegrity(startTimestamp, endTimestamp));
            break;

          case SecurityCheckType.GDPR_COMPLIANCE:
            findings.push(...await auditGDPRCompliance(startTimestamp, endTimestamp));
            break;

          case SecurityCheckType.PAYMENT_SECURITY:
            findings.push(...await auditPaymentSecurity(startTimestamp, endTimestamp));
            break;
        }
      }

      // Calculate statistics
      const severityCounts = {
        info: findings.filter(f => f.severity === SeverityLevel.INFO).length,
        low: findings.filter(f => f.severity === SeverityLevel.LOW).length,
        medium: findings.filter(f => f.severity === SeverityLevel.MEDIUM).length,
        high: findings.filter(f => f.severity === SeverityLevel.HIGH).length,
        critical: findings.filter(f => f.severity === SeverityLevel.CRITICAL).length,
      };

      const auditDuration = Date.now() - auditStartTime;

      // Save audit report
      const reportRef = await db.collection('security_audits').add({
        auditType: auditType || 'full_audit',
        startDate: startTimestamp,
        endDate: endTimestamp,
        findings,
        totalFindings: findings.length,
        severityCounts,
        auditDuration,
        runBy: request.auth?.uid,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Send alerts for critical findings
      const criticalFindings = findings.filter(f => f.severity === SeverityLevel.CRITICAL);
      if (criticalFindings.length > 0) {
        await sendSecurityAlert(criticalFindings, reportRef.id);
      }

      logInfo(`Security audit completed: ${findings.length} findings in ${auditDuration}ms`);

      return {
        success: true,
        reportId: reportRef.id,
        totalFindings: findings.length,
        severityCounts,
        criticalFindings: criticalFindings.length,
        auditDuration,
      };
    } catch (error) {
      logError('Error running security audit:', error);
      throw handleError(error);
    }
  }
);

// ========== 2. SCHEDULED SECURITY AUDIT (Scheduled - Weekly) ==========

export const scheduledSecurityAudit = onSchedule(
  {
    schedule: '0 3 * * 1', // Every Monday at 3 AM UTC
    timeZone: 'UTC',
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Running scheduled security audit');

    try {
      const findings: AuditFinding[] = [];
      const auditStartTime = Date.now();

      // Last 7 days
      const end = new Date();
      const start = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      const startTimestamp = admin.firestore.Timestamp.fromDate(start);
      const endTimestamp = admin.firestore.Timestamp.fromDate(end);

      // Run all audit checks
      findings.push(...await auditUserDataAccess(startTimestamp, endTimestamp));
      findings.push(...await auditAdminActions(startTimestamp, endTimestamp));
      findings.push(...await auditAuthenticationFailures(startTimestamp, endTimestamp));
      findings.push(...await auditSuspiciousActivity(startTimestamp, endTimestamp));
      findings.push(...await auditDataIntegrity(startTimestamp, endTimestamp));
      findings.push(...await auditGDPRCompliance(startTimestamp, endTimestamp));
      findings.push(...await auditPaymentSecurity(startTimestamp, endTimestamp));

      // Calculate statistics
      const severityCounts = {
        info: findings.filter(f => f.severity === SeverityLevel.INFO).length,
        low: findings.filter(f => f.severity === SeverityLevel.LOW).length,
        medium: findings.filter(f => f.severity === SeverityLevel.MEDIUM).length,
        high: findings.filter(f => f.severity === SeverityLevel.HIGH).length,
        critical: findings.filter(f => f.severity === SeverityLevel.CRITICAL).length,
      };

      const auditDuration = Date.now() - auditStartTime;

      // Save audit report
      const reportRef = await db.collection('security_audits').add({
        auditType: 'scheduled_full_audit',
        startDate: startTimestamp,
        endDate: endTimestamp,
        findings,
        totalFindings: findings.length,
        severityCounts,
        auditDuration,
        runBy: 'system',
        createdAt: FieldValue.serverTimestamp(),
      });

      // Send alerts for critical/high findings
      const alertFindings = findings.filter(
        f => f.severity === SeverityLevel.CRITICAL || f.severity === SeverityLevel.HIGH
      );

      if (alertFindings.length > 0) {
        await sendSecurityAlert(alertFindings, reportRef.id);
      }

      logInfo(`Scheduled security audit completed: ${findings.length} findings, ${alertFindings.length} alerts`);
    } catch (error) {
      logError('Error in scheduled security audit:', error);
      throw error;
    }
  }
);

// ========== 3. GET SECURITY AUDIT REPORT (HTTP Callable - Admin Only) ==========

export const getSecurityAuditReport = onCall<GetSecurityAuditReportRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { reportId } = request.data;

      logInfo(`Fetching security audit report: ${reportId}`);

      const reportDoc = await db.collection('security_audits').doc(reportId).get();

      if (!reportDoc.exists) {
        throw new Error('Audit report not found');
      }

      const reportData = reportDoc.data()!;

      return {
        success: true,
        report: {
          id: reportDoc.id,
          ...reportData,
        },
      };
    } catch (error) {
      logError('Error fetching security audit report:', error);
      throw handleError(error);
    }
  }
);

// ========== 4. LIST SECURITY AUDIT REPORTS (HTTP Callable - Admin Only) ==========

export const listSecurityAuditReports = onCall<ListSecurityAuditReportsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { limit = 50, startAfter, severityFilter } = request.data;

      logInfo('Listing security audit reports', { limit, startAfter, severityFilter });

      let query = db.collection('security_audits').orderBy('createdAt', 'desc').limit(limit);

      if (startAfter) {
        const startDoc = await db.collection('security_audits').doc(startAfter).get();
        if (startDoc.exists) {
          query = query.startAfter(startDoc);
        }
      }

      const snapshot = await query.get();

      let reports = snapshot.docs.map(doc => ({
        id: doc.id,
        ...(doc.data() as any),
      }));

      // Filter by severity if specified
      if (severityFilter) {
        reports = reports.filter((report: any) => {
          const severityCounts = report.severityCounts;
          return severityCounts && severityCounts[severityFilter] > 0;
        });
      }

      return {
        success: true,
        reports,
        hasMore: snapshot.size === limit,
        lastId: snapshot.docs[snapshot.docs.length - 1]?.id,
      };
    } catch (error) {
      logError('Error listing security audit reports:', error);
      throw handleError(error);
    }
  }
);

// ========== 5. CLEANUP OLD AUDIT REPORTS (Scheduled - Monthly) ==========

export const cleanupOldAuditReports = onSchedule(
  {
    schedule: '0 4 1 * *', // First day of month at 4 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Cleaning up old security audit reports');

    try {
      // Delete reports older than 1 year
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(oneYearAgo);

      const snapshot = await db
        .collection('security_audits')
        .where('createdAt', '<', cutoffTimestamp)
        .get();

      if (snapshot.empty) {
        logInfo('No old audit reports to cleanup');
        return;
      }

      // Delete in batches of 500
      const batchSize = 500;
      let deletedCount = 0;

      for (let i = 0; i < snapshot.docs.length; i += batchSize) {
        const batch = db.batch();
        const batchDocs = snapshot.docs.slice(i, i + batchSize);

        for (const doc of batchDocs) {
          batch.delete(doc.ref);
        }

        await batch.commit();
        deletedCount += batchDocs.length;
      }

      logInfo(`Cleaned up ${deletedCount} old security audit reports`);
    } catch (error) {
      logError('Error cleaning up old audit reports:', error);
      throw error;
    }
  }
);

// ========== HELPER FUNCTIONS ==========

async function auditUserDataAccess(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // Check for excessive data exports (more than 10 per user in time period)
    const exportsSnapshot = await db
      .collection('pdf_exports')
      .where('createdAt', '>=', startTimestamp)
      .where('createdAt', '<=', endTimestamp)
      .get();

    const exportsByUser: Record<string, number> = {};
    exportsSnapshot.docs.forEach(doc => {
      const userId = doc.data().userId;
      exportsByUser[userId] = (exportsByUser[userId] || 0) + 1;
    });

    for (const [userId, count] of Object.entries(exportsByUser)) {
      if (count > 10) {
        findings.push({
          type: SecurityCheckType.USER_DATA_ACCESS,
          severity: SeverityLevel.MEDIUM,
          description: `User ${userId} exported data ${count} times`,
          affectedUsers: [userId],
          timestamp: admin.firestore.Timestamp.now(),
          metadata: { exportCount: count },
        });
      }
    }
  } catch (error) {
    logError('Error auditing user data access:', error);
  }

  return findings;
}

async function auditAdminActions(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // Check for admin role changes
    const usersSnapshot = await db.collection('users').where('role', '==', 'admin').get();

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const roleChangedAt = userData.roleChangedAt;

      if (roleChangedAt && roleChangedAt >= startTimestamp && roleChangedAt <= endTimestamp) {
        findings.push({
          type: SecurityCheckType.ADMIN_ACTIONS,
          severity: SeverityLevel.HIGH,
          description: `User ${userDoc.id} was granted admin role`,
          affectedUsers: [userDoc.id],
          timestamp: roleChangedAt,
          metadata: { previousRole: userData.previousRole },
        });
      }
    }
  } catch (error) {
    logError('Error auditing admin actions:', error);
  }

  return findings;
}

async function auditAuthenticationFailures(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // This would check authentication logs if available
    // For now, we'll check for suspicious account lockouts
    const lockoutsSnapshot = await db
      .collection('users')
      .where('accountLocked', '==', true)
      .where('lockedAt', '>=', startTimestamp)
      .where('lockedAt', '<=', endTimestamp)
      .get();

    if (lockoutsSnapshot.size > 100) {
      findings.push({
        type: SecurityCheckType.AUTHENTICATION_FAILURES,
        severity: SeverityLevel.HIGH,
        description: `Unusual number of account lockouts: ${lockoutsSnapshot.size}`,
        timestamp: admin.firestore.Timestamp.now(),
        metadata: { lockoutCount: lockoutsSnapshot.size },
      });
    }
  } catch (error) {
    logError('Error auditing authentication failures:', error);
  }

  return findings;
}

async function auditSuspiciousActivity(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // Check for users with excessive reports
    const reportsSnapshot = await db
      .collection('reports')
      .where('createdAt', '>=', startTimestamp)
      .where('createdAt', '<=', endTimestamp)
      .get();

    const reportsByReportedUser: Record<string, number> = {};
    reportsSnapshot.docs.forEach(doc => {
      const reportedUserId = doc.data().reportedUserId;
      reportsByReportedUser[reportedUserId] = (reportsByReportedUser[reportedUserId] || 0) + 1;
    });

    for (const [userId, count] of Object.entries(reportsByReportedUser)) {
      if (count >= 10) {
        findings.push({
          type: SecurityCheckType.SUSPICIOUS_ACTIVITY,
          severity: count >= 20 ? SeverityLevel.CRITICAL : SeverityLevel.HIGH,
          description: `User ${userId} has ${count} reports`,
          affectedUsers: [userId],
          timestamp: admin.firestore.Timestamp.now(),
          metadata: { reportCount: count },
        });
      }
    }
  } catch (error) {
    logError('Error auditing suspicious activity:', error);
  }

  return findings;
}

async function auditDataIntegrity(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // Check for orphaned data
    // Example: Messages without valid conversations
    const messagesSnapshot = await db
      .collection('messages')
      .where('createdAt', '>=', startTimestamp)
      .where('createdAt', '<=', endTimestamp)
      .limit(1000)
      .get();

    const orphanedMessages: string[] = [];

    for (const messageDoc of messagesSnapshot.docs) {
      const messageData = messageDoc.data();
      const conversationId = messageData.conversationId;

      if (conversationId) {
        const conversationDoc = await db.collection('conversations').doc(conversationId).get();
        if (!conversationDoc.exists) {
          orphanedMessages.push(messageDoc.id);
        }
      }
    }

    if (orphanedMessages.length > 0) {
      findings.push({
        type: SecurityCheckType.DATA_INTEGRITY,
        severity: SeverityLevel.MEDIUM,
        description: `Found ${orphanedMessages.length} orphaned messages`,
        affectedResources: orphanedMessages,
        timestamp: admin.firestore.Timestamp.now(),
      });
    }
  } catch (error) {
    logError('Error auditing data integrity:', error);
  }

  return findings;
}

async function auditGDPRCompliance(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // Check for users who requested data deletion but still have data
    const deletionRequestsSnapshot = await db
      .collection('gdpr_requests')
      .where('type', '==', 'deletion')
      .where('status', '==', 'completed')
      .where('completedAt', '>=', startTimestamp)
      .where('completedAt', '<=', endTimestamp)
      .get();

    for (const requestDoc of deletionRequestsSnapshot.docs) {
      const requestData = requestDoc.data();
      const userId = requestData.userId;

      // Check if user still exists
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        findings.push({
          type: SecurityCheckType.GDPR_COMPLIANCE,
          severity: SeverityLevel.CRITICAL,
          description: `User ${userId} requested deletion but account still exists`,
          affectedUsers: [userId],
          timestamp: admin.firestore.Timestamp.now(),
          metadata: { requestId: requestDoc.id },
        });
      }
    }
  } catch (error) {
    logError('Error auditing GDPR compliance:', error);
  }

  return findings;
}

async function auditPaymentSecurity(
  startTimestamp: admin.firestore.Timestamp,
  endTimestamp: admin.firestore.Timestamp
): Promise<AuditFinding[]> {
  const findings: AuditFinding[] = [];

  try {
    // Check for unusual refund patterns
    const subscriptionsSnapshot = await db
      .collection('subscriptions')
      .where('refundedAt', '>=', startTimestamp)
      .where('refundedAt', '<=', endTimestamp)
      .get();

    const refundsByUser: Record<string, number> = {};
    subscriptionsSnapshot.docs.forEach(doc => {
      const userId = doc.data().userId;
      refundsByUser[userId] = (refundsByUser[userId] || 0) + 1;
    });

    for (const [userId, count] of Object.entries(refundsByUser)) {
      if (count >= 3) {
        findings.push({
          type: SecurityCheckType.PAYMENT_SECURITY,
          severity: SeverityLevel.HIGH,
          description: `User ${userId} has ${count} refunds - possible fraud`,
          affectedUsers: [userId],
          timestamp: admin.firestore.Timestamp.now(),
          metadata: { refundCount: count },
        });
      }
    }
  } catch (error) {
    logError('Error auditing payment security:', error);
  }

  return findings;
}

async function sendSecurityAlert(findings: AuditFinding[], reportId: string): Promise<void> {
  try {
    // Get all admin users
    const adminsSnapshot = await db.collection('users').where('role', '==', 'admin').get();

    const criticalCount = findings.filter(f => f.severity === SeverityLevel.CRITICAL).length;
    const highCount = findings.filter(f => f.severity === SeverityLevel.HIGH).length;

    for (const adminDoc of adminsSnapshot.docs) {
      await db.collection('notifications').add({
        userId: adminDoc.id,
        type: 'security_alert',
        title: 'Security Audit Alert',
        body: `Security audit found ${criticalCount} critical and ${highCount} high severity issues`,
        data: {
          reportId,
          criticalCount,
          highCount,
          findings: findings.slice(0, 5), // First 5 findings
        },
        read: false,
        sent: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    logInfo(`Security alerts sent to ${adminsSnapshot.size} admins`);
  } catch (error) {
    logError('Error sending security alerts:', error);
  }
}
