#!/usr/bin/env node

/**
 * ============================================================================
 * GreenGo - Trigger In-App Update Script
 * ============================================================================
 *
 * This script updates the Firestore version configuration to trigger
 * soft or force updates for app users.
 *
 * Usage:
 *   node scripts/trigger_update.js <platform> <version> <type> [release_notes]
 *
 * Arguments:
 *   platform      - 'android' or 'ios'
 *   version       - Version number (e.g., '1.2.0')
 *   type          - 'soft' or 'force'
 *   release_notes - Optional release notes (in quotes)
 *
 * Examples:
 *   # Soft update for Android
 *   node scripts/trigger_update.js android 1.2.0 soft "Bug fixes and improvements"
 *
 *   # Force update for iOS (security fix)
 *   node scripts/trigger_update.js ios 1.2.0 force "Critical security update"
 *
 *   # Enable maintenance mode
 *   node scripts/trigger_update.js maintenance on "Server upgrade in progress"
 *
 *   # Disable maintenance mode
 *   node scripts/trigger_update.js maintenance off
 *
 * Setup:
 *   1. npm install firebase-admin
 *   2. Download service account key from Firebase Console
 *   3. Set GOOGLE_APPLICATION_CREDENTIALS environment variable
 *      OR place serviceAccountKey.json in scripts folder
 *
 * ============================================================================
 */

const admin = require('firebase-admin');
const path = require('path');

// ============================================================================
// Configuration
// ============================================================================

// Try to load service account from various locations
let serviceAccount;
const possiblePaths = [
  './serviceAccountKey.json',
  '../serviceAccountKey.json',
  './firebase-adminsdk.json',
  '../firebase-adminsdk.json',
];

for (const p of possiblePaths) {
  try {
    serviceAccount = require(path.resolve(__dirname, p));
    console.log(`Using service account from: ${p}`);
    break;
  } catch (e) {
    // Continue to next path
  }
}

// Initialize Firebase Admin
if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault()
  });
} else {
  // For local emulator testing
  console.log('No service account found. Using emulator...');
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  admin.initializeApp({ projectId: 'greengo-chat-dev' });
}

const db = admin.firestore();

// ============================================================================
// Helper Functions
// ============================================================================

function printUsage() {
  console.log(`
Usage:
  node trigger_update.js <platform> <version> <type> [release_notes]
  node trigger_update.js maintenance <on|off> [message]
  node trigger_update.js status

Arguments:
  platform      - 'android' or 'ios'
  version       - Version number (e.g., '1.2.0')
  type          - 'soft' or 'force'
  release_notes - Optional release notes

Examples:
  node trigger_update.js android 1.2.0 soft "Bug fixes"
  node trigger_update.js ios 1.3.0 force "Security update"
  node trigger_update.js maintenance on "Server maintenance"
  node trigger_update.js maintenance off
  node trigger_update.js status
  `);
}

function validateVersion(version) {
  const regex = /^\d+\.\d+\.\d+$/;
  if (!regex.test(version)) {
    console.error(`Error: Invalid version format '${version}'. Use MAJOR.MINOR.PATCH (e.g., 1.2.0)`);
    process.exit(1);
  }
}

// ============================================================================
// Commands
// ============================================================================

