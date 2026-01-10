/**
 * Seed Version Configuration for Firestore
 *
 * Run this script to initialize version config in Firebase:
 *
 * Usage:
 *   1. Install Firebase Admin SDK: npm install firebase-admin
 *   2. Download service account key from Firebase Console
 *   3. Run: node seed_version_config.js
 *
 * Or manually create the document in Firebase Console > Firestore
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (for production)
// Uncomment and configure with your service account
/*
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
*/

// For local emulator testing:
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
admin.initializeApp({
  projectId: 'greengo-chat-dev'
});

const db = admin.firestore();

async function seedVersionConfig() {
  console.log('🚀 Seeding version configuration...\n');

  const versionConfig = {
    // Global maintenance mode
    maintenanceMode: false,
    maintenanceMessage: 'We are currently performing scheduled maintenance to improve your experience. Please check back in a few minutes.',

    // Android configuration
    android: {
      // Minimum version required (FORCE update if below)
      minVersion: '1.0.0',
      // Recommended version (SOFT update if below)
      recommendedVersion: '1.0.0',
      // Current latest version in store
      currentVersion: '1.0.0',
      // Google Play Store URL
      storeUrl: 'https://play.google.com/store/apps/details?id=com.greengo.chat',
      // Release notes shown in update dialog
      releaseNotes: 'Welcome to GreenGo! Find meaningful connections with our intelligent matching.',
      // Release date
      releaseDate: new Date().toISOString(),
    },

    // iOS configuration
    ios: {
      minVersion: '1.0.0',
      recommendedVersion: '1.0.0',
      currentVersion: '1.0.0',
      storeUrl: 'https://apps.apple.com/app/greengo/id123456789',
      releaseNotes: 'Welcome to GreenGo! Find meaningful connections with our intelligent matching.',
      releaseDate: new Date().toISOString(),
    },

    // Metadata
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: 'seed_script',
  };

  try {
    await db.doc('app_config/version').set(versionConfig);
    console.log('✅ Version config created at: app_config/version\n');
    console.log('Configuration:');
    console.log('─────────────────────────────────────────');
    console.log(`Maintenance Mode: ${versionConfig.maintenanceMode}`);
    console.log('');
    console.log('Android:');
    console.log(`  Min Version: ${versionConfig.android.minVersion}`);
    console.log(`  Recommended: ${versionConfig.android.recommendedVersion}`);
    console.log(`  Current: ${versionConfig.android.currentVersion}`);
    console.log('');
    console.log('iOS:');
    console.log(`  Min Version: ${versionConfig.ios.minVersion}`);
    console.log(`  Recommended: ${versionConfig.ios.recommendedVersion}`);
    console.log(`  Current: ${versionConfig.ios.currentVersion}`);
    console.log('─────────────────────────────────────────\n');
  } catch (error) {
    console.error('❌ Error creating version config:', error);
  }

  process.exit(0);
}

// Example: Simulate new release
async function simulateNewRelease() {
  console.log('📦 Simulating new app release...\n');

  // Update to version 1.1.0 (soft update)
  await db.doc('app_config/version').update({
    'android.currentVersion': '1.1.0',
    'android.recommendedVersion': '1.1.0',
    'android.releaseNotes': '• New chat features\n• Performance improvements\n• Bug fixes',
    'android.releaseDate': new Date().toISOString(),
    'ios.currentVersion': '1.1.0',
    'ios.recommendedVersion': '1.1.0',
    'ios.releaseNotes': '• New chat features\n• Performance improvements\n• Bug fixes',
    'ios.releaseDate': new Date().toISOString(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ Released version 1.1.0');
  console.log('   Users on 1.0.x will see SOFT update prompt\n');
}

// Example: Force critical update
async function simulateCriticalUpdate() {
  console.log('🔒 Simulating critical security update...\n');

  // Force all users to update to 1.2.0
  await db.doc('app_config/version').update({
    'android.minVersion': '1.2.0',
    'android.currentVersion': '1.2.0',
    'android.recommendedVersion': '1.2.0',
    'android.releaseNotes': '⚠️ Critical security update\n\nThis update fixes a security vulnerability. Please update immediately.',
    'ios.minVersion': '1.2.0',
    'ios.currentVersion': '1.2.0',
    'ios.recommendedVersion': '1.2.0',
    'ios.releaseNotes': '⚠️ Critical security update\n\nThis update fixes a security vulnerability. Please update immediately.',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ Released version 1.2.0 (FORCE UPDATE)');
  console.log('   ALL users below 1.2.0 will be FORCED to update\n');
}

// Example: Enable maintenance mode
async function enableMaintenance() {
  console.log('🔧 Enabling maintenance mode...\n');

  await db.doc('app_config/version').update({
    maintenanceMode: true,
    maintenanceMessage: 'We are upgrading our servers to provide you with a better experience.\n\nEstimated downtime: 30 minutes',
    maintenanceStartedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ Maintenance mode ENABLED');
  console.log('   All users will see maintenance screen\n');
}

// Example: Disable maintenance mode
async function disableMaintenance() {
  console.log('✅ Disabling maintenance mode...\n');

  await db.doc('app_config/version').update({
    maintenanceMode: false,
    maintenanceEndedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ Maintenance mode DISABLED');
  console.log('   App is back online\n');
}

// Run the seed
seedVersionConfig();

// Uncomment to test different scenarios:
// simulateNewRelease();
// simulateCriticalUpdate();
// enableMaintenance();
// disableMaintenance();
