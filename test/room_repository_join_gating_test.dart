// Phase 2 (room invitation semantics) — regression coverage for the
// Type-A ("room creation" invite code) approval-bypass bug: the previous
// logic in RoomRepository.joinByCode skipped the approval gate whenever
// the client-supplied `invitedBy` query parameter was non-null, but that
// parameter was never verified against a real room_invites row — and the
// app's own "Share Invite Link"/QR features populate it with the
// SHARER'S OWN id on every generic share, so requires_approval was
// effectively dead for every real Type-A link. This tests the pure
// decision table (resolveJoinByCodeAction) that replaces it, covering
// every combination the fix must get right — see that function's own
// doc comment in lib/features/rooms/data/room_repository.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/features/rooms/data/room_repository.dart';

void main() {
  group('resolveJoinByCodeAction', () {
    test(
      'creation invitation + approval required + no genuine invite -> '
      'requestApproval (the actual bug: must NOT bypass)',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: false,
            requiresApproval: true,
            isMidGame: false,
            hasPriorMembership: false,
          ),
          JoinByCodeAction.requestApproval,
        );
      },
    );

    test(
      'creation invitation + approval disabled + no genuine invite + not '
      'mid-game -> directJoin',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: false,
            requiresApproval: false,
            isMidGame: false,
            hasPriorMembership: false,
          ),
          JoinByCodeAction.directJoin,
        );
      },
    );

    test(
      'genuine Type-B invite present -> acceptInvite, regardless of '
      'requires_approval (manual admin invitation still bypasses, '
      'unchanged)',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: true,
            requiresApproval: true,
            isMidGame: false,
            hasPriorMembership: false,
          ),
          JoinByCodeAction.acceptInvite,
        );
      },
    );

    test(
      'genuine Type-B invite present -> acceptInvite even mid-game with no '
      'prior membership (an explicit admin invite intentionally bypasses '
      'the mid-game stranger gate too — that is the whole point of a '
      'direct admin invite)',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: true,
            requiresApproval: false,
            isMidGame: true,
            hasPriorMembership: false,
          ),
          JoinByCodeAction.acceptInvite,
        );
      },
    );

    test(
      'mid-game + no prior membership + approval disabled -> '
      'requestApproval (the missing "game already started" gate this fix '
      'adds — a total stranger must not drop straight into a live game '
      'via a bare code link)',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: false,
            requiresApproval: false,
            isMidGame: true,
            hasPriorMembership: false,
          ),
          JoinByCodeAction.requestApproval,
        );
      },
    );

    test(
      'mid-game + HAS prior membership + approval disabled -> directJoin '
      '(a returning member must not be blocked by the new mid-game gate)',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: false,
            requiresApproval: false,
            isMidGame: true,
            hasPriorMembership: true,
          ),
          JoinByCodeAction.directJoin,
        );
      },
    );

    test(
      'requires_approval takes priority over the mid-game gate — either '
      'reason alone is enough to require approval, checked in that order',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: false,
            requiresApproval: true,
            isMidGame: true,
            hasPriorMembership: true,
          ),
          JoinByCodeAction.requestApproval,
        );
      },
    );

    test(
      'not mid-game -> hasPriorMembership is irrelevant, still directJoin '
      'when approval is disabled and there is no genuine invite',
      () {
        expect(
          resolveJoinByCodeAction(
            hasGenuineInvite: false,
            requiresApproval: false,
            isMidGame: false,
            hasPriorMembership: true,
          ),
          JoinByCodeAction.directJoin,
        );
      },
    );
  });
}
