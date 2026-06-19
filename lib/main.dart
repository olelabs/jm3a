import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for gameplay consistency.
  // Landscape support can be unlocked per-screen via SystemChrome.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables before anything else.
  // In production: .env is bundled as an asset.
  // Sensitive keys (service role) never touch the client.
  await dotenv.load(fileName: '.env');

  // Bootstrap all singletons: Supabase, SQLite, OneSignal, etc.
  // Throws on misconfigured env — fail fast in production.
  await ServiceLocator.initialize();

  AppLogger.info('App initialized — starting runApp');

  runApp(const Jma3aApp());
}
