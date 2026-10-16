/**
 * Terms 14.1: "The support chat starts with an AI assistant. It is labelled as
 * AI, and you can ask for a human at any time."
 *
 * requestHumanSupport { conversationId } - the chat owner's visible "Talk to a
 * person" button. Hands the conversation to the human agents at once, with
 * the same flags the AI assistant uses for its own escalations
 * (adminPanelFunctions.ts: status 'open', escalatedFromAI, escalationReason,
 * escalatedAt), so the assistant stops replying (it skips escalated chats)
 * and the admin panel's escalated queue shows it. Posts the localized handoff
 * message once (srvSupportAiHandoff, rendered by the app in the user's
 * language). Idempotent: an already escalated / assigned chat is left as is.
 * The priority is NOT changed (it follows the owner's plan, set by the server).
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { t } from '../shared/i18n';

const db = () => admin.firestore();
export const HUMAN_REQUEST_REASON = 'user_requested_human';

export async function handOffToHuman(uid: string, conversationId: unknown): Promise<{ ok: true; already: boolean }> {
  if (typeof conversationId !== 'string' || !conversationId || conversationId.length > 128 || conversationId.includes('/')) {
    throw new HttpsError('invalid-argument', 'conversationId required');
  }
  const ref = db().collection('support_chats').doc(conversationId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Conversation not found');
    const c = snap.data() || {};
    if (c.userId !== uid) throw new HttpsError('permission-denied', 'Not your conversation');
    if (c.escalatedFromAI === true || c.assignedTo) return { ok: true as const, already: true };
    const now = admin.firestore.FieldValue.serverTimestamp();
    tx.update(ref, {
      status: 'open',
      escalatedFromAI: true,
      escalationReason: HUMAN_REQUEST_REASON,
      escalatedAt: now,
      humanRequestedAt: now,
      updatedAt: now,
    });
    tx.set(db().collection('support_messages').doc(), {
      conversationId,
      senderId: 'ai-agent',
      senderType: 'admin',
      senderName: 'Support Assistant',
      // English fallback + key (the app renders it in the user's language).
      content: t('en', 'srvSupportAiHandoff'),
      metadata: { systemKey: 'srvSupportAiHandoff' },
      messageType: 'text',
      readByAdmin: false,
      readByUser: true,
      isAIGenerated: true,
      createdAt: now,
    });
    return { ok: true as const, already: false };
  });
}

export const requestHumanSupport = onCall({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  return handOffToHuman(uid, (request.data || {}).conversationId);
});
