/**
 * Finance exports: buyer fee invoices + credit notes, business monthly
 * statements, NFS-e (Brazil) / PDF invoices (USA), sales stats, admin callable.
 * See ./model.ts for the data model and the BR / US switch.
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { FCOL, loadSettings, processDocument, refreshNfse } from './invoices';
import { orderTransition, previousMonthKey } from './model';
import { applyOrderFinance } from './stats';
import { generateStatementsForMonth } from './statements';

export { adminFinance } from './admin';
export { listMyFinanceDocuments, getMyFinanceDocumentPdf } from './seller';
export { getMyBillingProfile, saveMyBillingProfile } from './billing';

/** ticket_orders paid / refunded / disputed -> stats + fee invoice / credit note. */
export const onTicketOrderFinance = onDocumentWritten(
  { document: 'ticket_orders/{orderId}', memory: '512MiB', timeoutSeconds: 120, retry: false },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const t = orderTransition(before, after);
    if (!t || !after) return;
    try {
      await applyOrderFinance(event.params.orderId, after, t);
    } catch (e) {
      // Never throw: the order itself is already settled. The admin
      // "reprocess order" action / backfill re-runs this idempotently.
      console.error('[finance] order', event.params.orderId, t, (e as Error)?.message || e);
    }
  },
);

/**
 * Every 10 min: poll NFS-e still processing / being cancelled, retry pending
 * ones (provider down at issue time) and retryable errors (max 5 attempts).
 */
export const pollNfseStatus = onSchedule(
  { schedule: 'every 10 minutes', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 300 },
  async () => {
    const db = admin.firestore();
    const open = await db.collection(FCOL.invoices)
      .where('nfse.status', 'in', ['processing', 'cancel_pending']).limit(100).get();
    for (const d of open.docs) {
      try { await refreshNfse(d.id); } catch (e) { console.warn('[finance] nfse refresh', d.id, (e as Error)?.message); }
    }
    const pending = await db.collection(FCOL.invoices).where('nfse.status', '==', 'pending').limit(50).get();
    for (const d of pending.docs) {
      if ((d.data().nfse?.attempts || 0) >= 5) continue;
      try { await processDocument(d.id, { email: false }); } catch (e) { console.warn('[finance] nfse submit', d.id, (e as Error)?.message); }
    }
  },
);

/** 2nd of the month 06:00 UTC: statements for the previous month (late refunds settled). */
export const generateMonthlyStatements = onSchedule(
  { schedule: '0 6 2 * *', timeZone: 'UTC', memory: '1GiB', timeoutSeconds: 540 },
  async () => {
    const st = await loadSettings();
    if (!st.monthlyStatements) return;
    const month = previousMonthKey(new Date());
    const r = await generateStatementsForMonth(month);
    console.log('[finance] statements', month, r);
  },
);
