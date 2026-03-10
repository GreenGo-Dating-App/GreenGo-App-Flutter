/**
 * Vocabulary Processor - Firestore trigger
 *
 * Processes vocabulary from new messages, tracks unique words per user,
 * and awards XP for new vocabulary learned.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, FieldValue, logInfo, logError } from '../shared/utils';

const WORD_REGEX = /[a-zA-ZÀ-ÿ\u00C0-\u024F']+/g;
const MIN_WORD_LENGTH = 2;
const BATCH_SIZE = 450;
const XP_PER_NEW_WORD = 1;

export const onMessageCreatedVocabulary = onDocumentCreated(
  {
    document: 'conversations/{conversationId}/messages/{messageId}',
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (event) => {
    try {
      const messageData = event.data?.data();
      if (!messageData) {
        logInfo('vocabularyProcessor: No message data found, skipping.');
        return;
      }

      const senderId: string | undefined = messageData.senderId;
      const text: string | undefined = messageData.content || messageData.text;

      if (!senderId || !text) {
        logInfo('vocabularyProcessor: Missing senderId or text, skipping.');
        return;
      }

      // Get language from the parent conversation document
      const conversationId = event.params.conversationId;
      const conversationDoc = await db
        .collection('conversations')
        .doc(conversationId)
        .get();
      const language: string = conversationDoc.data()?.language || 'en';

      // Extract unique words from the message text
      const matches = text.match(WORD_REGEX) || [];
      const uniqueWords = Array.from(new Set(
        matches
          .filter((w) => w.length >= MIN_WORD_LENGTH)
          .map((w) => w.toLowerCase())
      ));

      if (uniqueWords.length === 0) {
        logInfo('vocabularyProcessor: No valid words extracted, skipping.');
        return;
      }

      logInfo(
        `vocabularyProcessor: Processing ${uniqueWords.length} unique words for user ${senderId} (lang: ${language}).`
      );

      let newWordCount = 0;

      // Process words in batches of 450 to stay under the Firestore 500 limit
      for (let i = 0; i < uniqueWords.length; i += BATCH_SIZE) {
        const batchWords = uniqueWords.slice(i, i + BATCH_SIZE);
        const batch = db.batch();

        for (const word of batchWords) {
          const wordDocId = `${language}_${word}`;
          const wordRef = db
            .collection('user_vocabulary')
            .doc(senderId)
            .collection('words')
            .doc(wordDocId);

          const wordDoc = await wordRef.get();

          if (wordDoc.exists) {
            // Word already exists: just increment useCount
            batch.update(wordRef, {
              useCount: FieldValue.increment(1),
            });
          } else {
            // New word: create the document
            batch.set(wordRef, {
              word,
              language,
              frequencyScore: 0,
              firstUsedAt: FieldValue.serverTimestamp(),
              useCount: 1,
            });
            newWordCount++;
          }
        }

        await batch.commit();
      }

      // Award XP for new words learned
      if (newWordCount > 0) {
        const totalXp = newWordCount * XP_PER_NEW_WORD;

        // Update user level XP
        const userLevelRef = db.collection('user_levels').doc(senderId);
        const userLevelDoc = await userLevelRef.get();

        if (userLevelDoc.exists) {
          await userLevelRef.update({
            totalXP: FieldValue.increment(totalXp),
            currentXP: FieldValue.increment(totalXp),
            lastUpdated: FieldValue.serverTimestamp(),
          });
        }

        // Log XP transaction
        await db.collection('xp_transactions').add({
          userId: senderId,
          xpAmount: totalXp,
          actionType: 'vocabulary_usage',
          newWords: newWordCount,
          createdAt: FieldValue.serverTimestamp(),
        });

        logInfo(
          `vocabularyProcessor: Awarded ${totalXp} XP to user ${senderId} for ${newWordCount} new words.`
        );
      }

      logInfo(
        `vocabularyProcessor: Done. ${uniqueWords.length} words processed, ${newWordCount} new.`
      );
    } catch (error) {
      logError('vocabularyProcessor: Error processing vocabulary.', error);
      throw error;
    }
  }
);
