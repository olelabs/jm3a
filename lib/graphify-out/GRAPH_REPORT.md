# Graph Report - jma3a/lib  (2026-07-30)

## Corpus Check
- 167 files · ~1,361,705 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5824 nodes · 8177 edges · 169 communities (160 shown, 9 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- app_localizations.dart
- app_localizations_en.dart
- app_localizations_fr.dart
- app_localizations_ar.dart
- app_colors.dart
- tod_models.dart
- pack_entity.dart
- tod_game_provider.dart
- lobby_screen.dart
- room_provider.dart
- offline_play_screen.dart
- meme_game_screen.dart
- offline_game_provider.dart
- room_entity.dart
- wallet_entity.dart
- realtime_service.dart
- lan_service.dart
- avatar_creator_screen.dart
- create_pack_screen.dart
- nhie_game_screen.dart
- service_locator.dart
- tod_card_screen.dart
- room_repository.dart
- j_card.dart
- State
- offline_session.dart
- friends_repository.dart
- meme_game_engine.dart
- pack_provider.dart
- tod_punishment_screen.dart
- friends_provider.dart
- never_have_i_ever_engine.dart
- tod_game_screen.dart
- offline_game_screen.dart
- user_profile_screen.dart
- ../../core/providers/auth_provider.dart
- otp_screen.dart
- pack_repository.dart
- app_router.dart
- playful_background.dart
- j_theme_extension.dart
- profile_screen.dart
- truth_or_dare_engine.dart
- lan_host_screen.dart
- premium_screen.dart
- wallet_provider.dart
- j_game_hud.dart
- offline_setup_screen.dart
- user_entity.dart
- j_page_transition.dart
- notification_provider.dart
- chat_panel.dart
- withdrawal_screen.dart
- pack_sync_service.dart
- friends_screen.dart
- StatelessWidget
- String get
- member_tile.dart
- pack_detail_screen.dart
- app_config.dart
- context_ext.dart
- app_theme_service.dart
- core/utils/app_logger.dart
- auth_provider.dart
- game_provider.dart
- notification_entity.dart
- presence_service.dart
- base_game_engine.dart
- j_button.dart
- auth_repository.dart
- AuthProvider
- room_browser_screen.dart
- pack_download_manager.dart
- marketplace_screen.dart
- edit_profile_screen.dart
- deposit_screen.dart
- Sticker.dart
- app_database.dart
- onboarding_screen.dart
- notifications_screen.dart
- game_settings_sheet.dart
- j_chat_bubble.dart
- creator_dashboard_screen.dart
- wallet_home_screen.dart
- wallet_repository.dart
- user_avatar.dart
- premium_avatar_service.dart
- change_username_screen.dart
- route_names.dart
- notification_service.dart
- List
- transaction_history_screen.dart
- local_storage_service.dart
- moderation_sheet.dart
- review_sheet.dart
- app.dart
- settings_screen.dart
- create_room_sheet.dart
- failures.dart
- offline_repository.dart
- friend_tile.dart
- tod_repository.dart
- tod_end_screen.dart
- GameEngineEvent
- PackProvider
- pack_download_button.dart
- room_cache_service.dart
- transaction_detail_sheet.dart
- tod_timer_ring.dart
- animated_reaction_overlay.dart
- join_code_dialog.dart
- permium_badge.dart
- app_constants.dart
- profile_provider.dart
- package:flutter/material.dart
- Equatable
- tod_hud.dart
- profile_repository.dart
- connectivity_service.dart
- secure_storage_service.dart
- deep_links.dart
- tod_timer_service.dart
- api_client.dart
- image_cache_service.dart
- background_color_screen.dart
- ../../../core/extensions/context_ext.dart
- home_shell_screen.dart
- Map
- app_theme.dart
- notification_repository.dart
- app_provider.dart
- dart:async
- app_text_styles.dart
- closed_rooms_screen.dart
- physical_pack_requests_screen.dart
- app_logger.dart
- bool get
- static const
- theme_picker_screen.dart
- ../../../core/errors/failures.dart
- String?
- game_rules_sheet.dart
- tod_waiting_overlay.dart
- BaseRepository
- package:supabase_flutter/supabase_flutter.dart
- AppLocalizations
- game_registry.dart
- ChangeNotifier
- physical_pack_request_sheet.dart
- _AmountStepState
- JThemeExtension
- BuildContext
- _AvatarCreatorScreenState
- online_indicator.dart
- _ExecutionPhase
- TodPunishmentScreen
- report_pack_sheet.dart
- payment_method_card.dart
- Timer?
- build
- RouteNames.home
- WalletProvider
- MaterialPageRoute
- ../utils/app_logger.dart
- CustomPainter
- _ProofViewer
- _VoicePlayerSheet
- lan_host_screen.dart

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 128 edges
2. `VoidCallback` - 45 edges
3. `PackProvider` - 35 edges
4. `WalletProvider` - 23 edges
5. `AppThemeService` - 20 edges
6. `RoomProvider` - 20 edges
7. `Failure` - 19 edges
8. `GameEngineEvent` - 19 edges
9. `FriendsProvider` - 16 edges
10. `NotificationProvider` - 14 edges

## Surprising Connections (you probably didn't know these)
- `didChangeDependencies` --references--> `AuthProvider`  [EXTRACTED]
  jma3a/lib/app.dart → jma3a/lib/core/providers/auth_provider.dart
- `AppRouter` --references--> `AuthProvider`  [EXTRACTED]
  jma3a/lib/core/router/app_router.dart → jma3a/lib/core/providers/auth_provider.dart
- `createRouter` --references--> `AuthProvider`  [EXTRACTED]
  jma3a/lib/core/router/app_router.dart → jma3a/lib/core/providers/auth_provider.dart
- `_submit` --references--> `AuthProvider`  [EXTRACTED]
  jma3a/lib/features/auth/presentation/screens/onboarding_screen.dart → jma3a/lib/core/providers/auth_provider.dart
- `initState` --references--> `AuthProvider`  [EXTRACTED]
  jma3a/lib/features/auth/presentation/screens/splash_screen.dart → jma3a/lib/core/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (169 total, 9 thin omitted)

### Community 0 - "app_localizations.dart"
Cohesion: 0.01
Nodes (170): app_localizations_ar.dart, app_localizations_en.dart, app_localizations_fr.dart, appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired (+162 more)

### Community 1 - "app_localizations_en.dart"
Cohesion: 0.01
Nodes (158): app_localizations.dart, appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired, authOtpHint, authOtpInvalid (+150 more)

### Community 2 - "app_localizations_fr.dart"
Cohesion: 0.01
Nodes (157): appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired, authOtpHint, authOtpInvalid, authOtpLabel (+149 more)

### Community 3 - "app_localizations_ar.dart"
Cohesion: 0.01
Nodes (158): appName, authEmailHint, authEmailInvalid, authEmailLabel, authOtpExpired, authOtpHint, authOtpInvalid, authOtpLabel (+150 more)

### Community 4 - "app_colors.dart"
Cohesion: 0.02
Nodes (126): amberOrangeLight, AppColors, AppCurves, AppDuration, AppRadius, AppShadows, AppSpacing, avatar (+118 more)

### Community 5 - "tod_models.dart"
Cohesion: 0.02
Nodes (101): allowSpectators, canView, card, cardType, completedDares, completedTruths, content, copyWith (+93 more)

### Community 6 - "pack_entity.dart"
Cohesion: 0.02
Nodes (104): allowSpicy, archived, authorAvatarUrl, authorName, availableLanguages, avgRating, canPublish, cardCount (+96 more)

### Community 7 - "tod_game_provider.dart"
Cohesion: 0.02
Nodes (120): activePlayerCount, addChatMessage, _advancing, applyOwnershipChange, _awayPlayerIds, banPlayerFromGame, broadcastActivity, _broadcastState (+112 more)

### Community 8 - "lobby_screen.dart"
Cohesion: 0.02
Nodes (105): ../../data/room_repository.dart, RoomConnectionState, _ActionBtn, allowAnonymous, _banConfirm, _banned, _checkStatus, code (+97 more)

### Community 9 - "room_provider.dart"
Cohesion: 0.02
Nodes (113): connected,
  reconnecting,
  recovering,
  pendingApproval,, ../../../core/services/subscription_service.dart, activeMembers, banPlayer, _cache, canAcceptJoins, canAcceptRejoins, canAdvanceTurn (+105 more)

### Community 10 - "offline_play_screen.dart"
Cohesion: 0.02
Nodes (89): GameEngineState, MemeState, NhieState, TodState, accentColor, action, actionType, asset (+81 more)

### Community 11 - "meme_game_screen.dart"
Cohesion: 0.02
Nodes (122): activePlayerCount, _advancing, applyOwnershipChange, asset, assetPath, _autoFillAwayPlayers, _autoFilling, _awayPlayerIds (+114 more)

### Community 12 - "offline_game_provider.dart"
Cohesion: 0.02
Nodes (84): _addChat, advanceTurn, _broadcastState, _chatMessages, clearUnreadChat, _clientEngineReady, _clientPlayerId, _clientPlayerName (+76 more)

### Community 13 - "room_entity.dart"
Cohesion: 0.02
Nodes (107): acceptJoins, acceptRejoins, acceptSpectators, actorId, advanceTurn, all, allowAnonymousSpectators, allowSkip (+99 more)

### Community 14 - "wallet_entity.dart"
Cohesion: 0.03
Nodes (74): commission, payout, adjustment, bonus,, absAmount, accountName, accountNumber, amountMru, approvedAt, availableFormatted, availableForWithdrawalMru (+66 more)

### Community 15 - "realtime_service.dart"
Cohesion: 0.03
Nodes (72): avatarUrl, _bcast, broadcastChat, broadcastGameEnded, broadcastGameStarted, broadcastGameState, BroadcastHandler, broadcastModeration (+64 more)

### Community 16 - "lan_service.dart"
Cohesion: 0.03
Nodes (65): address, _advertisingTimer, broadcastGameState, broadcastLobbyUpdate, broadcastMessage, broadcastMessageExcept, broadcastStartGame, _cleanup (+57 more)

### Community 17 - "avatar_creator_screen.dart"
Cohesion: 0.03
Nodes (65): >, AvatarConfig get, _accessories, accessoriesType, AvatarConfig, AvatarDisplay, avatarReactionKey, avatarUrl (+57 more)

### Community 18 - "create_pack_screen.dart"
Cohesion: 0.02
Nodes (91): ../../data/pack_upload_service.dart, CardDifficulty, CardType, PackDraft, _activeSteps, _add, _arCtrl, _AudienceStep (+83 more)

### Community 19 - "nhie_game_screen.dart"
Cohesion: 0.02
Nodes (97): activePlayerCount, _advancing, applyOwnershipChange, _autoFillAwayPlayers, _awayPlayerIds, banPlayerFromGame, _broadcastState, _buildContent (+89 more)

### Community 20 - "service_locator.dart"
Cohesion: 0.03
Nodes (60): ApiClient get, AuthRepository get, ConnectivityService get, apiClient, authRepository, connectivityService, friendsRepository, imageCacheService (+52 more)

### Community 21 - "tod_card_screen.dart"
Cohesion: 0.03
Nodes (76): AudioPlayer?, ../../../../avatar/presentation/avatar_creator_screen.dart, TodCard, TodCardType, TodDifficulty, TodProofViewMode, activity, _alreadyViewed (+68 more)

### Community 22 - "room_repository.dart"
Cohesion: 0.02
Nodes (80): _api, banMember, _chatRowToEntity, claimRoomOwnership, clearPack, clearReturnTimer, createRoom, decideGameRejoinRequest (+72 more)

### Community 23 - "j_card.dart"
Cohesion: 0.03
Nodes (57): EdgeInsetsGeometry?, package:shimmer/shimmer.dart, action, avatarUrls, avgRating, badge, borderColor, borderWidth (+49 more)

### Community 24 - "State"
Cohesion: 0.04
Nodes (75): _ShakeState, _ShakeWidget, SplashScreen, _SplashScreenState, FriendsScreen, _FriendsScreenState, UserProfileScreen, _UserProfileScreenState (+67 more)

### Community 25 - "offline_session.dart"
Cohesion: 0.04
Nodes (52): advertisedAt, allowSkip, allowSpicy, cardCount, config, copyWith, copyWithPlayers, coverImageUrl (+44 more)

### Community 26 - "friends_repository.dart"
Cohesion: 0.04
Nodes (51): avatarConfig, avatarUrl, bio, blockUser, cancelRequest, canInteract, _checkNotBlocked, displayName (+43 more)

### Community 27 - "meme_game_engine.dart"
Cohesion: 0.04
Nodes (51): advanceTurn, caption, _config, copyWith, currentPrompt, currentState, emoji, EmojiReaction (+43 more)

### Community 28 - "pack_provider.dart"
Cohesion: 0.04
Nodes (47): ../../../core/services/pack_sync_service.dart, ../data/pack_download_manager.dart, allDownloadedPackIds, allPacks, _browsePacks, _browsePage, _categories, _createdPacks (+39 more)

### Community 29 - "tod_punishment_screen.dart"
Cohesion: 0.04
Nodes (55): bool isAdmin,, TodPunishment, TodPunishmentVote, TodPunishmentVoteState, build, _canConfirm, canPick, color (+47 more)

### Community 30 - "friends_provider.dart"
Cohesion: 0.04
Nodes (44): acceptRequest, _blockedUsers, blockUser, cancelRequest, clearSearch, dispose, _followers, _following (+36 more)

### Community 31 - "never_have_i_ever_engine.dart"
Cohesion: 0.04
Nodes (47): advanceTurn, card, _cards, _config, content, copyWith, currentCard, currentPlayerId (+39 more)

### Community 32 - "tod_game_screen.dart"
Cohesion: 0.03
Nodes (60): bool?, ../../../../../core/utils/game_end_navigation.dart, data/tod_repository.dart, config, createState, _ctrl, displayNames, dispose (+52 more)

### Community 33 - "offline_game_screen.dart"
Cohesion: 0.06
Nodes (35): build, _Bullet, canHost, _checking, _checkState, color, createState, dispose (+27 more)

### Community 34 - "user_profile_screen.dart"
Cohesion: 0.06
Nodes (30): SocialProfile, _act, _BlockedBanner, createState, _Divider, emoji, _error, _FollowAction (+22 more)

### Community 35 - "../../core/providers/auth_provider.dart"
Cohesion: 0.10
Nodes (21): ../../core/providers/auth_provider.dart, _BrandHeader, build, createState, dispose, _emailCtrl, _emailFocus, EmailScreen (+13 more)

### Community 36 - "otp_screen.dart"
Cohesion: 0.06
Nodes (35): _attemptsRemaining, build, child, _clearAll, _complete, controller, _controllers, _cooldown (+27 more)

### Community 37 - "pack_repository.dart"
Cohesion: 0.04
Nodes (50): addCards, _api, browsePacks, code, createPackDraft, deleteCard, getAvailableLanguages, getCardLanguageCoverage (+42 more)

### Community 38 - "app_router.dart"
Cohesion: 0.05
Nodes (40): AppRouter, createRouter, _instance, isReady, ready, _readyCompleter, rootKey, ../../features/auth/presentation/screens/email_screen.dart (+32 more)

### Community 39 - "playful_background.dart"
Cohesion: 0.06
Nodes (34): _buildParticles, _builtFor, child, color, createState, _ctrl, dispose, _drawBubble (+26 more)

### Community 40 - "j_theme_extension.dart"
Cohesion: 0.06
Nodes (33): copyWith, dareCardBg, dareCardFg, dark, frozenOverlay, gameProgressActive, gameProgressBg, inGameDot (+25 more)

### Community 41 - "profile_screen.dart"
Cohesion: 0.08
Nodes (26): AvatarService, ../../../../features/packs/data/pack_repository.dart, _createdPacks, createState, didChangeDependencies, _fetch, _friends, _games (+18 more)

### Community 42 - "truth_or_dare_engine.dart"
Cohesion: 0.06
Nodes (35): advanceTurn, _applyDecision, _buildQueue, _config, currentState, _deck, _draw, handleEvent (+27 more)

### Community 43 - "lan_host_screen.dart"
Cohesion: 0.07
Nodes (34): ../../data/offline_game_provider.dart, OfflineGameProvider, build, config, createState, dispose, gameType, hostName (+26 more)

### Community 44 - "premium_screen.dart"
Cohesion: 0.06
Nodes (33): _accent, _ActiveBanner, build, _cell, createState, _dataRow, _FeatureTable, _gold (+25 more)

### Community 45 - "wallet_provider.dart"
Cohesion: 0.06
Nodes (35): EarningsSummary? get, _balanceChannel, balanceMru, canAfford, _depositMethods, dispose, _earnings, earningsBalanceMru (+27 more)

### Community 46 - "j_game_hud.dart"
Cohesion: 0.06
Nodes (31): ../../../core/theme/app_text_styles.dart, double?, int count,, int round,, activeColor, activeIndex, avatarUrl, build (+23 more)

### Community 47 - "offline_setup_screen.dart"
Cohesion: 0.07
Nodes (29): ../../data/offline_repository.dart, OfflineMode, _addPlayer, _allowSkip, _allowSpicy, build, createState, dispose (+21 more)

### Community 48 - "user_entity.dart"
Cohesion: 0.06
Nodes (32): age, avatarConfig, avatarUrl, bio, canChangeUsername, copyWith, countryCode, createdAt (+24 more)

### Community 49 - "j_page_transition.dart"
Cohesion: 0.07
Nodes (29): Color yesColor,, Curve, int yesCount,, Offset, package:jma3a/core/theme/app_colors.dart, _anim, build, createState (+21 more)

### Community 50 - "notification_provider.dart"
Cohesion: 0.06
Nodes (30): ../data/notification_repository.dart, _cdcChannel, clearAllToasts, deleteNotification, dismissToast, dispose, _enqueueToast, _hasMore (+22 more)

### Community 51 - "chat_panel.dart"
Cohesion: 0.07
Nodes (30): ChatMessageEntity, _ChatEntityX, build, _ChatBubble, ChatPanel, _ChatPanelState, createState, _ctrl (+22 more)

### Community 52 - "withdrawal_screen.dart"
Cohesion: 0.07
Nodes (26): _amountCtrl, amountMru, _AmountStep, build, _ConfirmRow, _ConfirmStep, createState, dispose (+18 more)

### Community 53 - "pack_sync_service.dart"
Cohesion: 0.07
Nodes (29): _cachePurchaseRecords, complete, current, dispose, _downloader, _fetchActivePurchases, fraction, getDownloadedPackIds (+21 more)

### Community 54 - "friends_screen.dart"
Cohesion: 0.06
Nodes (30): _Badge, _BlockedTab, build, color, controller, count, createState, dispose (+22 more)

### Community 55 - "StatelessWidget"
Cohesion: 0.05
Nodes (44): _ActiveGameBody, _AppPatternBg, _BigChoiceButton, _CardBottomStrip, _ChatBadgeButton, _ChatBubble, _ErrorScreen, _GameAppBar (+36 more)

### Community 56 - "String get"
Cohesion: 0.08
Nodes (25): _connectivity, clearError, _currentUserId, _failure, hasError, _isLoading, onAuthChanged, onUserLoggedIn (+17 more)

### Community 57 - "member_tile.dart"
Cohesion: 0.12
Nodes (16): RoomMemberEntity, build, canModerate, isCurrentUser, isOwner, isReady, member, MemberTile (+8 more)

### Community 58 - "pack_detail_screen.dart"
Cohesion: 0.03
Nodes (62): ../../../../core/services/image_cache_service.dart, ../../domain/pack_entity.dart, PackDownloadManager, PackDownloadState, PackEntity, PackPurchase, build, dlState (+54 more)

### Community 59 - "app_config.dart"
Cohesion: 0.10
Nodes (20): apiBaseUrl, apiTimeout, AppConfig, AppConfigException, AppEnvironment, isDevelopment, isProduction, message (+12 more)

### Community 60 - "context_ext.dart"
Cohesion: 0.07
Nodes (26): AppLocalizations get, ColorScheme get, colorScheme, isDarkMode, isLandscape, isRTL, l10n, padding (+18 more)

### Community 61 - "app_theme_service.dart"
Cohesion: 0.06
Nodes (31): AppThemeData get, allThemes, availableFor, BackgroundMotif, buildTheme, clearPreviewBackground, current, _currentId (+23 more)

### Community 62 - "core/utils/app_logger.dart"
Cohesion: 0.11
Nodes (18): ErrorHandler, handle, _handleAuthException, _handleDioException, _handlePostgrestException, core/utils/app_logger.dart, dart:io, ../../data/pack_repository.dart (+10 more)

### Community 63 - "auth_provider.dart"
Cohesion: 0.07
Nodes (27): _authRepository, _authStateSubscription, clearError, _currentUser, dispose, enterGuestMode, _error, exitGuestMode (+19 more)

### Community 64 - "game_provider.dart"
Cohesion: 0.06
Nodes (30): ../../../core/services/realtime_service.dart, RealtimeService, ../engine/game_registry.dart, BaseGameEngine, MemeGameEngine, NeverHaveIEverEngine, advanceTurn, _broadcastCurrentState (+22 more)

### Community 65 - "notification_entity.dart"
Cohesion: 0.07
Nodes (26): achievement, body, bodyFor, bodyJson, copyWith, createdAt, data, dbString (+18 more)

### Community 66 - "presence_service.dart"
Cohesion: 0.07
Nodes (26): _channel, _currentUserId, _emitCurrentState, fromMap, _heartbeatTimer, _instance, _presenceController, PresenceService (+18 more)

### Community 67 - "base_game_engine.dart"
Cohesion: 0.06
Nodes (30): advanceTurn, allowSkip, allowSpicy, currentState, displayName, enablePunishments, fromMap, handleEvent (+22 more)

### Community 68 - "j_button.dart"
Cohesion: 0.07
Nodes (27): Animation, package:jma3a/core/theme/app_text_styles.dart, build, color, createState, _ctrl, disabled, dispose (+19 more)

### Community 69 - "auth_repository.dart"
Cohesion: 0.08
Nodes (25): AuthChangeEvent, ../../../core/storage/local_storage_service.dart, ../../../core/storage/secure_storage_service.dart, ../domain/entities/user_entity.dart, _api, AuthStateChangeEvent, authStateStream, clearPendingOtpEmail (+17 more)

### Community 70 - "AuthProvider"
Cohesion: 0.09
Nodes (26): AuthProvider, _enterGuestMode, _submit, _resend, _submit, build, _enterGuestMode, _submit (+18 more)

### Community 71 - "room_browser_screen.dart"
Cohesion: 0.07
Nodes (30): closed_rooms_screen.dart, ../../data/room_cache_service.dart, _autoRefreshTimer, _buildBody, _createRoom, createState, _deepLinkSub, didChangeAppLifecycleState (+22 more)

### Community 72 - "pack_download_manager.dart"
Cohesion: 0.08
Nodes (25): _active, _db, deleteDownload, deleteExpiredDownloads, _doDownload, download, _downloadImage, _downloadImages (+17 more)

### Community 73 - "marketplace_screen.dart"
Cohesion: 0.08
Nodes (23): _BrowseTab, _categoryFilter, createState, dispose, _FeaturedTab, _FilterChip, _FilterRow, _freeOnly (+15 more)

### Community 74 - "edit_profile_screen.dart"
Cohesion: 0.08
Nodes (25): _bioCtrl, build, _countries, createState, _displayNameCtrl, dispose, EditProfileScreen, _EditProfileScreenState (+17 more)

### Community 75 - "deposit_screen.dart"
Cohesion: 0.08
Nodes (25): _amount, _amountCtrl, _AmountStep, createState, DepositScreen, _DepositScreenState, dispose, _formKey (+17 more)

### Community 76 - "Sticker.dart"
Cohesion: 0.08
Nodes (25): alreadyReacted, assetPath, avatarConfig, avatarConfigByValue, build, customUrls, EmojiReactionRow, kEmojiReactions (+17 more)

### Community 77 - "app_database.dart"
Cohesion: 0.08
Nodes (24): AppDatabase, close, _db, _dbName, _dbVersion, instance, isOpen, _migration001 (+16 more)

### Community 78 - "onboarding_screen.dart"
Cohesion: 0.08
Nodes (24): build, _buildUsernameSuffix, _checkUsernameAvailability, createState, _debounce, _displayNameCtrl, dispose, _formKey (+16 more)

### Community 79 - "notifications_screen.dart"
Cohesion: 0.11
Nodes (19): NotificationPreference, createState, _decline, dispose, _formatDate, initState, _invites, _load (+11 more)

### Community 80 - "game_settings_sheet.dart"
Cohesion: 0.07
Nodes (30): double min,, RoomProvider, build, build, _cardLanguages, createState, display, divisions (+22 more)

### Community 81 - "j_chat_bubble.dart"
Cohesion: 0.09
Nodes (22): ../../../core/theme/j_theme_extension.dart, avatarUrl, body, build, emoji, isMe, isOptimistic, isRead (+14 more)

### Community 82 - "creator_dashboard_screen.dart"
Cohesion: 0.11
Nodes (18): create_pack_screen.dart, build, color, createState, _CreatorPackRow, _EmptyCreator, icon, initState (+10 more)

### Community 83 - "wallet_home_screen.dart"
Cohesion: 0.07
Nodes (29): Color, deposit_screen.dart, earnings_screen.dart, WithdrawalEntity, build, icon, iconColor, isSuccess (+21 more)

### Community 84 - "wallet_repository.dart"
Cohesion: 0.08
Nodes (24): ../domain/wallet_entity.dart, _api, getEarningsSummary, getMyDeposits, getMyWithdrawals, getPaymentMethodForTransaction, getPaymentMethods, getTransactions (+16 more)

### Community 85 - "user_avatar.dart"
Cohesion: 0.09
Nodes (22): ../../../features/avatar/presentation/avatar_creator_screen.dart, package:flutter_svg/flutter_svg.dart, avatarConfig, AvatarStack, avatarUrl, avatarUrls, borderColor, borderWidth (+14 more)

### Community 86 - "premium_avatar_service.dart"
Cohesion: 0.09
Nodes (22): allAvatars, availableFor, avatar, AvatarPickerScreen, _AvatarTile, build, emoji, id (+14 more)

### Community 87 - "change_username_screen.dart"
Cohesion: 0.10
Nodes (22): _reset, _save, ProfileProvider, build, _buildSuffix, ChangeUsernameScreen, _ChangeUsernameScreenState, _checkState (+14 more)

### Community 88 - "route_names.dart"
Cohesion: 0.09
Nodes (22): authEmail, authOtp, authPhone, avatarCreator, avatarPicker, backgroundColor, friends, home (+14 more)

### Community 89 - "notification_service.dart"
Cohesion: 0.10
Nodes (19): _handleForeground, _handleRoomInviteTap, _handleTap, initialize, _instance, logout, NotificationService, registerForegroundHandler (+11 more)

### Community 90 - "List"
Cohesion: 0.10
Nodes (19): domain, EmailAddress, localPart, props, _regex, toString, tryParse, value (+11 more)

### Community 91 - "transaction_history_screen.dart"
Cohesion: 0.14
Nodes (14): TransactionType, build, createState, dispose, _filters, _scrollCtrl, selected, TransactionHistoryScreen (+6 more)

### Community 92 - "local_storage_service.dart"
Cohesion: 0.10
Nodes (20): clear, containsKey, getBool, getDouble, getInt, getString, getStringList, initialize (+12 more)

### Community 93 - "moderation_sheet.dart"
Cohesion: 0.15
Nodes (13): ../../domain/room_entity.dart, Duration, BanConfirmSheet, _BanConfirmSheetState, build, createState, dispose, _duration (+5 more)

### Community 94 - "review_sheet.dart"
Cohesion: 0.11
Nodes (20): build, createState, _ctrl, _detailsCtrl, dispose, _hover, initState, _isSubmitting (+12 more)

### Community 95 - "app.dart"
Cohesion: 0.11
Nodes (20): _AppShell, _AppShellState, child, createState, didChangeDependencies, Jma3aApp, _Jma3aAppState, _OfflineBanner (+12 more)

### Community 96 - "settings_screen.dart"
Cohesion: 0.13
Nodes (19): build, AppProvider, ../../../../core/providers/app_provider.dart, AppThemeService, ../../core/services/app_theme_service.dart, _selectColor, ThemePickerScreen, build (+11 more)

### Community 97 - "create_room_sheet.dart"
Cohesion: 0.08
Nodes (24): bool selected,, RoomVisibility, _allowSpectators, build, _create, CreateRoomSheet, _CreateRoomSheetState, createState (+16 more)

### Community 98 - "failures.dart"
Cohesion: 0.16
Nodes (19): AuthFailure, code, ConflictFailure, Failure, field, ForbiddenFailure, message, NetworkFailure (+11 more)

### Community 99 - "offline_repository.dart"
Cohesion: 0.10
Nodes (19): Database get, ../domain/offline_session.dart, _db, endSession, getActiveSession, getAvailablePackCount, getAvailablePacks, getRecentSessions (+11 more)

### Community 100 - "friend_tile.dart"
Cohesion: 0.06
Nodes (30): ../../../core/services/presence_service.dart, UserPresenceStatus, ../../data/friends_repository.dart, FriendEntity, build, _color, friend, FriendTile (+22 more)

### Community 101 - "tod_repository.dart"
Cohesion: 0.10
Nodes (19): dart:convert, ../engine/base_game_engine.dart, addCustomCard, completeSession, createSession, deleteCustomCard, findActiveSession, findLatestSession (+11 more)

### Community 102 - "tod_end_screen.dart"
Cohesion: 0.11
Nodes (18): domain/tod_models.dart, TodPlayerScore, build, displayName, displayNames, _endLabel, icon, isWinner (+10 more)

### Community 103 - "GameEngineEvent"
Cohesion: 0.11
Nodes (19): GameEngineEvent, MemeReactEvent, MemeSubmitEvent, MemeVoteEvent, NhieReactionEvent, NhieVoteEvent, TodCastProofVoteEvent, TodChoiceEvent (+11 more)

### Community 104 - "PackProvider"
Cohesion: 0.10
Nodes (21): PackProvider, build, CreatePackScreen, _CreatePackScreenState, _saveDraft, _submit, CreatorDashboardScreen, _CreatorDashboardScreenState (+13 more)

### Community 105 - "pack_download_button.dart"
Cohesion: 0.11
Nodes (18): build, colorScheme, compact, _DownloadCta, _DownloadedCta, _DownloadProgress, errorMessage, _FailedCta (+10 more)

### Community 106 - "room_cache_service.dart"
Cohesion: 0.10
Nodes (19): ../../../../core/storage/database/app_database.dart, appendChatMessage, cacheChatMessages, cacheRooms, _chatToMap, clearRoomCache, _ensureTables, getCachedChatMessages (+11 more)

### Community 107 - "transaction_detail_sheet.dart"
Cohesion: 0.10
Nodes (21): ../../data/wallet_repository.dart, WalletTransaction, build, context, createState, _DetailRow, _formatDateTime, initState (+13 more)

### Community 108 - "tod_timer_ring.dart"
Cohesion: 0.18
Nodes (10): dart:math, double get, build, color, paint, _progress, remaining, shouldRepaint (+2 more)

### Community 109 - "animated_reaction_overlay.dart"
Cohesion: 0.08
Nodes (27): Set, AnimatedReactionOverlay, _AnimatedReactionOverlayState, build, _burstTimers, createState, didUpdateWidget, dispose (+19 more)

### Community 110 - "join_code_dialog.dart"
Cohesion: 0.08
Nodes (24): app.dart, ../../core/di/service_locator.dart, build, createState, _ctrl, dispose, _error, formatEditUpdate (+16 more)

### Community 111 - "permium_badge.dart"
Cohesion: 0.12
Nodes (15): Color get, badgeSize, build, child, _color, gap, _goldColor, isPremium (+7 more)

### Community 112 - "app_constants.dart"
Cohesion: 0.12
Nodes (16): AppConstants, bioMaxLength, chatMaxLength, maxPackCards, maxRoomPlayers, minPackCards, minWithdrawalMru, otpLength (+8 more)

### Community 113 - "profile_provider.dart"
Cohesion: 0.11
Nodes (18): ../../../core/providers/base_provider.dart, ../data/profile_repository.dart, Failure? get, _authProvider, clearLastFailure, _isChangingUsername, _isSaving, _isUploadingAvatar (+10 more)

### Community 114 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (22): app_logger.dart, goToLobbyOrHome, roomExists, VoidCallback, ../../features/rooms/domain/room_entity.dart, ../../features/rooms/presentation/room_provider.dart, package:flutter/material.dart, package:go_router/go_router.dart (+14 more)

### Community 115 - "Equatable"
Cohesion: 0.14
Nodes (14): Equatable, UserEntity, NotificationEntity, LanRoomDescriptor, OfflinePack, OfflinePlayer, OfflineSession, PackCardEntity (+6 more)

### Community 116 - "tod_hud.dart"
Cohesion: 0.12
Nodes (15): TodTurnPhase, build, displayNames, game, maxRound, phase, _PhaseBadge, round (+7 more)

### Community 117 - "profile_repository.dart"
Cohesion: 0.12
Nodes (16): ../../auth/domain/entities/user_entity.dart, ../../../core/network/api_client.dart, _api, changeUsername, createOrUpdateProfile, getProfile, getProfileByUsername, _instance (+8 more)

### Community 118 - "connectivity_service.dart"
Cohesion: 0.12
Nodes (15): _canReach, _connectivity, connectivityStream, _controller, _debounceTimer, dispose, _hasInterface, _init (+7 more)

### Community 119 - "secure_storage_service.dart"
Cohesion: 0.12
Nodes (15): containsKey, delete, deleteAll, _instance, pendingOtpEmail, read, SecureKeys, SecureStorageService (+7 more)

### Community 120 - "deep_links.dart"
Cohesion: 0.12
Nodes (15): _appLinks, code, _ctrl, DeepLinkService, dispose, _handle, init, instance (+7 more)

### Community 121 - "tod_timer_service.dart"
Cohesion: 0.12
Nodes (15): dispose, _durationSeconds, _instance, isRunning, _onExpired, start, _startedAtMs, stop (+7 more)

### Community 122 - "api_client.dart"
Cohesion: 0.14
Nodes (14): ApiClient, _AuthInterceptor, _dio, initialize, _instance, _LoggingInterceptor, onError, onRequest (+6 more)

### Community 123 - "image_cache_service.dart"
Cohesion: 0.13
Nodes (14): avatar, _avatarPlaceholder, _avatarShimmer, _cacheKey, configure, ImageCacheService, _instance, packCover (+6 more)

### Community 124 - "background_color_screen.dart"
Cohesion: 0.09
Nodes (23): BackgroundColorScreen, _BackgroundColorScreenState, _BackgroundOption, _backgroundPalette, _BackgroundPreviewMockup, _blend, build, color (+15 more)

### Community 125 - "../../../core/extensions/context_ext.dart"
Cohesion: 0.04
Nodes (49): ../../../core/extensions/context_ext.dart, ../../core/router/route_names.dart, ../../../../core/services/notification_service.dart, ../../../core/theme/app_colors.dart, _checkAndNavigate, color, createState, _Dot (+41 more)

### Community 126 - "home_shell_screen.dart"
Cohesion: 0.09
Nodes (27): initState, BaseProvider, FriendsProvider, ../../features/friends/presentation/screens/friends_screen.dart, _openProfile, build, _load, ../../features/notifications/presentation/notification_provider.dart (+19 more)

### Community 127 - "Map"
Cohesion: 0.13
Nodes (14): avatarConfig, avatarUrl, build, currentPlayerId, isMyTurn, isPremium, onPlayerTap, _PlayerAvatar (+6 more)

### Community 128 - "app_theme.dart"
Cohesion: 0.07
Nodes (26): app_colors.dart, app_text_styles.dart, AppTheme, _build, container, containerHigh, containerHighest, containerLow (+18 more)

### Community 129 - "notification_repository.dart"
Cohesion: 0.14
Nodes (13): ../../../core/data/base_repository.dart, ../../domain/notification_entity.dart, deleteNotification, getNotifications, getPreferences, _instance, markAllRead, markRead (+5 more)

### Community 130 - "app_provider.dart"
Cohesion: 0.13
Nodes (14): initialize, _Keys, _locale, setLocale, setThemeMode, _storage, _supportedLocales, _themeMode (+6 more)

### Community 131 - "dart:async"
Cohesion: 0.14
Nodes (13): _expiryCheckTimer, getActiveSubscription, instance, isCachedPremium, isPremiumActive, maxProofReplays, startExpiryCheck, stopExpiryCheck (+5 more)

### Community 132 - "app_text_styles.dart"
Cohesion: 0.14
Nodes (13): AppTextStyles, _arabicFamily, familyForLocale, gameCardContent, gameChoiceLabel, hudLabel, _latinFamily, playerName (+5 more)

### Community 133 - "closed_rooms_screen.dart"
Cohesion: 0.09
Nodes (23): _buildContent, child, ClosedRoomDetailScreen, _ClosedRoomDetailScreenState, ClosedRoomsScreen, _ClosedRoomsScreenState, createState, _details (+15 more)

### Community 134 - "physical_pack_requests_screen.dart"
Cohesion: 0.09
Nodes (22): class, DateTime?, build, createState, _error, _formatTs, initState, isCurrent (+14 more)

### Community 135 - "app_logger.dart"
Cohesion: 0.15
Nodes (12): ../config/app_config.dart, AppLogger, debug, error, fatal, info, _logger, _logLevel (+4 more)

### Community 136 - "bool get"
Cohesion: 0.17
Nodes (11): bool get, disable, enable, _enabled, enableScreenshotDetection, instance, isEnabled, ScreenSecurityService (+3 more)

### Community 137 - "static const"
Cohesion: 0.18
Nodes (10): @pragma, _channelKey, initialize, instance, LocalNotificationService, _onAction, show, package:awesome_notifications/awesome_notifications.dart (+2 more)

### Community 138 - "theme_picker_screen.dart"
Cohesion: 0.12
Nodes (15): bool isSelected,, ../../core/router/app_router.dart, AppThemeData, _BackgroundColorTile, build, currentHex, currentId, data (+7 more)

### Community 139 - "../../../core/errors/failures.dart"
Cohesion: 0.09
Nodes (20): ../buttons/j_button.dart, ../../../core/errors/failures.dart, build, compact, _CompactError, ErrorView, failure, _iconForFailure (+12 more)

### Community 140 - "String?"
Cohesion: 0.15
Nodes (12): StringExt, build, child, color, InlineLoader, isLoading, LoadingOverlay, message (+4 more)

### Community 141 - "game_rules_sheet.dart"
Cohesion: 0.11
Nodes (18): ../../features/games/engine/base_game_engine.dart, GameConfig, GameType, RoomSettingsEntity, body, build, config, context (+10 more)

### Community 142 - "tod_waiting_overlay.dart"
Cohesion: 0.25
Nodes (7): AnimationController, build, createState, dispose, initState, playerName, _pulse

### Community 143 - "BaseRepository"
Cohesion: 0.22
Nodes (9): BaseRepository, AuthRepository, FriendsRepository, TodRepository, NotificationRepository, PackRepository, ProfileRepository, RoomRepository (+1 more)

### Community 144 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.25
Nodes (7): currentUserId, initialize, isAuthenticated, SupabaseClientConfig, SupabaseExtensions, package:supabase_flutter/supabase_flutter.dart, SupabaseClient

### Community 145 - "AppLocalizations"
Cohesion: 0.33
Nodes (7): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsAr, AppLocalizationsEn, AppLocalizationsFr, of, LocalizationsDelegate

### Community 146 - "game_registry.dart"
Cohesion: 0.33
Nodes (5): base_game_engine.dart, gameRegistry, ../meme_game/meme_game_engine.dart, ../never_have_i_ever/never_have_i_ever_engine.dart, ../truth_or_dare/truth_or_dare_engine.dart

### Community 147 - "ChangeNotifier"
Cohesion: 0.33
Nodes (6): ChangeNotifier, ConnectivityProvider, GameProvider, MemeGameProvider, NhieGameProvider, TodGameProvider

### Community 148 - "physical_pack_request_sheet.dart"
Cohesion: 0.11
Nodes (17): build, _cityAutocompleteCtrl, createState, dispose, _formKey, initState, _kCities, _loadingPrice (+9 more)

### Community 149 - "_AmountStepState"
Cohesion: 0.67
Nodes (3): _AmountStep, _AmountStepState, _AmountStepState

### Community 150 - "JThemeExtension"
Cohesion: 1.00
Nodes (3): @immutable, JThemeExtension, ThemeExtension

### Community 151 - "BuildContext"
Cohesion: 0.67
Nodes (3): BuildContext, ContextExt, JThemeExt

### Community 159 - "Timer?"
Cohesion: 0.13
Nodes (15): build, createState, dispose, inGame, initState, JoinRequestsPanel, _JoinRequestsPanelState, _load (+7 more)

### Community 160 - "build"
Cohesion: 0.17
Nodes (13): routeFromPayload, purchase, build, build, _doCreateRoom, Route /profile/edit, RouteNames.avatarCreator, RouteNames.friends (+5 more)

### Community 161 - "RouteNames.home"
Cohesion: 0.15
Nodes (13): build, initState, build, initState, build, _handleModerationEvent, _resubscribeWithGameHandlers, _showLeaveDialog (+5 more)

### Community 162 - "WalletProvider"
Cohesion: 0.18
Nodes (11): _AmountStepState, build, _submit, initState, initState, _onScroll, initState, _submit (+3 more)

### Community 163 - "MaterialPageRoute"
Cohesion: 0.22
Nodes (9): build, _goToSetup, _resumeSession, _showLanOptions, build, build, build, MaterialPageRoute (+1 more)

### Community 164 - "../utils/app_logger.dart"
Cohesion: 0.25
Nodes (7): instance, MediaUploadService, uploadProofMedia, dart:typed_data, ../di/service_locator.dart, static final MediaUploadService, ../utils/app_logger.dart

### Community 165 - "CustomPainter"
Cohesion: 0.29
Nodes (7): CustomPainter, _Jma3aMarkPainter, _CardShimmerPainter, _RingPainter, _CardShimmerPainter, _PatternPainter, _MotifPainter

## Knowledge Gaps
- **4363 isolated node(s):** `kStickerAssets`, `kEmojiReactions`, `assetPath`, `size`, `selected` (+4358 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthProvider` connect `AuthProvider` to `lobby_screen.dart`, `theme_picker_screen.dart`, `meme_game_screen.dart`, `avatar_creator_screen.dart`, `ChangeNotifier`, `nhie_game_screen.dart`, `tod_card_screen.dart`, `_AvatarCreatorScreenState`, `State`, `tod_game_screen.dart`, `RouteNames.home`, `offline_game_screen.dart`, `../../core/providers/auth_provider.dart`, `otp_screen.dart`, `MaterialPageRoute`, `app_router.dart`, `build`, `playful_background.dart`, `profile_screen.dart`, `premium_screen.dart`, `chat_panel.dart`, `pack_detail_screen.dart`, `auth_provider.dart`, `room_browser_screen.dart`, `marketplace_screen.dart`, `edit_profile_screen.dart`, `onboarding_screen.dart`, `notifications_screen.dart`, `game_settings_sheet.dart`, `premium_avatar_service.dart`, `change_username_screen.dart`, `app.dart`, `settings_screen.dart`, `create_room_sheet.dart`, `PackProvider`, `join_code_dialog.dart`, `profile_provider.dart`, `../../../core/extensions/context_ext.dart`, `home_shell_screen.dart`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Why does `VoidCallback` connect `package:flutter/material.dart` to `lobby_screen.dart`, `offline_play_screen.dart`, `meme_game_screen.dart`, `theme_picker_screen.dart`, `../../../core/errors/failures.dart`, `avatar_creator_screen.dart`, `create_pack_screen.dart`, `nhie_game_screen.dart`, `tod_card_screen.dart`, `j_card.dart`, `tod_punishment_screen.dart`, `tod_game_screen.dart`, `offline_game_screen.dart`, `user_profile_screen.dart`, `otp_screen.dart`, `premium_screen.dart`, `chat_panel.dart`, `withdrawal_screen.dart`, `friends_screen.dart`, `StatelessWidget`, `member_tile.dart`, `pack_detail_screen.dart`, `j_button.dart`, `marketplace_screen.dart`, `deposit_screen.dart`, `Sticker.dart`, `notifications_screen.dart`, `j_chat_bubble.dart`, `creator_dashboard_screen.dart`, `wallet_home_screen.dart`, `user_avatar.dart`, `premium_avatar_service.dart`, `create_room_sheet.dart`, `friend_tile.dart`, `tod_end_screen.dart`, `pack_download_button.dart`, `animated_reaction_overlay.dart`, `tod_timer_service.dart`, `background_color_screen.dart`, `../../../core/extensions/context_ext.dart`, `Map`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `Failure` connect `failures.dart` to `room_provider.dart`, `../../../core/errors/failures.dart`, `profile_provider.dart`, `Equatable`, `String get`, `auth_provider.dart`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `kStickerAssets`, `kEmojiReactions`, `assetPath` to the rest of the system?**
  _4363 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_localizations.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.011695906432748537 - nodes in this community are weakly interconnected._
- **Should `app_localizations_en.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012578616352201259 - nodes in this community are weakly interconnected._
- **Should `app_localizations_fr.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.012658227848101266 - nodes in this community are weakly interconnected._