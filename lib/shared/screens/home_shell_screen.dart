// // // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // // import '../../core/extensions/context_ext.dart';
// // // // // // // // // import '../../core/router/route_names.dart';

// // // // // // // // // class HomeShellScreen extends StatelessWidget {
// // // // // // // // //   const HomeShellScreen({super.key, required this.child});
// // // // // // // // //   final Widget child;

// // // // // // // // //   static const _paths = [RouteNames.home, RouteNames.friends, RouteNames.marketplace, RouteNames.profile];

// // // // // // // // //   @override
// // // // // // // // //   Widget build(BuildContext context) {
// // // // // // // // //     final l10n = context.l10n;
// // // // // // // // //     final location = GoRouterState.of(context).uri.toString();
// // // // // // // // //     final currentIndex = _indexForLocation(location);

// // // // // // // // //     return Scaffold(
// // // // // // // // //       body: child,
// // // // // // // // //       bottomNavigationBar: NavigationBar(
// // // // // // // // //         selectedIndex: currentIndex,
// // // // // // // // //         onDestinationSelected: (i) => context.go(_paths[i]),
// // // // // // // // //         destinations: [
// // // // // // // // //           NavigationDestination(icon: const Icon(Icons.meeting_room_outlined), selectedIcon: const Icon(Icons.meeting_room_rounded), label: l10n.navRooms),
// // // // // // // // //           NavigationDestination(icon: const Icon(Icons.people_outline_rounded), selectedIcon: const Icon(Icons.people_rounded), label: l10n.navFriends),
// // // // // // // // //           NavigationDestination(icon: const Icon(Icons.store_outlined), selectedIcon: const Icon(Icons.store_rounded), label: l10n.navMarketplace),
// // // // // // // // //           NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: l10n.navProfile),
// // // // // // // // //         ],
// // // // // // // // //       ),
// // // // // // // // //     );
// // // // // // // // //   }

// // // // // // // // //   int _indexForLocation(String loc) {
// // // // // // // // //     if (loc.startsWith(RouteNames.profile))     return 3;
// // // // // // // // //     if (loc.startsWith(RouteNames.marketplace)) return 2;
// // // // // // // // //     if (loc.startsWith(RouteNames.friends))     return 1;
// // // // // // // // //     return 0;
// // // // // // // // //   }
// // // // // // // // // }

// // // // // // // // import 'package:flutter/material.dart';
// // // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // // import 'package:provider/provider.dart';
// // // // // // // // import '../../core/extensions/context_ext.dart';
// // // // // // // // import '../../core/router/route_names.dart';
// // // // // // // // import '../../features/notifications/presentation/notification_provider.dart';
// // // // // // // // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // // // // // // // import '../../features/friends/presentation/friends_provider.dart';

// // // // // // // // import 'package:jma3a/core/utils/app_logger.dart';
// // // // // // // // import 'package:sqflite/sqflite.dart';
// // // // // // // // import 'package:path/path.dart' as p;

// // // // // // // // // import '../../utils/app_logger.dart';
// // // // // // // // import '../../../features/offline/data/offline_repository.dart'
// // // // // // // //     show OfflineRepository;

// // // // // // // // class HomeShellScreen extends StatelessWidget {
// // // // // // // //   const HomeShellScreen({super.key, required this.child});
// // // // // // // //   final Widget child;

// // // // // // // //   static const _paths = [
// // // // // // // //     RouteNames.home,
// // // // // // // //     RouteNames.friends,
// // // // // // // //     RouteNames.marketplace,
// // // // // // // //     RouteNames.profile,
// // // // // // // //   ];

// // // // // // // //   @override
// // // // // // // //   Widget build(BuildContext context) {
// // // // // // // //     final l10n = context.l10n;
// // // // // // // //     final location = GoRouterState.of(context).uri.toString();
// // // // // // // //     final currentIndex = _indexForLocation(location);

