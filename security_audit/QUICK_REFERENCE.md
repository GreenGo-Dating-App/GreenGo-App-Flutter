# Security Audit Quick Reference

## Running the Audit

### Via Cloud Function
```typescript
const result = await firebase.functions().httpsCallable('runSecurityAudit')();
console.log(result.data.summary);
```

### Expected Runtime
⏱️ **8-10 minutes** for complete 500+ test suite

---

## Test Categories (500+ Tests)

| # | Category | Tests | Focus Area |
|---|----------|-------|------------|
| 1 | Authentication | 100 | Passwords, MFA, Sessions, OAuth |
| 2 | Data Protection | 100 | Encryption, PII, GDPR, Retention |
| 3 | API Security | 80 | Rate Limiting, Input Validation, Auth |
| 4 | Firebase Security | 80 | Firestore Rules, Storage Rules |
| 5 | Payment Security | 40 | PCI DSS, Receipt Validation |
| 6 | Content Moderation | 40 | Image/Text Moderation, Safety |
| 7 | Video Call Security | 30 | WebRTC, Call Privacy, Recording |
| 8 | Infrastructure | 30 | Cloud Functions, Storage, Network |
| 9 | OWASP Top 10 | 50 | Access Control, Injection, XSS |
| 10 | Compliance | 50 | GDPR, CCPA, COPPA, App Stores |

---

## Severity Levels

| Severity | SLA | Examples |
|----------|-----|----------|
| 🔴 **Critical** | Fix within 24 hours | No MFA for admins, unencrypted PII, card data stored |
| 🟠 **High** | Fix within 7 days | XSS vulnerabilities, no rate limiting, precise location storage |
| 🟡 **Medium** | Fix within 30 days | No password history, missing session tracking |
| 🟢 **Low** | Fix in next release | Weak password complexity, missing file size limits |

---

## Common Critical Issues & Fixes

### 1. Admin Accounts Without MFA
```typescript
// Force MFA on admin creation
if (!data.mfaEnabled) {
  throw new functions.https.HttpsError(
    'failed-precondition',
    'MFA required for admin accounts'
  );
}
```

### 2. Unencrypted Sensitive Data
```typescript
import * as crypto from 'crypto';

function encryptField(data: string, key: Buffer): string {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return JSON.stringify({
    iv: iv.toString('hex'),
    encrypted,
    authTag: cipher.getAuthTag().toString('hex'),
  });
}
```

### 3. XSS in User Inputs
```typescript
import * as DOMPurify from 'isomorphic-dompurify';

const sanitized = DOMPurify.sanitize(userInput, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong'],
  ALLOWED_ATTR: [],
});
```

### 4. No Rate Limiting
```typescript
// Use Firebase App Check + Cloud Armor
// Or implement custom rate limiting:
const attempts = await redis.incr(`login:${ip}`);
await redis.expire(`login:${ip}`, 900); // 15 minutes

if (attempts > 5) {
  throw new Error('Too many attempts');
}
```

---

## Report Structure

```json
{
  "totalTests": 500,
  "passedTests": 485,
  "failedTests": 15,
  "criticalIssues": 2,
  "highIssues": 5,
  "mediumIssues": 6,
  "lowIssues": 2,
  "categories": [...],
  "failedTests": [...]
}
```

---

## Automated Schedule

- **Weekly**: Every Monday at 2:00 AM EST
- **Retention**: Last 12 reports kept (3 months)
- **Notifications**: Sent to all admins if critical issues found

---

## Compliance Checks

### GDPR ✅
- Right to access
- Right to erasure
- Data portability
- Encryption requirements
- Breach notification

### CCPA ✅
- Do Not Sell
- Data disclosure
- Consumer rights

### PCI DSS ✅
- No card data storage
- TLS 1.2+ encryption
- Tokenization only

### COPPA ⚠️
- Age verification (13+)
- Parental consent

---

## Key Metrics

### Security Score
**Formula**: (Passed Tests / Total Tests) × 100

**Target**: >95%
**Warning**: <90%
**Critical**: <80%

### Risk Score
Each failed test has a risk score (0-10):
- **9.0-10.0**: Critical
- **7.0-8.9**: High
- **4.0-6.9**: Medium
- **0.0-3.9**: Low

---

## Emergency Contacts

**Critical Issues**: security@greengo.app
**Documentation**: https://docs.greengo.app/security
**Status Page**: https://status.greengo.app

---

## Remediation Tracking

1. Run audit → Identify issues
2. Create remediation tasks
3. Implement fixes
4. Re-run audit to verify
5. Document in compliance log

---

## Next Steps After Audit

### If Critical Issues Found:
1. ⚠️ Review all critical issues immediately
2. 🚨 Assign to senior engineers
3. 🔧 Implement fixes within 24 hours
4. ✅ Re-run audit to verify
5. 📝 Document in incident log

### If High Issues Found:
1. ⚙️ Review within 1 business day
2. 📋 Create JIRA tickets
3. 🔧 Fix within 7 days
4. ✅ Verify in next weekly audit

### If Only Medium/Low:
1. 📊 Review in weekly security meeting
2. 📅 Schedule for upcoming sprint
3. ✅ Track in backlog

---

## Report Access

### View Reports
```typescript
const reports = await firebase.functions()
  .httpsCallable('listSecurityAuditReports')({ limit: 10 });
```

### Download Report
```typescript
const report = await firebase.functions()
  .httpsCallable('getSecurityAuditReport')({ reportId: 'audit_xxx' });
```

---

**Last Updated**: January 15, 2025
**Version**: 1.0.0
