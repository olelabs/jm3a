import '../../../core/errors/failures.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../data/friends_repository.dart';

/// The user-facing confirmation/error for a friend-request attempt. A
/// null [outcome] means the request was NOT sent ([failure] says why), so
/// this never claims success for a failed request. Pure, so each case is
/// unit-testable.
String friendRequestOutcomeMessage(
  AppLocalizations l10n,
  FriendRequestOutcome? outcome, {
  required String displayName,
  Failure? failure,
}) {
  return switch (outcome) {
    FriendRequestOutcome.sent => l10n.lobbyFriendRequestSent(displayName),
    FriendRequestOutcome.alreadySent => l10n.friendRequestAlreadySent(
      displayName,
    ),
    FriendRequestOutcome.incomingPending => l10n.friendRequestIncoming(
      displayName,
    ),
    FriendRequestOutcome.alreadyFriends => l10n.lobbyAreFriends(displayName),
    null =>
      failure is ForbiddenFailure
          ? l10n.lobbyCannotSendRequest(displayName)
          : l10n.lobbyCouldNotSendRequest,
  };
}
