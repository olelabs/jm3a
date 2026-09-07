import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/base_repository.dart';
import 'platform_config.dart';

export 'platform_config.dart';

/// Single point of access to `app_settings` — every admin-configurable
/// limit/price in the app is read through here in one query, instead of
/// each screen/feature querying `app_settings` independently for its own
/// key(s).
class PlatformConfigRepository extends BaseRepository {
  PlatformConfigRepository._();
  static final PlatformConfigRepository _instance = PlatformConfigRepository._();
  static PlatformConfigRepository get instance => _instance;

  final _supabase = Supabase.instance.client;

  Future<PlatformConfig> getConfig() => guardedCall(
    operationName: 'getPlatformConfig',
    operation: () async {
      final rows = await _supabase
          .from('app_settings')
          .select('key, value')
          .inFilter('key', PlatformConfig.keys);
      final byKey = <String, dynamic>{
        for (final row in rows) row['key'] as String: row['value'],
      };
      return PlatformConfig.fromRows(byKey);
    },
  );
}