// // // // // // // //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// // // // // // // //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// // // // // // // //     return Scaffold(
// // // // // // // //       body: Stack(children: [child, const InAppToastOverlay()]),
// // // // // // // //       bottomNavigationBar: NavigationBar(
// // // // // // // //         selectedIndex: currentIndex,
// // // // // // // //         onDestinationSelected: (i) => context.go(_paths[i]),
// // // // // // // //         destinations: [
// // // // // // // //           NavigationDestination(
// // // // // // // //             icon: const Icon(Icons.meeting_room_outlined),
// // // // // // // //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// // // // // // // //             label: l10n.navRooms,
// // // // // // // //           ),
// // // // // // // //           NavigationDestination(
// // // // // // // //             icon: Badge(
// // // // // // // //               isLabelVisible: friendCount > 0,
// // // // // // // //               label: Text('$friendCount'),
// // // // // // // //               child: const Icon(Icons.people_outline_rounded),
// // // // // // // //             ),
// // // // // // // //             selectedIcon: Badge(
// // // // // // // //               isLabelVisible: friendCount > 0,
// // // // // // // //               label: Text('$friendCount'),
// // // // // // // //               child: const Icon(Icons.people_rounded),
// // // // // // // //             ),
// // // // // // // //             label: l10n.navFriends,
// // // // // // // //           ),
// // // // // // // //           NavigationDestination(
// // // // // // // //             icon: const Icon(Icons.store_outlined),
// // // // // // // //             selectedIcon: const Icon(Icons.store_rounded),
// // // // // // // //             label: l10n.navMarketplace,
// // // // // // // //           ),
// // // // // // // //           NavigationDestination(
// // // // // // // //             icon: Badge(
// // // // // // // //               isLabelVisible: notifCount > 0,
// // // // // // // //               label: Text('$notifCount'),
// // // // // // // //               child: const Icon(Icons.person_outline_rounded),
// // // // // // // //             ),
// // // // // // // //             selectedIcon: Badge(
// // // // // // // //               isLabelVisible: notifCount > 0,
// // // // // // // //               label: Text('$notifCount'),
// // // // // // // //               child: const Icon(Icons.person_rounded),
// // // // // // // //             ),
// // // // // // // //             label: l10n.navProfile,
// // // // // // // //           ),
// // // // // // // //         ],
// // // // // // // //       ),
// // // // // // // //     );
// // // // // // // //   }

// // // // // // // //   int _indexForLocation(String loc) {
// // // // // // // //     if (loc.startsWith(RouteNames.profile)) return 3;
// // // // // // // //     if (loc.startsWith(RouteNames.marketplace)) return 2;
// // // // // // // //     if (loc.startsWith(RouteNames.friends)) return 1;
// // // // // // // //     return 0;
// // // // // // // //   }
// // // // // // // // }

// // // // // // // // /// Offline sessions schema — referenced by AppDatabase migration v2.
// // // // // // // // abstract class OfflineSessionsMigration {
// // // // // // // //   static const schema = OfflineRepository.schemaV2;
// // // // // // // // }

// // // // // // // // /// SQLite database singleton with versioned migrations.
// // // // // // // // ///
// // // // // // // // /// Stores: downloaded pack cards, purchase metadata, offline sync log.
// // // // // // // // /// All game and social data lives in Supabase — SQLite is offline-only.
// // // // // // // // class AppDatabase {
// // // // // // // //   AppDatabase._();
// // // // // // // //   static final AppDatabase instance = AppDatabase._();

// // // // // // // //   static const _dbName = 'jma3a.db';
// // // // // // // //   static const _dbVersion = 2;

// // // // // // // //   Database? _db;
// // // // // // // //   Database get db {
// // // // // // // //     assert(_db != null, 'AppDatabase not opened. Call open() first.');
// // // // // // // //     return _db!;
// // // // // // // //   }

// // // // // // // //   bool get isOpen => _db?.isOpen ?? false;

// // // // // // // //   Future<void> open() async {
// // // // // // // //     if (isOpen) return;

// // // // // // // //     final dbPath = p.join(await getDatabasesPath(), _dbName);

// // // // // // // //     _db = await openDatabase(
// // // // // // // //       dbPath,
// // // // // // // //       version: _dbVersion,
// // // // // // // //       onCreate: _onCreate,
// // // // // // // //       onUpgrade: _onUpgrade,
// // // // // // // //       onConfigure: (db) async {
// // // // // // // //         // Enable foreign key enforcement
// // // // // // // //         await db.execute('PRAGMA foreign_keys = ON');
// // // // // // // //         // Write-ahead logging for better concurrent read performance
// // // // // // // //         await db.execute('PRAGMA journal_mode = WAL');
// // // // // // // //       },
// // // // // // // //     );

// // // // // // // //     AppLogger.info('SQLite database opened: $dbPath (v$_dbVersion)');
// // // // // // // //   }

// // // // // // // //   // ── Schema creation ────────────────────────────────────────────────────
// // // // // // // //   Future<void> _onCreate(Database db, int version) async {
// // // // // // // //     AppLogger.info('Creating SQLite schema v$version');
// // // // // // // //     await _runMigration(db, version);
// // // // // // // //   }

// // // // // // // //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
// // // // // // // //     AppLogger.info('Upgrading SQLite $oldVersion → $newVersion');
// // // // // // // //     for (var v = oldVersion + 1; v <= newVersion; v++) {
// // // // // // // //       await _runMigration(db, v);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _runMigration(Database db, int version) async {
// // // // // // // //     switch (version) {
// // // // // // // //       case 1:
// // // // // // // //         await _migration001(db);
// // // // // // // //       case 2:
// // // // // // // //         await _migration002(db);
// // // // // // // //     }
// // // // // // // //   }

// // // // // // // //   Future<void> _migration002(Database db) async {
// // // // // // // //     await db.execute(OfflineSessionsMigration.schema);
// // // // // // // //     AppLogger.info('Migration 002: offline_sessions applied');
// // // // // // // //   }

