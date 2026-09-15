import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Looks up a conversation by `matchId`, scoped to the signed-in user.
///
/// Firestore security rules are NOT filters. A query is refused unless its own
/// constraints prove that every document it could return is readable - and it
/// is refused even when it would have matched nothing at all. Querying
/// `conversations` by `matchId` alone proves nothing about who is allowed to
/// see the result, so the rule
///
///   allow read: if convMember(resource.data) || convAdmin();
///
/// rejects it outright. That is what surfaced as "Could not start the chat."
/// for users who had a perfectly valid membership: the very first thing the
/// connect flow does is this existence check, and the failure was swallowed by
/// a catch-all and reported as a generic error.
///
/// It worked before v4.0.0 only because the ruleset ended in a catch-all
/// `match /{document=**} { allow read: if isSignedIn(); }`, which let any
/// signed-in user read anything. Removing that catch-all was correct; this
/// query simply had to become honest about whose conversation it wants.
///
/// Adding the participant constraint gives up nothing: a conversation the
/// caller is not part of was never readable. The OR covers both sides, because
/// whoever creates the conversation becomes `userId1` and the other person
/// `userId2` - matching on one side only would miss half the conversations and
/// silently create duplicates.
Query<Map<String, dynamic>> conversationsByMatchId(
  FirebaseFirestore firestore,
  String matchId, {
  String? uid,
}) {
  final me = uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  return firestore
      .collection('conversations')
      .where(
        Filter.or(
          Filter('userId1', isEqualTo: me),
          Filter('userId2', isEqualTo: me),
        ),
      )
      .where('matchId', isEqualTo: matchId);
}
