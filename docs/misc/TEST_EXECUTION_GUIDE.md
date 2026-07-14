# GreenGo App - Test Execution Guide

## Overview

This guide explains how to run the comprehensive test suite for the GreenGo dating application. The test suite validates all 300+ feature points, 109 Cloud Functions, and 500+ security checks.

---

## Quick Start

### Windows
```cmd
run_tests.bat
```

### macOS/Linux
```bash
chmod +x run_tests.sh
./run_tests.sh
```

### Manual Execution
```bash
node run_all_tests.js
```

---

## What Gets Tested

The comprehensive test suite runs **10 major test categories**:

### 1. Environment Checks ✅
- Node.js version (requires v18 or v20)
- npm availability
- Firebase CLI installation
- TypeScript compiler

### 2. TypeScript Compilation ✅
- Compiles all TypeScript files in `functions/src/`
- Validates syntax and types
- Checks JavaScript output generation
- Reports compilation errors

### 3. ESLint Code Quality ✅
- Runs ESLint on all source files
- Checks for code style violations
- Reports warnings and errors
- Validates coding standards

### 4. Unit Tests ✅
- Runs Jest unit tests (if available)
- Executes all `.test.ts` and `.spec.ts` files
- Reports test coverage
- Identifies failing tests

### 5. Function Export Validation ✅
- Verifies all 109 Cloud Functions are exported
- Checks `functions/src/index.ts` structure
- Validates function categories:
  - Media Processing (10 functions)
  - Messaging (7 functions)
  - Backup & Export (9 functions)
  - Subscriptions (4 functions)
  - Coins (6 functions)
  - Analytics (14 functions)
  - Gamification (8 functions)
  - Safety & Moderation (15 functions)
  - Admin Panel (37 functions)
  - User Segmentation (5 functions)
  - Notifications (4 functions)
  - Email Communication (5 functions)
  - Video Calling (27 functions)
  - Security Audit (5 functions)

### 6. File Structure Validation ✅
- Checks all required directories exist
- Validates TypeScript file count
- Verifies critical files:
  - `functions/package.json`
  - `functions/tsconfig.json`
  - `functions/src/index.ts`
  - `security_audit/security_test_suite.ts`
  - `VERIFICATION_REPORT.md`

### 7. Security Audit Validation ✅
- Validates 500+ security test definitions
- Checks all 10 security categories:
  - Authentication & Authorization (100 tests)
  - Data Protection & Privacy (100 tests)
  - API Security (80 tests)
  - Firebase Security Rules (80 tests)
  - Payment & Transaction Security (40 tests)
  - Content Moderation & Safety (40 tests)
  - Video Call Security (30 tests)
  - Infrastructure Security (30 tests)
  - OWASP Top 10 Vulnerabilities (50 tests)
  - Compliance & Regulations (50 tests)

### 8. Dependency Audit ✅
- Runs `npm audit` to check for vulnerabilities
- Reports critical, high, medium, and low severity issues
- Checks for outdated packages
- Recommends security updates

### 9. Firebase Configuration Check ✅
- Validates `firebase.json` exists
- Checks configuration sections:
  - Functions
  - Firestore
  - Hosting
  - Storage
- Verifies `.firebaserc` project configuration

### 10. Report Generation ✅
- Generates comprehensive Markdown report
- Creates JSON report for programmatic access
- Saves timestamped reports
- Updates latest report links

---

## Test Results

### Report Formats

After execution, you'll find two types of reports in the `test_reports/` directory:

#### 1. Timestamped Reports
```
test_reports/
├── test_report_2025-01-15T14-30-00-000Z.md
└── test_report_2025-01-15T14-30-00-000Z.json
```

#### 2. Latest Reports (always updated)
```
test_reports/
├── latest_test_report.md    ← Human-readable
└── latest_test_report.json  ← Machine-readable
```

### Markdown Report Contents

The Markdown report includes:

1. **Executive Summary**
   - Total tests run
   - Pass/fail counts
   - Pass rate percentage
   - Execution duration

2. **Category Breakdown**
   - Results for each of 10 test categories
   - Individual test results
   - Pass/fail status with details

3. **Errors** (if any)
   - Detailed error messages
   - Stack traces
   - Affected categories

4. **Warnings** (if any)
   - Non-critical issues
   - Code quality warnings
   - Deprecation notices

5. **Recommendations**
   - Next steps based on results
   - Required fixes
   - Deployment readiness

### JSON Report Structure

```json
{
  "startTime": "2025-01-15T14:30:00.000Z",
  "endTime": "2025-01-15T14:32:15.000Z",
  "totalTests": 85,
  "passedTests": 82,
  "failedTests": 3,
  "skippedTests": 0,
  "categories": {
    "Environment": {
      "passed": 4,
      "failed": 0,
      "tests": [...]
    }
  },
  "errors": [],
  "warnings": []
}
```

---

## Sample Test Output

