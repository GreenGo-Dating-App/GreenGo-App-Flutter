/**
 * Disappearing Media Cloud Function
 * Point 108: Auto-delete media after 24 hours (Instagram-style)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const storage = admin.storage();
const firestore = admin.firestore();

// Time to keep disappearing media (24 hours in milliseconds)
const DISAPPEARING_MEDIA_TTL = 24 * 60 * 60 * 1000;

/**
 * Scheduled function that runs every hour to clean up expired disappearing media
 */
export const cleanupDisappearingMedia = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    console.log('Starting disappearing media cleanup...');

    const cutoffTime = new Date(Date.now() - DISAPPEARING_MEDIA_TTL);

    try {
      // Find messages with disappearing media older than 24 hours
      const messagesSnapshot = await firestore
        .collectionGroup('messages')
        .where('metadata.isDisappearing', '==', true)
        .where('metadata.disappearingMediaDeleted', '==', false)
        .where('sentAt', '<', cutoffTime)
        .limit(100)
        .get();

      console.log(`Found ${messagesSnapshot.size} messages to process`);

      const batch = firestore.batch();
      const filesToDelete: string[] = [];

      for (const doc of messagesSnapshot.docs) {
        const message = doc.data();

        // Extract file path from content URL
        if (message.content) {
          try {
            const url = new URL(message.content);
            const pathMatch = url.pathname.match(/\/o\/(.+?)\?/);
            if (pathMatch) {
              const filePath = decodeURIComponent(pathMatch[1]);
              filesToDelete.push(filePath);

              // Also delete thumbnail if exists
              if (message.metadata?.thumbnailUrl) {
                const thumbUrl = new URL(message.metadata.thumbnailUrl);
                const thumbMatch = thumbUrl.pathname.match(/\/o\/(.+?)\?/);
                if (thumbMatch) {
                  filesToDelete.push(decodeURIComponent(thumbMatch[1]));
                }
              }
            }
          } catch (error) {
            console.error('Error parsing URL:', message.content, error);
          }
        }

        // Update message to mark media as deleted
        batch.update(doc.ref, {
          content: '[Media expired]',
          'metadata.disappearingMediaDeleted': true,
          'metadata.deletedAt': admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Commit Firestore updates
      await batch.commit();
      console.log(`Updated ${messagesSnapshot.size} messages`);

      // Delete files from Storage
      const bucket = storage.bucket();
      const deletePromises = filesToDelete.map(async (filePath) => {
        try {
          await bucket.file(filePath).delete();
          console.log(`Deleted file: ${filePath}`);
        } catch (error) {
          console.error(`Error deleting file ${filePath}:`, error);
        }
      });

      await Promise.all(deletePromises);
      console.log(`Deleted ${filesToDelete.length} files`);

      return {
        success: true,
        messagesProcessed: messagesSnapshot.size,
        filesDeleted: filesToDelete.length,
      };
    } catch (error) {
      console.error('Error in cleanupDisappearingMedia:', error);
      throw error;
    }
  });

/**
 * Mark message media as disappearing when it's created
 */
export const markMediaAsDisappearing = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();

    // Check if this is a media message with disappearing flag
    if (
      message.metadata?.isDisappearing &&
      (message.type === 'image' || message.type === 'video')
    ) {
      console.log(`Marking message ${snapshot.id} as disappearing`);

      // Calculate expiry time
      const expiryTime = new Date(message.sentAt.toDate().getTime() + DISAPPEARING_MEDIA_TTL);

      // Update message with expiry information
      await snapshot.ref.update({
        'metadata.disappearingMediaDeleted': false,
        'metadata.expiresAt': admin.firestore.Timestamp.fromDate(expiryTime),
      });

      console.log(`Message will expire at: ${expiryTime.toISOString()}`);
    }

    return null;
  });

/**
 * HTTP function to manually trigger cleanup
 */
export const triggerMediaCleanup = functions.https.onCall(async (data, context) => {
  // Verify admin authentication
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can trigger manual cleanup'
    );
  }

  console.log('Manual cleanup triggered by admin');

  const cutoffTime = new Date(Date.now() - DISAPPEARING_MEDIA_TTL);

  try {
    const messagesSnapshot = await firestore
      .collectionGroup('messages')
      .where('metadata.isDisappearing', '==', true)
      .where('metadata.disappearingMediaDeleted', '==', false)
      .where('sentAt', '<', cutoffTime)
      .limit(500)
      .get();

    const batch = firestore.batch();
    const filesToDelete: string[] = [];

    for (const doc of messagesSnapshot.docs) {
      const message = doc.data();

      if (message.content) {
        try {
          const url = new URL(message.content);
          const pathMatch = url.pathname.match(/\/o\/(.+?)\?/);
          if (pathMatch) {
            filesToDelete.push(decodeURIComponent(pathMatch[1]));
          }
        } catch (error) {
          console.error('Error parsing URL:', error);
        }
      }

      batch.update(doc.ref, {
        content: '[Media expired]',
        'metadata.disappearingMediaDeleted': true,
        'metadata.deletedAt': admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    const bucket = storage.bucket();
    await Promise.all(
      filesToDelete.map((filePath) => bucket.file(filePath).delete().catch(console.error))
    );

    return {
      success: true,
      messagesProcessed: messagesSnapshot.size,
      filesDeleted: filesToDelete.length,
    };
  } catch (error) {
    console.error('Error in triggerMediaCleanup:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get expiring media stats
 */
export const getExpiringMediaStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  try {
    const userId = context.auth.uid;

    // Get user's conversations
    const conversationsSnapshot = await firestore
      .collection('conversations')
      .where('userId1', '==', userId)
      .get();

    const conversationsSnapshot2 = await firestore
      .collection('conversations')
      .where('userId2', '==', userId)
      .get();

    const conversationIds = [
      ...conversationsSnapshot.docs.map((doc) => doc.id),
      ...conversationsSnapshot2.docs.map((doc) => doc.id),
    ];

    // Count disappearing media messages
    let totalDisappearing = 0;
    let totalExpired = 0;

    for (const convId of conversationIds) {
      const disappearingSnapshot = await firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .where('metadata.isDisappearing', '==', true)
        .count()
        .get();

      const expiredSnapshot = await firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .where('metadata.disappearingMediaDeleted', '==', true)
        .count()
        .get();

      totalDisappearing += disappearingSnapshot.data().count;
      totalExpired += expiredSnapshot.data().count;
    }

    return {
      totalDisappearing,
      totalExpired,
      totalActive: totalDisappearing - totalExpired,
    };
  } catch (error) {
    console.error('Error in getExpiringMediaStats:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
