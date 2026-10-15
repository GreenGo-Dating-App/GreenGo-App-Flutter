/**
 * Seller (business account) access to their OWN finance documents, for the
 * in-app "Invoices" section:
 *   listMyFinanceDocuments({ kind: 'invoices' | 'statements', cursor?, pageSize? })
 *   getMyFinanceDocumentPdf({ kind, id }) -> { filename, base64 }
 *
 * finance_* collections stay server-only in the rules; ownership is checked
 * here (invoice.customer.uid / statement.organizerId == caller). Test documents
 * are shown only to test accounts (a real seller never sees a TEST document
 * produced by a test buyer's order).
 */
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { FCOL, getInvoicePdf, isTestUid } from './invoices';
import { getStatementPdf } from './statements';

const db = () => admin.firestore();
const iso = (v: any) => (v && typeof v.toDate === 'function' ? v.toDate().toISOString() : null);

function invoiceItem(id: string, d: any) {
  return {
    id, kind: 'invoice', type: d.type, number: d.number, status: d.status, isTest: !!d.isTest,
    currency: d.currency, total: d.total, month: d.source?.month || null, issuedAt: iso(d.issuedAt),
    nfse: d.jurisdiction === 'BR' && d.nfse?.status !== 'not_required'
      ? { status: d.nfse?.status || null, number: d.nfse?.number || null, url: d.nfse?.url || null }
      : null,
    title: d.lines?.length === 1 ? d.lines[0].description : `${d.lines?.length || 0}`,
  };
}

function statementItem(id: string, d: any) {
  return {
    id, kind: 'statement', number: d.number, month: d.month, isTest: !!d.isTest, issuedAt: iso(d.issuedAt),
    lines: (d.lines || []).map((l: any) => ({ currency: l.currency, sales: l.sales, feesNet: l.feesNet, net: l.net, orders: l.orders })),
    feeInvoiceIds: d.feeInvoiceIds || [],
  };
}

export const listMyFinanceDocuments = onCall({ memory: '512MiB', timeoutSeconds: 60 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  const kind = request.data?.kind === 'statements' ? 'statements' : 'invoices';
  const size = Math.min(50, Math.max(1, Math.round(Number(request.data?.pageSize) || 20)));
  const showTest = await isTestUid(uid);
  const col = kind === 'statements' ? FCOL.statements : FCOL.invoices;
  let q: FirebaseFirestore.Query = db().collection(col)
    .where(kind === 'statements' ? 'organizerId' : 'customer.uid', '==', uid)
    .where('isTest', '==', showTest)
    .orderBy('issuedAt', 'desc')
    .limit(size + 1);
  const cursor = typeof request.data?.cursor === 'string' && !request.data.cursor.includes('/') ? request.data.cursor : null;
  if (cursor) {
    const c = await db().collection(col).doc(cursor).get();
    const cd = c.data();
    const owner = kind === 'statements' ? cd?.organizerId : cd?.customer?.uid;
    if (c.exists && owner === uid) q = q.startAfter(c);
  }
  const snap = await q.get();
  const docs = snap.docs.slice(0, size);
  return {
    items: docs.map((d) => (kind === 'statements' ? statementItem(d.id, d.data()) : invoiceItem(d.id, d.data()))),
    nextCursor: snap.docs.length > size ? docs[docs.length - 1].id : null,
  };
});

export const getMyFinanceDocumentPdf = onCall({ memory: '512MiB', timeoutSeconds: 60 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first');
  const id = String(request.data?.id || '');
  if (!id || id.includes('/') || id.length > 200) throw new HttpsError('invalid-argument', 'id is invalid');
  if (request.data?.kind === 'statement') {
    const r = await getStatementPdf(id);
    if (!r || r.statement.organizerId !== uid) throw new HttpsError('not-found', 'not found');
    return { filename: `${r.statement.number}.pdf`, base64: r.buffer.toString('base64') };
  }
  // Ownership BEFORE rendering: never render (or reveal) someone else's invoice.
  const snap = await db().collection(FCOL.invoices).doc(id).get();
  if (!snap.exists || snap.data()?.customer?.uid !== uid) throw new HttpsError('not-found', 'not found');
  const r = await getInvoicePdf(id);
  if (!r) throw new HttpsError('not-found', 'not found');
  return { filename: `${r.invoice.number}.pdf`, base64: r.buffer.toString('base64') };
});