```
╔════════════════════════════════════════════════╗
║   GreenGo App - Comprehensive Test Suite      ║
╚════════════════════════════════════════════════╝

[1/10] Running Environment Checks...
  ✓ Node.js Version: v18.17.0
  ✓ npm Available: 9.8.1
  ✓ Firebase CLI: 12.9.1
  ✓ TypeScript Installed: 5.3.3

[2/10] Running TypeScript Compilation...
  ✓ TypeScript Compilation: Compilation successful
  ✓ JavaScript Output: 31 files generated

[3/10] Running ESLint Code Quality Tests...
  ✓ ESLint: Passed with 5 warnings

[4/10] Running Unit Tests...
  ✓ Unit Tests: No unit test files found (skipped)

[5/10] Validating Function Exports...
  ✓ Total Function Exports: 109 functions exported
  ✓ Media Processing Functions: Present
  ✓ Messaging Functions: Present
  ✓ Video Calling Functions: Present
  ... (all categories)

[6/10] Validating File Structure...
  ✓ Directory: functions/src/admin: Present
  ✓ Directory: functions/src/video_calling: Present
  ✓ TypeScript Files: 31 files found
  ... (all checks)

[7/10] Validating Security Audit System...
  ✓ Authentication Tests: Implemented
  ✓ Data Protection Tests: Implemented
  ✓ Total Test Cases: 500+ tests defined
  ... (all categories)

[8/10] Running Dependency Audit...
  ✓ Dependency Vulnerabilities: No vulnerabilities found
  ✓ Outdated Packages: 3 packages can be updated

[9/10] Checking Firebase Configuration...
  ✓ firebase.json: Present
  ✓ Config: functions: Configured
  ✓ .firebaserc: Present

[10/10] Generating Reports...
  ✓ Report Generation: In progress

============================================================
TEST EXECUTION SUMMARY
============================================================
Total Tests:    85
Passed:         82
Failed:         3
Skipped:        0
Pass Rate:      96.5%
Duration:       45.23s
============================================================

Category Breakdown:
  Environment: 4/4 (100%)
  TypeScript Compilation: 2/2 (100%)
  Code Quality: 1/1 (100%)
  ... (all categories)

✓ Markdown report saved: test_reports/test_report_2025-01-15...md
✓ JSON report saved: test_reports/test_report_2025-01-15...json
```

---

## Prerequisites

### Required Software

1. **Node.js** (v18 or v20)
   - Download: https://nodejs.org/
   - Verify: `node --version`

2. **npm** (comes with Node.js)
   - Verify: `npm --version`

3. **Firebase CLI** (optional, for config checks)
   ```bash
   npm install -g firebase-tools
   ```

4. **TypeScript** (installed as dev dependency)
   - Automatically installed with `npm install`

### Installation

1. Navigate to the functions directory:
   ```bash
   cd "c:\Users\Software Engineering\GreenGo App\functions"
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

---

## Running Specific Tests

### Compile TypeScript Only
```bash
cd functions
npm run build
```

### Run ESLint Only
```bash
cd functions
npm run lint
```

### Fix ESLint Issues
```bash
cd functions
npm run lint:fix
```

### Run Unit Tests Only (if available)
```bash
cd functions
npm test
```

### Run Dependency Audit
```bash
cd functions
npm audit
```

### Fix Dependency Vulnerabilities
```bash
cd functions
npm audit fix
```

---

## Interpreting Results

### Pass Rate Guidelines

| Pass Rate | Status | Action Required |
|-----------|--------|-----------------|
| 100% | ✅ Excellent | Ready for deployment |
| 95-99% | ✅ Good | Review warnings, deploy OK |
| 90-94% | ⚠️ Fair | Fix failures before deployment |
| < 90% | ❌ Poor | Significant issues, DO NOT deploy |

### Critical Failures

If any of these categories fail, **DO NOT DEPLOY**:

- ❌ TypeScript Compilation
- ❌ Function Export Validation
- ❌ Firebase Configuration (for deployment)
- ❌ Critical/High Dependency Vulnerabilities

### Non-Critical Issues

These can be addressed post-deployment:

- ⚠️ ESLint warnings (code style)
- ⚠️ Outdated packages (low severity)
- ⚠️ Missing unit tests
- ⚠️ Code quality improvements

---

## Troubleshooting

### Error: "Node.js not found"
**Solution**: Install Node.js from https://nodejs.org/

### Error: "npm install fails"
**Solution**:
```bash
cd functions
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Error: "TypeScript compilation fails"
**Solution**: Check the error messages in the report. Common issues:
- Missing type definitions
- Syntax errors
- Import/export issues

Fix errors in the reported files and run again.

### Error: "Firebase CLI not found"
**Solution**: Install Firebase CLI:
```bash
npm install -g firebase-tools
```

### Error: "Permission denied" (Unix)
**Solution**: Make the script executable:
```bash
chmod +x run_tests.sh
```

---

## Continuous Integration (CI)

### GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      run: |
        cd functions
        npm install

    - name: Run tests
      run: node run_all_tests.js

    - name: Upload test reports
      uses: actions/upload-artifact@v3
      with:
        name: test-reports
        path: test_reports/
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
test:
  image: node:18
  script:
    - cd functions && npm install
    - cd .. && node run_all_tests.js
  artifacts:
    paths:
      - test_reports/
    expire_in: 1 week
```

---

## Best Practices

### Before Committing Code
```bash
./run_tests.sh
# Fix any failures before git commit
```

### Before Deploying
```bash
./run_tests.sh
# Ensure 95%+ pass rate
firebase deploy --only functions
```

### After Deployment
- Run security audit: `firebase functions:shell > runSecurityAudit()`
- Monitor Cloud Functions logs
- Check error rates in Firebase Console

### Weekly Maintenance
```bash
cd functions
npm outdated          # Check for updates
npm audit             # Check for vulnerabilities
npm update            # Update dependencies
./run_tests.sh        # Verify after updates
```

---

## Support & Documentation

- **Test Execution Issues**: Review this guide
- **Security Audit**: See [security_audit/README.md](security_audit/README.md)
- **Verification Report**: See [VERIFICATION_REPORT.md](VERIFICATION_REPORT.md)
- **Quick Summary**: See [TEST_SUMMARY.md](TEST_SUMMARY.md)

---

## Changelog

### v1.0.0 (January 15, 2025)
- Initial release
- 10 test categories
- 85+ individual tests
- Markdown and JSON report generation
- Windows and Unix support

---

**Last Updated**: January 15, 2025
**Author**: GreenGo Development Team
