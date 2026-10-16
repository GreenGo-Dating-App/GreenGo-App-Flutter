/**
 * Terms 18.6 (first bullet): "If someone often posts clearly illegal Content,
 * we suspend their account after a warning."
 *
 * Called after every recorded violation (moderator warning, content removal,
 * legacy / automatic warning). Uses the shared user_strikes counter
 * (moderationEffects.ts recordStrike) and user_warnings: once a user has
 * REPEAT_STRIKE_THRESHOLD violations in 12 months AND at least one earlier
 * warning, the account is suspended (7 days; 30 days for a second escalation
 * in the window), with its own statement of reasons + appeal.
 *
 * The suspension is a consequence of the human decision that recorded the
 * violation, so it carries that decider (automated:false) unless the
 * triggering violation itself was automatic.
 */
import { createModerationDecision, AutomatedInfo } from './moderationDecisions';
import {
  applySuspension, offenderHistory, recordStrike, repeatOffenderEscalation, REPEAT_STRIKE_THRESHOLD,
} from './moderationEffects';

export async function escalateIfRepeatOffender(p: {
  userId: string;
  /** Decision that recorded the current violation. */
  decisionId: string;
  /** user_warnings id of the current warning (excluded from "prior warnings"). */
  currentWarningId: string | null;
  decidedBy: string;
  automated?: AutomatedInfo | null;
  nowMs?: number;
}): Promise<{ escalated: boolean; days?: number; decisionId?: string }> {
  const nowMs = p.nowMs ?? Date.now();
  const history = await offenderHistory(p.userId, p.currentWarningId, nowMs);
  const esc = repeatOffenderEscalation(history);
  if (!esc) return { escalated: false };
  const escalationId = `${p.decisionId}__escalation`;
  const reason = `Repeated violations: ${history.violations} in the last 12 months (limit ${REPEAT_STRIKE_THRESHOLD}) after a warning (Terms 18.6).`;
  const effects = [
    await applySuspension({ userId: p.userId, reason, days: esc.days, decisionId: escalationId, by: p.decidedBy, nowMs }),
    await recordStrike({ userId: p.userId, decisionId: escalationId, kind: 'escalation', nowMs }),
  ];
  await createModerationDecision({
    decisionId: escalationId,
    queueId: p.decisionId,
    userId: p.userId,
    action: 'suspendUser',
    reasonCode: 'repeat_violations',
    explanation: `${reason} Suspension: ${esc.days} days.`,
    decidedBy: p.decidedBy,
    contentRef: { type: 'account', id: null, excerpt: null },
    automated: p.automated ?? null,
    effects,
    extra: { escalationOf: p.decisionId, suspensionDays: esc.days },
    nowMs,
  });
  return { escalated: true, days: esc.days, decisionId: escalationId };
}
