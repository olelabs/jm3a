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

  // Logs every uncaught Flutter framework exception (the ones that render
  // as the red error screen — e.g. a null-check/RangeError thrown from a
  // widget's build()) BEFORE handing off to Flutter's own default
  // handler, which still renders the exact same red screen it always did
  // — this only adds a log line, it never suppresses/replaces/redirects
  // the error. Added specifically because a build-time exception thrown
  // from deep inside a Consumer rebuild (e.g. the Meme admin next-round
  // crash) previously left no trace anywhere once the screen was
  // dismissed/backgrounded, making it unreproducible after the fact.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'UNCAUGHT_FLUTTER_ERROR: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
    defaultOnError?.call(details);
  };

  runApp(const Jma3aApp());
}
