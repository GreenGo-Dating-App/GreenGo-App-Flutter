# GreenGoChat DevOps

This directory contains all deployment and DevOps related scripts and configurations for the GreenGoChat application.

## Directory Structure

```
devops/
├── dev/                    # Development environment
│   └── config.env         # Dev environment variables
├── test/                   # Test/Staging environment
│   └── config.env         # Test environment variables
├── prod/                   # Production environment
│   └── config.env         # Production environment variables
├── scripts/                # Utility scripts
├── DEPLOYMENT.md          # Detailed deployment guide
├── deployment.sh          # Legacy deployment script
├── TEST_MOCK_SETUP.sh     # Mock server setup
├── start_mock_servers.sh  # Start mock servers
├── stop_mock_servers.sh   # Stop mock servers
└── run_tests.sh           # Test runner

../deploy.sh               # Main unified deployment script (project root)
```

## Quick Start

### Deploy to Development
```bash
./deploy.sh dev android
```

### Deploy to Test/Staging
```bash
./deploy.sh test android
```

### Deploy to Production
```bash
./deploy.sh prod android --clean
```

## Unified Deployment Script

The main deployment script (`deploy.sh`) in the project root provides a unified interface for deploying to any environment.

### Usage

```bash
./deploy.sh [ENVIRONMENT] [PLATFORM] [OPTIONS]
```

### Parameters

**ENVIRONMENT** (required):
- `dev` - Development environment with Firebase emulators and mock servers
- `test` - Staging/test environment
- `prod` - Production environment

**PLATFORM** (required):
- `android` - Build Android app (APK)
- `ios` - Build iOS app (macOS only)
- `web` - Build web app
- `all` - Build all platforms

**OPTIONS** (optional):
- `--skip-tests` - Skip running tests before deployment
- `--clean` - Clean build before deploying
- `--help` - Show help message

### Examples

#### Development
```bash
# Deploy Android app to dev environment
./deploy.sh dev android

# Deploy with clean build
./deploy.sh dev android --clean

# Deploy without running tests
./deploy.sh dev android --skip-tests
```

#### Test/Staging
```bash
# Deploy Android app to staging
./deploy.sh test android

# Deploy all platforms
./deploy.sh test all

# Deploy with clean build
./deploy.sh test android --clean
```

#### Production
```bash
# Deploy Android app to production
./deploy.sh prod android

# Deploy all platforms with clean build
./deploy.sh prod all --clean

# Deploy without tests (not recommended)
./deploy.sh prod android --skip-tests
```

## Environment Configuration

Each environment has its own configuration file (`devops/{env}/config.env`):

### Development (`dev/config.env`)
- Uses Firebase emulators (localhost)
- Mock servers enabled
- Debug build mode
- Bundle ID: `com.greengochat.dev`
- Analytics/Crashlytics disabled

### Test/Staging (`test/config.env`)
- Uses Firebase staging project
- Staging API endpoints
- Release build mode
- Bundle ID: `com.greengochat.staging`
- Analytics/Crashlytics enabled

### Production (`prod/config.env`)
- Uses Firebase production project
- Production API endpoints
- Release build mode
- Bundle ID: `com.greengochat.greengochatapp`
- All monitoring enabled

## What the Deployment Script Does

1. **Validates** environment and platform arguments
2. **Loads** environment-specific configuration
3. **Checks** prerequisites (Flutter, Firebase CLI)
4. **Cleans** build (if --clean flag)
5. **Installs** dependencies (`flutter pub get`)
6. **Generates** localizations
7. **Starts** services (dev only):
   - Mock API servers
   - Firebase emulators
8. **Runs** tests (unless --skip-tests)
9. **Builds** the app for specified platform(s)
10. **Deploys** (for non-dev environments)
11. **Cleans up** running services

## Environment-Specific Features

### Development
- **Firebase Emulators**: Auth, Firestore, Storage run locally
- **Mock Servers**: API endpoints on localhost:3000
- **Debug Mode**: Full debugging enabled
- **Hot Reload**: Supports Flutter hot reload
- **No Analytics**: Faster development

### Test/Staging
- **Real Firebase**: Connects to staging project
- **Staging APIs**: Isolated from production
- **Release Build**: Performance testing
- **Analytics Enabled**: Monitor usage
- **Beta Testing**: Firebase App Distribution

### Production
- **Production Firebase**: Live project
- **Production APIs**: Live endpoints
- **Optimized Build**: Fully optimized
- **Full Monitoring**: Crashlytics, Analytics, Performance
- **App Stores**: Ready for Google Play / App Store

## Prerequisites

### Required
- **Flutter SDK**: v3.0.0 or higher
- **Dart SDK**: Comes with Flutter
- **Android Studio**: For Android builds
- **Xcode**: For iOS builds (macOS only)

### Optional
- **Firebase CLI**: For Firebase deployment
- **Node.js**: For mock servers (dev only)

### Installation

```bash
# Flutter
https://docs.flutter.dev/get-started/install

# Firebase CLI
npm install -g firebase-tools

# Node.js (for mock servers)
https://nodejs.org/
```

## Mock Servers (Development Only)

Mock servers provide a local development environment without requiring Firebase.

### Start Mock Servers
```bash
cd devops
./start_mock_servers.sh
```

### Stop Mock Servers
```bash
cd devops
./stop_mock_servers.sh
```

### Mock Endpoints
- **API**: http://localhost:3000
- **Firebase Auth Emulator**: http://localhost:9099
- **Firestore Emulator**: http://localhost:8080
- **Storage Emulator**: http://localhost:9199
- **Emulator UI**: http://localhost:4000

## CI/CD Integration

The deployment script can be integrated into CI/CD pipelines:

### GitHub Actions Example
```yaml
- name: Deploy to Staging
  run: |
    chmod +x deploy.sh
    ./deploy.sh test android --skip-tests
```

### GitLab CI Example
```yaml
deploy_staging:
  script:
    - chmod +x deploy.sh
    - ./deploy.sh test android
```

## Troubleshooting

### Script Permission Denied
```bash
chmod +x deploy.sh
```

### Firebase CLI Not Found
```bash
npm install -g firebase-tools
firebase login
```

### Emulators Won't Start
```bash
# Check if ports are in use
lsof -i :4000,8080,9099,9199

# Kill processes using those ports
kill -9 [PID]
```

### Build Fails
```bash
# Clean and retry
./deploy.sh [env] [platform] --clean

# Or manually
flutter clean
flutter pub get
./deploy.sh [env] [platform]
```

## Security Notes

⚠️ **Important Security Practices**:

1. **Never commit** Firebase API keys or secrets to Git
2. **Use environment variables** for sensitive data
3. **Rotate keys** regularly for production
4. **Limit Firebase project access** to authorized team members
5. **Enable Firebase App Check** for production
6. **Use separate projects** for dev/test/prod

## Support

For issues or questions:
1. Check [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment guide
2. Review logs in `build/` directory
3. Check Firebase console for errors
4. Contact DevOps team

## Maintenance

### Regular Tasks
- Update Firebase SDK versions
- Review and update environment configurations
- Test deployment scripts after Flutter updates
- Monitor build sizes and optimize
- Review and update security rules

### Monthly Reviews
- Check for outdated dependencies (`flutter pub outdated`)
- Review Firebase usage and costs
- Update documentation
- Test disaster recovery procedures