async function triggerUpdate(platform, version, updateType, releaseNotes) {
  validateVersion(version);

  const isForce = updateType === 'force';
  const docRef = db.doc('app_config/version');

  console.log('\n========================================');
  console.log(`Triggering ${isForce ? 'FORCE' : 'SOFT'} update for ${platform.toUpperCase()}`);
  console.log('========================================\n');

  const updates = {
    [`${platform}.currentVersion`]: version,
    [`${platform}.recommendedVersion`]: version,
    [`${platform}.releaseDate`]: new Date().toISOString(),
    'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
    'updatedBy': 'trigger_update_script',
  };

  if (releaseNotes) {
    updates[`${platform}.releaseNotes`] = releaseNotes;
  }

  if (isForce) {
    updates[`${platform}.minVersion`] = version;
    console.log('WARNING: This will FORCE all users to update!');
    console.log('Users below this version will be blocked from using the app.\n');
  }

  // Show what will be updated
  console.log('Updates to apply:');
  for (const [key, value] of Object.entries(updates)) {
    if (typeof value === 'string') {
      console.log(`  ${key}: "${value}"`);
    }
  }
  console.log('');

  // Confirm
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  rl.question('Proceed? (yes/no): ', async (answer) => {
    rl.close();

    if (answer.toLowerCase() !== 'yes' && answer.toLowerCase() !== 'y') {
      console.log('Cancelled.');
      process.exit(0);
    }

    try {
      await docRef.update(updates);
      console.log(`\n✅ ${platform.toUpperCase()} update triggered successfully!`);
      console.log(`   Version: ${version}`);
      console.log(`   Type: ${isForce ? 'FORCE (blocking)' : 'SOFT (dismissible)'}`);
      if (releaseNotes) {
        console.log(`   Notes: ${releaseNotes}`);
      }
    } catch (error) {
      if (error.code === 5) {
        console.log('Document does not exist. Creating...');
        await docRef.set({
          maintenanceMode: false,
          maintenanceMessage: '',
          android: {
            minVersion: '1.0.0',
            recommendedVersion: platform === 'android' ? version : '1.0.0',
            currentVersion: platform === 'android' ? version : '1.0.0',
            storeUrl: 'https://play.google.com/store/apps/details?id=com.greengo.chat',
            releaseNotes: platform === 'android' ? (releaseNotes || '') : '',
          },
          ios: {
            minVersion: '1.0.0',
            recommendedVersion: platform === 'ios' ? version : '1.0.0',
            currentVersion: platform === 'ios' ? version : '1.0.0',
            storeUrl: 'https://apps.apple.com/app/greengo/id123456789',
            releaseNotes: platform === 'ios' ? (releaseNotes || '') : '',
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log('✅ Document created with initial configuration.');
      } else {
        console.error('Error:', error.message);
        process.exit(1);
      }
    }

    process.exit(0);
  });
}

async function setMaintenance(enabled, message) {
  const docRef = db.doc('app_config/version');

  console.log('\n========================================');
  console.log(`${enabled ? 'ENABLING' : 'DISABLING'} Maintenance Mode`);
  console.log('========================================\n');

  if (enabled) {
    console.log('WARNING: This will block ALL users from using the app!\n');
  }

  const updates = {
    maintenanceMode: enabled,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (enabled && message) {
    updates.maintenanceMessage = message;
    updates.maintenanceStartedAt = admin.firestore.FieldValue.serverTimestamp();
  } else if (!enabled) {
    updates.maintenanceEndedAt = admin.firestore.FieldValue.serverTimestamp();
  }

  try {
    await docRef.update(updates);
    console.log(`✅ Maintenance mode ${enabled ? 'ENABLED' : 'DISABLED'}`);
    if (enabled && message) {
      console.log(`   Message: ${message}`);
    }
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

async function showStatus() {
  const docRef = db.doc('app_config/version');

  try {
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log('\n❌ No version configuration found!');
      console.log('Run with a platform argument to create initial config.\n');
      process.exit(1);
    }

    const data = doc.data();

    console.log('\n========================================');
    console.log('  Current Version Configuration');
    console.log('========================================\n');

    console.log(`Maintenance Mode: ${data.maintenanceMode ? '🔴 ENABLED' : '🟢 Disabled'}`);
    if (data.maintenanceMode) {
      console.log(`  Message: ${data.maintenanceMessage}`);
    }
    console.log('');

    console.log('ANDROID:');
    if (data.android) {
      console.log(`  Min Version:         ${data.android.minVersion} (force update below)`);
      console.log(`  Recommended Version: ${data.android.recommendedVersion} (soft update below)`);
      console.log(`  Current Version:     ${data.android.currentVersion}`);
      console.log(`  Store URL:           ${data.android.storeUrl}`);
      if (data.android.releaseNotes) {
        console.log(`  Release Notes:       ${data.android.releaseNotes.substring(0, 50)}...`);
      }
    } else {
      console.log('  Not configured');
    }
    console.log('');

    console.log('iOS:');
    if (data.ios) {
      console.log(`  Min Version:         ${data.ios.minVersion} (force update below)`);
      console.log(`  Recommended Version: ${data.ios.recommendedVersion} (soft update below)`);
      console.log(`  Current Version:     ${data.ios.currentVersion}`);
      console.log(`  Store URL:           ${data.ios.storeUrl}`);
      if (data.ios.releaseNotes) {
        console.log(`  Release Notes:       ${data.ios.releaseNotes.substring(0, 50)}...`);
      }
    } else {
      console.log('  Not configured');
    }
    console.log('');

    if (data.updatedAt) {
      console.log(`Last Updated: ${data.updatedAt.toDate().toISOString()}`);
    }
    console.log('');

  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

// ============================================================================
// Main
// ============================================================================

const args = process.argv.slice(2);

if (args.length === 0) {
  printUsage();
  process.exit(1);
}

const command = args[0].toLowerCase();

switch (command) {
  case 'android':
  case 'ios':
    if (args.length < 3) {
      console.error('Error: Missing arguments for platform update.');
      printUsage();
      process.exit(1);
    }
    const version = args[1];
    const type = args[2].toLowerCase();
    if (type !== 'soft' && type !== 'force') {
      console.error("Error: Update type must be 'soft' or 'force'");
      process.exit(1);
    }
    const notes = args[3] || null;
    triggerUpdate(command, version, type, notes);
    break;

  case 'maintenance':
    const enabled = args[1]?.toLowerCase() === 'on';
    const message = args[2] || 'We are currently performing maintenance. Please try again later.';
    setMaintenance(enabled, message);
    break;

  case 'status':
    showStatus();
    break;

  default:
    console.error(`Error: Unknown command '${command}'`);
    printUsage();
    process.exit(1);
}
