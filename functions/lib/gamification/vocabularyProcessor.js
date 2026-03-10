"use strict";
/**
 * Vocabulary Processor - Firestore trigger
 *
 * Processes vocabulary from new messages, tracks unique words per user,
 * and awards XP for new vocabulary learned.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.onMessageCreatedVocabulary = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const utils_1 = require("../shared/utils");
const WORD_REGEX = /[a-zA-ZÀ-ÿ\u00C0-\u024F']+/g;
const MIN_WORD_LENGTH = 2;
const BATCH_SIZE = 450;
const XP_PER_NEW_WORD = 1;
exports.onMessageCreatedVocabulary = (0, firestore_1.onDocumentCreated)({
    document: 'conversations/{conversationId}/messages/{messageId}',
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (event) => {
    var _a, _b;
    try {
        const messageData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!messageData) {
            (0, utils_1.logInfo)('vocabularyProcessor: No message data found, skipping.');
            return;
        }
        const senderId = messageData.senderId;
        const text = messageData.content || messageData.text;
        if (!senderId || !text) {
            (0, utils_1.logInfo)('vocabularyProcessor: Missing senderId or text, skipping.');
            return;
        }
        // Get language from the parent conversation document
        const conversationId = event.params.conversationId;
        const conversationDoc = await utils_1.db
            .collection('conversations')
            .doc(conversationId)
            .get();
        const language = ((_b = conversationDoc.data()) === null || _b === void 0 ? void 0 : _b.language) || 'en';
        // Extract unique words from the message text
        const matches = text.match(WORD_REGEX) || [];
        const uniqueWords = Array.from(new Set(matches
            .filter((w) => w.length >= MIN_WORD_LENGTH)
            .map((w) => w.toLowerCase())));
        if (uniqueWords.length === 0) {
            (0, utils_1.logInfo)('vocabularyProcessor: No valid words extracted, skipping.');
            return;
        }
        (0, utils_1.logInfo)(`vocabularyProcessor: Processing ${uniqueWords.length} unique words for user ${senderId} (lang: ${language}).`);
        let newWordCount = 0;
        // Process words in batches of 450 to stay under the Firestore 500 limit
        for (let i = 0; i < uniqueWords.length; i += BATCH_SIZE) {
            const batchWords = uniqueWords.slice(i, i + BATCH_SIZE);
            const batch = utils_1.db.batch();
            for (const word of batchWords) {
                const wordDocId = `${language}_${word}`;
                const wordRef = utils_1.db
                    .collection('user_vocabulary')
                    .doc(senderId)
                    .collection('words')
                    .doc(wordDocId);
                const wordDoc = await wordRef.get();
                if (wordDoc.exists) {
                    // Word already exists: just increment useCount
                    batch.update(wordRef, {
                        useCount: utils_1.FieldValue.increment(1),
                    });
                }
                else {
                    // New word: create the document
                    batch.set(wordRef, {
                        word,
                        language,
                        frequencyScore: 0,
                        firstUsedAt: utils_1.FieldValue.serverTimestamp(),
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
            const userLevelRef = utils_1.db.collection('user_levels').doc(senderId);
            const userLevelDoc = await userLevelRef.get();
            if (userLevelDoc.exists) {
                await userLevelRef.update({
                    totalXP: utils_1.FieldValue.increment(totalXp),
                    currentXP: utils_1.FieldValue.increment(totalXp),
                    lastUpdated: utils_1.FieldValue.serverTimestamp(),
                });
            }
            // Log XP transaction
            await utils_1.db.collection('xp_transactions').add({
                userId: senderId,
                xpAmount: totalXp,
                actionType: 'vocabulary_usage',
                newWords: newWordCount,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
            (0, utils_1.logInfo)(`vocabularyProcessor: Awarded ${totalXp} XP to user ${senderId} for ${newWordCount} new words.`);
        }
        (0, utils_1.logInfo)(`vocabularyProcessor: Done. ${uniqueWords.length} words processed, ${newWordCount} new.`);
    }
    catch (error) {
        (0, utils_1.logError)('vocabularyProcessor: Error processing vocabulary.', error);
        throw error;
    }
});
//# sourceMappingURL=vocabularyProcessor.js.map