// // // // // // // //   // ── Migration 001: Initial schema ──────────────────────────────────────
// // // // // // // //   Future<void> _migration001(Database db) async {
// // // // // // // //     final batch = db.batch();

// // // // // // // //     // Downloaded packs (header only — cards in pack_cards table)
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS packs (
// // // // // // // //         id            TEXT PRIMARY KEY,
// // // // // // // //         name_json     TEXT NOT NULL,
// // // // // // // //         cover_url     TEXT,
// // // // // // // //         game_type     TEXT NOT NULL,
// // // // // // // //         language      TEXT NOT NULL DEFAULT 'en',
// // // // // // // //         price         INTEGER NOT NULL DEFAULT 0,
// // // // // // // //         server_version INTEGER NOT NULL DEFAULT 1,
// // // // // // // //         downloaded_at INTEGER NOT NULL,
// // // // // // // //         expires_at    INTEGER
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     // Individual cards for each downloaded pack
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS pack_cards (
// // // // // // // //         id           TEXT PRIMARY KEY,
// // // // // // // //         pack_id      TEXT NOT NULL REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // //         content_json TEXT NOT NULL,
// // // // // // // //         card_type    TEXT NOT NULL,
// // // // // // // //         difficulty   TEXT NOT NULL DEFAULT 'mild',
// // // // // // // //         sort_order   INTEGER NOT NULL DEFAULT 0,
// // // // // // // //         image_path   TEXT
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     // Alias view for TodRepository compatibility
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE VIEW IF NOT EXISTS pack_cards_cache AS
// // // // // // // //       SELECT id, pack_id, content_json, card_type, difficulty, sort_order, image_path
// // // // // // // //       FROM pack_cards
// // // // // // // //     ''');

// // // // // // // //     batch.execute(
// // // // // // // //       'CREATE INDEX IF NOT EXISTS idx_cards_pack ON pack_cards(pack_id, sort_order)',
// // // // // // // //     );

// // // // // // // //     // Local mirror of server purchase records (for expiry checking offline)
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS purchases (
// // // // // // // //         pack_id      TEXT PRIMARY KEY REFERENCES packs(id) ON DELETE CASCADE,
// // // // // // // //         purchased_at INTEGER NOT NULL,
// // // // // // // //         expires_at   INTEGER NOT NULL
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     // Sync log: tracks which packs need re-download
// // // // // // // //     batch.execute('''
// // // // // // // //       CREATE TABLE IF NOT EXISTS sync_log (
// // // // // // // //         pack_id        TEXT PRIMARY KEY,
// // // // // // // //         server_version INTEGER NOT NULL,
// // // // // // // //         local_version  INTEGER NOT NULL,
// // // // // // // //         synced_at      INTEGER NOT NULL
// // // // // // // //       )
// // // // // // // //     ''');

// // // // // // // //     await batch.commit(noResult: true);
// // // // // // // //     AppLogger.info('Migration 001 applied');
// // // // // // // //   }

// // // // // // // //   Future<void> close() async {
// // // // // // // //     await _db?.close();
// // // // // // // //     _db = null;
// // // // // // // //   }
// // // // // // // // }

// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:go_router/go_router.dart';
// // // // // // // import 'package:provider/provider.dart';

// // // // // // // import '../../core/extensions/context_ext.dart';
// // // // // // // import '../../core/router/route_names.dart';
// // // // // // // import '../../features/notifications/presentation/notification_provider.dart';
// // // // // // // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // // // // // // import '../../features/friends/presentation/friends_provider.dart';

// // // // // // // class HomeShellScreen extends StatelessWidget {
// // // // // // //   const HomeShellScreen({super.key, required this.navigationShell});
// // // // // // //   final StatefulNavigationShell navigationShell;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final l10n = context.l10n;
// // // // // // //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// // // // // // //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// // // // // // //     return Scaffold(
// // // // // // //       body: Stack(children: [navigationShell, const InAppToastOverlay()]),
// // // // // // //       bottomNavigationBar: NavigationBar(
// // // // // // //         selectedIndex: navigationShell.currentIndex,
// // // // // // //         onDestinationSelected: (i) => navigationShell.goBranch(
// // // // // // //           i,
// // // // // // //           initialLocation: i == navigationShell.currentIndex,
// // // // // // //         ),
// // // // // // //         destinations: [
// // // // // // //           NavigationDestination(
// // // // // // //             icon: const Icon(Icons.meeting_room_outlined),
// // // // // // //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// // // // // // //             label: l10n.navRooms,
// // // // // // //           ),
// // // // // // //           NavigationDestination(
// // // // // // //             icon: Badge(
// // // // // // //               isLabelVisible: friendCount > 0,
// // // // // // //               label: Text('$friendCount'),
// // // // // // //               child: const Icon(Icons.people_outline_rounded),
// // // // // // //             ),
// // // // // // //             selectedIcon: Badge(
// // // // // // //               isLabelVisible: friendCount > 0,
// // // // // // //               label: Text('$friendCount'),
// // // // // // //               child: const Icon(Icons.people_rounded),
// // // // // // //             ),
// // // // // // //             label: l10n.navFriends,
// // // // // // //           ),
// // // // // // //           NavigationDestination(
// // // // // // //             icon: const Icon(Icons.store_outlined),
// // // // // // //             selectedIcon: const Icon(Icons.store_rounded),
// // // // // // //             label: l10n.navMarketplace,
// // // // // // //           ),
// // // // // // //           NavigationDestination(
// // // // // // //             icon: Badge(
// // // // // // //               isLabelVisible: notifCount > 0,
// // // // // // //               label: Text('$notifCount'),
// // // // // // //               child: const Icon(Icons.person_outline_rounded),
// // // // // // //             ),
// // // // // // //             selectedIcon: Badge(
// // // // // // //               isLabelVisible: notifCount > 0,
// // // // // // //               label: Text('$notifCount'),
// // // // // // //               child: const Icon(Icons.person_rounded),
// // // // // // //             ),
// // // // // // //             label: l10n.navProfile,
// // // // // // //           ),
// // // // // // //         ],
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:go_router/go_router.dart';
// // // // // // import 'package:provider/provider.dart';

// // // // // // import '../../core/extensions/context_ext.dart';
// // // // // // import '../../features/notifications/presentation/notification_provider.dart';
// // // // // // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // // // // // import '../../features/friends/presentation/friends_provider.dart';

// // // // // // class HomeShellScreen extends StatelessWidget {
// // // // // //   const HomeShellScreen({super.key, required this.navigationShell});
// // // // // //   final StatefulNavigationShell navigationShell;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final l10n = context.l10n;
// // // // // //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// // // // // //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// // // // // //     return Scaffold(
// // // // // //       body: navigationShell,
// // // // // //       bottomNavigationBar: NavigationBar(
// // // // // //         selectedIndex: navigationShell.currentIndex,
// // // // // //         onDestinationSelected: (i) {
// // // // // //           debugPrint(
// // // // // //             '=== NAV TAP: index=$i current=${navigationShell.currentIndex}',
// // // // // //           );
// // // // // //           navigationShell.goBranch(
// // // // // //             i,
// // // // // //             initialLocation: i == navigationShell.currentIndex,
// // // // // //           );
// // // // // //         },
// // // // // //         destinations: [
// // // // // //           NavigationDestination(
// // // // // //             icon: const Icon(Icons.meeting_room_outlined),
// // // // // //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// // // // // //             label: l10n.navRooms,
// // // // // //           ),
// // // // // //           NavigationDestination(
// // // // // //             icon: Badge(
// // // // // //               isLabelVisible: friendCount > 0,
// // // // // //               label: Text('$friendCount'),
// // // // // //               child: const Icon(Icons.people_outline_rounded),
// // // // // //             ),
// // // // // //             selectedIcon: Badge(
// // // // // //               isLabelVisible: friendCount > 0,
// // // // // //               label: Text('$friendCount'),
// // // // // //               child: const Icon(Icons.people_rounded),
// // // // // //             ),
// // // // // //             label: l10n.navFriends,
// // // // // //           ),
// // // // // //           NavigationDestination(
// // // // // //             icon: const Icon(Icons.store_outlined),
// // // // // //             selectedIcon: const Icon(Icons.store_rounded),
// // // // // //             label: l10n.navMarketplace,
// // // // // //           ),
// // // // // //           NavigationDestination(
// // // // // //             icon: Badge(
// // // // // //               isLabelVisible: notifCount > 0,
// // // // // //               label: Text('$notifCount'),
// // // // // //               child: const Icon(Icons.person_outline_rounded),
// // // // // //             ),
// // // // // //             selectedIcon: Badge(
// // // // // //               isLabelVisible: notifCount > 0,
// // // // // //               label: Text('$notifCount'),
// // // // // //               child: const Icon(Icons.person_rounded),
// // // // // //             ),
// // // // // //             label: l10n.navProfile,
// // // // // //           ),
// // // // // //         ],
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:provider/provider.dart';

// // // // // import '../../core/extensions/context_ext.dart';
// // // // // import '../../features/friends/presentation/friends_provider.dart';
// // // // // import '../../features/notifications/presentation/notification_provider.dart';
// // // // // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // // import '../../features/profile/presentation/screens/profile_screen.dart';

// // // // // class HomeShellScreen extends StatefulWidget {
// // // // //   const HomeShellScreen({super.key});

// // // // //   @override
// // // // //   State<HomeShellScreen> createState() => _HomeShellScreenState();
// // // // // }

// // // // // class _HomeShellScreenState extends State<HomeShellScreen> {
// // // // //   int _index = 0;

// // // // //   static const _pages = [
// // // // //     RoomBrowserScreen(),
// // // // //     FriendsScreen(),
// // // // //     MarketplaceScreen(),
// // // // //     ProfileScreen(),
// // // // //   ];

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final l10n = context.l10n;
// // // // //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// // // // //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// // // // //     return Scaffold(
// // // // //       body: IndexedStack(index: _index, children: _pages),
// // // // //       bottomNavigationBar: NavigationBar(
// // // // //         selectedIndex: _index,
// // // // //         onDestinationSelected: (i) => setState(() => _index = i),
// // // // //         destinations: [
// // // // //           NavigationDestination(
// // // // //             icon: const Icon(Icons.meeting_room_outlined),
// // // // //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// // // // //             label: l10n.navRooms,
// // // // //           ),
// // // // //           NavigationDestination(
// // // // //             icon: Badge(
// // // // //               isLabelVisible: friendCount > 0,
// // // // //               label: Text('$friendCount'),
// // // // //               child: const Icon(Icons.people_outline_rounded),
// // // // //             ),
// // // // //             selectedIcon: Badge(
// // // // //               isLabelVisible: friendCount > 0,
// // // // //               label: Text('$friendCount'),
// // // // //               child: const Icon(Icons.people_rounded),
// // // // //             ),
// // // // //             label: l10n.navFriends,
// // // // //           ),
// // // // //           NavigationDestination(
// // // // //             icon: const Icon(Icons.store_outlined),
// // // // //             selectedIcon: const Icon(Icons.store_rounded),
// // // // //             label: l10n.navMarketplace,
// // // // //           ),
// // // // //           NavigationDestination(
// // // // //             icon: Badge(
// // // // //               isLabelVisible: notifCount > 0,
// // // // //               label: Text('$notifCount'),
// // // // //               child: const Icon(Icons.person_outline_rounded),
// // // // //             ),
// // // // //             selectedIcon: Badge(
// // // // //               isLabelVisible: notifCount > 0,
// // // // //               label: Text('$notifCount'),
// // // // //               child: const Icon(Icons.person_rounded),
// // // // //             ),
// // // // //             label: l10n.navProfile,
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // import 'package:flutter/material.dart';
// // // // import 'package:provider/provider.dart';

// // // // import '../../core/extensions/context_ext.dart';
// // // // import '../../features/friends/presentation/friends_provider.dart';
// // // // import '../../features/notifications/presentation/notification_provider.dart';
// // // // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // // // import '../../features/packs/presentation/pack_provider.dart';
// // // // import '../../features/wallet/presentation/wallet_provider.dart';
// // // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // // import '../../features/profile/presentation/screens/profile_screen.dart';

// // // // class HomeShellScreen extends StatefulWidget {
// // // //   const HomeShellScreen({super.key});

// // // //   @override
// // // //   State<HomeShellScreen> createState() => _HomeShellScreenState();
// // // // }

// // // // class _HomeShellScreenState extends State<HomeShellScreen> {
// // // //   int _index = 0;

// // // //   static const _pages = [
// // // //     RoomBrowserScreen(),
// // // //     FriendsScreen(),
// // // //     MarketplaceScreen(),
// // // //     ProfileScreen(),
// // // //   ];

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     // Ensure all providers refresh on shell mount — handles the case where
// // // //     // onUserLoggedIn fired before providers were subscribed to auth changes
// // // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // // //       _refreshAll();
// // // //     });
// // // //   }

// // // //   void _refreshAll() {
// // // //     final uid = context.read<PackProvider>().currentUserId;
// // // //     if (uid == null) return;

// // // //     // Re-trigger onAuthChanged for providers that extend BaseProvider
// // // //     context.read<PackProvider>().onAuthChanged(uid);
// // // //     context.read<FriendsProvider>().onAuthChanged(uid);
// // // //     context.read<WalletProvider>().onAuthChanged(uid);
// // // //     // RoomBrowserScreen handles its own loading via initState
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final l10n = context.l10n;
// // // //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// // // //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// // // //     return Scaffold(
// // // //       body: IndexedStack(index: _index, children: _pages),
// // // //       bottomNavigationBar: NavigationBar(
// // // //         selectedIndex: _index,
// // // //         onDestinationSelected: (i) => setState(() => _index = i),
// // // //         destinations: [
// // // //           NavigationDestination(
// // // //             icon: const Icon(Icons.meeting_room_outlined),
// // // //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// // // //             label: l10n.navRooms,
// // // //           ),
// // // //           NavigationDestination(
// // // //             icon: Badge(
// // // //               isLabelVisible: friendCount > 0,
// // // //               label: Text('$friendCount'),
// // // //               child: const Icon(Icons.people_outline_rounded),
// // // //             ),
// // // //             selectedIcon: Badge(
// // // //               isLabelVisible: friendCount > 0,
// // // //               label: Text('$friendCount'),
// // // //               child: const Icon(Icons.people_rounded),
// // // //             ),
// // // //             label: l10n.navFriends,
// // // //           ),
// // // //           NavigationDestination(
// // // //             icon: const Icon(Icons.store_outlined),
// // // //             selectedIcon: const Icon(Icons.store_rounded),
// // // //             label: l10n.navMarketplace,
// // // //           ),
// // // //           NavigationDestination(
// // // //             icon: Badge(
// // // //               isLabelVisible: notifCount > 0,
// // // //               label: Text('$notifCount'),
// // // //               child: const Icon(Icons.person_outline_rounded),
// // // //             ),
// // // //             selectedIcon: Badge(
// // // //               isLabelVisible: notifCount > 0,
// // // //               label: Text('$notifCount'),
// // // //               child: const Icon(Icons.person_rounded),
// // // //             ),
// // // //             label: l10n.navProfile,
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // import 'package:flutter/material.dart';
// // // import 'package:jma3a/shared/widgets/playful_background.dart';
// // // import 'package:provider/provider.dart';

// // // import '../../core/di/service_locator.dart';
// // // import '../../core/extensions/context_ext.dart';
// // // import '../../features/friends/presentation/friends_provider.dart';
// // // import '../../features/notifications/presentation/notification_provider.dart';
// // // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // // import '../../features/packs/presentation/pack_provider.dart';
// // // import '../../features/wallet/presentation/wallet_provider.dart';
// // // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // // import '../../features/friends/presentation/screens/friends_screen.dart';
// // // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // // import '../../features/profile/presentation/screens/profile_screen.dart';

// // // class HomeShellScreen extends StatefulWidget {
// // //   const HomeShellScreen({super.key});

// // //   @override
// // //   State<HomeShellScreen> createState() => _HomeShellScreenState();
// // // }

// // // class _HomeShellScreenState extends State<HomeShellScreen> {
// // //   int _index = 0;

// // //   static const _pages = [
// // //     RoomBrowserScreen(),
// // //     FriendsScreen(),
// // //     MarketplaceScreen(),
// // //     ProfileScreen(),
// // //   ];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     // Ensure all providers refresh on shell mount — handles the case where
// // //     // onUserLoggedIn fired before providers were subscribed to auth changes
// // //     WidgetsBinding.instance.addPostFrameCallback((_) {
// // //       _refreshAll();
// // //     });
// // //   }

// // //   void _refreshAll() {
// // //     final uid = context.read<PackProvider>().currentUserId;
// // //     if (uid == null) return;

// // //     // Re-trigger onAuthChanged for providers that extend BaseProvider
// // //     context.read<PackProvider>().onAuthChanged(uid);
// // //     context.read<FriendsProvider>().onAuthChanged(uid);
// // //     context.read<WalletProvider>().onAuthChanged(uid);
// // //     // RoomBrowserScreen handles its own loading via initState

// // //     // Register this device with OneSignal so push notifications work
// // //     sl.notificationService.setExternalUserId(uid);
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final l10n = context.l10n;
// // //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// // //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// // //     return Scaffold(
// // //       body: PlayfulBackground(
// // //         child: IndexedStack(index: _index, children: _pages),
// // //       ),
// // //       bottomNavigationBar: NavigationBar(
// // //         selectedIndex: _index,
// // //         onDestinationSelected: (i) => setState(() => _index = i),
// // //         destinations: [
// // //           NavigationDestination(
// // //             icon: const Icon(Icons.meeting_room_outlined),
// // //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// // //             label: l10n.navRooms,
// // //           ),
// // //           NavigationDestination(
// // //             icon: Badge(
// // //               isLabelVisible: friendCount > 0,
// // //               label: Text('$friendCount'),
// // //               child: const Icon(Icons.people_outline_rounded),
// // //             ),
// // //             selectedIcon: Badge(
// // //               isLabelVisible: friendCount > 0,
// // //               label: Text('$friendCount'),
// // //               child: const Icon(Icons.people_rounded),
// // //             ),
// // //             label: l10n.navFriends,
// // //           ),
// // //           NavigationDestination(
// // //             icon: const Icon(Icons.store_outlined),
// // //             selectedIcon: const Icon(Icons.store_rounded),
// // //             label: l10n.navMarketplace,
// // //           ),
// // //           NavigationDestination(
// // //             icon: Badge(
// // //               isLabelVisible: notifCount > 0,
// // //               label: Text('$notifCount'),
// // //               child: const Icon(Icons.person_outline_rounded),
// // //             ),
// // //             selectedIcon: Badge(
// // //               isLabelVisible: notifCount > 0,
// // //               label: Text('$notifCount'),
// // //               child: const Icon(Icons.person_rounded),
// // //             ),
// // //             label: l10n.navProfile,
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';

// // import '../../core/di/service_locator.dart';
// // import '../../core/extensions/context_ext.dart';
// // import '../../core/providers/auth_provider.dart';
// // import '../../core/services/app_theme_service.dart';
// // import '../../features/friends/presentation/friends_provider.dart';
// // import '../../features/notifications/presentation/notification_provider.dart';
// // import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// // import '../../features/packs/presentation/pack_provider.dart';
// // import '../../features/wallet/presentation/wallet_provider.dart';
// // import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// // import '../../shared/widgets/playful_background.dart';
// // import '../../features/friends/presentation/screens/friends_screen.dart';
// // import '../../features/packs/presentation/screens/marketplace_screen.dart';
// // import '../../features/profile/presentation/screens/profile_screen.dart';

// // class HomeShellScreen extends StatefulWidget {
// //   const HomeShellScreen({super.key});

// //   @override
// //   State<HomeShellScreen> createState() => _HomeShellScreenState();
// // }

// // class _HomeShellScreenState extends State<HomeShellScreen> {
// //   int _index = 0;

// //   static const _pages = [
// //     RoomBrowserScreen(),
// //     FriendsScreen(),
// //     MarketplaceScreen(),
// //     ProfileScreen(),
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       _refreshAll();
// //     });
// //   }

// //   void _refreshAll() {
// //     final uid = context.read<PackProvider>().currentUserId;
// //     if (uid == null) return;

// //     context.read<PackProvider>().onAuthChanged(uid);
// //     context.read<FriendsProvider>().onAuthChanged(uid);
// //     context.read<WalletProvider>().onAuthChanged(uid);

// //     sl.notificationService.setExternalUserId(uid);
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final l10n = context.l10n;
// //     final notifCount = context.watch<NotificationProvider>().unreadCount;
// //     final friendCount = context.watch<FriendsProvider>().pendingCount;

// //     return Scaffold(
// //       body: PlayfulBackground(
// //         child: IndexedStack(index: _index, children: _pages),
// //       ),
// //       bottomNavigationBar: NavigationBar(
// //         selectedIndex: _index,
// //         onDestinationSelected: (i) => setState(() => _index = i),
// //         destinations: [
// //           NavigationDestination(
// //             icon: const Icon(Icons.meeting_room_outlined),
// //             selectedIcon: const Icon(Icons.meeting_room_rounded),
// //             label: l10n.navRooms,
// //           ),
// //           NavigationDestination(
// //             icon: Badge(
// //               isLabelVisible: friendCount > 0,
// //               label: Text('$friendCount'),
// //               child: const Icon(Icons.people_outline_rounded),
// //             ),
// //             selectedIcon: Badge(
// //               isLabelVisible: friendCount > 0,
// //               label: Text('$friendCount'),
// //               child: const Icon(Icons.people_rounded),
// //             ),
// //             label: l10n.navFriends,
// //           ),
// //           NavigationDestination(
// //             icon: const Icon(Icons.store_outlined),
// //             selectedIcon: const Icon(Icons.store_rounded),
// //             label: l10n.navMarketplace,
// //           ),
// //           NavigationDestination(
// //             icon: Badge(
// //               isLabelVisible: notifCount > 0,
// //               label: Text('$notifCount'),
// //               child: const Icon(Icons.person_outline_rounded),
// //             ),
// //             selectedIcon: Badge(
// //               isLabelVisible: notifCount > 0,
// //               label: Text('$notifCount'),
// //               child: const Icon(Icons.person_rounded),
// //             ),
// //             label: l10n.navProfile,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/di/service_locator.dart';
// import '../../core/extensions/context_ext.dart';
// import '../../core/providers/auth_provider.dart';
// import '../../core/services/app_theme_service.dart';
// import '../../features/friends/presentation/friends_provider.dart';
// import '../../features/notifications/presentation/notification_provider.dart';
// import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
// import '../../features/packs/presentation/pack_provider.dart';
// import '../../features/wallet/presentation/wallet_provider.dart';
// import '../../features/rooms/presentation/screens/room_browser_screen.dart';
// import '../../shared/widgets/playful_background.dart';
// import '../../features/friends/presentation/screens/friends_screen.dart';
// import '../../features/packs/presentation/screens/marketplace_screen.dart';
// import '../../features/profile/presentation/screens/profile_screen.dart';

// class HomeShellScreen extends StatefulWidget {
//   const HomeShellScreen({super.key});

//   @override
//   State<HomeShellScreen> createState() => _HomeShellScreenState();
// }

// class _HomeShellScreenState extends State<HomeShellScreen> {
//   int _index = 0;

//   // We'll wrap each page with a widget that provides a translucent background
//   // so the bubbles show through while keeping text readable.
//   List<Widget> get _pages => [
//     _buildTransparentPage(const RoomBrowserScreen()),
//     _buildTransparentPage(const FriendsScreen()),
//     _buildTransparentPage(const MarketplaceScreen()),
//     _buildTransparentPage(const ProfileScreen()),
//   ];

//   Widget _buildTransparentPage(Widget page) {
//     return Container(
//       // Choose your preferred opacity – 0.85 means 15% transparency
//       color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
//       child: page,
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _refreshAll();
//     });
//   }

//   void _refreshAll() {
//     final uid = context.read<PackProvider>().currentUserId;
//     if (uid == null) return;

//     context.read<PackProvider>().onAuthChanged(uid);
//     context.read<FriendsProvider>().onAuthChanged(uid);
//     context.read<WalletProvider>().onAuthChanged(uid);

//     sl.notificationService.setExternalUserId(uid);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = context.l10n;
//     final notifCount = context.watch<NotificationProvider>().unreadCount;
//     final friendCount = context.watch<FriendsProvider>().pendingCount;

//     // Wrap the whole screen with PlayfulBackground – it will paint bubbles behind everything.
//     return PlayfulBackground(
//       child: Scaffold(
//         backgroundColor: Colors.transparent, // Make scaffold transparent
//         body: IndexedStack(
//           index: _index,
//           children: _pages, // each page now has a semi‑transparent background
//         ),
//         bottomNavigationBar: NavigationBar(
//           backgroundColor: Theme.of(
//             context,
//           ).scaffoldBackgroundColor.withOpacity(0.9), // also translucent
//           selectedIndex: _index,
//           onDestinationSelected: (i) => setState(() => _index = i),
//           destinations: [
//             NavigationDestination(
//               icon: const Icon(Icons.meeting_room_outlined),
//               selectedIcon: const Icon(Icons.meeting_room_rounded),
//               label: l10n.navRooms,
//             ),
//             NavigationDestination(
//               icon: Badge(
//                 isLabelVisible: friendCount > 0,
//                 label: Text('$friendCount'),
//                 child: const Icon(Icons.people_outline_rounded),
//               ),
//               selectedIcon: Badge(
//                 isLabelVisible: friendCount > 0,
//                 label: Text('$friendCount'),
//                 child: const Icon(Icons.people_rounded),
//               ),
//               label: l10n.navFriends,
//             ),
//             NavigationDestination(
//               icon: const Icon(Icons.store_outlined),
//               selectedIcon: const Icon(Icons.store_rounded),
//               label: l10n.navMarketplace,
//             ),
//             NavigationDestination(
//               icon: Badge(
//                 isLabelVisible: notifCount > 0,
//                 label: Text('$notifCount'),
//                 child: const Icon(Icons.person_outline_rounded),
//               ),
//               selectedIcon: Badge(
//                 isLabelVisible: notifCount > 0,
//                 label: Text('$notifCount'),
//                 child: const Icon(Icons.person_rounded),
//               ),
//               label: l10n.navProfile,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/service_locator.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/app_theme_service.dart';
import '../../features/friends/presentation/friends_provider.dart';
import '../../features/notifications/presentation/notification_provider.dart';
import '../../features/notifications/presentation/widgets/in_app_toast_overlay.dart';
import '../../features/packs/presentation/pack_provider.dart';
import '../../features/wallet/presentation/wallet_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_names.dart';
import '../../features/rooms/presentation/screens/room_browser_screen.dart';
import '../../shared/widgets/playful_background.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/packs/presentation/screens/marketplace_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  static const _pages = [
    RoomBrowserScreen(),
    FriendsScreen(),
    MarketplaceScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
      _checkActiveGameMembership();
    });
  }

  void _refreshAll() {
    final uid = context.read<PackProvider>().currentUserId;
    if (uid == null) return;

    context.read<PackProvider>().onAuthChanged(uid);
    context.read<FriendsProvider>().onAuthChanged(uid);
    context.read<WalletProvider>().onAuthChanged(uid);

    sl.notificationService.setExternalUserId(uid);
  }

  bool _checkedActiveGameMembership = false;

  /// Landing on Home right after login/launch while still an intact member
  /// of a room whose game is already running is the common "app was just
  /// backgrounded or restarted mid-game" case — route straight back to the
  /// lobby (which shows the in-progress-game banner) instead of leaving the
  /// player stranded on Home with no obvious way back in. Checked once per
  /// screen lifetime, not on every rebuild.
  Future<void> _checkActiveGameMembership() async {
    if (_checkedActiveGameMembership) return;
    _checkedActiveGameMembership = true;
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid == null) return;
    try {
      final membership = await sl.roomRepository.getActiveMembership(uid);
      if (!mounted || membership == null) return;
      final status = membership['status'] as String?;
      if (status != 'in_game' && status != 'paused') return;
      final roomId = membership['room_id'] as String?;
      if (roomId == null) return;
      AppRouter.router.push('${RouteNames.home}/room/$roomId');
    } catch (_) {
      // Non-fatal — the room is still reachable manually via Room Browser.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifCount = context.watch<NotificationProvider>().unreadCount;
    final friendCount = context.watch<FriendsProvider>().pendingCount;
    final isPremium =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;

    return Scaffold(
      body: PlayfulBackground(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.meeting_room_outlined),
            selectedIcon: const Icon(Icons.meeting_room_rounded),
            label: l10n.navRooms,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: friendCount > 0,
              label: Text('$friendCount'),
              child: const Icon(Icons.people_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: friendCount > 0,
              label: Text('$friendCount'),
              child: const Icon(Icons.people_rounded),
            ),
            label: l10n.navFriends,
          ),
          NavigationDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store_rounded),
            label: l10n.navMarketplace,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notifCount > 0,
              label: Text('$notifCount'),
              child: const Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: notifCount > 0,
              label: Text('$notifCount'),
              child: isPremium
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFF5A623), Color(0xFFFF6B35)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_rounded),
            ),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
