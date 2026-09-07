# Graph Report - lib  (2026-07-30)

## Corpus Check
- Large corpus: 167 files · ~1,362,701 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 5763 nodes · 8077 edges · 165 communities (157 shown, 8 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- App Localizations Ar
- App Localizations
- Package Intl Intl
- Core L10n Generated App
- Core Theme App Colors
- Memeloadstate Get
- Todloadstate Get
- Roomentity Get
- String Emoji
- Public
- String Roomid
- Features Packs Domain Pack
- String Userid
- Features Games Truth Or
- Data Pack Upload Service
- Gametype Get
- Static Roomrepository Get
- Pending Underreview Approved
- Audioplayer
- Realtimesubscribestatus
- Community 20
- Socket
- Object
- Apiclient Get
- State
- Bool
- Edgeinsetsgeometry
- Data Friends Repository
- Features Offline Domain Offline
- Static Friendsrepository Get
- Memestate Get
- Static Packrepository Get
- Data Pack Download Manager
- Nhiestate Get
- Deposit Screen
- Features Friends Presentation Friends
- Static Future
- Focusnode
- Widgets Room Card
- Bool Isadmin
- String Label
- App
- Test Main Screen
- Walletentity Get
- Lan Join Screen
- Route Routenames Home
- Todstate Get
- Features Wallet Presentation Screens
- Tickerproviderstatemixin
- Jthemeextension Get
- Int Get
- Offline Play Screen
- Features Premium Presentation Premium
- Globalkey
- User Profile Screen
- String Id Name
- Curve
- Domain Tod Models
- Double
- Lan Host Screen
- Data Notification Repository
- Profile Data Profile Repository
- Gameenginestate Get
- Features Rooms Presentation Widgets
- Size
- Shared Screens Home Shell
- Valuenotifier
- Static Packsyncservice Get
- Session Get
- Statsrow
- Walletcredit Walletdebit Moderation System
- Set
- App Colors
- Size Get
- Map
- Realtimechannel
- Engine Game Registry
- File
- Session
- Static Packdownloadmanager Get
- Tabcontroller
- Sticker
- Bool Selected
- Database
- Package Uuid Uuid
- Double Min
- Class
- Formstate
- Core Router Route Names
- Core Theme J Theme
- Shared Widgets Cards User
- Static Const List
- Features Rooms Presentation Screens
- Scrollcontroller
- Preferredsizewidget
- Exception
- Sharedpreferences
- List
- Texteditingcontroller
- Features Packs Presentation Widgets
- Bool Get
- Color
- Core Errors Failures
- Static Roomcacheservice Get
- Convert
- Database Get
- Route Routenames Authemail
- Main
- String
- Failure Get
- Shared Screens Home Shell
- Shared Widgets Game Rules
- Features Games Engine Base
- Get
- Profile Provider
- Textinputformatter
- Router App Router
- Features Wallet Presentation Widgets
- Core Network Api Client
- Static Const Int
- T
- Dio
- Static Connectivityservice Get
- Static Securestorageservice Get
- Stream
- Int
- Features Rooms Presentation Widgets
- Bool Isselected
- Locale
- Static Imagecacheservice Get
- Duration
- Shared Widgets Join Requests
- Core Data Base Repository
- Timer
- Static Const String
- Equatable
- Buttons J Button
- Static Final
- Static Const
- Math
- Animationcontroller
- Data Offline Game Provider
- Core Data Base Repository
- Shared Widgets Room Members
- Failures
- Typed Data
- Route Creator
- App Logger
- Localizationsdelegate
- Custompainter
- Base Game Engine
- Route Profile Edit
- Features Games Engine Base
- Themeextension
- Buildcontext
- Features Auth Presentation Screens
- Features Auth Presentation Screens
- Features Avatar Presentation Avatar
- Friend Tile
- Features Games Truth Or
- Features Games Truth Or
- Review Sheet
- Transaction Tile

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 128 edges
2. `VoidCallback` - 46 edges
3. `PackProvider` - 34 edges
4. `WalletProvider` - 23 edges
5. `AppThemeService` - 20 edges
6. `RoomProvider` - 20 edges
7. `Failure` - 19 edges
8. `GameEngineEvent` - 19 edges
9. `FriendsProvider` - 16 edges
10. `OfflineGameProvider` - 14 edges

## Surprising Connections (you probably didn't know these)
- `didChangeDependencies` --references--> `AuthProvider`  [EXTRACTED]
  app.dart → core/providers/auth_provider.dart
- `_submit` --references--> `AuthProvider`  [EXTRACTED]
  features/auth/presentation/screens/onboarding_screen.dart → core/providers/auth_provider.dart
- `_resend` --references--> `AuthProvider`  [EXTRACTED]
  features/auth/presentation/screens/otp_screen.dart → core/providers/auth_provider.dart
- `_submit` --references--> `AuthProvider`  [EXTRACTED]
  features/auth/presentation/screens/otp_screen.dart → core/providers/auth_provider.dart
- `initState` --references--> `AuthProvider`  [EXTRACTED]
  features/auth/presentation/screens/splash_screen.dart → core/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (165 total, 8 thin omitted)

### Community 0 - "App Localizations Ar"
Cohesion: 0.01
Nodes (170): app_localizations_ar.dart, app_localizations_en.dart, app_localizations_fr.dart, appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired (+162 more)

### Community 1 - "App Localizations"
Cohesion: 0.01
Nodes (158): app_localizations.dart, appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired, authOtpHint, authOtpInvalid (+150 more)

### Community 2 - "Package Intl Intl"
Cohesion: 0.01
Nodes (158): appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired, authOtpHint, authOtpInvalid, authOtpLabel (+150 more)

### Community 3 - "Core L10n Generated App"
Cohesion: 0.01
Nodes (157): appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired, authOtpHint, authOtpInvalid, authOtpLabel (+149 more)

### Community 4 - "Core Theme App Colors"
Cohesion: 0.02
Nodes (126): amberOrangeLight, AppColors, AppCurves, AppDuration, AppRadius, AppShadows, AppSpacing, avatar (+118 more)

### Community 5 - "Memeloadstate Get"
Cohesion: 0.02
Nodes (122): activePlayerCount, _advancing, applyOwnershipChange, asset, assetPath, _autoFillAwayPlayers, _autoFilling, _awayPlayerIds (+114 more)

### Community 6 - "Todloadstate Get"
Cohesion: 0.02
Nodes (116): activePlayerCount, addChatMessage, _advancing, applyOwnershipChange, _awayPlayerIds, banPlayerFromGame, broadcastActivity, _broadcastState (+108 more)

### Community 7 - "Roomentity Get"
Cohesion: 0.02
Nodes (111): connected,
  reconnecting,
  recovering,
  pendingApproval,, ../../../core/services/subscription_service.dart, activeMembers, banPlayer, _cache, canAcceptJoins, canAcceptRejoins, canAdvanceTurn (+103 more)

### Community 8 - "String Emoji"
Cohesion: 0.02
Nodes (111): accentColor, action, actionType, _ActiveGameBody, _AppPatternBg, asset, autoAdvance, b64 (+103 more)

### Community 9 - "Public"
Cohesion: 0.02
Nodes (108): acceptJoins, acceptRejoins, acceptSpectators, actorId, advanceTurn, all, allowAnonymousSpectators, allowSkip (+100 more)

### Community 10 - "String Roomid"
Cohesion: 0.02
Nodes (100): ../../data/room_repository.dart, RoomConnectionState, _ActionBtn, allowAnonymous, _banConfirm, _banned, _checkStatus, code (+92 more)

### Community 11 - "Features Packs Domain Pack"
Cohesion: 0.02
Nodes (100): allowSpicy, archived, authorAvatarUrl, authorName, availableLanguages, avgRating, canPublish, cardCount (+92 more)

### Community 12 - "String Userid"
Cohesion: 0.02
Nodes (97): activePlayerCount, _advancing, applyOwnershipChange, _autoFillAwayPlayers, _awayPlayerIds, banPlayerFromGame, _broadcastState, _buildContent (+89 more)

### Community 13 - "Features Games Truth Or"
Cohesion: 0.02
Nodes (94): allowSpectators, canView, card, cardType, completedDares, completedTruths, content, copyWith (+86 more)

### Community 14 - "Data Pack Upload Service"
Cohesion: 0.03
Nodes (86): ../../data/pack_upload_service.dart, CardDifficulty, CardType, PackDraft, _activeSteps, _add, _arCtrl, _AudienceStep (+78 more)

### Community 15 - "Gametype Get"
Cohesion: 0.02
Nodes (84): _addChat, advanceTurn, _broadcastState, _chatMessages, clearUnreadChat, _clientEngineReady, _clientPlayerId, _clientPlayerName (+76 more)

### Community 16 - "Static Roomrepository Get"
Cohesion: 0.03
Nodes (77): _api, banMember, _chatRowToEntity, claimRoomOwnership, clearPack, clearReturnTimer, createRoom, decideGameRejoinRequest (+69 more)

### Community 17 - "Pending Underreview Approved"
Cohesion: 0.03
Nodes (73): commission, payout, adjustment, bonus,, absAmount, accountName, accountNumber, amountMru, approvedAt, availableFormatted, availableForWithdrawalMru (+65 more)

### Community 18 - "Audioplayer"
Cohesion: 0.03
Nodes (72): AudioPlayer?, ../../../../avatar/presentation/avatar_creator_screen.dart, TodCard, TodCardType, TodDifficulty, TodProofViewMode, activity, _alreadyViewed (+64 more)

### Community 19 - "Realtimesubscribestatus"
Cohesion: 0.03
Nodes (72): avatarUrl, _bcast, broadcastChat, broadcastGameEnded, broadcastGameStarted, broadcastGameState, BroadcastHandler, broadcastModeration (+64 more)

### Community 20 - "Community 20"
Cohesion: 0.03
Nodes (65): >, AvatarConfig get, _accessories, accessoriesType, AvatarConfig, AvatarDisplay, avatarReactionKey, avatarUrl (+57 more)

### Community 21 - "Socket"
Cohesion: 0.03
Nodes (65): address, _advertisingTimer, broadcastGameState, broadcastLobbyUpdate, broadcastMessage, broadcastMessageExcept, broadcastStartGame, _cleanup (+57 more)

### Community 22 - "Object"
Cohesion: 0.03
Nodes (62): ../../../../core/services/image_cache_service.dart, ../../domain/pack_entity.dart, PackDownloadManager, PackDownloadState, PackEntity, PackPurchase, build, dlState (+54 more)

### Community 23 - "Apiclient Get"
Cohesion: 0.03
Nodes (61): ApiClient get, AuthRepository get, ConnectivityService get, apiClient, authRepository, connectivityService, friendsRepository, imageCacheService (+53 more)

### Community 24 - "State"
Cohesion: 0.05
Nodes (60): _AmountStep, _GameOverScreen, _GameOverScreenState, _HiddenReactionCard, _HiddenReactionCardState, MemeGameScreen, _MemeGameScreenState, _MemeNhiePausedOverlay (+52 more)

### Community 25 - "Bool"
Cohesion: 0.03
Nodes (59): bool?, ../../../../../core/utils/game_end_navigation.dart, data/tod_repository.dart, config, createState, _ctrl, displayNames, dispose (+51 more)

### Community 26 - "Edgeinsetsgeometry"
Cohesion: 0.03
Nodes (57): EdgeInsetsGeometry?, package:shimmer/shimmer.dart, action, avatarUrls, avgRating, badge, borderColor, borderWidth (+49 more)

### Community 27 - "Data Friends Repository"
Cohesion: 0.04
Nodes (49): ../../../core/services/presence_service.dart, UserPresenceStatus, ../../data/friends_repository.dart, FriendEntity, build, _color, friend, FriendTile (+41 more)

### Community 28 - "Features Offline Domain Offline"
Cohesion: 0.04
Nodes (52): advertisedAt, allowSkip, allowSpicy, cardCount, config, copyWith, copyWithPlayers, coverImageUrl (+44 more)

### Community 29 - "Static Friendsrepository Get"
Cohesion: 0.04
Nodes (51): avatarConfig, avatarUrl, bio, blockUser, cancelRequest, canInteract, _checkNotBlocked, displayName (+43 more)

### Community 30 - "Memestate Get"
Cohesion: 0.04
Nodes (51): advanceTurn, caption, _config, copyWith, currentPrompt, currentState, emoji, EmojiReaction (+43 more)

### Community 31 - "Static Packrepository Get"
Cohesion: 0.04
Nodes (50): addCards, _api, browsePacks, code, createPackDraft, deleteCard, getAvailableLanguages, getCardLanguageCoverage (+42 more)

### Community 32 - "Data Pack Download Manager"
Cohesion: 0.04
Nodes (47): ../../../core/services/pack_sync_service.dart, ../data/pack_download_manager.dart, allDownloadedPackIds, allPacks, _browsePacks, _browsePage, _categories, _createdPacks (+39 more)

### Community 33 - "Nhiestate Get"
Cohesion: 0.04
Nodes (47): advanceTurn, card, _cards, _config, content, copyWith, currentCard, currentPlayerId (+39 more)

### Community 34 - "Deposit Screen"
Cohesion: 0.05
Nodes (43): deposit_screen.dart, earnings_screen.dart, TransactionType, build, _BulletItem, color, createState, _EarningStatCard (+35 more)

### Community 35 - "Features Friends Presentation Friends"
Cohesion: 0.04
Nodes (44): acceptRequest, _blockedUsers, blockUser, cancelRequest, clearSearch, dispose, _followers, _following (+36 more)

### Community 36 - "Static Future"
Cohesion: 0.05
Nodes (40): AppRouter, createRouter, _instance, isReady, ready, _readyCompleter, rootKey, ../../features/auth/presentation/screens/email_screen.dart (+32 more)

### Community 37 - "Focusnode"
Cohesion: 0.05
Nodes (39): _attemptsRemaining, build, child, _clearAll, _complete, controller, _controllers, _cooldown (+31 more)

### Community 38 - "Widgets Room Card"
Cohesion: 0.05
Nodes (38): closed_rooms_screen.dart, routeFromPayload, ../../data/room_cache_service.dart, purchase, _autoRefreshTimer, build, _buildBody, _createRoom (+30 more)

### Community 39 - "Bool Isadmin"
Cohesion: 0.05
Nodes (37): bool isAdmin,, TodPunishment, TodPunishmentVoteState, build, canPick, createState, _ctrl, displayNames (+29 more)

### Community 40 - "String Label"
Cohesion: 0.06
Nodes (37): SocialProfile, FriendsProvider, _FriendsTab, _openProfile, _act, _BlockedBanner, build, createState (+29 more)

### Community 41 - "App"
Cohesion: 0.07
Nodes (35): _AppShell, _AppShellState, build, child, createState, didChangeDependencies, initState, Jma3aApp (+27 more)

### Community 42 - "Test Main Screen"
Cohesion: 0.06
Nodes (33): ../../../core/extensions/context_ext.dart, create_pack_screen.dart, build, color, createState, _CreatorPackRow, _EmptyCreator, icon (+25 more)

### Community 43 - "Walletentity Get"
Cohesion: 0.06
Nodes (35): EarningsSummary? get, _balanceChannel, balanceMru, canAfford, _depositMethods, dispose, _earnings, earningsBalanceMru (+27 more)

### Community 44 - "Lan Join Screen"
Cohesion: 0.06
Nodes (35): build, _Bullet, canHost, _checking, _checkState, color, createState, dispose (+27 more)

### Community 45 - "Route Routenames Home"
Cohesion: 0.07
Nodes (35): AuthProvider, _enterGuestMode, _submit, _enterGuestMode, _submit, build, build, initState (+27 more)

### Community 46 - "Todstate Get"
Cohesion: 0.06
Nodes (34): advanceTurn, _buildQueue, _config, currentState, _deck, _draw, handleEvent, init (+26 more)

### Community 47 - "Features Wallet Presentation Screens"
Cohesion: 0.06
Nodes (34): _amount, _amountCtrl, build, createState, DepositScreen, _DepositScreenState, dispose, _formKey (+26 more)

### Community 48 - "Tickerproviderstatemixin"
Cohesion: 0.06
Nodes (34): _buildParticles, _builtFor, child, color, createState, _ctrl, dispose, _drawBubble (+26 more)

### Community 49 - "Jthemeextension Get"
Cohesion: 0.06
Nodes (33): copyWith, dareCardBg, dareCardFg, dark, frozenOverlay, gameProgressActive, gameProgressBg, inGameDot (+25 more)

### Community 50 - "Int Get"
Cohesion: 0.06
Nodes (33): age, avatarConfig, avatarUrl, bio, canChangeUsername, copyWith, countryCode, createdAt (+25 more)

### Community 51 - "Offline Play Screen"
Cohesion: 0.07
Nodes (33): OfflineGameProvider, build, config, createState, dispose, gameType, hostName, initState (+25 more)

### Community 52 - "Features Premium Presentation Premium"
Cohesion: 0.06
Nodes (33): _accent, _ActiveBanner, build, _cell, createState, _dataRow, _FeatureTable, _gold (+25 more)

### Community 53 - "Globalkey"
Cohesion: 0.06
Nodes (32): _AmountStepState, _amountCtrl, amountMru, build, _ConfirmRow, _ConfirmStep, createState, dispose (+24 more)

### Community 54 - "User Profile Screen"
Cohesion: 0.06
Nodes (32): _Badge, _BlockedTab, build, color, controller, count, createState, dispose (+24 more)

### Community 55 - "String Id Name"
Cohesion: 0.06
Nodes (31): AppThemeData get, allThemes, availableFor, BackgroundMotif, buildTheme, clearPreviewBackground, current, _currentId (+23 more)

### Community 56 - "Curve"
Cohesion: 0.06
Nodes (31): Color yesColor,, Curve, int yesCount,, Offset, package:jma3a/core/theme/app_colors.dart, _anim, build, createState (+23 more)

### Community 57 - "Domain Tod Models"
Cohesion: 0.07
Nodes (29): ../../../core/theme/app_colors.dart, domain/tod_models.dart, TodPlayerScore, build, displayName, displayNames, _endLabel, icon (+21 more)

### Community 58 - "Double"
Cohesion: 0.06
Nodes (31): ../../../core/theme/app_text_styles.dart, double?, int count,, int round,, activeColor, activeIndex, avatarUrl, build (+23 more)

### Community 59 - "Lan Host Screen"
Cohesion: 0.06
Nodes (30): ../../data/offline_repository.dart, OfflineMode, _addPlayer, _allowSkip, _allowSpicy, build, createState, dispose (+22 more)

### Community 60 - "Data Notification Repository"
Cohesion: 0.06
Nodes (30): ../data/notification_repository.dart, _cdcChannel, clearAllToasts, deleteNotification, dismissToast, dispose, _enqueueToast, _hasMore (+22 more)

### Community 61 - "Profile Data Profile Repository"
Cohesion: 0.07
Nodes (30): build, _buildUsernameSuffix, _checkUsernameAvailability, createState, _debounce, _displayNameCtrl, dispose, _formKey (+22 more)

### Community 62 - "Gameenginestate Get"
Cohesion: 0.06
Nodes (30): advanceTurn, allowSkip, allowSpicy, currentState, displayName, enablePunishments, fromMap, handleEvent (+22 more)

### Community 63 - "Features Rooms Presentation Widgets"
Cohesion: 0.07
Nodes (30): ChatMessageEntity, _ChatEntityX, build, _ChatBubble, ChatPanel, _ChatPanelState, createState, _ctrl (+22 more)

### Community 64 - "Size"
Cohesion: 0.07
Nodes (29): Animation, package:jma3a/core/theme/app_text_styles.dart, build, color, createState, _ctrl, disabled, dispose (+21 more)

### Community 65 - "Shared Screens Home Shell"
Cohesion: 0.08
Nodes (29): BaseProvider, ../../../../core/services/notification_service.dart, NotificationEntity, NotificationPreference, NotificationProvider, build, createState, _decline (+21 more)

### Community 66 - "Valuenotifier"
Cohesion: 0.09
Nodes (28): AppThemeService, BackgroundColorScreen, _BackgroundColorScreenState, _BackgroundOption, _backgroundPalette, _BackgroundPreviewMockup, _blend, build (+20 more)

### Community 67 - "Static Packsyncservice Get"
Cohesion: 0.07
Nodes (28): _cachePurchaseRecords, complete, current, dispose, _downloader, _fetchActivePurchases, fraction, getDownloadedPackIds (+20 more)

### Community 68 - "Session Get"
Cohesion: 0.07
Nodes (27): _authRepository, _authStateSubscription, clearError, _currentUser, dispose, enterGuestMode, _error, exitGuestMode (+19 more)

### Community 69 - "Statsrow"
Cohesion: 0.08
Nodes (27): AvatarService, ../../../../features/packs/data/pack_repository.dart, ../../../../features/packs/domain/pack_entity.dart, _createdPacks, createState, didChangeDependencies, _fetch, _friends (+19 more)

### Community 70 - "Walletcredit Walletdebit Moderation System"
Cohesion: 0.07
Nodes (27): achievement, body, bodyFor, bodyJson, copyWith, createdAt, data, dbString (+19 more)

### Community 71 - "Set"
Cohesion: 0.08
Nodes (27): Set, AnimatedReactionOverlay, _AnimatedReactionOverlayState, build, _burstTimers, createState, didUpdateWidget, dispose (+19 more)

### Community 72 - "App Colors"
Cohesion: 0.07
Nodes (26): app_colors.dart, app_text_styles.dart, AppTheme, _build, container, containerHigh, containerHighest, containerLow (+18 more)

### Community 73 - "Size Get"
Cohesion: 0.07
Nodes (26): AppLocalizations get, ColorScheme get, colorScheme, isDarkMode, isLandscape, isRTL, l10n, padding (+18 more)

### Community 74 - "Map"
Cohesion: 0.07
Nodes (26): ChangeNotifier, ConnectivityProvider, GameEngineState, MemeState, NhieState, GameProvider, MemeGameProvider, NhieGameProvider (+18 more)

### Community 75 - "Realtimechannel"
Cohesion: 0.07
Nodes (26): _channel, _currentUserId, _emitCurrentState, fromMap, _heartbeatTimer, _instance, _presenceController, PresenceService (+18 more)

### Community 76 - "Engine Game Registry"
Cohesion: 0.07
Nodes (26): ../../../core/services/realtime_service.dart, RealtimeService, ../engine/game_registry.dart, advanceTurn, _broadcastCurrentState, completeTurn, _currentUserId, dispose (+18 more)

### Community 77 - "File"
Cohesion: 0.08
Nodes (26): _bioCtrl, build, _countries, createState, _displayNameCtrl, dispose, EditProfileScreen, _EditProfileScreenState (+18 more)

### Community 78 - "Session"
Cohesion: 0.08
Nodes (25): AuthChangeEvent, ../../../core/storage/local_storage_service.dart, ../../../core/storage/secure_storage_service.dart, ../domain/entities/user_entity.dart, _api, AuthStateChangeEvent, authStateStream, clearPendingOtpEmail (+17 more)

### Community 79 - "Static Packdownloadmanager Get"
Cohesion: 0.08
Nodes (25): _active, _db, deleteDownload, deleteExpiredDownloads, _doDownload, download, _downloadImage, _downloadImages (+17 more)

### Community 80 - "Tabcontroller"
Cohesion: 0.08
Nodes (25): _BrowseTab, _categoryFilter, createState, dispose, _FeaturedTab, _FilterChip, _FilterRow, _freeOnly (+17 more)

### Community 81 - "Sticker"
Cohesion: 0.08
Nodes (25): alreadyReacted, assetPath, avatarConfig, avatarConfigByValue, build, customUrls, EmojiReactionRow, kEmojiReactions (+17 more)

### Community 82 - "Bool Selected"
Cohesion: 0.08
Nodes (24): bool selected,, RoomVisibility, _allowSpectators, build, _create, CreateRoomSheet, _CreateRoomSheetState, createState (+16 more)

### Community 83 - "Database"
Cohesion: 0.08
Nodes (24): AppDatabase, close, _db, _dbName, _dbVersion, instance, isOpen, _migration001 (+16 more)

### Community 84 - "Package Uuid Uuid"
Cohesion: 0.08
Nodes (24): ../domain/wallet_entity.dart, _api, getEarningsSummary, getMyDeposits, getMyWithdrawals, getPaymentMethodForTransaction, getPaymentMethods, getTransactions (+16 more)

### Community 85 - "Double Min"
Cohesion: 0.08
Nodes (24): double min,, build, _cardLanguages, createState, display, divisions, _flagEmoji, GameSettingsSheet (+16 more)

### Community 86 - "Class"
Cohesion: 0.09
Nodes (22): class, DateTime?, build, createState, _error, _formatTs, initState, isCurrent (+14 more)

### Community 87 - "Formstate"
Cohesion: 0.10
Nodes (21): ../../core/providers/auth_provider.dart, ../../core/router/route_names.dart, _BrandHeader, build, createState, dispose, _emailCtrl, _emailFocus (+13 more)

### Community 88 - "Core Router Route Names"
Cohesion: 0.09
Nodes (22): authEmail, authOtp, authPhone, avatarCreator, avatarPicker, backgroundColor, friends, home (+14 more)

### Community 89 - "Core Theme J Theme"
Cohesion: 0.09
Nodes (22): ../../../core/theme/j_theme_extension.dart, avatarUrl, body, build, emoji, isMe, isOptimistic, isRead (+14 more)

### Community 90 - "Shared Widgets Cards User"
Cohesion: 0.09
Nodes (22): ../../../features/avatar/presentation/avatar_creator_screen.dart, package:flutter_svg/flutter_svg.dart, avatarConfig, AvatarStack, avatarUrl, avatarUrls, borderColor, borderWidth (+14 more)

### Community 91 - "Static Const List"
Cohesion: 0.09
Nodes (22): allAvatars, availableFor, avatar, AvatarPickerScreen, _AvatarTile, build, emoji, id (+14 more)

### Community 92 - "Features Rooms Presentation Screens"
Cohesion: 0.09
Nodes (22): _buildContent, child, ClosedRoomDetailScreen, _ClosedRoomDetailScreenState, ClosedRoomsScreen, _ClosedRoomsScreenState, createState, _details (+14 more)

### Community 93 - "Scrollcontroller"
Cohesion: 0.10
Nodes (21): ../../data/wallet_repository.dart, WalletTransaction, build, context, createState, _DetailRow, _formatDateTime, initState (+13 more)

### Community 94 - "Preferredsizewidget"
Cohesion: 0.10
Nodes (22): PackProvider, build, _saveDraft, initState, _onScroll, build, _load, _showReportSheet (+14 more)

### Community 95 - "Exception"
Cohesion: 0.10
Nodes (20): apiBaseUrl, apiTimeout, AppConfig, AppConfigException, AppEnvironment, isDevelopment, isProduction, message (+12 more)

### Community 96 - "Sharedpreferences"
Cohesion: 0.10
Nodes (20): clear, containsKey, getBool, getDouble, getInt, getString, getStringList, initialize (+12 more)

### Community 97 - "List"
Cohesion: 0.10
Nodes (19): domain, EmailAddress, localPart, props, _regex, toString, tryParse, value (+11 more)

### Community 98 - "Texteditingcontroller"
Cohesion: 0.10
Nodes (20): build, _cityAutocompleteCtrl, createState, dispose, _formKey, initState, _kCities, _loadingPrice (+12 more)

### Community 99 - "Features Packs Presentation Widgets"
Cohesion: 0.11
Nodes (20): build, createState, _ctrl, _detailsCtrl, dispose, _hover, initState, _isSubmitting (+12 more)

### Community 100 - "Bool Get"
Cohesion: 0.11
Nodes (18): bool get, currentUserId, initialize, isAuthenticated, SupabaseClientConfig, SupabaseExtensions, clearError, _currentUserId (+10 more)

### Community 101 - "Color"
Cohesion: 0.10
Nodes (18): Color, build, icon, iconColor, isSuccess, subtitle, title, TransactionStatusScreen (+10 more)

### Community 102 - "Core Errors Failures"
Cohesion: 0.16
Nodes (19): AuthFailure, code, ConflictFailure, Failure, field, ForbiddenFailure, message, NetworkFailure (+11 more)

### Community 103 - "Static Roomcacheservice Get"
Cohesion: 0.10
Nodes (19): ../../../../core/storage/database/app_database.dart, appendChatMessage, cacheChatMessages, cacheRooms, _chatToMap, clearRoomCache, _ensureTables, getCachedChatMessages (+11 more)

### Community 104 - "Convert"
Cohesion: 0.10
Nodes (19): dart:convert, ../engine/base_game_engine.dart, addCustomCard, completeSession, createSession, deleteCustomCard, findActiveSession, findLatestSession (+11 more)

### Community 105 - "Database Get"
Cohesion: 0.10
Nodes (19): Database get, ../domain/offline_session.dart, _db, endSession, getActiveSession, getAvailablePackCount, getAvailablePacks, getRecentSessions (+11 more)

### Community 106 - "Route Routenames Authemail"
Cohesion: 0.11
Nodes (19): build, build, _checkAndNavigate, color, createState, _Dot, _Glow, _hasNavigated (+11 more)

### Community 107 - "Main"
Cohesion: 0.11
Nodes (17): app.dart, core/utils/app_logger.dart, dart:io, ../../data/pack_repository.dart, _instance, PackUploadService, _repo, _upload (+9 more)

### Community 108 - "String"
Cohesion: 0.11
Nodes (18): Color get, StringExt, badgeSize, build, child, _color, gap, _goldColor (+10 more)

### Community 109 - "Failure Get"
Cohesion: 0.11
Nodes (18): ../../../core/providers/base_provider.dart, ../data/profile_repository.dart, Failure? get, _authProvider, clearLastFailure, _isChangingUsername, _isSaving, _isUploadingAvatar (+10 more)

### Community 110 - "Shared Screens Home Shell"
Cohesion: 0.11
Nodes (18): ../../features/friends/presentation/friends_provider.dart, ../../features/friends/presentation/screens/friends_screen.dart, ../../features/notifications/presentation/notification_provider.dart, ../../features/notifications/presentation/widgets/in_app_toast_overlay.dart, ../../features/packs/presentation/pack_provider.dart, ../../features/packs/presentation/screens/marketplace_screen.dart, ../../features/profile/presentation/screens/profile_screen.dart, ../../features/rooms/presentation/screens/room_browser_screen.dart (+10 more)

### Community 111 - "Shared Widgets Game Rules"
Cohesion: 0.11
Nodes (18): ../../features/games/engine/base_game_engine.dart, GameConfig, GameType, RoomSettingsEntity, body, build, config, context (+10 more)

### Community 112 - "Features Games Engine Base"
Cohesion: 0.11
Nodes (19): GameEngineEvent, MemeReactEvent, MemeSubmitEvent, MemeVoteEvent, NhieReactionEvent, NhieVoteEvent, TodCastProofVoteEvent, TodChoiceEvent (+11 more)

### Community 113 - "Get"
Cohesion: 0.11
Nodes (18): build, colorScheme, compact, _DownloadCta, _DownloadedCta, _DownloadProgress, errorMessage, _FailedCta (+10 more)

### Community 114 - "Profile Provider"
Cohesion: 0.11
Nodes (18): build, _buildSuffix, ChangeUsernameScreen, _ChangeUsernameScreenState, _checkState, createState, _debounce, dispose (+10 more)

### Community 115 - "Textinputformatter"
Cohesion: 0.12
Nodes (17): ../../core/di/service_locator.dart, build, createState, _ctrl, dispose, _error, formatEditUpdate, initState (+9 more)

### Community 116 - "Router App Router"
Cohesion: 0.11
Nodes (17): _handleForeground, _handleRoomInviteTap, _handleTap, initialize, _instance, logout, NotificationService, setExternalUserId (+9 more)

### Community 117 - "Features Wallet Presentation Widgets"
Cohesion: 0.11
Nodes (17): PaymentMethodEntity, build, color, compact, _FallbackIcon, _formatDate, isSelected, label (+9 more)

### Community 118 - "Core Network Api Client"
Cohesion: 0.12
Nodes (16): ../../auth/domain/entities/user_entity.dart, ../../../core/network/api_client.dart, _api, changeUsername, createOrUpdateProfile, getProfile, getProfileByUsername, _instance (+8 more)

### Community 119 - "Static Const Int"
Cohesion: 0.12
Nodes (16): AppConstants, bioMaxLength, chatMaxLength, maxPackCards, maxRoomPlayers, minPackCards, minWithdrawalMru, otpLength (+8 more)

### Community 120 - "T"
Cohesion: 0.12
Nodes (15): _connectivity, dispose, isOffline, _isOnline, _onConnectivityChanged, _service, _subscription, ConnectivityService (+7 more)

### Community 121 - "Dio"
Cohesion: 0.13
Nodes (15): ../config/app_config.dart, ApiClient, _AuthInterceptor, _dio, initialize, _instance, _LoggingInterceptor, onError (+7 more)

### Community 122 - "Static Connectivityservice Get"
Cohesion: 0.12
Nodes (15): _canReach, _connectivity, connectivityStream, _controller, _debounceTimer, dispose, _hasInterface, _init (+7 more)

### Community 123 - "Static Securestorageservice Get"
Cohesion: 0.12
Nodes (15): containsKey, delete, deleteAll, _instance, pendingOtpEmail, read, SecureKeys, SecureStorageService (+7 more)

### Community 124 - "Stream"
Cohesion: 0.12
Nodes (15): _appLinks, code, _ctrl, DeepLinkService, dispose, _handle, init, instance (+7 more)

### Community 125 - "Int"
Cohesion: 0.12
Nodes (15): dispose, _durationSeconds, _instance, isRunning, _onExpired, start, _startedAtMs, stop (+7 more)

### Community 126 - "Features Rooms Presentation Widgets"
Cohesion: 0.12
Nodes (15): RoomMemberEntity, build, canModerate, isCurrentUser, isOwner, isReady, member, MemberTile (+7 more)

### Community 127 - "Bool Isselected"
Cohesion: 0.13
Nodes (14): bool isSelected,, ../../core/router/app_router.dart, AppThemeData, _BackgroundColorTile, currentHex, currentId, data, isPremium (+6 more)

### Community 128 - "Locale"
Cohesion: 0.13
Nodes (14): initialize, _Keys, _locale, setLocale, setThemeMode, _storage, _supportedLocales, _themeMode (+6 more)

### Community 129 - "Static Imagecacheservice Get"
Cohesion: 0.13
Nodes (14): avatar, _avatarPlaceholder, _avatarShimmer, _cacheKey, configure, ImageCacheService, _instance, packCover (+6 more)

### Community 130 - "Duration"
Cohesion: 0.14
Nodes (14): ../../domain/room_entity.dart, Duration, BanConfirmSheet, _BanConfirmSheetState, build, createState, dispose, _duration (+6 more)

### Community 131 - "Shared Widgets Join Requests"
Cohesion: 0.14
Nodes (14): build, createState, dispose, inGame, initState, JoinRequestsPanel, _JoinRequestsPanelState, _load (+6 more)

### Community 132 - "Core Data Base Repository"
Cohesion: 0.14
Nodes (13): ../../../core/data/base_repository.dart, ../../domain/notification_entity.dart, deleteNotification, getNotifications, getPreferences, _instance, markAllRead, markRead (+5 more)

### Community 133 - "Timer"
Cohesion: 0.14
Nodes (13): _expiryCheckTimer, getActiveSubscription, instance, isCachedPremium, isPremiumActive, maxProofReplays, startExpiryCheck, stopExpiryCheck (+5 more)

### Community 134 - "Static Const String"
Cohesion: 0.14
Nodes (13): AppTextStyles, _arabicFamily, familyForLocale, gameCardContent, gameChoiceLabel, hudLabel, _latinFamily, playerName (+5 more)

### Community 135 - "Equatable"
Cohesion: 0.14
Nodes (14): Equatable, UserEntity, LanRoomDescriptor, OfflinePack, OfflinePlayer, OfflineSession, PackCardEntity, PackCategory (+6 more)

### Community 136 - "Buttons J Button"
Cohesion: 0.17
Nodes (11): ../buttons/j_button.dart, ../../../core/errors/failures.dart, build, compact, _CompactError, ErrorView, failure, _iconForFailure (+3 more)

### Community 137 - "Static Final"
Cohesion: 0.17
Nodes (11): AppLogger, debug, error, fatal, info, _logger, _logLevel, warning (+3 more)

### Community 138 - "Static Const"
Cohesion: 0.18
Nodes (10): @pragma, _channelKey, initialize, instance, LocalNotificationService, _onAction, show, package:awesome_notifications/awesome_notifications.dart (+2 more)

### Community 139 - "Math"
Cohesion: 0.18
Nodes (10): dart:math, double get, build, color, paint, _progress, remaining, shouldRepaint (+2 more)

### Community 140 - "Animationcontroller"
Cohesion: 0.22
Nodes (9): AnimationController, build, createState, dispose, initState, playerName, _pulse, TodWaitingOverlay (+1 more)

### Community 141 - "Data Offline Game Provider"
Cohesion: 0.20
Nodes (9): ../../data/offline_game_provider.dart, build, game, OfflineHud, session, state, _TurnDots, ../../../games/truth_or_dare/domain/tod_models.dart (+1 more)

### Community 142 - "Core Data Base Repository"
Cohesion: 0.22
Nodes (9): BaseRepository, AuthRepository, FriendsRepository, TodRepository, NotificationRepository, PackRepository, ProfileRepository, RoomRepository (+1 more)

### Community 143 - "Shared Widgets Room Members"
Cohesion: 0.22
Nodes (8): ../../features/rooms/presentation/room_provider.dart, build, heroTag, RoomMembersFab, RoomMembersManagementSheet, roomProvider, _statusColor, _statusOf

### Community 144 - "Failures"
Cohesion: 0.25
Nodes (7): ErrorHandler, handle, _handleAuthException, _handleDioException, _handlePostgrestException, failures.dart, package:supabase_flutter/supabase_flutter.dart

### Community 145 - "Typed Data"
Cohesion: 0.25
Nodes (7): instance, MediaUploadService, uploadProofMedia, dart:typed_data, package:dio/dio.dart, static final MediaUploadService, ../utils/app_logger.dart

### Community 146 - "Route Creator"
Cohesion: 0.25
Nodes (8): _goToSetup, _resumeSession, _showLanOptions, build, build, build, MaterialPageRoute, Route /creator

### Community 147 - "App Logger"
Cohesion: 0.29
Nodes (6): app_logger.dart, goToLobbyOrHome, roomExists, ../di/service_locator.dart, ../../features/rooms/domain/room_entity.dart, ../router/route_names.dart

### Community 148 - "Localizationsdelegate"
Cohesion: 0.33
Nodes (7): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsAr, AppLocalizationsEn, AppLocalizationsFr, of, LocalizationsDelegate

### Community 149 - "Custompainter"
Cohesion: 0.29
Nodes (7): CustomPainter, _Jma3aMarkPainter, _CardShimmerPainter, _RingPainter, _CardShimmerPainter, _PatternPainter, _MotifPainter

### Community 150 - "Base Game Engine"
Cohesion: 0.33
Nodes (5): base_game_engine.dart, gameRegistry, ../meme_game/meme_game_engine.dart, ../never_have_i_ever/never_have_i_ever_engine.dart, ../truth_or_dare/truth_or_dare_engine.dart

### Community 151 - "Route Profile Edit"
Cohesion: 0.40
Nodes (5): build, Route /profile/edit, RouteNames.avatarCreator, RouteNames.settings, RouteNames.themePicker

### Community 152 - "Features Games Engine Base"
Cohesion: 0.50
Nodes (4): BaseGameEngine, MemeGameEngine, NeverHaveIEverEngine, TruthOrDareEngine

### Community 153 - "Themeextension"
Cohesion: 1.00
Nodes (3): @immutable, JThemeExtension, ThemeExtension

### Community 154 - "Buildcontext"
Cohesion: 0.67
Nodes (3): BuildContext, ContextExt, JThemeExt

## Knowledge Gaps
- **4320 isolated node(s):** `kStickerAssets`, `kEmojiReactions`, `assetPath`, `size`, `selected` (+4315 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `Route Routenames Home` to `Memeloadstate Get`, `String Roomid`, `String Userid`, `Audioplayer`, `Route Creator`, `Community 20`, `Object`, `Route Profile Edit`, `State`, `Bool`, `Features Auth Presentation Screens`, `Features Avatar Presentation Avatar`, `Static Future`, `Focusnode`, `Widgets Room Card`, `App`, `Lan Join Screen`, `Tickerproviderstatemixin`, `Features Premium Presentation Premium`, `Profile Data Profile Repository`, `Features Rooms Presentation Widgets`, `Shared Screens Home Shell`, `Session Get`, `Statsrow`, `Map`, `File`, `Tabcontroller`, `Bool Selected`, `Formstate`, `Static Const List`, `Preferredsizewidget`, `Route Routenames Authemail`, `Failure Get`, `Shared Screens Home Shell`, `Profile Provider`, `Textinputformatter`, `Bool Isselected`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Why does `VoidCallback` connect `Data Friends Repository` to `Memeloadstate Get`, `String Emoji`, `Buttons J Button`, `String Roomid`, `String Userid`, `Data Pack Upload Service`, `Audioplayer`, `Community 20`, `Object`, `Bool`, `Edgeinsetsgeometry`, `Deposit Screen`, `Focusnode`, `Bool Isadmin`, `String Label`, `Test Main Screen`, `Lan Join Screen`, `Features Wallet Presentation Screens`, `Features Premium Presentation Premium`, `Globalkey`, `User Profile Screen`, `Domain Tod Models`, `Profile Data Profile Repository`, `Features Rooms Presentation Widgets`, `Size`, `Shared Screens Home Shell`, `Valuenotifier`, `Set`, `Tabcontroller`, `Sticker`, `Bool Selected`, `Core Theme J Theme`, `Shared Widgets Cards User`, `Static Const List`, `Get`, `Features Wallet Presentation Widgets`, `Int`, `Features Rooms Presentation Widgets`, `Bool Isselected`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `GameConfig` connect `Shared Widgets Game Rules` to `Nhiestate Get`, `Memeloadstate Get`, `Todloadstate Get`, `String Emoji`, `String Userid`, `Todstate Get`, `Offline Play Screen`, `Memestate Get`, `Bool`, `Features Offline Domain Offline`, `Gameenginestate Get`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `kStickerAssets`, `kEmojiReactions`, `assetPath` to the rest of the system?**
  _4320 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App Localizations Ar` be split into smaller, more focused modules?**
  _Cohesion score 0.011695906432748537 - nodes in this community are weakly interconnected._
- **Should `App Localizations` be split into smaller, more focused modules?**
  _Cohesion score 0.012578616352201259 - nodes in this community are weakly interconnected._
- **Should `Package Intl Intl` be split into smaller, more focused modules?**
  _Cohesion score 0.012578616352201259 - nodes in this community are weakly interconnected._