/**
 * Optional link of a user experience to a community (`communityId` +
 * denormalised `communityName` on user_experiences/{id}).
 *
 * Set ONLY at creation by createUserExperience (rules deny client creates and
 * list both fields as server-owned, so they are immutable afterwards). The
 * permission mirrors the community Events tab exactly: the "+ Create" button
 * there is shown to the community's creator and to members whose role is
 * owner or admin (community_detail_screen.dart `_isModerator`).
 *
 * PURE: no Firestore access here (the callable reads the two docs inside its
 * transaction and passes the data in), so it is unit-tested directly.
 */

export type CommunityLinkRefusal =
  | 'invalid_community'
  | 'community_not_found'
  | 'community_not_allowed';

export const COMMUNITY_NAME_MAX = 120;

/**
 * The requested community id of a create payload: null = no link (absent /
 * null / empty string), 'invalid' = present but not a usable document id.
 */
export function requestedCommunityId(v: unknown): string | null | 'invalid' {
  if (v === undefined || v === null) return null;
  if (typeof v !== 'string') return 'invalid';
  const id = v.trim();
  if (id.length === 0) return null;
  if (id.length > 128 || id.includes('/') || id === '.' || id === '..' ||
      /^__.*__$/.test(id)) {
    return 'invalid';
  }
  return id;
}

/**
 * Whether [uid] may post an experience in the community, given the community
 * doc data (null = it does not exist) and the caller's members/{uid} doc data
 * (null = not a member). Returns null when allowed, else the refusal code.
 */
export function communityPostRefusal(
  uid: string,
  community: Record<string, unknown> | null | undefined,
  member: Record<string, unknown> | null | undefined,
): CommunityLinkRefusal | null {
  if (!community) return 'community_not_found';
  if (community.createdByUserId === uid) return null;
  const role = member?.role;
  if (role === 'owner' || role === 'admin') return null;
  return 'community_not_allowed';
}

/** The denormalised display name stored with the experience. */
export function communityDisplayName(
  community: Record<string, unknown> | null | undefined,
): string | null {
  const n = typeof community?.name === 'string' ? community.name.trim() : '';
  return n.length === 0 ? null : n.slice(0, COMMUNITY_NAME_MAX);
}
