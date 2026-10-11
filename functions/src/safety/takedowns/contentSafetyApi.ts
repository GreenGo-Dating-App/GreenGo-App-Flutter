/**
 * Google Content Safety API (child-safety classifier for NEW, unhashed CSAM)
 * - INTEGRATION STUB.
 *
 * Google offers the Content Safety API free to qualifying platforms after an
 * application (https://protectingchildren.google/tools-for-partners/). It
 * returns a review PRIORITY, not a verdict: a human must review.
 *
 * Off by default. To enable once access is granted (owner step, see
 * docs/safety/csae-ncii-runbook.md):
 *   CONTENT_SAFETY_API_ENABLED=true
 *   CONTENT_SAFETY_API_KEY=<key from Google>  (Secret Manager, never in git)
 *
 * TODO(content-safety): implement the request below with the endpoint and
 * payload from Google's onboarding docs (they are shared under NDA, which is
 * why nothing is guessed here), add a timeout, and route VERY_HIGH / HIGH
 * results to a CSAE review case (uploadScreening.ts) WITHOUT auto-hiding
 * until precision is measured. Same scope rule as hash scanning: public
 * uploads only (audit EU-19).
 */

export type ReviewPriority = 'VERY_LOW' | 'LOW' | 'MEDIUM' | 'HIGH' | 'VERY_HIGH';

export interface ContentSafetyVerdict {
  reviewPriority: ReviewPriority;
  engine: 'google-content-safety';
}

export function contentSafetyApiEnabled(): boolean {
  return process.env.CONTENT_SAFETY_API_ENABLED === 'true' && !!process.env.CONTENT_SAFETY_API_KEY;
}

export async function classifyWithContentSafetyApi(_image: Buffer): Promise<ContentSafetyVerdict | null> {
  if (!contentSafetyApiEnabled()) return null;
  // TODO(content-safety): call the API here. Until then, enabled-but-stubbed
  // must be visible in the logs rather than silently "clean".
  console.warn('[contentSafetyApi] CONTENT_SAFETY_API_ENABLED is set but the client is not implemented yet');
  return null;
}
