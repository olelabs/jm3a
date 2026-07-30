import 'dart:async';

import 'package:jma3a/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
// import '../auth/domain/entities/user_entity.dart';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  final _supabase = Supabase.instance.client;

  Timer? _expiryCheckTimer;

  void startExpiryCheck(void Function() onExpired) {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final stillPremium = await isPremiumActive(userId);
      if (!stillPremium) {
        AppLogger.info('SubscriptionService: premium expired for $userId');
        onExpired();
      }
    });
  }

  void stopExpiryCheck() {
    _expiryCheckTimer?.cancel();
    _expiryCheckTimer = null;
  }

  Future<bool> isPremiumActive(String userId) async {
    try {
      final rows = await _supabase
          .from('subscriptions')
          .select('id, status, expires_at')
          .eq('user_id', userId)
          .eq('status', 'active')
          .or(
            'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
          )
          .limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      AppLogger.warning('SubscriptionService: validation failed, $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getActiveSubscription(String userId) async {
    try {
      final rows = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .or(
            'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
          )
          .order('expires_at', ascending: false)
          .limit(1);
      return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static bool isCachedPremium(UserEntity? user) =>
      user?.isPremiumActive ?? false;

  static int maxProofReplays(UserEntity? user) => isCachedPremium(user) ? 3 : 1;
}
