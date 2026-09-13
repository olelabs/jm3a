// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Jma3a';

  @override
  String get introSkip => 'Passer';

  @override
  String get introNext => 'Suivant';

  @override
  String get introGetStarted => 'Commencer';

  @override
  String get introPage1Title => 'Bienvenue sur Jma3a';

  @override
  String get introPage1Body =>
      'Des jeux de société multijoueurs — jouez avec vos amis et votre famille, à tout moment, où que vous soyez.';

  @override
  String get introPage2Title => 'Découvrez les packs';

  @override
  String get introPage2Body =>
      'Packs créés par la communauté, packs premium et packs physiques que vous pouvez commander et utiliser.';

  @override
  String get introPage3Title => 'Créez ou rejoignez des salles';

  @override
  String get introPage3Body =>
      'Salles publiques, salles privées, codes d\'invitation — jouez avec vos amis comme vous le souhaitez.';

  @override
  String get introPage4Title => 'Fonctionnalités Premium';

  @override
  String get introPage4Body =>
      'Thèmes personnalisés, arrière-plans, fonctionnalités exclusives et outils pour les créateurs.';

  @override
  String get introPage5Title => 'Prêt à jouer';

  @override
  String get introPage5Body => 'Tout est prêt. Lançons la fête.';

  @override
  String get settingsReplayIntro => 'Revoir l\'introduction';

  @override
  String get noInternetConnection => 'Pas de connexion internet';

  @override
  String get loading => 'Chargement…';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Terminé';

  @override
  String get back => 'Retour';

  @override
  String get skip => 'Passer';

  @override
  String get remove => 'Retirer';

  @override
  String get no => 'Non';

  @override
  String get or => 'ou';

  @override
  String get optional => 'Optionnel';

  @override
  String get error => 'Une erreur s\'est produite';

  @override
  String get errorNetwork => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get errorUnexpected =>
      'Une erreur inattendue s\'est produite. Réessayez.';

  @override
  String get errorForbidden => 'Vous n\'avez pas la permission de faire ça';

  @override
  String get navRooms => 'Salles';

  @override
  String get navFriends => 'Amis';

  @override
  String get navMarketplace => 'Packs';

  @override
  String get navProfile => 'Profil';

  @override
  String get authWelcome => 'Bienvenue sur Jma3a';

  @override
  String get authTagline => 'Jouez ensemble, partout';

  @override
  String get authEmailLabel => 'Votre adresse e-mail';

  @override
  String get authEmailHint => 'Entrez votre e-mail';

  @override
  String get authEmailInvalid => 'Veuillez entrer une adresse e-mail valide';

  @override
  String get authSendOtp => 'Envoyer le code';

  @override
  String get authOtpLabel => 'Code de vérification';

  @override
  String get authOtpVerify => 'Vérifier';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get authOtpInvalid => 'Code invalide. Réessayez.';

  @override
  String get onboardingTitle => 'Créer votre profil';

  @override
  String get onboardingSubtitle =>
      'Choisissez un nom d\'utilisateur pour commencer';

  @override
  String get onboardingUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get onboardingUsernameHint =>
      'lettres minuscules, chiffres, tirets bas';

  @override
  String get onboardingDisplayNameLabel => 'Nom affiché';

  @override
  String get onboardingDisplayNameHint => 'Comment les autres vous verront';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingUsernameInvalid =>
      '3 à 30 caractères, lettres, chiffres et tirets bas uniquement';

  @override
  String get onboardingUsernameTaken => 'Ce nom d\'utilisateur est déjà pris';

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileBioLabel => 'Bio';

  @override
  String get profileBioHint => 'Parlez un peu de vous';

  @override
  String get profileCountryLabel => 'Pays';

  @override
  String get profileLanguageLabel => 'Langue';

  @override
  String get profileAvatarChange => 'Changer la photo';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsOnlineStatus => 'Statut en ligne';

  @override
  String get settingsOnlineStatusPremiumHint =>
      'Le statut manuel est une fonctionnalité Premium';

  @override
  String get presenceModeAuto => 'Auto';

  @override
  String get presenceModeOnline => 'En ligne';

  @override
  String get presenceModeOffline => 'Hors ligne';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutConfirm =>
      'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsSigningOut => 'Déconnexion…';

  @override
  String get premiumBackgroundCustomSet => 'Arrière-plan personnalisé défini';

  @override
  String get premiumBackgroundChooseColor =>
      'Choisir une couleur d\'arrière-plan';

  @override
  String get premiumBackgroundUpgradeHint =>
      'Fonctionnalité Premium — appuyez pour mettre à niveau';

  @override
  String get premiumBackgroundSaveFailed =>
      'Impossible d\'enregistrer la couleur d\'arrière-plan.';

  @override
  String get premiumBackgroundResetFailed =>
      'Impossible de réinitialiser la couleur d\'arrière-plan.';

  @override
  String get roomsTitle => 'Salles';

  @override
  String get roomsCreate => 'Créer une salle';

  @override
  String get roomsJoinCode => 'Rejoindre avec un code';

  @override
  String get roomsEnterCode => 'Entrez le code d\'invitation';

  @override
  String get roomsCodeHint => 'Code à 6 caractères';

  @override
  String get roomsJoin => 'Rejoindre';

  @override
  String get qrRoomRevealTitle => 'Code QR de la salle';

  @override
  String get qrRoomRevealInstruction => 'Scannez pour rejoindre cette salle';

  @override
  String get qrProfileRevealTitle => 'Mon code QR';

  @override
  String get qrProfileRevealInstruction => 'Scannez pour voir mon profil';

  @override
  String get qrClose => 'Fermer';

  @override
  String get qrShareLink => 'Partager le lien';

  @override
  String get qrScanButtonLabel => 'Scanner un code QR';

  @override
  String get qrScanScreenTitle => 'Scanner un code QR';

  @override
  String get qrScanInstruction => 'Pointez votre caméra vers un code QR Jma3a';

  @override
  String get qrScanInvalidCode => 'Ce n\'est pas un code QR Jma3a valide';

  @override
  String get qrScanTryAgain => 'Réessayer';

  @override
  String roomsInvitedByName(String name) {
    return 'Invité(e) par $name';
  }

  @override
  String get roomsPublic => 'Publique';

  @override
  String get roomsPrivate => 'Privée';

  @override
  String roomsPlayers(int current, int max) {
    return '$current/$max joueurs';
  }

  @override
  String get roomsEmpty => 'Aucune salle pour l\'instant';

  @override
  String get roomsEmptySubtitle => 'Créez-en une et invitez vos amis !';

  @override
  String get roomsFull => 'Salle complète';

  @override
  String get lobbyTitle => 'Salle d\'attente';

  @override
  String get lobbyReady => 'Prêt';

  @override
  String get lobbyNotReady => 'Pas prêt';

  @override
  String get lobbyStartGame => 'Démarrer la partie';

  @override
  String get lobbyStartGameFailed =>
      'Impossible de démarrer la partie — veuillez réessayer.';

  @override
  String get lobbyGameStarting => 'Préparation de la partie…';

  @override
  String get lobbyGameStartingBody =>
      'Veuillez patienter pendant la préparation de la partie.';

  @override
  String get lobbyCopied => 'Code copié !';

  @override
  String get lobbyLeaveConfirm => 'Voulez-vous vraiment quitter ?';

  @override
  String lobbyPlayerLeft(String name) {
    return '$name est parti';
  }

  @override
  String get chatPlaceholder => 'Dites quelque chose…';

  @override
  String get chatMuted => 'Vous êtes en sourdine';

  @override
  String get gameSettings => 'Paramètres du jeu';

  @override
  String get gameSettingsTurnTimer => 'Minuteur de tour';

  @override
  String get gameSettingsAllowSkip => 'Autoriser le passage';

  @override
  String get gameSettingsMaxRounds => 'Nombre max de tours';

  @override
  String gameSettingsMaxRoundsCapHint(int cap) {
    return 'Maximum $cap tours — ce pack contient $cap cartes utilisables et chaque carte n\'est utilisée qu\'une seule fois par partie.';
  }

  @override
  String gameSettingsSeconds(int n) {
    return '${n}s';
  }

  @override
  String get gameReconnecting => 'Reconnexion…';

  @override
  String get gameConnectionLost => 'Connexion perdue';

  @override
  String get gameTryAgain => 'Réessayer';

  @override
  String get gameYourTurn => 'À vous de jouer !';

  @override
  String gamePlayerTurn(String name) {
    return 'Au tour de $name';
  }

  @override
  String get moderationKick => 'Expulser le joueur';

  @override
  String get moderationMute => 'Mettre en sourdine';

  @override
  String get moderationBan => 'Bannir de la salle';

  @override
  String moderationKickConfirm(String name) {
    return 'Expulser $name de la salle ?';
  }

  @override
  String get moderationYouWereKicked => 'Vous avez été expulsé de la salle';

  @override
  String moderationYouWereKickedBy(String name) {
    return '$name vous a expulsé de la salle';
  }

  @override
  String moderationYouWereBannedBy(String name) {
    return '$name vous a banni de la salle';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get walletEarningsTotal => 'Total gagné';

  @override
  String get walletEarningsThisMonth => 'Ce mois-ci';

  @override
  String get walletEarningsTotalSales => 'Ventes totales';

  @override
  String get walletTransactionHistory => 'Historique des transactions';

  @override
  String get walletFilterAll => 'Tout';

  @override
  String get walletFilterDeposits => 'Dépôts';

  @override
  String get walletFilterWithdrawals => 'Retraits';

  @override
  String get walletFilterPurchases => 'Achats';

  @override
  String get walletFilterEarnings => 'Gains';

  @override
  String get walletFilterRefunds => 'Remboursements';

  @override
  String get walletFilterPayouts => 'Versements';

  @override
  String get walletFilterBonuses => 'Bonus';

  @override
  String get walletFilterAdjustments => 'Ajustements';

  @override
  String get walletFilterTransfers => 'Transferts';

  @override
  String get walletTypeDeposit => 'Dépôt';

  @override
  String get walletTypeWithdrawal => 'Retrait';

  @override
  String get walletTypePurchase => 'Achat de pack';

  @override
  String get walletTypeRefund => 'Remboursement';

  @override
  String get walletTypeCommission => 'Gains du créateur';

  @override
  String get walletTypePayout => 'Versement';

  @override
  String get walletTypeAdjustment => 'Ajustement';

  @override
  String get walletTypeBonus => 'Bonus';

  @override
  String get walletTypeTransfer => 'Transfert de solde';

  @override
  String get walletStatusPending => 'En attente';

  @override
  String get walletStatusProcessing => 'En cours';

  @override
  String get walletStatusCompleted => 'Terminé';

  @override
  String get walletStatusFailed => 'Échoué';

  @override
  String get walletStatusCancelled => 'Annulé';

  @override
  String get walletStatusReversed => 'Inversé';

  @override
  String get walletDepositStatusPending => 'En attente';

  @override
  String get walletDepositStatusUnderReview => 'En cours d\'examen';

  @override
  String get walletDepositStatusApproved => 'Approuvé';

  @override
  String get walletDepositStatusRejected => 'Rejeté';

  @override
  String get profileGames => 'Jeux';

  @override
  String get usernameProfileResolving => 'Chargement du profil…';

  @override
  String get usernameProfileNotFound => 'Ce profil est introuvable.';

  @override
  String get profileScore => 'Score';

  @override
  String get profileHonestyPoints => 'Points d\'honnêteté';

  @override
  String get honestyVoteHonest => 'Honnête';

  @override
  String get honestyVoteNotHonest => 'Pas honnête';

  @override
  String get honestyVoteRecorded => 'Votre vote a été enregistré';

  @override
  String get honestyVoteFailed =>
      'Impossible d\'envoyer votre vote — réessayez';

  @override
  String profileStreakDays(int count) {
    return 'Série de $count jours';
  }

  @override
  String get profileFriends => 'Amis';

  @override
  String get profilePacks => 'Packs';

  @override
  String get profileFollowers => 'Abonnés';

  @override
  String get streakAchievementBarrierLabel => 'Succès de série';

  @override
  String get streakNewTitle => 'Nouvelle série !';

  @override
  String get streakNewBody =>
      'Vous avez commencé une nouvelle série ! Continuez à jouer chaque jour pour l\'agrandir.';

  @override
  String get streakNewCta => 'C\'est parti !';

  @override
  String streakExtendedTitle(int count) {
    return 'Série prolongée ! $count jours d\'affilée !';
  }

  @override
  String streakExtendedBody(int count) {
    return '$count jours d\'affilée ! Vous êtes en feu 🔥';
  }

  @override
  String get streakExtendedCta => 'Continuer';

  @override
  String get profileShareAction => 'Partager le profil';

  @override
  String profileShareMessage(String name, String link) {
    return '🎮 Rejoins-moi sur Jma3a ! Suis $name\n\n$link';
  }

  @override
  String profileShareSubject(String name) {
    return '🎮 $name sur Jma3a';
  }

  @override
  String get profileShareCardCta => 'Appuyez pour voir mon profil Jma3a';

  @override
  String get gameSettingsSpicy => 'Cartes épicées';

  @override
  String get gameSettingsRequireApproval =>
      'Approbation requise pour rejoindre';

  @override
  String get gameSettingsHonestyVote => 'Vote d\'honnêteté';

  @override
  String get gameSettingsAllowSpectators => 'Autoriser les spectateurs';

  @override
  String get lobbyApprove => 'Approuver';

  @override
  String get lobbyReject => 'Refuser';

  @override
  String get authUseEmailInstead => 'Utiliser l\'e-mail à la place';

  @override
  String get authUsePhoneInstead => 'Utiliser le téléphone à la place';

  @override
  String get authContinueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get authTermsPrivacyNotice =>
      'En continuant, vous acceptez nos conditions et notre politique de confidentialité';

  @override
  String authOtpAttemptsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tentatives restantes',
      one: '$count tentative restante',
    );
    return '$_temp0';
  }

  @override
  String get authTakingLonger => 'Cela prend plus de temps que prévu…';

  @override
  String get authContinueWithoutSigningIn => 'Continuer sans se connecter';

  @override
  String get required => 'Requis';

  @override
  String get onboardingGenderLabel => 'Genre';

  @override
  String get onboardingGenderMale => 'Homme';

  @override
  String get onboardingGenderFemale => 'Femme';

  @override
  String get onboardingGenderRequired => 'Veuillez sélectionner votre genre';

  @override
  String get onboardingAgeLabel => 'Âge';

  @override
  String get onboardingAgeHint => 'Votre âge (13 ans et plus)';

  @override
  String get onboardingAgeRequired => 'L\'âge est requis';

  @override
  String get onboardingAgeInvalid => 'Entrez un âge valide';

  @override
  String get onboardingAgeTooYoung => 'Vous devez avoir au moins 13 ans';

  @override
  String get onboardingDisplayNameTooShort => 'Au moins 2 caractères';

  @override
  String get onboardingDisplayNameTooLong => '50 caractères maximum';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get chatTabLabel => 'Discussion';

  @override
  String get checking => 'Vérification…';

  @override
  String get defaultPlayerName => 'Un joueur';

  @override
  String get deny => 'Refuser';

  @override
  String get errorConnectionFailed => 'Échec de la connexion';

  @override
  String get invited => 'Invité';

  @override
  String get kick => 'Exclure';

  @override
  String get leave => 'Quitter';

  @override
  String get leaveGame => 'Quitter la partie';

  @override
  String get ok => 'OK';

  @override
  String get muted => 'Muet';

  @override
  String get sending => 'Envoi…';

  @override
  String get unban => 'Débannir';

  @override
  String get unmute => 'Réactiver le son';

  @override
  String get moderationYouWereBanned => 'Vous avez été banni';

  @override
  String lobbyAddAsFriend(String name) {
    return 'Ajouter $name comme ami';
  }

  @override
  String get lobbyAllRequestsDecided => 'Toutes les demandes ont été traitées.';

  @override
  String lobbyAreFriends(String name) {
    return 'Vous et $name êtes amis ✓';
  }

  @override
  String get lobbyAutoLetInOnceApproved =>
      'Vous serez admis automatiquement une fois approuvé.';

  @override
  String lobbyBanReason(String reason) {
    return 'Motif : $reason';
  }

  @override
  String get lobbyBannedSectionTitle => '🚫 Bannis';

  @override
  String lobbyCannotSendRequest(String name) {
    return 'Impossible d\'envoyer une demande à $name';
  }

  @override
  String get lobbyCloseRoomBody => 'Fermer la salle retirera tous les joueurs.';

  @override
  String get lobbyCloseRoomConfirm => 'Fermer la salle';

  @override
  String get lobbyCloseRoomTitle => 'Fermer la salle ?';

  @override
  String get lobbyCloseKeepGameTitle => 'Fermer cette salle ?';

  @override
  String get lobbyCloseKeepGameBody =>
      'La salle disparaîtra de la liste et aucun nouveau joueur ne pourra entrer. Les joueurs déjà en partie continuent — la partie n\'est pas interrompue et la salle n\'est pas supprimée.';

  @override
  String get lobbyCloseKeepGameConfirm => 'Fermer la salle';

  @override
  String get lobbyCloseKeepGameCta => 'Fermer la salle';

  @override
  String get lobbyRoomClosedForNewPlayers =>
      'L\'hôte a fermé la salle aux nouveaux joueurs.';

  @override
  String get lobbyReopenTitle => 'Rouvrir cette salle ?';

  @override
  String get lobbyReopenBody =>
      'La salle acceptera de nouveau des joueurs et réapparaîtra dans la liste. Rien d\'autre ne change — la salle n\'est pas recréée et aucune partie n\'est réinitialisée.';

  @override
  String get lobbyReopenConfirm => 'Rouvrir la salle';

  @override
  String get lobbyReopenCta => 'Rouvrir la salle';

  @override
  String get lobbySelectPackBeforeStart =>
      'Veuillez sélectionner un pack avant de démarrer la partie.';

  @override
  String lobbyRejoinDecisionFailed(String error) {
    return 'Échec : $error';
  }

  @override
  String get premiumErrorInsufficientBalance =>
      'Solde insuffisant. Veuillez recharger votre portefeuille.';

  @override
  String get premiumErrorWalletNotFound =>
      'Portefeuille introuvable. Veuillez contacter le support.';

  @override
  String get premiumErrorWalletFrozen =>
      'Votre portefeuille est gelé. Veuillez contacter le support.';

  @override
  String get premiumErrorInvalidPlan => 'Plan sélectionné invalide.';

  @override
  String get premiumErrorDowngradeBlocked =>
      'Vous pourrez changer de plan une fois votre abonnement actuel expiré.';

  @override
  String premiumErrorPurchaseFailed(String error) {
    return 'Échec de l\'achat : $error';
  }

  @override
  String get lobbyRoomReopened =>
      'Salle rouverte — les nouveaux joueurs peuvent revenir.';

  @override
  String get lobbyCouldNotSendRequest =>
      'Impossible d\'envoyer la demande — réessayez';

  @override
  String get lobbyDeselectAll => 'Tout désélectionner';

  @override
  String get lobbyFriendRequestPending => 'Demande d\'ami en attente';

  @override
  String lobbyFriendRequestSent(String name) {
    return 'Demande d\'ami envoyée à $name ✅';
  }

  @override
  String lobbyHiddenAnonymousCount(int count) {
    return '+ $count anonymes (visible par les modérateurs uniquement)';
  }

  @override
  String get lobbyHowToJoin => 'Comment souhaitez-vous rejoindre ?';

  @override
  String lobbyInviteCount(int count) {
    return 'Inviter $count';
  }

  @override
  String get lobbyInviteFriendsTitle => '👥 Inviter des amis';

  @override
  String get lobbyJoinRequestSentTitle => 'Demande d\'adhésion envoyée';

  @override
  String lobbyKickSpectatorBody(String name) {
    return 'Retirer $name de la salle.';
  }

  @override
  String get lobbyKickSpectatorTitle => 'Exclure le spectateur ?';

  @override
  String get lobbyLeaveRoomTitle => 'Quitter la salle ?';

  @override
  String get lobbyModerationTitle => '⚖️ Modération';

  @override
  String get lobbyMutedSectionTitle => '🔇 En sourdine';

  @override
  String lobbyNoFriendsMatchQuery(String query) {
    return 'Aucun ami ne correspond à « $query »';
  }

  @override
  String get lobbyNoFriendsToInvite => 'Pas encore d\'amis à inviter.';

  @override
  String get lobbyNoMutedOrBanned => 'Aucun joueur en sourdine ou banni.';

  @override
  String get lobbyNoVisibleSpectators => 'Aucun spectateur visible';

  @override
  String get lobbySpectatorsSection => 'Spectateurs';

  @override
  String lobbyPermissionsFor(String name) {
    return 'Permissions de $name';
  }

  @override
  String get lobbyPermissionsHint =>
      'Les propriétaires peuvent les modifier à tout moment.';

  @override
  String lobbyRejoinRequestsCount(int count) {
    return 'Demandes de retour ($count)';
  }

  @override
  String get lobbyRoomClosedBody => 'L\'hôte a fermé la salle.';

  @override
  String get lobbyRoomClosedTitle => 'Salle fermée';

  @override
  String get lobbySearchFriendsHint => 'Rechercher des amis…';

  @override
  String get lobbySelectAll => 'Tout sélectionner';

  @override
  String get lobbySelectPackToStart =>
      'Sélectionnez un pack dans les paramètres pour commencer';

  @override
  String get lobbyShareInviteLink => 'Partager le lien d\'invitation';

  @override
  String roomShareMaxPlayers(int count) {
    return '$count joueurs max';
  }

  @override
  String get roomShareInvitedBy => 'Invité par';

  @override
  String get roomShareScoreLabel => 'Score';

  @override
  String get roomShareHonestyLabel => 'Honnêteté';

  @override
  String get roomShareJoinCta => 'REJOINDRE LA SALLE';

  @override
  String lobbyShareInviteMessage(String code, String link) {
    return '🎮 Rejoins ma salle Jma3a !\n\nCode : $code\n\n$link';
  }

  @override
  String lobbyShareInviteSubject(String code) {
    return '🎮 Code Jma3a : $code';
  }

  @override
  String get lobbySpectateWatchHint =>
      'Ces joueurs veulent regarder la partie en tant que spectateurs.';

  @override
  String lobbySpectatorRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count demandes de spectateur',
      one: '$count demande de spectateur',
    );
    return '$_temp0';
  }

  @override
  String get lobbySpectatorRequestsTitle => 'Demandes de spectateurs';

  @override
  String lobbySpectatorsCount(int count) {
    return 'Spectateurs ($count)';
  }

  @override
  String get lobbyWaitingForHostApproval =>
      'En attente de l\'approbation de l\'hôte pour votre demande d\'adhésion.';

  @override
  String get lobbyWantsToRejoin => 'Veut rejoindre à nouveau la partie';

  @override
  String get lobbyWantsToSpectate => 'Veut regarder';

  @override
  String get lobbyYouAreHost => 'Vous êtes l\'hôte';

  @override
  String get lobbyYouAreNowOwner =>
      'Vous êtes maintenant le propriétaire de la salle 👑';

  @override
  String get defaultPackName => 'Pack';

  @override
  String get gameNameAll => 'Tous';

  @override
  String get gameNameMeme => 'Jeu de Mèmes';

  @override
  String get gameNameNeverHaveIEver => 'Je n\'ai jamais';

  @override
  String get gameNameTruthOrDare => 'Action ou Vérité';

  @override
  String get gameSettingsChooseProofViewers =>
      'Choisissez exactement qui peut voir la preuve';

  @override
  String gameSettingsMemberLabelSpectator(String name) {
    return '$name (spec)';
  }

  @override
  String get gameSettingsNoPacksDevMsg =>
      'Aucun pack disponible. Exécutez le SQL d\'amorçage dans Supabase.';

  @override
  String get gameSettingsPackPunishments => 'Gages du pack';

  @override
  String get gameSettingsPlayersSubmit => 'Proposés par les joueurs';

  @override
  String get gameSettingsProofCustom => 'Personnalisé';

  @override
  String get gameSettingsProofEveryone => 'Tout le monde';

  @override
  String get gameSettingsProofPlayers => 'Joueurs';

  @override
  String get gameSettingsProofSpectators => 'Spectateurs';

  @override
  String get gameSettingsProofVisibility => 'Visibilité de la preuve';

  @override
  String get gameSettingsPunishmentHintDefault =>
      'Quand un joueur passe son tour, chaque autre joueur propose un gage et le joueur qui a passé en choisit un à réaliser.';

  @override
  String get gameSettingsPunishmentHintPackAvailable =>
      'Ce pack inclut ses propres gages. Choisissez qui les fournit quand un joueur passe son tour.';

  @override
  String get gameSettingsPunishmentMode => 'Mode gage';

  @override
  String get gameSettingsSelectPack => 'Sélectionner un pack';

  @override
  String get packSituationFilterTitle => 'Que recherchez-vous ?';

  @override
  String get packSituationFilterSubtitle =>
      'Facultatif — choisissez une ambiance et nous mettrons en avant les packs les plus adaptés.';

  @override
  String get packBestMatchTitle => 'MEILLEUR CHOIX POUR VOUS';

  @override
  String get packOtherPacksTitle => 'AUTRES PACKS';

  @override
  String get packMatchedLabel => 'Correspond';

  @override
  String get packTagRelationship => 'Relation';

  @override
  String get packTagBreakup => 'Rupture';

  @override
  String get packTagFixingRelationship => 'Réparer la relation';

  @override
  String get packTagDating => 'Rencontres';

  @override
  String get packTagCouples => 'Couples';

  @override
  String get packTagFriendship => 'Amitié';

  @override
  String get packTagFamily => 'Famille';

  @override
  String get packTagParty => 'Fête';

  @override
  String get packTagIcebreaker => 'Brise-glace';

  @override
  String get packTagWork => 'Travail';

  @override
  String get packTagTravel => 'Voyage';

  @override
  String get packTagLateNight => 'Tard le soir';

  @override
  String get packCreationTagsTitle => 'Types (facultatif)';

  @override
  String get packCreationTagsSubtitle =>
      'Aidez les joueurs à trouver ce pack au bon moment.';

  @override
  String get none => 'Aucun';

  @override
  String get roleLabelPlayer => 'Joueur';

  @override
  String get roleLabelSpectator => 'Spectateur';

  @override
  String roomsActiveRoomOpenBody(String name) {
    return 'Votre salle « $name » est toujours ouverte. Retournez-y, ou fermez-la pour en créer une nouvelle.';
  }

  @override
  String roomsActiveRoomPausedBody(String name) {
    return 'Votre salle « $name » est en pause. Retournez-y, ou fermez-la pour en créer une nouvelle.';
  }

  @override
  String get roomsActiveRoomTitle => 'Vous avez déjà une salle active';

  @override
  String get roomsAllowSpectators => 'Autoriser les spectateurs';

  @override
  String get roomsAllowSpectatorsHint =>
      'Les autres peuvent regarder sans jouer';

  @override
  String roomsAlreadyInRoomBody(String name) {
    return 'Vous êtes toujours dans « $name ». Vous ne pouvez pas être joueur ou spectateur dans deux salles à la fois — retournez-y, ou quittez-la définitivement pour rejoindre celle-ci à la place.';
  }

  @override
  String get roomsAlreadyInRoomTitle => 'Vous êtes déjà dans une salle';

  @override
  String roomsBanConfirm(String name) {
    return 'Bannir $name de cette salle ?';
  }

  @override
  String get roomsBrowsePacks => 'Parcourir les packs';

  @override
  String get roomsCloseAndCreateNew =>
      'Fermer la salle existante et en créer une nouvelle';

  @override
  String get roomsClosedSnackbar => 'Salle fermée';

  @override
  String roomsDailyLimitFreeBody(int basicLimit, int premiumLimit) {
    return 'Le plan gratuit autorise $basicLimit salles par jour. Réessayez demain, ou passez à Premium pour $premiumLimit salles/jour.';
  }

  @override
  String roomsDailyLimitPremiumBody(int premiumLimit) {
    return 'Le plan Premium autorise $premiumLimit salles par jour. Réessayez demain.';
  }

  @override
  String get roomsDailyLimitTitle => 'Limite quotidienne atteinte';

  @override
  String get roomsCreationTooSoonTitle => 'Pas encore';

  @override
  String roomsCreationTooSoonBody(int hours, int minutes) {
    return 'Vous pourrez créer votre prochaine salle dans ${hours}h ${minutes}m.';
  }

  @override
  String get roomsDuration => 'Durée';

  @override
  String roomsDurationLabel(String duration) {
    return 'Durée : $duration';
  }

  @override
  String roomsGameLabel(String game) {
    return 'Jeu : $game';
  }

  @override
  String get roomsIconFree => 'Gratuit';

  @override
  String get roomsIconPremium => 'Premium ✦';

  @override
  String get roomsLeaveForGood => 'Quitter définitivement';

  @override
  String get roomsLeftTheGame => 'A quitté la partie';

  @override
  String get roomsMutedInGame => 'En sourdine — spectateur';

  @override
  String get roomsWaitingForGameApproval =>
      'En attente d\'approbation pour la partie';

  @override
  String get roomsMaxPlayers => 'Joueurs max';

  @override
  String roomsMaxPlayersLabel(String count) {
    return 'Joueurs max : $count';
  }

  @override
  String roomsModPermissionsCount(int count) {
    return 'MOD · $count';
  }

  @override
  String get roomsMyClosedRooms => 'Mes salles fermées';

  @override
  String get roomsNameHint => 'ex. Soirée du vendredi';

  @override
  String get roomsNameLabel => 'Nom de la salle';

  @override
  String get roomsNameTooLong => '60 caractères maximum';

  @override
  String get roomsNameTooShort => 'Au moins 3 caractères';

  @override
  String get roomsNoClosedRooms =>
      'Aucune salle fermée au cours des 5 derniers jours.';

  @override
  String get roomsNoGameData => 'Aucune donnée de partie disponible.';

  @override
  String get roomsNoPacksBody =>
      'Vous avez besoin d\'au moins un pack pour créer une salle — obtenez un pack gratuit ou achetez-en un sur la place de marché d\'abord.';

  @override
  String get roomsNoPacksTitle => 'Aucun pack disponible';

  @override
  String roomsParticipantsCount(int count) {
    return 'Participants ($count)';
  }

  @override
  String roomsPlayedLabel(String date) {
    return 'Jouée : $date';
  }

  @override
  String roomsPlayedPacksCount(int count) {
    return 'Packs joués ($count)';
  }

  @override
  String get roomsRequestSentBody =>
      'Votre demande d\'adhésion a été envoyée. Vous serez averti dès que l\'hôte l\'approuvera.';

  @override
  String get roomsRequestSentTitle => 'Demande envoyée !';

  @override
  String get roomsRequireJoinApproval => 'Exiger l\'approbation d\'adhésion';

  @override
  String get roomsRequireJoinApprovalHint =>
      'Vous approuvez chaque demande d\'adhésion';

  @override
  String get roomsRequireSpectatorApproval =>
      'Exiger l\'approbation des spectateurs';

  @override
  String get roomsRequireSpectatorApprovalHint =>
      'Vous approuvez chaque demande de spectateur, séparément de l\'approbation d\'adhésion des joueurs';

  @override
  String get roomsResults => 'Résultats';

  @override
  String get roomsReturnToMyRoom => 'Retour à ma salle';

  @override
  String get roomsRoomIcon => 'Icône de la salle';

  @override
  String get roomsRoomInfo => 'Infos sur la salle';

  @override
  String roomsStillInRoomBody(String name) {
    return 'Vous êtes toujours dans « $name ». Quittez-la avant d\'en créer une nouvelle.';
  }

  @override
  String roomsSupportsUpToPlayers(int count) {
    return 'Votre salle prend en charge jusqu\'à $count joueurs';
  }

  @override
  String get roomsTransferOwnership => 'Transférer la propriété';

  @override
  String get roomsUpgradeArrow => 'Passer à Premium →';

  @override
  String get roomsVisibility => 'Visibilité';

  @override
  String roomsWinnerLabel(String name) {
    return '🏆 Gagnant : $name';
  }

  @override
  String get gameNameNeverHaveIEverFull => 'Je n\'ai jamais';

  @override
  String get defaultGameName => 'Jeu';

  @override
  String get chatDisabledForRoom =>
      'La discussion est désactivée pour cette salle';

  @override
  String get chatNoMessagesYet => 'Aucun message pour le moment';

  @override
  String get chatSayHint => 'Dites quelque chose…';

  @override
  String get chatSendFailed =>
      'Échec de l\'envoi du message — appuyez sur envoyer pour réessayer';

  @override
  String chatReplyingTo(String name) {
    return 'Réponse à $name';
  }

  @override
  String get chatCancelReply => 'Annuler la réponse';

  @override
  String get chatAudienceEveryone => 'Tout le monde';

  @override
  String chatAudienceOnly(String names) {
    return 'Seulement : $names';
  }

  @override
  String get chatAudiencePickerTitle => 'Qui peut voir ce message ?';

  @override
  String get chatAudienceSelectPeople => 'Sélectionner des personnes';

  @override
  String get chatAudienceNoOneAvailable =>
      'Personne d\'autre n\'est disponible à sélectionner pour le moment.';

  @override
  String get chatAudienceApply => 'Terminé';

  @override
  String chatTargetedIndicatorSender(String names) {
    return 'Visible uniquement par $names';
  }

  @override
  String get chatTargetedIndicatorRecipient =>
      'Envoyé uniquement à vous et à des personnes sélectionnées';

  @override
  String get chatAudienceRequiresPremiumPlus =>
      'Seuls les membres Premium Plus peuvent cibler des personnes spécifiques.';

  @override
  String get chatAudienceRecipientUnavailable =>
      'L\'une des personnes sélectionnées n\'est plus disponible.';

  @override
  String get chatAudienceNoLongerRoomMember =>
      'Vous ne faites plus partie de cette salle/partie.';

  @override
  String get failed => 'Échec';

  @override
  String get photo => 'Photo';

  @override
  String get premiumBadge => '✨ Premium';

  @override
  String get preview => 'Aperçu';

  @override
  String todActivityAnswering(String name) {
    return '$name répond…';
  }

  @override
  String todActivityChoosing(String name) {
    return '$name choisit…';
  }

  @override
  String todActivityFinishingUp(String name) {
    return '$name termine…';
  }

  @override
  String todActivityPerforming(String name) {
    return '$name est en train de le faire…';
  }

  @override
  String todActivityUploadingProof(String name) {
    return '$name envoie une preuve…';
  }

  @override
  String get todAddCardToDeck => 'Ajouter la carte au deck';

  @override
  String get todAddCustomCardButton => 'Ajouter une carte personnalisée';

  @override
  String get todAddCustomCardTitle => 'Ajouter une carte personnalisée';

  @override
  String get todAddDescriptionOptional =>
      'Ajouter une description (facultatif)…';

  @override
  String get todAnswerRequiredHint => 'Votre réponse est requise…';

  @override
  String todChoosingTruthOrDare(String name) {
    return '$name choisit Action ou Vérité…';
  }

  @override
  String get todCompleteTurn => 'Terminer le tour';

  @override
  String get todCompletedTurn => 'a terminé son tour !';

  @override
  String get todNoAnswerOrProofYet => 'Aucune réponse ni preuve pour ce tour';

  @override
  String get todSpectatorWatchingLabel =>
      'En spectateur — aucune action disponible';

  @override
  String get todCustomCardAdded => '✅ Carte personnalisée ajoutée au deck !';

  @override
  String get todCustomCardSessionOnly =>
      'Cette carte sera ajoutée au deck pour cette session uniquement.';

  @override
  String get todDare => 'Action';

  @override
  String todDefaultPlayerNumbered(String id) {
    return 'Joueur $id';
  }

  @override
  String get todDifficultyLabel => 'Difficulté';

  @override
  String get todDoneButton => 'Répondre ✅';

  @override
  String get todEndGame => 'Terminer la partie';

  @override
  String get todEndGameBody =>
      'Cela mettra fin à la partie pour tous les joueurs.';

  @override
  String get todEndGameTitle => 'Terminer la partie ?';

  @override
  String todLikedResponseVotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '👍 A aimé cette réponse ($count votes)',
      one: '👍 A aimé cette réponse ($count vote)',
    );
    return '$_temp0';
  }

  @override
  String get todNextTurn => 'Tour suivant →';

  @override
  String get todNoCardAvailable =>
      'Aucune carte disponible — toutes les cartes ont été utilisées !';

  @override
  String todPointsAbbrev(int points) {
    return '$points pts';
  }

  @override
  String todQuotedResponse(String response) {
    return '« $response »';
  }

  @override
  String get todProofTimerLabel => 'Durée d\'affichage';

  @override
  String get todProofTimerNoLimit => 'Illimitée';

  @override
  String get todProofVisibilityLabel => 'Qui peut voir ceci ?';

  @override
  String get todProofVisibilityEveryone => 'Tout le monde';

  @override
  String get todProofVisibilityPlayersOnly => 'Joueurs uniquement';

  @override
  String get todProofVisibilitySpectatorsOnly => 'Spectateurs uniquement';

  @override
  String get todProofVisibilityPersonalized => 'Personnalisé';

  @override
  String get todProofVisibilityNoOneElse =>
      'Personne d\'autre n\'est encore dans la salle.';

  @override
  String get todProofVisibilityPickAtLeastOne =>
      'Choisissez au moins une personne.';

  @override
  String get todProofViewedLabel => 'Preuve consultée';

  @override
  String get todProofTapToViewLabel => '🔒 Toucher pour voir la preuve';

  @override
  String get todVoiceProofLabel => 'PREUVE VOCALE';

  @override
  String get todImageProofLabel => 'PREUVE IMAGE';

  @override
  String todProofReplayCount(int count) {
    return '👁 Revoir ($count restant(s))';
  }

  @override
  String get todProofNoReplaysLeft =>
      'Plus de visionnages disponibles pour cette preuve.';

  @override
  String get todProofNotAllowedToView =>
      'Vous n\'êtes pas autorisé à voir cette preuve.';

  @override
  String get todProofOpenFailed =>
      'Impossible d\'ouvrir la preuve — veuillez réessayer.';

  @override
  String get todReactLabel => 'Réagir :';

  @override
  String get todReadyForNextTurn => 'Je suis prêt pour le tour suivant';

  @override
  String get todReadyWaitingHost =>
      '✓ Vous êtes prêt — en attente que l\'hôte continue…';

  @override
  String get todRecording => 'Enregistrement…';

  @override
  String get todSkipTurnMod => 'Passer le tour (mod)';

  @override
  String get todSpectatingWaitingHost =>
      'Spectateur — en attente que l\'hôte continue…';

  @override
  String get todSpicyBadge => '🌶 PIMENTÉ';

  @override
  String get todStopRecording => 'Arrêter l\'enregistrement';

  @override
  String get todSubmitCompleteTurn => 'Envoyer et terminer le tour ✅';

  @override
  String get todTruth => 'Vérité';

  @override
  String get todChooseYourChallenge => 'Choisissez votre défi';

  @override
  String todPlayerIsChoosing(String name) {
    return '$name choisit…';
  }

  @override
  String get todWaitingForPlayerGeneric => 'En attente du joueur…';

  @override
  String get todTruthChoiceDescription =>
      'Répondez honnêtement à une question personnelle.';

  @override
  String get todDareChoiceDescription => 'Réalisez un défi audacieux.';

  @override
  String get todSkipCardConfirmTitle => 'Passer cette carte ?';

  @override
  String get todSkipCardConfirmBody =>
      'Passer peut entraîner un vote de punition collective.';

  @override
  String get todStatRounds => 'Manches';

  @override
  String get todStatPlayers => 'Joueurs';

  @override
  String get todStatTotalTurns => 'Tours totaux';

  @override
  String get todDareBadge => 'ACTION';

  @override
  String get todTruthBadge => 'VÉRITÉ';

  @override
  String get nhieBadgeAllCaps => 'JE N\'AI JAMAIS';

  @override
  String get memeBadgeAllCaps => 'PROMPT MÈME';

  @override
  String get memePickStickerFirst => 'Choisissez d\'abord un autocollant';

  @override
  String get memeSubmitResponseButton => 'Envoyer la réponse';

  @override
  String get gameNotStartedYet => 'La partie n\'a pas encore commencé';

  @override
  String get gameNotReady => 'La partie n\'est pas prête';

  @override
  String get todTruthRequiresResponse => 'Vérité nécessite une réponse';

  @override
  String get todDareRequiresResponseOrProof =>
      'Ajoutez une description ou joignez une preuve avant de continuer';

  @override
  String get todProofVoteRequiresVoice =>
      'Le groupe a voté pour une preuve vocale — enregistrez-en une pour continuer';

  @override
  String get todProofVoteRequiresImage =>
      'Le groupe a voté pour une preuve photo — joignez-en une pour continuer';

  @override
  String get todTypeDare => '🔥 Action';

  @override
  String get todTypeTruth => '🤔 Vérité';

  @override
  String todVoiceMaxSeconds(int n) {
    return 'Voix (max ${n}s)';
  }

  @override
  String get todVoiceProofRecorded => 'Preuve vocale enregistrée';

  @override
  String get todVoiceProofTitle => 'Preuve vocale';

  @override
  String todVotedForResponseTotal(int count) {
    return '✓ Vous avez voté pour cette réponse ($count au total)';
  }

  @override
  String todWaitingForToFinishReading(String names) {
    return 'En attente de $names pour finir de lire…';
  }

  @override
  String get todWriteCardPromptHint => 'Écrivez le texte de votre carte…';

  @override
  String get someone => 'Quelqu\'un';

  @override
  String get todAllPlayersLeftGameBody =>
      'Tous les joueurs ont quitté la partie.';

  @override
  String get todAllPlayersLeftGameEnded =>
      'Tous les joueurs ont quitté — partie terminée';

  @override
  String get todChatTitle => '💬 Discussion';

  @override
  String get todGameEnded => 'Partie terminée';

  @override
  String get todGameOver => 'Partie terminée';

  @override
  String get todGamePausedTitle => 'Partie en pause';

  @override
  String get todGoToLobby => 'Aller à la salle';

  @override
  String todHistoryRoundsCount(int count) {
    return 'Historique ($count manches)';
  }

  @override
  String get todHostEndedGame => 'L\'hôte a terminé la partie';

  @override
  String get todHostEndedGameBody => 'L\'hôte a terminé la partie.';

  @override
  String get todHostSteppedAway =>
      'L\'hôte s\'est absenté et reviendra bientôt.';

  @override
  String get todLeaveForNow => 'Quitter pour l\'instant';

  @override
  String get todNoRoundsYet => 'Aucune manche terminée pour le moment.';

  @override
  String todPlayerLeftGame(String name) {
    return '👋 $name a quitté la partie';
  }

  @override
  String get todForcePunishmentTooltip => 'Forcer ce gage';

  @override
  String get todPunishmentModeOn => 'Mode gage ACTIVÉ';

  @override
  String get todQuitGame => 'Quitter la partie';

  @override
  String get todQuitGameBody => 'Quitter la partie en cours ?';

  @override
  String get todQuitGameTitle => 'Quitter la partie ?';

  @override
  String get todRemovedFromGame => 'Vous avez été retiré de cette partie';

  @override
  String todRoundTypeContent(String type, String content) {
    return '$type : $content';
  }

  @override
  String todScreenshotTaken(String name) {
    return '📸 $name a pris une capture d\'écran';
  }

  @override
  String get todSkipped => 'Passé';

  @override
  String todProofWatchedByCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Preuve visionnée par $count',
      zero: 'Preuve envoyée — pas encore visionnée',
    );
    return '$_temp0';
  }

  @override
  String todReplayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replays',
      one: '$count replay',
      zero: 'Aucun replay',
    );
    return '$_temp0';
  }

  @override
  String todVoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '👍 $count votes',
      one: '👍 $count vote',
    );
    return '$_temp0';
  }

  @override
  String get todYouAreNowHost =>
      '👑 Vous êtes maintenant l\'hôte de la partie !';

  @override
  String get secAbbrev => 'sec';

  @override
  String get submit => 'Envoyer';

  @override
  String get todConfigTitle => 'Configuration Action ou Vérité';

  @override
  String get todConfigSubtitle =>
      'Configurez cette partie avant qu\'elle ne commence — vous ne pourrez plus la modifier une fois lancée.';

  @override
  String get todConfigForceDareTitle => 'Règles d\'Action forcée';

  @override
  String get todConfigForceDareUnlimited => 'Illimité';

  @override
  String get todConfigForceDarePerPlayer => 'Par joueur';

  @override
  String get todConfigForceDarePerTurn => 'Par tour';

  @override
  String get todConfigMaxTruths => 'Vérités maximum';

  @override
  String get todConfigCardRepetitionTitle => 'Répétition des cartes';

  @override
  String get todConfigCardRepetitionShuffle => 'Mélange continu';

  @override
  String get todConfigCardRepetitionUnique => 'Cartes uniques';

  @override
  String todConfigUniqueCardsCapHint(int count) {
    return 'Ce pack contient $count cartes — le nombre max de tours ne peut pas dépasser ce qui est disponible, chaque carte n\'étant utilisée qu\'une fois au maximum par tour de joueur.';
  }

  @override
  String get todConfigConfirmStart => 'Confirmer et démarrer';

  @override
  String get gameSettingsPackAlreadyPlayed =>
      'Ce pack a déjà été joué dans cette salle. Choisissez un autre pack.';

  @override
  String get todForcedDareHint =>
      'Vous avez épuisé vos Vérités pour l\'instant — Action uniquement.';

  @override
  String get todEndReasonDefault => 'Partie terminée';

  @override
  String get todEndReasonManual => 'Partie terminée par l\'hôte';

  @override
  String get todEndReasonRoundLimit => 'Toutes les manches terminées';

  @override
  String get todEndReasonScoreLimit => 'Limite de score atteinte';

  @override
  String get todEndReasonCardsExhausted =>
      'Toutes les cartes uniques ont été utilisées';

  @override
  String get todEveryoneElsePickingPunishment =>
      'Les autres choisissent un gage pour vous.';

  @override
  String get todGameOverBang => 'Partie terminée !';

  @override
  String get todLeaderboard => 'Classement';

  @override
  String get todLoadingGame => 'Chargement de la partie…';

  @override
  String todWaitingForPlayers(int ready, int total) {
    return 'En attente des autres joueurs… ($ready/$total prêts)';
  }

  @override
  String get hostReconnectWaitingTitle =>
      'En attente de la reconnexion de l\'hôte…';

  @override
  String hostReconnectWaitingBody(int seconds) {
    return 'La partie est en pause. Elle se terminera automatiquement dans ${seconds}s si l\'hôte ne revient pas.';
  }

  @override
  String todOnlyPlayerCanPick(String name) {
    return 'Seul $name peut choisir — un modérateur peut forcer si inactif.';
  }

  @override
  String get todPhaseChoosing => 'Choix en cours';

  @override
  String get todPhaseCompleting => 'Finalisation…';

  @override
  String get todPhaseInProgress => 'En cours';

  @override
  String get todPhaseVoting => '⚠️ Vote';

  @override
  String todPlayerSkipped(String name) {
    return '$name a passé son tour !';
  }

  @override
  String todRoundBadge(int round, int maxRound) {
    return 'Manche $round / $maxRound';
  }

  @override
  String todSubmitPunishmentFor(String name) {
    return 'Proposez un gage pour $name :';
  }

  @override
  String get todPunishmentHint => 'ex. « Fais 10 pompes »';

  @override
  String get todPickYourPunishment => '⚡ CHOISISSEZ VOTRE GAGE';

  @override
  String todPlayerIsChoosingPunishment(String name) {
    return '⚡ $name CHOISIT…';
  }

  @override
  String get todEveryoneSubmittedPickOne =>
      'Tout le monde a proposé un gage — choisissez celui que vous ferez.';

  @override
  String todWaitingForPlayerToPickOne(String name) {
    return 'En attente que $name en choisisse un.';
  }

  @override
  String todSubmittedCount(int submitted, int expected) {
    return '$submitted / $expected envoyés';
  }

  @override
  String get todSubmittedWaitingForOthers => 'Envoyé — en attente des autres…';

  @override
  String get todTimeForPunishment => 'C\'est l\'heure du gage…';

  @override
  String get todWaitingChoosingQuestion => 'Action ou Vérité ?';

  @override
  String get todYourTurnBadge => '⚡ VOTRE TOUR';

  @override
  String get todTheirTurn => 'C\'est leur tour';

  @override
  String todWinnerWins(String name) {
    return '$name gagne !';
  }

  @override
  String get todYouSkipped => 'Vous avez passé votre tour…';

  @override
  String errorPrefix(String error) {
    return 'Erreur : $error';
  }

  @override
  String get nhieAddCommentOptional => 'Ajouter un commentaire (facultatif)…';

  @override
  String nhieAnsweredCount(int count, int total) {
    return '$count/$total ont répondu';
  }

  @override
  String get nhieCardPromptHint => 'Je n\'ai jamais…';

  @override
  String get nhieCardTitle => 'Je n\'ai jamais…';

  @override
  String nhieDrinksScore(int count) {
    return '$count 🍹';
  }

  @override
  String nhieDrinksTotal(int count) {
    return '🍹 $count';
  }

  @override
  String get nhieGameHistoryTitle => 'Historique de la partie';

  @override
  String get nhieGoToHome => 'Aller à l\'accueil';

  @override
  String get gameBackToRoom => 'Retour au salon';

  @override
  String get nhieIHave => 'J\'AI DÉJÀ';

  @override
  String get nhieMostDrinksWins => 'Le plus de 🍹 gagne !';

  @override
  String get nhieNever => 'JAMAIS';

  @override
  String get nhieTimedOut => 'Temps écoulé — vous n\'avez pas répondu à temps';

  @override
  String get nhieNextCard => 'Carte suivante →';

  @override
  String get nhiePlayAnotherHandOff => 'Rejouer et transmettre';

  @override
  String get nhieReadyForNextRound => 'Je suis prêt pour la manche suivante';

  @override
  String nhieViewHistoryCount(int count) {
    return 'Voir l\'historique ($count manches)';
  }

  @override
  String nhieWaitingCount(int count, int total) {
    return 'En attente… $count/$total';
  }

  @override
  String get nhieWaitingForPlayersReady =>
      'En attente que les joueurs soient prêts…';

  @override
  String get nhieWhoTakesOver => 'Qui reprend la main ?';

  @override
  String get memeAddCaptionOptional => 'Ajouter une légende (facultatif)…';

  @override
  String get memeCustomPromptSessionOnly =>
      'Ce prompt sera ajouté au deck pour cette session uniquement.';

  @override
  String get memeFunniestPlayerWins => 'Le plus drôle gagne !';

  @override
  String get memeNextRound => 'Manche suivante →';

  @override
  String get memePassVote => 'Passer — Prêt pour la manche suivante';

  @override
  String get memePickSticker => 'Choisissez votre sticker :';

  @override
  String memePlayersVoted(int count, int total) {
    return '$count/$total joueurs ont voté';
  }

  @override
  String memeResponseNumber(int n) {
    return 'Réponse n°$n';
  }

  @override
  String get memeResponseSubmittedWaiting =>
      'Réponse envoyée ! En attente des autres…';

  @override
  String memeRoundBadgeAllCaps(int round) {
    return 'MANCHE $round';
  }

  @override
  String memeRoundResultsTitle(int round) {
    return 'Résultats de la manche $round 🏆';
  }

  @override
  String get memeSpectatingWaitingSubmit =>
      'Spectateur — en attente des réponses…';

  @override
  String memeSubmittedCount(int submitted, int total) {
    return '$submitted / $total envoyés';
  }

  @override
  String get memeTapAnywhereToClose => 'Touchez n\'importe où pour fermer';

  @override
  String get memeTapToExpand => 'Touchez pour agrandir';

  @override
  String get memeTapToSeeReaction => 'Touchez pour voir leur réaction';

  @override
  String get memeTie => 'Égalité';

  @override
  String memeTrophyScore(int count) {
    return '$count 🏆';
  }

  @override
  String get memeVoteForBest => 'Votez pour le meilleur ! 😂';

  @override
  String get memeVoteForThis => 'Voter pour celui-ci 👍';

  @override
  String get memeVotedWaiting => 'Voté ! En attente des autres…';

  @override
  String memeVotesAbbrev(int count) {
    return '$count 👍';
  }

  @override
  String memeVotesCount(int count, int total) {
    return '$count / $total ont voté';
  }

  @override
  String memeWinnerLabel(String name) {
    return 'Gagnant : $name';
  }

  @override
  String get memeWinsThisRound => 'gagne cette manche !';

  @override
  String get memeWritePromptHint => 'Écrivez votre prompt de mème…';

  @override
  String get memeYourResponse => 'Votre réponse';

  @override
  String get memeYourVote => '✓ Votre vote';

  @override
  String get exit => 'Quitter';

  @override
  String get offlineAcceptChallenge => 'Accepter le défi';

  @override
  String get offlineAddCaptionOptional => 'Ajouter une légende (facultatif)…';

  @override
  String get offlineAddProofPhoto =>
      'Ajouter une photo de preuve (à usage unique)';

  @override
  String get offlineAnswerHonestly => 'Répondre honnêtement';

  @override
  String get offlineBackToMenu => 'Retour au menu';

  @override
  String get offlineChooseYourFate => 'Choisissez votre destin';

  @override
  String get offlineCompleteTurnCheck => 'Terminer le tour ✅';

  @override
  String offlineCompletedName(String name) {
    return '$name a terminé !';
  }

  @override
  String offlineCouldNotPickImage(String error) {
    return 'Impossible de sélectionner l\'image : $error';
  }

  @override
  String get offlineDareLabel => 'ACTION';

  @override
  String get offlineDoneCheck => '✓ Terminé';

  @override
  String get offlineFinalScores => 'Scores finaux';

  @override
  String get offlineGameHistoryTitle => '📖 Historique de la partie';

  @override
  String get offlineGameOverTrophy => 'Partie terminée 🏆';

  @override
  String offlineGameTypeAndPack(String gameType, String packName) {
    return '$gameType • $packName';
  }

  @override
  String offlineGoodOneVotes(int count) {
    return '👍 Bien joué ! ($count)';
  }

  @override
  String get offlineHistoryTab => '📖 Historique';

  @override
  String offlineIsDeciding(String name) {
    return '$name choisit…';
  }

  @override
  String get offlineKickConfirmBody => 'Il sera retiré de la salle d\'attente.';

  @override
  String offlineKickConfirmTitle(String name) {
    return 'Exclure $name ?';
  }

  @override
  String get offlineMemeBadge => '😂  MÈME';

  @override
  String get offlineMemeChampion => 'Champion des mèmes !';

  @override
  String offlineMyVoteCount(String voteLabel, int count, int total) {
    return '$voteLabel ($count/$total)';
  }

  @override
  String get offlineNeverHaveIEverBadge => 'JE N\'AI JAMAIS…';

  @override
  String get offlineNextTurnShort => 'Tour suivant';

  @override
  String get offlineNoHistoryAvailable => 'Aucun historique disponible';

  @override
  String get offlineNoRoundsCompleted =>
      'Aucune manche terminée pour le moment';

  @override
  String get offlineNoTurnsCompleted => 'Aucun tour terminé pour le moment';

  @override
  String get offlinePackCover => 'Couverture du pack';

  @override
  String get offlinePickFavourite => 'Choisissez votre préféré :';

  @override
  String get offlinePickReaction => 'Choisissez une réaction :';

  @override
  String get offlinePickReactionColon => 'Choisissez votre réaction :';

  @override
  String offlinePlayersCount(int count) {
    return '$count joueurs';
  }

  @override
  String get offlinePlayersInLobby => 'JOUEURS DANS LA SALLE';

  @override
  String get offlinePreviousCards => 'Cartes précédentes';

  @override
  String get offlineProofViewed => '📷 Preuve consultée';

  @override
  String offlineRoundColonCaption(int round, String caption) {
    return 'Manche $round : $caption';
  }

  @override
  String offlineRoundOf(int round, int maxRounds) {
    return 'Manche $round sur $maxRounds';
  }

  @override
  String get offlineSayHiToGroup => 'Dites bonjour au groupe !';

  @override
  String get offlineScoresTab => '🏆 Scores';

  @override
  String get offlineSkippedCross => '✗ Passé';

  @override
  String offlineSubmissionTitle(String name) {
    return 'Réponse de $name';
  }

  @override
  String offlineSubmitCount(int count, int total) {
    return 'Envoyer ($count/$total)';
  }

  @override
  String get offlineSubmitExclaim => 'Envoyer !';

  @override
  String get offlineSubmittedWaitingCheck =>
      '✅ Envoyé ! En attente des autres…';

  @override
  String get offlineTapAgainToDismiss => 'Touchez à nouveau pour fermer';

  @override
  String get offlineTapToDismiss => 'Touchez pour fermer';

  @override
  String get offlineTapToRevealProof =>
      'Touchez pour révéler la photo de preuve';

  @override
  String offlineTimerSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get offlineTruthLabel => 'VÉRITÉ';

  @override
  String offlineVoteCountBallot(int count) {
    return '$count 🗳️';
  }

  @override
  String get offlineVoteForBestNoEmoji => 'Votez pour le meilleur !';

  @override
  String offlineVotesExclaim(String name) {
    return '$name vote !';
  }

  @override
  String get offlineWaitingForHost => 'En attente de l\'hôte…';

  @override
  String get offlineWaitingForHostToStart => 'En attente que l\'hôte commence…';

  @override
  String offlineWaitingForMore(int count) {
    return 'En attente de $count de plus…';
  }

  @override
  String get offlineWaitingHostAdvance => 'En attente que l\'hôte avance…';

  @override
  String get ptsSuffix => ' pts';

  @override
  String get gameLabel => 'Jeu';

  @override
  String get offlineBulletDownloadedPacks =>
      'Les packs téléchargés fonctionnent entièrement hors ligne — aucune connexion nécessaire.';

  @override
  String get offlineBulletLan =>
      'LAN : chaque joueur sur son propre téléphone, même WiFi ou point d\'accès.';

  @override
  String get offlineBulletPassPlay =>
      'Passer et jouer : un seul téléphone, à faire passer entre les joueurs à chaque tour.';

  @override
  String get offlineChooseMode => 'Choisir le mode';

  @override
  String get offlineCreateLanRoomHint =>
      'Créer une salle LAN sur votre appareil';

  @override
  String get offlineDiscard => 'Abandonner';

  @override
  String get offlineDownloadPackFirst =>
      'Téléchargez un pack d\'abord pour héberger';

  @override
  String get offlineEnable18Cards => 'Activer les cartes 18+';

  @override
  String get offlineEnterNameAboveToJoin =>
      'Entrez votre nom ci-dessus pour rejoindre';

  @override
  String get offlineEnterNameToJoin => 'Entrez votre nom pour rejoindre';

  @override
  String get offlineFailedToStart => 'Échec du démarrage';

  @override
  String get offlineFindNearbyLanRooms => 'Trouver des salles LAN à proximité';

  @override
  String get offlineGoBack => 'Retour';

  @override
  String get offlineHostBadge => 'HÔTE';

  @override
  String get offlineHostRoom => 'Héberger une salle';

  @override
  String offlineHostsRoom(String name) {
    return 'Salle de $name';
  }

  @override
  String get offlineHowItWorks => 'ℹ️  Comment fonctionne le mode hors ligne';

  @override
  String get offlineJoinLanRoomTitle => 'Rejoindre une salle LAN';

  @override
  String get offlineJoinRoom => 'Rejoindre une salle';

  @override
  String get offlineJoinRoomButton => 'Rejoindre la salle';

  @override
  String get offlineLanMultiplayer => 'Multijoueur LAN';

  @override
  String get offlineLanRoom => 'Salle LAN';

  @override
  String get offlineLoadingCards => 'Chargement des cartes…';

  @override
  String get offlineNearbyRooms => 'Salles à proximité';

  @override
  String offlineNoPacksDownloaded(String gameType) {
    return 'Aucun pack $gameType téléchargé. Connectez-vous pour télécharger des packs.';
  }

  @override
  String get offlineOtherPlayersJoinInstructions =>
      'Autres joueurs : ouvrez Jma3a → Jouer → LAN → Rejoindre une salle';

  @override
  String offlinePackExpiry(int day, int month) {
    return 'Exp : $day/$month';
  }

  @override
  String offlinePackMeta(int count, String lang, String status) {
    return '$count cartes · $lang · $status';
  }

  @override
  String offlinePackPlayersCount(String packName, int count) {
    return '$packName · $count joueurs';
  }

  @override
  String get offlinePlayTitle => 'Jeu hors ligne';

  @override
  String offlinePlayersCountDash(int count) {
    return 'Joueurs — $count';
  }

  @override
  String get offlineResume => 'Reprendre';

  @override
  String get offlineResumeGame => 'Reprendre la partie';

  @override
  String get offlineRoomBroadcasting => 'La salle diffuse';

  @override
  String offlineRoomMeta(String gameType, String packName, int count, int max) {
    return '$gameType • $packName • $count/$max joueurs';
  }

  @override
  String offlineRoundsSlider(int count) {
    return 'Manches : $count';
  }

  @override
  String get offlineSameWifiHint =>
      'Assurez-vous que l\'appareil hôte est sur le même WiFi.';

  @override
  String get offlineScanningForRooms => 'Recherche de salles…';

  @override
  String get offlineSetupFailed => 'Échec de la configuration.';

  @override
  String get offlineSignInToDownload =>
      'Connectez-vous pour télécharger des packs et débloquer tous les jeux.';

  @override
  String get offlineSpicyContent => 'Contenu pimenté';

  @override
  String offlineTimerSecsLabel(int secs) {
    return 'Minuteur : ${secs}s';
  }

  @override
  String get offlineYourName => 'Votre nom';

  @override
  String get purchased => 'Acheté';

  @override
  String get signIn => 'Se connecter';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get accountLabel => 'Compte';

  @override
  String get amountLabel => 'Montant';

  @override
  String get copiedNotice => 'Copié !';

  @override
  String labelColonSuffix(String label) {
    return '$label : ';
  }

  @override
  String get nameLabel => 'Nom';

  @override
  String get pendingLabel => 'En attente';

  @override
  String get phoneInvalid =>
      'Le numéro de téléphone doit comporter exactement 8 chiffres';

  @override
  String get refresh => 'Actualiser';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get walletAmountToWithdraw => 'Montant à retirer';

  @override
  String walletAmountValue(String amount) {
    return 'Montant : $amount MRU';
  }

  @override
  String walletAvailableAmount(String amount) {
    return 'Disponible : $amount';
  }

  @override
  String get walletAvailableEarnings => 'Gains disponibles';

  @override
  String get walletAvailableForWithdrawal => 'Disponible pour retrait';

  @override
  String get walletBackToWallet => 'Retour au portefeuille';

  @override
  String get walletBalanceAfter => 'Solde après';

  @override
  String get walletBulletCreditedAfterConfirm =>
      'Les gains sont crédités après confirmation de l\'achat.';

  @override
  String get walletBulletEarn85 => 'Vous gagnez 85 % de chaque vente de pack.';

  @override
  String get walletBulletMinWithdrawal => 'Retrait minimum : 500 MRU.';

  @override
  String get walletBulletPlatformFee =>
      'Les frais de plateforme de 15 % font fonctionner Jma3a.';

  @override
  String get walletChooseHowToAddFunds =>
      'Choisissez comment ajouter des fonds.';

  @override
  String get walletConfirmWithdrawal => 'Confirmer le retrait';

  @override
  String get walletCreateSellPacksHint =>
      'Créez et vendez des packs pour gagner des commissions.';

  @override
  String get walletCreatorEarningsRateLabel => 'Taux de gains du créateur';

  @override
  String get walletCreatorEarningsTitle => 'Gains du créateur';

  @override
  String get walletCurrencyName => 'Ouguiya mauritanienne';

  @override
  String get walletCurrencyShort => 'MRU';

  @override
  String get walletAvailableBalanceLabel => 'Solde disponible';

  @override
  String get walletFrozenLabel => 'Portefeuille (gelé)';

  @override
  String get walletDeposit => 'Dépôt';

  @override
  String walletDepositAmount(String amount) {
    return 'Dépôt $amount';
  }

  @override
  String get walletDepositWarningNotice =>
      'Ne soumettez qu\'après avoir effectué le virement. Les dépôts sont examinés manuellement et peuvent prendre 1 à 24 heures.';

  @override
  String get walletEarningsBalance => 'Solde des gains';

  @override
  String get walletEnterReference => 'Entrez la référence de votre paiement';

  @override
  String get walletHowEarningsWork => 'Comment fonctionnent les gains';

  @override
  String get walletInsufficientBalance => 'Solde insuffisant';

  @override
  String get walletMaxDeposit => 'Dépôt maximum : 1 000 000 MRU';

  @override
  String get walletMethodLabel => 'Méthode';

  @override
  String get walletMinDeposit => 'Dépôt minimum : 100 MRU';

  @override
  String walletMinWithdrawal(int amount) {
    return 'Retrait minimum : $amount MRU';
  }

  @override
  String get walletNoEarningsYet => 'Pas encore de gains';

  @override
  String get walletNoTransactions => 'Aucune transaction';

  @override
  String get walletNoTransactionsYet => 'Aucune transaction pour le moment';

  @override
  String walletOfEveryPackSale(int fee) {
    return 'de chaque vente de pack (frais de plateforme $fee %)';
  }

  @override
  String get walletPaymentReferenceLabel =>
      'Référence de paiement / ID de transaction';

  @override
  String get walletPhoneNumberHint => 'Numéro de téléphone à 8 chiffres';

  @override
  String get walletPayoutPhoneNumber => 'Numéro de téléphone de paiement';

  @override
  String get walletPhoneLabel => 'Téléphone';

  @override
  String get walletRecentTransactions => 'Transactions récentes';

  @override
  String get walletReferenceHint => 'ex. TXN123456789';

  @override
  String get walletSelectPaymentMethod => 'Sélectionner le mode de paiement';

  @override
  String get walletSelectPayoutMethod => 'Sélectionner le mode de paiement';

  @override
  String walletStatusPaymentMethod(String status, String method) {
    return '$status • $method';
  }

  @override
  String get walletTitle => 'Portefeuille';

  @override
  String get walletDepositSubmittedTitle => 'Dépôt soumis !';

  @override
  String walletDepositSubmittedSubtitle(String amount) {
    return 'Votre dépôt de $amount est en cours d\'examen. Le solde sera mis à jour une fois approuvé.';
  }

  @override
  String get walletDepositRequestFailed => 'Échec de la demande de dépôt.';

  @override
  String get walletSubmitDeposit => 'Soumettre le dépôt';

  @override
  String get walletWithdrawalSubmittedTitle => 'Retrait soumis !';

  @override
  String walletWithdrawalSubmittedSubtitle(String amount) {
    return 'Votre retrait de $amount est en cours de traitement. Les fonds arriveront sous 1 à 24 heures.';
  }

  @override
  String get walletWithdrawalRequestFailed => 'Échec de la demande de retrait.';

  @override
  String get walletContinueArrow => 'Continuer →';

  @override
  String get walletActionDeposit => 'Déposer';

  @override
  String get walletActionWithdraw => 'Retirer';

  @override
  String get walletActionEarnings => 'Revenus';

  @override
  String get walletDetailDateTime => 'Date et heure';

  @override
  String get walletDetailWalletAffected => 'Portefeuille concerné';

  @override
  String get walletDetailEarnings => 'Revenus';

  @override
  String get walletDetailWalletBalance => 'Solde du portefeuille';

  @override
  String get walletDetailBalanceAfter => 'Solde après';

  @override
  String get walletDetailPaymentMethod => 'Moyen de paiement';

  @override
  String get walletDetailDescription => 'Description';

  @override
  String get walletDetailReference => 'Référence';

  @override
  String get walletDetailTransactionId => 'ID de transaction';

  @override
  String walletDetailDateAtTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String get walletTransferAmount => 'Montant du virement';

  @override
  String get walletTransferButton => 'Transférer';

  @override
  String get walletTransferFailed => 'Échec du transfert.';

  @override
  String get walletTransferSuccess =>
      'Transféré vers le solde du portefeuille.';

  @override
  String get walletTransferToWallet => 'Transférer vers le portefeuille';

  @override
  String get walletTransferToWalletBalance =>
      'Transférer vers le solde du portefeuille';

  @override
  String get walletWithdraw => 'Retirer';

  @override
  String walletWithdrawalAmount(String amount) {
    return 'Retrait $amount';
  }

  @override
  String get walletWithdrawalProcessingNotice =>
      'Les retraits sont traités manuellement. Les fonds arrivent en 1 à 24 heures une fois approuvés.';

  @override
  String get walletYourPhoneNumber => 'Votre numéro de téléphone';

  @override
  String get actionLabel => 'Action';

  @override
  String get activeLabel => 'Actif';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get getButton => 'Obtenir';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get premiumAppThemeTitle => 'Thème de l\'application';

  @override
  String get appThemeNameJma3a => 'Jma3a';

  @override
  String get appThemeNameMidnight => 'Minuit';

  @override
  String get appThemeNameClassic => 'Classique';

  @override
  String get appThemeNameCandy => 'Bonbon';

  @override
  String get appThemeNameOcean => 'Océan';

  @override
  String get appThemeNameForest => 'Forêt';

  @override
  String get appThemeNameSunset => 'Coucher de soleil';

  @override
  String get appThemeNameLavender => 'Lavande';

  @override
  String get appThemeNameRose => 'Rose';

  @override
  String get appThemeNameGalaxy => 'Galaxie';

  @override
  String get appThemeNameNeon => 'Néon';

  @override
  String get appThemeNameGold => 'Or';

  @override
  String get appThemeNameCyber => 'Cyber';

  @override
  String get appThemeNameLava => 'Lave';

  @override
  String get appThemeNameAurora => 'Aurore';

  @override
  String get appThemeNameBubblegum => 'Chewing-gum';

  @override
  String get appThemeNameCandyPop => 'Candy Pop';

  @override
  String get appThemeNameDeepSpace => 'Espace profond';

  @override
  String get appThemeNameBlossom => 'Floraison';

  @override
  String get appThemeNameLovestruck => 'Éperdument amoureux';

  @override
  String get premiumGameCardColorTitle => 'Couleur de la carte de jeu';

  @override
  String get premiumGameCardColorHint =>
      'S\'applique uniquement au recto de vos cartes de jeu — le verso garde son propre style.';

  @override
  String get premiumGameCardColorEmoji => 'Couleur de la carte de jeu 🎴';

  @override
  String get premiumChooseGameCardColor =>
      'Choisissez une couleur de carte de jeu';

  @override
  String get gameCardColorClassicPurple => 'Violet classique';

  @override
  String get gameCardColorMidnightBlue => 'Bleu minuit';

  @override
  String get gameCardColorEmberRed => 'Rouge braise';

  @override
  String get gameCardColorForestEmerald => 'Émeraude forêt';

  @override
  String get gameCardColorSunsetOrange => 'Orange coucher de soleil';

  @override
  String get gameCardColorGoldPrestige => 'Or prestige';

  @override
  String get gameCardColorRosePink => 'Rose poudré';

  @override
  String get gameCardColorCyberTeal => 'Sarcelle cyber';

  @override
  String get premiumAutoRenewNotice =>
      'Les abonnements se renouvellent automatiquement sauf annulation 24h avant le renouvellement.';

  @override
  String get premiumBackgroundColorEmoji => 'Couleur d\'arrière-plan ✦';

  @override
  String get premiumBackgroundColorTitle => 'Couleur d\'arrière-plan';

  @override
  String get bgColorWhite => 'Blanc';

  @override
  String get bgColorWarmWhite => 'Blanc chaud';

  @override
  String get bgColorLightGrey => 'Gris clair';

  @override
  String get bgColorCoolGrey => 'Gris froid';

  @override
  String get bgColorCharcoal => 'Charbon';

  @override
  String get bgColorSoftBlack => 'Noir doux';

  @override
  String get bgColorCream => 'Crème';

  @override
  String get bgColorBeige => 'Beige';

  @override
  String get bgColorSand => 'Sable';

  @override
  String get bgColorStone => 'Pierre';

  @override
  String get bgColorSlate => 'Ardoise';

  @override
  String get bgColorNavyGrey => 'Gris marine';

  @override
  String get bgColorDeepBlueGrey => 'Gris bleu foncé';

  @override
  String get bgColorForestMist => 'Brume de forêt';

  @override
  String get bgColorSage => 'Sauge';

  @override
  String get bgColorPaleBlue => 'Bleu pâle';

  @override
  String get bgColorMistBlue => 'Bleu brumeux';

  @override
  String get bgColorLavenderMist => 'Brume de lavande';

  @override
  String get bgColorBlush => 'Rose poudré';

  @override
  String get bgColorSoftMint => 'Menthe douce';

  @override
  String get bgColorGraphite => 'Graphite';

  @override
  String get premiumBlendsIntoTheme =>
      'S\'intègre à votre thème sélectionné — le texte, les cartes et les icônes s\'adaptent automatiquement.';

  @override
  String premiumCannotDowngradeBody(String date) {
    return 'Vous avez un abonnement Premium Plus actif. Vous pourrez passer à un plan inférieur une fois qu\'il expirera le $date.';
  }

  @override
  String get premiumCannotDowngradeTitle =>
      'Rétrogradation impossible pour l\'instant';

  @override
  String get premiumCardTextReadable => 'Le texte de la carte reste lisible';

  @override
  String get premiumChooseAvatar => 'Choisir un avatar';

  @override
  String get premiumChooseBackground => 'Choisir un arrière-plan';

  @override
  String get premiumConfirmPurchase => 'Confirmer l\'achat';

  @override
  String get premiumCurrentTermEnds => 'la fin de votre période actuelle';

  @override
  String get premiumFeatureColumnHeader => 'Fonctionnalité';

  @override
  String get premiumFeatureListDescription =>
      'Thèmes et avatars personnalisés, 15 salles/jour, jusqu\'à 12 joueurs par salle, 10 packs hors ligne (1 gratuit), chat anonyme, et plus encore.';

  @override
  String get premiumLockedUntilExpires =>
      'Verrouillé jusqu\'à l\'expiration de Premium Plus';

  @override
  String get premiumMonthly => 'Mensuel';

  @override
  String get premiumPageBackground => 'Arrière-plan de la page';

  @override
  String premiumPlanActivated(String plan) {
    return '🎉 $plan activé !';
  }

  @override
  String get premiumPlusLabel => 'Premium Plus';

  @override
  String get premiumPlusShort => 'Plus';

  @override
  String get premiumPremiumAvatars => 'Avatars Premium';

  @override
  String get premiumPremiumThemes => 'Thèmes Premium ✦';

  @override
  String premiumPricePerPeriod(String price, String period) {
    return '$price / $period';
  }

  @override
  String premiumPurchaseConfirmBody(
    String plan,
    String planPrice,
    String period,
  ) {
    return 'Cela déduira $planPrice de votre solde de portefeuille.\n\nPlan : $plan — $planPrice/$period';
  }

  @override
  String premiumPurchasePlan(String plan) {
    return 'Acheter $plan';
  }

  @override
  String get premiumSave33 => 'Économisez 33 %';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumUnlockTitle => 'Débloquer Premium';

  @override
  String get premiumUpgradeToUnlock => 'Passer à Premium pour débloquer';

  @override
  String get premiumWhatYouGet => 'Ce que vous obtenez';

  @override
  String get premiumYearly => 'Annuel';

  @override
  String get premiumYourAvatars => 'Vos avatars';

  @override
  String get premiumYourThemes => 'Vos thèmes';

  @override
  String get resetToDefault => 'Réinitialiser par défaut';

  @override
  String get continueArrow => 'Continuer →';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get noneLabel => 'Aucun';

  @override
  String get packAddFirstCardHint => 'Ajoutez votre première carte ci-dessus !';

  @override
  String get packAddImages => 'Ajouter des images';

  @override
  String packAddMoreMinimum(int count) {
    return 'Ajoutez $count de plus (minimum 10) ou supprimez-les toutes.';
  }

  @override
  String packAdditionalFeeBody(int fee) {
    return 'Ce pack contient des cartes supplémentaires, ce qui nécessite des frais additionnels de $fee MRU pour la soumission en révision.';
  }

  @override
  String get packAdditionalFeeTitle => 'Frais additionnels requis';

  @override
  String get packAgeLabel => 'Âge';

  @override
  String get packAllowedLabel => 'Autorisé';

  @override
  String get packAudienceEveryone => 'Tout le monde';

  @override
  String get packAudienceHint =>
      'Restreignez le public visé par ce pack. Pas encore appliqué en rejoignant une salle — enregistré avec le pack pour un usage ultérieur.';

  @override
  String get packCardTypePrompt => 'Consigne';

  @override
  String get packCardTypeStatement => 'Affirmation';

  @override
  String get packCategoryHintExample => 'ex. Jeux de fête';

  @override
  String get packCategoryOptionalLabel => 'Catégorie (facultatif)';

  @override
  String packCategoryRejectedNoReason(String name) {
    return 'Votre catégorie suggérée « $name » a été rejetée.';
  }

  @override
  String packCategoryRejectedWithReason(String name, String reason) {
    return 'Votre catégorie suggérée « $name » a été rejetée : $reason';
  }

  @override
  String get packCategorySubmittedForReview =>
      'Catégorie soumise pour révision';

  @override
  String get packCoverImageHint =>
      'Cette image apparaît sur la carte du pack dans la boutique.';

  @override
  String get packCoverImageLabel => 'Image de couverture';

  @override
  String get packLivePreviewLabel => 'Aperçu en direct de la carte de jeu';

  @override
  String get packLivePreviewHint =>
      'Voici approximativement ce que les joueurs verront dans le jeu.';

  @override
  String get packCardPreviewSampleText => 'Le texte de la carte apparaîtra ici';

  @override
  String get packCardPreviewSectionLabel => 'Aperçu de la carte';

  @override
  String packCardPreviewCountLabel(int current, int total) {
    return 'Carte $current sur $total';
  }

  @override
  String get packChooseSticker => 'Choisir un autocollant';

  @override
  String get packStickerSelected => 'Autocollant sélectionné';

  @override
  String get packRemoveSticker => 'Retirer l\'autocollant';

  @override
  String get packNoStickersAvailable =>
      'Aucun autocollant disponible pour le moment';

  @override
  String get packCardPreviewEmptyTitle => 'Pas encore de cartes';

  @override
  String get packCardPreviewEmptyBody =>
      'Ajoutez votre première carte ci-dessous et elle apparaîtra ici.';

  @override
  String packCreateTitle(String step) {
    return 'Créer un pack — $step';
  }

  @override
  String packDescriptionFieldLabel(String lang) {
    return 'Description ($lang, facultatif)';
  }

  @override
  String get packDifficultyMedium => 'Moyen';

  @override
  String get packDifficultyMild => 'Doux';

  @override
  String get packDifficultySpicy => '🌶 Épicé';

  @override
  String get packEditPunishment => 'Modifier le gage';

  @override
  String get packEnableSpicyHint =>
      'Activez le contenu épicé dans les paramètres du pack pour ajouter des cartes épicées';

  @override
  String packFailedSuggestCategory(String error) {
    return 'Échec de la suggestion de catégorie : $error';
  }

  @override
  String packFailedToSave(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String packFailedToSaveCards(String error) {
    return 'Échec de l\'enregistrement des cartes : $error';
  }

  @override
  String packFailedToSaveReactions(String error) {
    return 'Échec de l\'enregistrement des réactions : $error';
  }

  @override
  String packFillContentInLanguages(String languages) {
    return 'Veuillez remplir le contenu en : $languages';
  }

  @override
  String get packFreeLabel => 'Gratuit';

  @override
  String get packGameTypeLabel => 'Type de jeu';

  @override
  String get packGameTypeMeme => '😂 Jeu de mèmes';

  @override
  String get packGameTypeNhie => '🍹 Je n\'ai jamais';

  @override
  String get packGameTypeTod => '🎯 Action ou Vérité';

  @override
  String get packGenderFemaleOnly => 'Femmes uniquement';

  @override
  String get packGenderLabel => 'Genre';

  @override
  String get packGenderMaleOnly => 'Hommes uniquement';

  @override
  String get packImportantRulesBody =>
      '• Les packs ne peuvent pas être modifiés après publication.\n• Vous devez acheter votre propre pack pour l\'utiliser dans les jeux.\n• La modération prend 1 à 3 jours ouvrables.';

  @override
  String get packImportantRulesTitle => '📋 Règles importantes :';

  @override
  String get packInformationTitle => 'Informations sur le pack';

  @override
  String get packLangArabic => 'Arabe';

  @override
  String get packLangEnglish => 'Anglais';

  @override
  String get packLangFrench => 'Français';

  @override
  String get packLangGerman => 'Allemand';

  @override
  String get packLangPortuguese => 'Portugais';

  @override
  String get packLangRussian => 'Russe';

  @override
  String get packLangSpanish => 'Espagnol';

  @override
  String get packLangTurkish => 'Turc';

  @override
  String get packMaxReactionImagesReached =>
      'Maximum de 30 images de réaction atteint';

  @override
  String packMinPlayersLabel(int count) {
    return 'Joueurs minimum : $count';
  }

  @override
  String get packSetMaxPlayersToggle => 'Définir un nombre maximum de joueurs';

  @override
  String packMaxPlayersLabel(int count) {
    return 'Joueurs maximum : $count';
  }

  @override
  String packMaxPlayersSliderLabel(int count) {
    return '$count joueurs';
  }

  @override
  String get packNoMaxPlayersHint =>
      'Aucune limite — jouable avec tout groupe au-dessus du minimum';

  @override
  String get packMinimumReached => '✅ Minimum atteint';

  @override
  String packMoreNeeded(int count) {
    return '$count de plus nécessaires';
  }

  @override
  String packNameFieldLabel(String lang) {
    return 'Nom du pack ($lang)*';
  }

  @override
  String get packNameHint => 'ex. Folle nuit de vendredi';

  @override
  String get packNoReactionImagesYet =>
      'Aucune image de réaction pour l\'instant';

  @override
  String get packNotLoggedIn => 'Non connecté';

  @override
  String get packOneNamePerLanguage =>
      'Un nom et une description par langue sélectionnée.';

  @override
  String packPayFeeAndSubmit(int fee) {
    return 'Payer $fee MRU et soumettre';
  }

  @override
  String packPendingAdminReview(String name) {
    return '« $name » est en attente de révision par l\'administrateur';
  }

  @override
  String get packPickExistingCategory => 'Choisir une catégorie existante';

  @override
  String get roomSettingsCategoryFilterLabel => 'Catégorie';

  @override
  String packPlayersSliderLabel(int count) {
    return '$count joueurs';
  }

  @override
  String get packPriceFreeHint => 'Laissez 0 pour un pack gratuit';

  @override
  String packMinPriceError(int min) {
    return 'Les packs payants doivent coûter au moins $min MRU';
  }

  @override
  String get packPriceLabel => 'Prix';

  @override
  String packPriceMru(int price) {
    return '$price MRU';
  }

  @override
  String packPunishmentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gages',
      one: '$count gage',
    );
    return '$_temp0';
  }

  @override
  String get packPunishmentInputHint => 'ex. Faites 10 pompes';

  @override
  String get packPunishmentsEmptyHint =>
      'Facultatif — ajoutez-en, ou passez directement à la publication.';

  @override
  String get packPunishmentsHint =>
      'Affiché au joueur qui passe ou refuse une carte, si le propriétaire de la salle choisit d\'utiliser les gages du pack plutôt que les soumissions en direct des joueurs.';

  @override
  String get packPunishmentsOptionalTitle => 'Gages (facultatif)';

  @override
  String packReactionImageCount(int count) {
    return '$count / 30 images de réaction';
  }

  @override
  String packReactionSlotsRemaining(int count) {
    return '$count emplacements restants';
  }

  @override
  String get packReactionsDescription =>
      'Les joueurs utiliseront ces images comme réactions pendant le jeu. Ajoutez-en jusqu\'à 30. Sinon, des autocollants par défaut sont utilisés.';

  @override
  String get packReactionsOptionalHint =>
      'Facultatif — passez pour utiliser les valeurs par défaut';

  @override
  String get packReadyToPublish => 'Prêt à publier ?';

  @override
  String get packReviewBeforeSubmitting =>
      'Vérifiez votre pack avant de le soumettre à la modération.';

  @override
  String get packSelectLanguagesHint =>
      'Choisissez toutes les langues dans lesquelles vous rédigerez les noms, descriptions et cartes de ce pack.';

  @override
  String get packSpicyLabel => 'Contenu épicé';

  @override
  String get packSpicyContentDisabled =>
      'Le contenu épicé n\'est pas disponible pour le moment.';

  @override
  String get packStepAudience => 'Public';

  @override
  String get packStepCards => 'Cartes';

  @override
  String get packStepGeneralInfo => 'Informations générales';

  @override
  String get packStepLanguages => 'Langues';

  @override
  String get packStepNamesDescriptions => 'Noms et descriptions';

  @override
  String get packStepPublish => 'Publier';

  @override
  String get packStepPunishments => 'Gages';

  @override
  String get packStepReactions => 'Réactions';

  @override
  String packSubmissionFailed(String error) {
    return 'Échec de la soumission : $error';
  }

  @override
  String get packSubmitForReview => 'Soumettre pour révision';

  @override
  String get packEligibilityChecking => 'Vérification de votre éligibilité…';

  @override
  String get packFreeSubmissionAvailable =>
      'Votre soumission gratuite est disponible';

  @override
  String get packFreeSubmissionUnavailable =>
      'Soumission gratuite pas encore disponible';

  @override
  String packNextFreeSubmissionAt(String date) {
    return 'Prochaine soumission gratuite : $date';
  }

  @override
  String packPaidExtraPackHint(int price) {
    return 'Vous pouvez créer un pack supplémentaire maintenant pour $price MRU.';
  }

  @override
  String packCreateExtraPackPriced(int price) {
    return 'Créer un pack supplémentaire — $price MRU';
  }

  @override
  String get packCreatorNotVerified =>
      'Seuls les créateurs vérifiés peuvent soumettre des packs pour révision.';

  @override
  String get packAlreadyHasDraft =>
      'Vous avez déjà un pack brouillon. Terminez-le, publiez-le ou supprimez-le avant d\'en créer un autre.';

  @override
  String get packDraftLimitReachedTitle => 'Limite de brouillons atteinte';

  @override
  String get packDeleteDraft => 'Supprimer le brouillon';

  @override
  String get packDeleteDraftConfirmTitle => 'Supprimer ce brouillon ?';

  @override
  String packDeleteDraftConfirmBody(String title) {
    return '« $title » sera définitivement supprimé. Cette action est irréversible.';
  }

  @override
  String get packDraftDeletedNotice => 'Brouillon supprimé.';

  @override
  String packDeleteDraftFailed(String error) {
    return 'Échec de la suppression du brouillon : $error';
  }

  @override
  String get packSubmittedForReviewNotice =>
      'Pack soumis pour révision ! Vous serez notifié une fois approuvé.';

  @override
  String get packSuggestAgain => 'Suggérer à nouveau';

  @override
  String get packSuggestNew => 'Suggérer une nouvelle';

  @override
  String get packSuggestNewCategory => 'Suggérer une nouvelle catégorie';

  @override
  String get packSummaryCards => 'Cartes';

  @override
  String packSummaryCardsValue(int count, int truthCount, int dareCount) {
    return '$count (${truthCount}V + ${dareCount}A)';
  }

  @override
  String get packSummaryGameType => 'Type de jeu';

  @override
  String get packSummaryPrice => 'Prix';

  @override
  String get packSummarySpicyContent => 'Contenu épicé';

  @override
  String get packSummaryTitle => 'Titre';

  @override
  String get packTapToAddCover => 'Touchez pour ajouter une couverture';

  @override
  String get packTypeDare => 'Action 🔥';

  @override
  String get packTypePrompt => 'Consigne 😂';

  @override
  String get packTypeStatement => 'Affirmation 🍹';

  @override
  String get packTypeTruth => 'Vérité 🤔';

  @override
  String packUploadFailed(String error) {
    return 'Échec du téléversement : $error';
  }

  @override
  String get packUploadingEllipsis => 'Téléversement...';

  @override
  String get packWhoCanPlay => 'Qui peut jouer avec ce pack';

  @override
  String get packAdditionalDetailsOptional =>
      'Détails supplémentaires (facultatif)';

  @override
  String get packAvailableOffline => 'Disponible hors ligne';

  @override
  String get packBrowseMarketplaceHint =>
      'Parcourez la boutique pour trouver des packs.';

  @override
  String get packConfirmPurchaseTitle => 'Confirmer l\'achat';

  @override
  String packConfirmPurchaseBody(String name, String price) {
    return 'Vous êtes sur le point d\'acheter « $name » pour $price.';
  }

  @override
  String get packConfirmPurchaseAction => 'Acheter';

  @override
  String packBuyForPrice(int price) {
    return 'Acheter pour $price MRU';
  }

  @override
  String get packCancelled => 'Annulé';

  @override
  String packCancelledOn(String date) {
    return 'Annulé le $date';
  }

  @override
  String packCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes',
      one: '$count carte',
    );
    return '$_temp0';
  }

  @override
  String packCardsAndSales(int cards, int sales) {
    return '$cards cartes • $sales ventes';
  }

  @override
  String packCardsAvailableOffline(int count) {
    return '$count cartes • Disponible hors ligne';
  }

  @override
  String get packCity => 'Ville';

  @override
  String packCountLabel(int count) {
    return '$count packs';
  }

  @override
  String get packCreateFirstHint =>
      'Créez votre premier pack et partagez-le avec le monde.';

  @override
  String get packCreatePack => 'Créer un pack';

  @override
  String get packCreator => 'Créateur';

  @override
  String get packCreatorLabel => 'Créateur du pack';

  @override
  String get packCreatorStudio => 'Studio créateur';

  @override
  String get packDownload => 'Télécharger';

  @override
  String get packDownloadFailed => 'Échec du téléchargement';

  @override
  String get packDownloadToPlayOfflineHint =>
      'Téléchargez des packs pour jouer sans internet.';

  @override
  String packDownloadingPercent(int percent) {
    return 'Téléchargement… $percent%';
  }

  @override
  String get packExpired => 'Expiré';

  @override
  String packExpiresInDays(int days) {
    return 'Expire dans $days jours';
  }

  @override
  String packExpiresInDaysShort(int days) {
    return 'Expire dans ${days}j';
  }

  @override
  String get packFailedToLoadYourPacks => 'Échec du chargement de vos packs.';

  @override
  String packFailedToRequest(String error) {
    return 'Échec de la demande : $error';
  }

  @override
  String get packFallbackTitle => 'Pack';

  @override
  String get packFeaturedHeading => '⭐ En vedette';

  @override
  String get packFreeOfflineLimitNotice =>
      'Le plan gratuit permet 1 pack hors ligne. Passez à Premium pour 10.';

  @override
  String get packFullName => 'Nom complet';

  @override
  String get packGetFreePack => 'Obtenir le pack gratuit';

  @override
  String get packInsufficientBalance => 'Solde insuffisant';

  @override
  String packInsufficientBalanceBody(int price) {
    return 'Vous avez besoin de $price MRU pour acheter ce pack. Votre solde actuel est trop bas.';
  }

  @override
  String get packLoadingPrice => 'Chargement du prix…';

  @override
  String get packMinReviewLength => 'Veuillez écrire au moins 10 caractères.';

  @override
  String get packMyPhysicalRequests => 'Mes demandes de packs physiques';

  @override
  String get packNewPack => 'Nouveau pack';

  @override
  String get packNoFeaturedPacksYet => 'Aucun pack en vedette pour l\'instant';

  @override
  String get packNoOfflinePacks => 'Aucun pack hors ligne';

  @override
  String get packNoPacksFound => 'Aucun pack trouvé';

  @override
  String get packNoPacksYet => 'Aucun pack pour l\'instant';

  @override
  String get packSearchHint =>
      'Rechercher par nom de pack, créateur ou catégorie…';

  @override
  String get packSearchForPacks => 'Rechercher des packs';

  @override
  String get packSearchMinChars => 'Entrez au moins 2 caractères.';

  @override
  String get packSearchNoResultsHint =>
      'Essayez un autre nom ou une autre catégorie.';

  @override
  String get packNoPurchasedPacks => 'Aucun pack acheté';

  @override
  String get packNoRequestsYet => 'Aucune demande pour l\'instant.';

  @override
  String get packNoReviewsYet =>
      'Aucun avis pour l\'instant. Soyez le premier !';

  @override
  String get packNotFound => 'Pack introuvable.';

  @override
  String get packNotesOptional => 'Notes (facultatif)';

  @override
  String packOfflineLimitReached(int limit) {
    return 'Limite hors ligne atteinte ($limit packs). Supprimez un pack pour en télécharger un autre.';
  }

  @override
  String packOfflineLimitReachedDelete(int limit) {
    return 'Limite hors ligne atteinte ($limit packs). Supprimez-en un pour en télécharger un autre.';
  }

  @override
  String get packOwnedBadge => 'Possédé';

  @override
  String get packPhoneNumber => 'Numéro de téléphone';

  @override
  String get packPhysicalCopyRequested => 'Copie physique demandée !';

  @override
  String packPhysicalFeeNotice(int total, int price, int quantity) {
    return 'Frais : $total MRU ($price × $quantity), débités de votre solde de portefeuille.';
  }

  @override
  String get packPlayer => 'Joueur';

  @override
  String get packProBadge => '★ PRO';

  @override
  String get packOfficialBadge => 'Jma3a';

  @override
  String get packProcessingEllipsis => 'Traitement…';

  @override
  String get packPromotedBadge => 'PROMU';

  @override
  String packPurchaseFailed(String error) {
    return 'Échec de l\'achat : $error';
  }

  @override
  String get packPurchasedNotice =>
      'Pack acheté ! Vous pouvez maintenant le télécharger.';

  @override
  String get packQuantity => 'Quantité';

  @override
  String get packRedownload => 'Retélécharger';

  @override
  String packRejectionReason(String reason) {
    return 'Motif du rejet : $reason';
  }

  @override
  String get packRemoveDownload => 'Supprimer le téléchargement';

  @override
  String packRemoveDownloadBody(String title) {
    return 'Cela supprimera la copie hors ligne de « $title ». Vous pourrez la retélécharger plus tard.';
  }

  @override
  String get packRemoveDownloadTitle => 'Supprimer le téléchargement ?';

  @override
  String get packReport => 'Signaler';

  @override
  String get packReportHint =>
      'Aidez-nous à assurer la sécurité de la boutique.';

  @override
  String get packReportPack => 'Signaler le pack';

  @override
  String get packReportReasonCheating => 'Triche ou manipulation du système';

  @override
  String get packReportReasonHateSpeech => 'Discours de haine';

  @override
  String get packReportReasonInappropriate => 'Contenu inapproprié';

  @override
  String get packReportReasonOther => 'Autre';

  @override
  String get packReportReasonSpam => 'Spam';

  @override
  String get packReportSubmitted => 'Signalement envoyé.';

  @override
  String get packReportAlreadySubmitted => 'Vous avez déjà signalé ce pack.';

  @override
  String get packReportFailed =>
      'Impossible d\'envoyer votre signalement. Veuillez réessayer.';

  @override
  String get packPromoteYourPack => 'Promouvoir votre pack';

  @override
  String get packPromotionDuration24h => '24 heures';

  @override
  String get packPromotionDuration7d => '1 semaine';

  @override
  String get packPromotionSubtitle =>
      'Mettez ce pack en avant dans le carrousel promu pour toucher plus de joueurs.';

  @override
  String get packPromotionSubmit => 'Promouvoir';

  @override
  String get packPromotionSuccess => 'Pack promu avec succès !';

  @override
  String get packPromotionActiveLabel => 'Promotion active';

  @override
  String packPromotionEndsAt(String date) {
    return 'Se termine le $date';
  }

  @override
  String get packPromotionAlreadyActive =>
      'Ce pack a déjà une promotion active.';

  @override
  String get packRequestPhysicalCopy => 'Demander une copie physique';

  @override
  String get packRetryDownload => 'Réessayer le téléchargement';

  @override
  String get packReviewSubmitted => 'Avis envoyé !';

  @override
  String get packReviewSubmitFailed =>
      'Impossible d\'envoyer votre avis. Veuillez réessayer.';

  @override
  String get packReviews => 'Avis';

  @override
  String get packShareThoughtsHint => 'Partagez votre avis sur ce pack…';

  @override
  String get packStageCompleted => 'Terminé';

  @override
  String get packStageDelivered => 'Livré';

  @override
  String get packStageOutForDelivery => 'En cours de livraison';

  @override
  String get packStagePackaging => 'Emballage';

  @override
  String get packStagePaymentConfirmed => 'Paiement confirmé';

  @override
  String get packStagePrinting => 'Impression';

  @override
  String get packStageRequestSubmitted => 'Demande soumise';

  @override
  String get packStageUnderReview => 'En cours de révision';

  @override
  String get packStatAvgRating => 'Note moyenne';

  @override
  String get packStatPublished => 'Publié';

  @override
  String get packStatSales => 'Ventes';

  @override
  String get packStatusArchived => 'Archivé';

  @override
  String get packStatusDraft => 'Brouillon';

  @override
  String get packStatusInReview => 'En révision';

  @override
  String get packStatusPublished => 'Publié';

  @override
  String get packStatusRejected => 'Rejeté';

  @override
  String get packStatusSuspended => 'Suspendu';

  @override
  String get packPlatformManaged => 'Géré par Jma3a';

  @override
  String get packSubmitReport => 'Envoyer le signalement';

  @override
  String get packSubmitRequest => 'Envoyer la demande';

  @override
  String get packSubmitReview => 'Envoyer l\'avis';

  @override
  String get packTabBrowse => 'Parcourir';

  @override
  String get packTabDownloaded => 'Téléchargé';

  @override
  String get packTabFeatured => 'En vedette';

  @override
  String get packTabMyPacks => 'Mes packs';

  @override
  String get packTabPurchased => 'Acheté';

  @override
  String get packTopUpWallet => 'Recharger le portefeuille';

  @override
  String get packWriteReview => 'Écrire un avis';

  @override
  String get packWriteReviewShort => 'Écrire un avis';

  @override
  String get packYouOwnThisPack => 'Vous possédez ce pack';

  @override
  String packYouRatedThis(int rating) {
    return 'Vous avez noté ceci $rating/5';
  }

  @override
  String get packRemoveRating => 'Retirer';

  @override
  String get packRatingRemoved => 'Votre note a été retirée.';

  @override
  String get packRatingFailed =>
      'Impossible d\'enregistrer votre note. Veuillez réessayer.';

  @override
  String get packYourPacks => 'Vos packs';

  @override
  String get packYourRating => 'Votre note :';

  @override
  String get packZoneDistrict => 'Zone / Quartier';

  @override
  String get packZoneHint => 'ex. Tevragh Zeina';

  @override
  String get searchLabel => 'Rechercher';

  @override
  String avatarAlreadyUpdatedNotice(int hours, int mins) {
    return 'Vous avez déjà mis à jour votre avatar. Réessayez dans ${hours}h ${mins}m.';
  }

  @override
  String get avatarCustomAvatarsHint =>
      'Créez votre propre avatar façon Bitmoji et affichez-le partout dans l\'application avec Premium.';

  @override
  String get avatarCustomAvatarsTitle => 'Avatars personnalisés';

  @override
  String get avatarFeelingLucky => 'Vous vous sentez chanceux ?';

  @override
  String get avatarGenerateRandomHint =>
      'Générez un avatar aléatoire instantanément.';

  @override
  String get avatarOnCooldown => 'En attente';

  @override
  String get avatarOptAccessories => 'Accessoires';

  @override
  String get avatarOptEyebrows => 'Sourcils';

  @override
  String get avatarOptEyes => 'Yeux';

  @override
  String get avatarOptFacialHair => 'Pilosité faciale';

  @override
  String get avatarOptFacialHairColor => 'Couleur de la pilosité faciale';

  @override
  String get avatarOptHairColor => 'Couleur des cheveux';

  @override
  String get avatarOptHairStyle => 'Coiffure';

  @override
  String get avatarOptMouth => 'Bouche';

  @override
  String get avatarOptOutfit => 'Tenue';

  @override
  String get avatarOptOutfitColor => 'Couleur de la tenue';

  @override
  String get avatarOptSkinTone => 'Teint de peau';

  @override
  String get avatarRandomizeAvatar => 'Avatar aléatoire';

  @override
  String get avatarReactionsDescription =>
      'Vos réactions d\'avatar (heureux, rire, pleurer et plus) sont disponibles aux côtés des réactions emoji dans Action ou Vérité et Je n\'ai jamais.';

  @override
  String get avatarSaveAvatar => 'Enregistrer l\'avatar';

  @override
  String get avatarSaveFailed => 'Impossible d\'enregistrer pour le moment.';

  @override
  String get avatarSaved => 'Avatar enregistré ! ✦';

  @override
  String get avatarSavingEllipsis => 'Enregistrement…';

  @override
  String get avatarDeleteAction => 'Supprimer l\'avatar';

  @override
  String get avatarDeleteDialogTitle => 'Supprimer votre avatar ?';

  @override
  String get avatarDeleteDialogMessage =>
      'Cela supprime votre avatar personnalisé. Vous reviendrez à votre photo importée ou à l\'apparence par défaut jusqu\'à ce que vous en créiez un nouveau.';

  @override
  String get avatarDeleted => 'Avatar supprimé.';

  @override
  String get avatarDeleteFailed => 'Impossible de supprimer pour le moment.';

  @override
  String get avatarTabExtras => 'Extras';

  @override
  String get avatarTabEyes => 'Yeux';

  @override
  String get avatarTabFace => 'Visage';

  @override
  String get avatarTabHair => 'Cheveux';

  @override
  String get avatarOptTanned => 'Bronzé';

  @override
  String get avatarOptYellow => 'Jaune';

  @override
  String get avatarOptPale => 'Pâle';

  @override
  String get avatarOptLight => 'Clair';

  @override
  String get avatarOptBrown => 'Brun';

  @override
  String get avatarOptDarkBrown => 'Brun foncé';

  @override
  String get avatarOptBlack => 'Noir';

  @override
  String get avatarOptAuburn => 'Auburn';

  @override
  String get avatarOptBlonde => 'Blond';

  @override
  String get avatarOptBlondeGolden => 'Blond doré';

  @override
  String get avatarOptBrownDark => 'Brun foncé';

  @override
  String get avatarOptPastelPink => 'Rose pastel';

  @override
  String get avatarOptPlatinum => 'Platine';

  @override
  String get avatarOptRed => 'Roux';

  @override
  String get avatarOptSilverGray => 'Gris argenté';

  @override
  String get avatarOptNoHair => 'Sans cheveux';

  @override
  String get avatarOptEyepatch => 'Cache-œil';

  @override
  String get avatarOptHat => 'Chapeau';

  @override
  String get avatarOptHijab => 'Hijab';

  @override
  String get avatarOptTurban => 'Turban';

  @override
  String get avatarOptWinterHat1 => 'Bonnet d\'hiver 1';

  @override
  String get avatarOptWinterHat2 => 'Bonnet d\'hiver 2';

  @override
  String get avatarOptWinterHat3 => 'Bonnet d\'hiver 3';

  @override
  String get avatarOptWinterHat4 => 'Bonnet d\'hiver 4';

  @override
  String get avatarOptLongHairBigHair => 'Cheveux longs — Volumineux';

  @override
  String get avatarOptLongHairBob => 'Cheveux longs — Carré';

  @override
  String get avatarOptLongHairBun => 'Cheveux longs — Chignon';

  @override
  String get avatarOptLongHairCurly => 'Cheveux longs — Bouclés';

  @override
  String get avatarOptLongHairCurvy => 'Cheveux longs — Ondulés';

  @override
  String get avatarOptLongHairDreads => 'Cheveux longs — Dreadlocks';

  @override
  String get avatarOptLongHairFrida => 'Cheveux longs — Frida';

  @override
  String get avatarOptLongHairFro => 'Cheveux longs — Afro';

  @override
  String get avatarOptLongHairFroBand => 'Cheveux longs — Afro avec bandeau';

  @override
  String get avatarOptLongHairNotTooLong => 'Cheveux longs — Mi-longs';

  @override
  String get avatarOptLongHairShavedSides => 'Cheveux longs — Tempes rasées';

  @override
  String get avatarOptLongHairMiaWallace => 'Cheveux longs — Mia Wallace';

  @override
  String get avatarOptLongHairStraight => 'Cheveux longs — Raides';

  @override
  String get avatarOptLongHairStraight2 => 'Cheveux longs — Raides 2';

  @override
  String get avatarOptLongHairStraightStrand => 'Cheveux longs — Mèche raide';

  @override
  String get avatarOptShortHairDreads01 => 'Cheveux courts — Dreadlocks 1';

  @override
  String get avatarOptShortHairDreads02 => 'Cheveux courts — Dreadlocks 2';

  @override
  String get avatarOptShortHairFrizzle => 'Cheveux courts — Frisottis';

  @override
  String get avatarOptShortHairShaggyMullet =>
      'Cheveux courts — Mulet ébouriffé';

  @override
  String get avatarOptShortHairShortCurly => 'Cheveux courts — Bouclés courts';

  @override
  String get avatarOptShortHairShortFlat => 'Cheveux courts — Plats';

  @override
  String get avatarOptShortHairShortRound => 'Cheveux courts — Arrondis';

  @override
  String get avatarOptShortHairShortWaved => 'Cheveux courts — Ondulés courts';

  @override
  String get avatarOptShortHairSides => 'Cheveux courts — Sur les côtés';

  @override
  String get avatarOptShortHairTheCaesar => 'Cheveux courts — César';

  @override
  String get avatarOptShortHairTheCaesarSidePart =>
      'Cheveux courts — César avec raie';

  @override
  String get avatarOptBlank => 'Aucun';

  @override
  String get avatarOptKurt => 'Lunettes Kurt';

  @override
  String get avatarOptPrescription01 => 'Lunettes de vue 1';

  @override
  String get avatarOptPrescription02 => 'Lunettes de vue 2';

  @override
  String get avatarOptRound => 'Lunettes rondes';

  @override
  String get avatarOptSunglasses => 'Lunettes de soleil';

  @override
  String get avatarOptWayfarers => 'Wayfarers';

  @override
  String get avatarOptBeardMedium => 'Barbe moyenne';

  @override
  String get avatarOptBeardLight => 'Barbe légère';

  @override
  String get avatarOptBeardMagestic => 'Barbe majestueuse';

  @override
  String get avatarOptMoustacheFancy => 'Moustache raffinée';

  @override
  String get avatarOptMoustacheMagnum => 'Moustache Magnum';

  @override
  String get avatarOptBlazerShirt => 'Blazer et chemise';

  @override
  String get avatarOptBlazerSweater => 'Blazer et pull';

  @override
  String get avatarOptCollarSweater => 'Pull à col';

  @override
  String get avatarOptGraphicShirt => 'Chemise à motif';

  @override
  String get avatarOptHoodie => 'Sweat à capuche';

  @override
  String get avatarOptOverall => 'Salopette';

  @override
  String get avatarOptShirtCrewNeck => 'Chemise col rond';

  @override
  String get avatarOptShirtScoopNeck => 'Chemise col échancré';

  @override
  String get avatarOptShirtVNeck => 'Chemise col en V';

  @override
  String get avatarOptBlue01 => 'Bleu 1';

  @override
  String get avatarOptBlue02 => 'Bleu 2';

  @override
  String get avatarOptBlue03 => 'Bleu 3';

  @override
  String get avatarOptGray01 => 'Gris 1';

  @override
  String get avatarOptGray02 => 'Gris 2';

  @override
  String get avatarOptHeather => 'Chiné';

  @override
  String get avatarOptPastelBlue => 'Bleu pastel';

  @override
  String get avatarOptPastelGreen => 'Vert pastel';

  @override
  String get avatarOptPastelOrange => 'Orange pastel';

  @override
  String get avatarOptPastelRed => 'Rouge pastel';

  @override
  String get avatarOptPastelYellow => 'Jaune pastel';

  @override
  String get avatarOptPink => 'Rose';

  @override
  String get avatarOptWhite => 'Blanc';

  @override
  String get avatarOptClose => 'Fermés';

  @override
  String get avatarOptCry => 'En pleurs';

  @override
  String get avatarOptDefault => 'Par défaut';

  @override
  String get avatarOptDizzy => 'Étourdis';

  @override
  String get avatarOptEyeRoll => 'Yeux au ciel';

  @override
  String get avatarOptHappy => 'Joyeux';

  @override
  String get avatarOptHearts => 'Yeux en cœur';

  @override
  String get avatarOptSide => 'Regard de côté';

  @override
  String get avatarOptSquint => 'Plissés';

  @override
  String get avatarOptSurprised => 'Surpris';

  @override
  String get avatarOptWink => 'Clin d\'œil';

  @override
  String get avatarOptWinkWacky => 'Clin d\'œil loufoque';

  @override
  String get avatarOptAngry => 'En colère';

  @override
  String get avatarOptAngryNatural => 'En colère (naturel)';

  @override
  String get avatarOptDefaultNatural => 'Par défaut (naturel)';

  @override
  String get avatarOptFlatNatural => 'Plat (naturel)';

  @override
  String get avatarOptRaisedExcited => 'Relevés, excités';

  @override
  String get avatarOptRaisedExcitedNatural => 'Relevés, excités (naturel)';

  @override
  String get avatarOptSadConcerned => 'Triste et inquiet';

  @override
  String get avatarOptSadConcernedNatural => 'Triste et inquiet (naturel)';

  @override
  String get avatarOptUnibrowNatural => 'Sourcils joints (naturel)';

  @override
  String get avatarOptUpDown => 'Haut et bas';

  @override
  String get avatarOptUpDownNatural => 'Haut et bas (naturel)';

  @override
  String get avatarOptConcerned => 'Inquiet';

  @override
  String get avatarOptDisbelief => 'Incrédule';

  @override
  String get avatarOptEating => 'En train de manger';

  @override
  String get avatarOptGrimace => 'Grimace';

  @override
  String get avatarOptSad => 'Triste';

  @override
  String get avatarOptScreamOpen => 'Cri';

  @override
  String get avatarOptSerious => 'Sérieux';

  @override
  String get avatarOptSmile => 'Sourire';

  @override
  String get avatarOptTongue => 'Langue tirée';

  @override
  String get avatarOptTwinkle => 'Pétillant';

  @override
  String get avatarOptVomit => 'Vomissement';

  @override
  String get avatarTabMouth => 'Bouche';

  @override
  String get avatarTabOutfit => 'Tenue';

  @override
  String avatarUpdateCooldownNotice(int hours, int mins) {
    return 'Vous pourrez mettre à jour votre avatar à nouveau dans ${hours}h ${mins}m.';
  }

  @override
  String get avatarUpgradeToPremium => 'Passer à Premium ✦';

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileAgeOptionalLabel => 'Âge (facultatif)';

  @override
  String get profileBalanceAndTransactions => 'Solde et transactions';

  @override
  String get profileBioTooLong => '280 caractères maximum';

  @override
  String get profileChangeUsername => 'Changer de nom d\'utilisateur';

  @override
  String get profileChooseColourTheme => 'Choisissez votre thème de couleur';

  @override
  String get profileChooseFromGallery => 'Choisir depuis la galerie';

  @override
  String get profileCooldownActive => 'Délai d\'attente actif';

  @override
  String profileCooldownBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return 'Vous pourrez changer votre nom d\'utilisateur à nouveau dans $_temp0.\n\nLes noms d\'utilisateur ne peuvent être changés qu\'une fois tous les 30 jours.';
  }

  @override
  String get profileCountryAlgeria => 'Algérie';

  @override
  String get profileCountryEgypt => 'Égypte';

  @override
  String get profileCountryFrance => 'France';

  @override
  String get profileCountryGermany => 'Allemagne';

  @override
  String get profileCountryMauritania => 'Mauritanie';

  @override
  String get profileCountryMorocco => 'Maroc';

  @override
  String get profileCountryOptionalLabel => 'Pays (facultatif)';

  @override
  String get profileCountryOther => 'Autre';

  @override
  String get profileCountrySaudiArabia => 'Arabie saoudite';

  @override
  String get profileCountryTunisia => 'Tunisie';

  @override
  String get profileCountryUae => 'EAU';

  @override
  String get profileCountryUnitedKingdom => 'Royaume-Uni';

  @override
  String get profileCountryUnitedStates => 'États-Unis';

  @override
  String get profileCreateAvatarHint => 'Créez votre avatar façon Bitmoji';

  @override
  String get profileCurrentUsername => 'Nom d\'utilisateur actuel';

  @override
  String get profileInfoSection => 'Infos du profil';

  @override
  String get profileMostPlayedPacks => '🔥 Packs les plus joués';

  @override
  String get profileMyAvatar => 'Mon avatar';

  @override
  String get profileMyCreatedPacks => '✏️ Mes packs créés';

  @override
  String get profileNewUsername => 'Nouveau nom d\'utilisateur';

  @override
  String get profilePersonalDetails => 'Détails personnels';

  @override
  String get profilePhoneOptionalLabel => 'Numéro de téléphone (facultatif)';

  @override
  String get profilePreferences => 'Préférences';

  @override
  String profilePremiumActiveExpires(int day, int month, int year) {
    return 'Actif · expire le $day/$month/$year';
  }

  @override
  String get profileSaveUsername => 'Enregistrer le nom d\'utilisateur';

  @override
  String get profileTakePhoto => 'Prendre une photo';

  @override
  String get profileUnlockPremiumHint =>
      'Débloquez thèmes, avatars, chat anonyme et plus';

  @override
  String get profileUploadingPhoto => 'Téléversement de la photo…';

  @override
  String profileUsernameCooldownNotice(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return 'Changement de nom d\'utilisateur disponible dans $_temp0.\nLes changements sont limités à une fois tous les 30 jours.';
  }

  @override
  String get profileUsernameHint => 'lowercase_letters_123';

  @override
  String get profileUsernamePermanentNotice =>
      'Les changements de nom d\'utilisateur sont permanents pendant 30 jours.';

  @override
  String get profileUsernameRequirements =>
      '3 à 30 caractères · lettres, chiffres, tirets bas';

  @override
  String get profileUsernameTaken => 'Ce nom d\'utilisateur est déjà pris.';

  @override
  String get profileUsernameUpdated => 'Nom d\'utilisateur mis à jour !';

  @override
  String get profileUsernameValidation =>
      '3 à 30 caractères, uniquement a-z, 0-9, _';

  @override
  String get profileVerifiedCreator => 'Créateur vérifié';

  @override
  String get notifARoom => 'une salle';

  @override
  String get notifAllCaughtUp => 'Vous êtes à jour !';

  @override
  String get notifDecline => 'Refuser';

  @override
  String notifDeclineFailed(String error) {
    return 'Échec : $error';
  }

  @override
  String get notifInApp => 'Dans l\'appli';

  @override
  String get notifInvitedYouToJoin => 'Vous a invité à rejoindre';

  @override
  String get notifMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notifNoNotifications => 'Aucune notification';

  @override
  String get notifPreferences => 'Préférences';

  @override
  String get notifPreferencesTitle => 'Préférences de notification';

  @override
  String get notifPush => 'Push';

  @override
  String notifRoomInvitesCount(int count) {
    return 'Invitations de salle ($count)';
  }

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifTypeAchievement => 'Succès';

  @override
  String get notifTypeFollow => 'Nouvel abonné';

  @override
  String get notifTypeFriendAccepted => 'Ami accepté';

  @override
  String get notifTypeFriendRequest => 'Demande d\'ami';

  @override
  String get notifTypeGameStarted => 'Partie commencée';

  @override
  String get notifTypeModeration => 'Modération';

  @override
  String get notifTypePackApproved => 'Pack approuvé';

  @override
  String get notifTypePackExpired => 'Pack expiré';

  @override
  String get notifTypePackRejected => 'Pack rejeté';

  @override
  String get notifTypePackReview => 'Avis sur le pack';

  @override
  String get notifTypePackSale => 'Vente de pack';

  @override
  String get notifTypePhysicalPackStatus => 'Mise à jour de la commande';

  @override
  String get notifTypeRoomInvite => 'Invitation de salle';

  @override
  String get notifTypeRoomJoinRequest => 'Demande pour rejoindre la salle';

  @override
  String get notifTypeRoomJoinRequestAccepted => 'Demande d\'adhésion acceptée';

  @override
  String get notifTypeRoomJoinRequestRejected => 'Demande d\'adhésion refusée';

  @override
  String get notifTypeRoomKicked => 'Retiré de la salle';

  @override
  String get notifTypeChatMessage => 'Message de discussion';

  @override
  String get notifTypeStreakIncreased => 'Série';

  @override
  String get notifTypeCreatorPacksTransferred => 'Packs gérés par Jma3a';

  @override
  String get notifTypeCreatorPrivilegesRemoved => 'Statut de créateur retiré';

  @override
  String get notifTypeCreatorRecoveryApproved =>
      'Demande de récupération approuvée';

  @override
  String get notifTypeCreatorRecoveryRejected =>
      'Demande de récupération rejetée';

  @override
  String get notifTypeSubscriptionExpired => 'Abonnement expiré';

  @override
  String get notifTypeSubscriptionExpiring1d => 'Abonnement expire dans 1 jour';

  @override
  String get notifTypeSubscriptionExpiring2d =>
      'Abonnement expire dans 2 jours';

  @override
  String get notifTypeSubscriptionStarted => 'Abonnement activé';

  @override
  String get notifTypeSystem => 'Système';

  @override
  String get notifTypeWalletCredit => 'Crédit du portefeuille';

  @override
  String get notifTypeWalletDebit => 'Débit du portefeuille';

  @override
  String get viewLabel => 'Voir';

  @override
  String get chatTitle => 'Chat';

  @override
  String get gameSettingsAllowOneReplay => 'Autoriser une seule relecture';

  @override
  String get gameSettingsProofViewDuration =>
      'Durée d\'affichage de la preuve (se ferme automatiquement après)';

  @override
  String get gameSettingsProofUnlimitedDuration =>
      'Durée illimitée (jusqu\'au prochain tour)';

  @override
  String get gameSettingsProofReplayHint =>
      'Les membres premium obtiennent une relecture supplémentaire au-delà.';

  @override
  String gameSettingsProofAutoCloseHint(int seconds) {
    return 'La preuve se ferme automatiquement après ${seconds}s — pas de relecture tant qu\'une durée est définie.';
  }

  @override
  String get gameSettingsRequireApprovalToSpectate =>
      'Exiger une approbation pour observer';

  @override
  String get moderationBanPlayer => 'Bannir le joueur';

  @override
  String get moderationDuration1Hour => '1 heure';

  @override
  String get moderationDuration24Hours => '24 heures';

  @override
  String get moderationDuration30Min => '30 minutes';

  @override
  String get moderationDuration7Days => '7 jours';

  @override
  String get moderationDurationPermanent => 'Permanent';

  @override
  String get moderationReasonOptional => 'Motif (facultatif)';

  @override
  String get roomsAnonymousModeOn => 'Mode anonyme activé';

  @override
  String get roomsAnonymousSender => 'Anonyme';

  @override
  String get roomsChatDisabled => 'Chat désactivé';

  @override
  String get roomsChooseYourRole => 'Choisissez votre rôle dans cette salle.';

  @override
  String get roomsClosed => 'Fermée';

  @override
  String roomsAgoMinutes(int count) {
    return 'il y a $count min';
  }

  @override
  String roomsAgoHours(int count) {
    return 'il y a $count h';
  }

  @override
  String roomsAgoDays(int count) {
    return 'il y a $count j';
  }

  @override
  String roomsClosedAgo(String ago) {
    return 'Fermée $ago';
  }

  @override
  String get roomsClosedRoomFallback => 'Salle fermée';

  @override
  String get roomsConnConnecting => 'Connexion…';

  @override
  String get roomsConnDisconnected => 'Déconnecté';

  @override
  String get roomsConnLive => 'En direct';

  @override
  String get roomsConnReconnecting => 'Reconnexion…';

  @override
  String get roomsConnSyncing => 'Synchronisation…';

  @override
  String roomsFailedToSendRequest(String error) {
    return 'Échec de l\'envoi de la demande : $error';
  }

  @override
  String get roomsFallbackRoom => 'Salle';

  @override
  String get roomsGameAlreadyInProgress => 'Cette partie est déjà en cours.';

  @override
  String get roomsGameInProgress => 'Partie en cours';

  @override
  String get roomsHiddenFromPlayersList =>
      'Caché de la liste des joueurs et spectateurs';

  @override
  String get roomsInvalidCodeOrNotFound => 'Code invalide ou salle introuvable';

  @override
  String get roomsInvite => 'Inviter';

  @override
  String get roomsJoinAsPlayer => 'Rejoindre en tant que joueur';

  @override
  String get roomsMakeModerator => 'Nommer modérateur';

  @override
  String roomsManagePermissionsCount(int count) {
    return 'Gérer les permissions ($count)';
  }

  @override
  String get roomsMessageAsAnonymous => 'Envoyer un message en anonyme…';

  @override
  String get roomsModeration => 'Modération';

  @override
  String get roomsObserveWithoutPlaying => 'Observer sans jouer';

  @override
  String roomsPackRequiresMinPlayers(int count) {
    return 'Ce pack nécessite au moins $count joueurs.';
  }

  @override
  String roomsPackRequiresMaxPlayers(int count) {
    return 'Ce pack ne peut être joué que par $count joueurs. Passez les joueurs en trop en spectateurs ou retirez-les pour démarrer.';
  }

  @override
  String get roomsPendingEllipsis => 'En attente…';

  @override
  String get roomsPermAcceptJoins => 'Accepter les demandes d\'adhésion';

  @override
  String get roomsPermAcceptRejoins => 'Accepter les demandes de retour';

  @override
  String get roomsPermAcceptSpectators =>
      'Accepter les demandes de spectateurs';

  @override
  String get roomsPermAdvanceTurn => 'Démarrer le tour suivant';

  @override
  String get roomsPermEndGame => 'Terminer la partie';

  @override
  String get roomsPermKickPlayers => 'Retirer des joueurs';

  @override
  String get roomsPermManageSettings => 'Gérer les paramètres de la salle';

  @override
  String get roomsPermSetSpectator => 'Passer des joueurs en spectateurs';

  @override
  String get roomsPermMuteChat => 'Couper le chat';

  @override
  String get roomsPermMutePlayers => 'Couper les joueurs dans la partie';

  @override
  String get roomsPermSkipTurn => 'Passer un tour';

  @override
  String get roomsPermStartGame => 'Démarrer la partie';

  @override
  String get roomsRejoin => 'Rejoindre à nouveau';

  @override
  String get roomsRejoinRequestDeclined =>
      'Votre demande de retour a été refusée';

  @override
  String get roomsRequestAgain => 'Redemander';

  @override
  String get roomsRequestSentWaiting =>
      'Demande envoyée — en attente de l\'hôte';

  @override
  String get roomsRequestToRejoin => 'Demander à rejoindre';

  @override
  String get roomsSendAnonymouslyPremium => 'Envoyer anonymement (Premium)';

  @override
  String get roomsStatusClosed => 'Fermée';

  @override
  String get roomsStatusInGame => 'En partie';

  @override
  String get roomsStatusPaused => 'En pause';

  @override
  String get roomsStatusWaiting => 'En attente';

  @override
  String get roomsTakePartInGame => 'Participer à la partie';

  @override
  String roomsTransferOwnershipConfirm(String name) {
    return 'Transférer la propriété de la salle à $name ? Vous deviendrez un joueur ordinaire.';
  }

  @override
  String get roomsWaitingForReconnecting =>
      'En attente des joueurs en reconnexion...';

  @override
  String get roomsWatchAnonymously => 'Observer anonymement ✦';

  @override
  String get roomsWatchAsSpectator => 'Observer en tant que spectateur';

  @override
  String get sharedApprove => 'Approuver';

  @override
  String get sharedBan => 'Bannir';

  @override
  String get sharedBanPlayerBody =>
      'Voulez-vous vraiment bannir ce joueur de cette salle ?';

  @override
  String get sharedBanPlayerTitle => 'Bannir le joueur';

  @override
  String get sharedEndGame => 'Terminer la partie';

  @override
  String get sharedEveryoneLeftNotice =>
      'Tous les autres joueurs sont partis. La partie ne peut pas continuer — terminez-la quand vous êtes prêt.';

  @override
  String sharedGameRulesTitle(String gameName) {
    return '$gameName — Règles';
  }

  @override
  String get sharedGoHome => 'Retour à l\'accueil';

  @override
  String get sharedHistoryTooltip => 'Historique';

  @override
  String get sharedReactionAvatarsTab => 'Avatars';

  @override
  String get sharedReactionIconsTab => 'Icônes';

  @override
  String get sharedReactionPickIconTitle => 'Choisir une réaction';

  @override
  String get sharedReactionPickAvatarTitle => 'Choisir une réaction d\'avatar';

  @override
  String get sharedReactionCategoryPopular => 'Populaire';

  @override
  String get sharedReactionCategoryLove => 'Amour';

  @override
  String get sharedReactionCategoryFunny => 'Drôle';

  @override
  String get sharedReactionCategoryShock => 'Choc';

  @override
  String get sharedReactionCategoryCelebration => 'Célébration';

  @override
  String get sharedReactionCategorySocial => 'Social';

  @override
  String get sharedReactionCategoryMoody => 'Humeur';

  @override
  String get gameResultSkipped => 'Passé';

  @override
  String get gameResultDidNotRespond => 'N\'a pas répondu à temps';

  @override
  String sharedJoinRequestFailed(String error) {
    return 'Échec : $error';
  }

  @override
  String sharedJoinRequestsCount(int count) {
    return 'Demandes d\'adhésion ($count)';
  }

  @override
  String get sharedKick => 'Expulser';

  @override
  String get sharedKickPlayerBody =>
      'Voulez-vous vraiment retirer ce joueur de la partie en cours ?';

  @override
  String get sharedKickPlayerTitle => 'Expulser le joueur';

  @override
  String get sharedMemeRuleObjective =>
      'Soumettez la légende ou l\'autocollant le plus drôle pour la consigne du tour, puis votez pour votre préféré parmi ceux des autres.';

  @override
  String get sharedMemeRuleScoring =>
      'Celui qui obtient le plus de votes lors d\'un tour remporte le point de ce tour. Le plus de points à la fin remporte la partie.';

  @override
  String get sharedMemeRuleTurnFlow =>
      'Phase de soumission → phase de vote → résultats, à chaque tour, jusqu\'à épuisement des consignes du pack ou atteinte de la limite de tours.';

  @override
  String get sharedMute => 'Muet';

  @override
  String get sharedNhieRuleObjective =>
      'Chaque tour affiche une déclaration « Je n\'ai jamais… ». Tout le monde répond honnêtement s\'il l\'a fait ou non.';

  @override
  String get sharedNhieRuleScoring =>
      'Votre historique de réponses honnêtes construit votre profil tout au long de la partie — il n\'y a pas de gagnant/perdant, juste des révélations.';

  @override
  String get sharedNhieRuleTurnFlow =>
      'Une nouvelle déclaration apparaît à chaque tour ; chaque joueur vote, puis le tour avance une fois que tout le monde a répondu.';

  @override
  String get sharedNoPendingJoinRequests =>
      'Aucune demande d\'adhésion en attente';

  @override
  String get sharedPageNotFound => 'Page introuvable';

  @override
  String get sharedPageNotFoundHint =>
      'La page que vous recherchez n\'existe pas.';

  @override
  String get sharedReject => 'Rejeter';

  @override
  String get sharedRemoveSpectator => 'Retirer le statut de spectateur';

  @override
  String get sharedSetSpectator => 'Passer en spectateur';

  @override
  String get sharedSetSpectatorBody =>
      'Ce joueur ne comptera plus comme joueur actif et ne pourra plus jouer son tour, mais pourra toujours regarder. Vous pouvez annuler cela à tout moment.';

  @override
  String get sharedSetSpectatorTitle => 'Passer en spectateur';

  @override
  String get sharedRoomMembers => 'Membres de la salle';

  @override
  String sharedRoomMembersCount(int count) {
    return '👥 Membres de la salle ($count)';
  }

  @override
  String get sharedRoomSettingsTitle => 'Paramètres de cette salle';

  @override
  String get sharedRuleNoTurnTimer => 'Aucune minuterie de tour';

  @override
  String get sharedRuleObjective => 'Objectif';

  @override
  String get sharedRulePolicyEveryone => 'tout le monde dans la partie';

  @override
  String get sharedRulePolicyPlayersOnly => 'joueurs uniquement';

  @override
  String get sharedRulePolicySpectatorsOnly => 'spectateurs uniquement';

  @override
  String get sharedRuleProofViewOnce =>
      'La preuve peut être visionnée une fois (Premium : deux fois).';

  @override
  String get sharedRuleProofViewTwice =>
      'La preuve peut être visionnée deux fois (Premium : trois fois).';

  @override
  String sharedRuleProofVisibleTo(String policy) {
    return 'La preuve est visible par : $policy.';
  }

  @override
  String get sharedRulePunishmentOff =>
      'Le mode gage est DÉSACTIVÉ — passer n\'est pas proposé comme option.';

  @override
  String get sharedRulePunishmentOn =>
      'Le mode gage est ACTIVÉ — passer signifie que chaque autre joueur soumet un gage et vous choisissez lequel vous ferez.';

  @override
  String get sharedRuleScoring => 'Score';

  @override
  String get sharedRuleSpectatorsApprovalRequired =>
      'Les spectateurs sont autorisés, sous réserve de l\'approbation de l\'hôte.';

  @override
  String get sharedRuleSpectatorsFreelyAllowed =>
      'Les spectateurs sont autorisés à regarder librement.';

  @override
  String get sharedRuleSpectatorsNotAllowed =>
      'Les spectateurs ne sont pas autorisés dans cette salle.';

  @override
  String get sharedRuleSpicyEnabled =>
      'Le contenu épicé est activé pour cette salle.';

  @override
  String get sharedRuleTurnFlow => 'Déroulement du tour';

  @override
  String sharedRuleTurnTimer(int seconds) {
    return 'Minuterie de tour : ${seconds}s';
  }

  @override
  String get sharedRules => 'Règles';

  @override
  String get sharedStatusDisconnected => 'Déconnecté';

  @override
  String get sharedStatusMuted => 'Muet';

  @override
  String get sharedStatusPlaying => 'En train de jouer';

  @override
  String get sharedStatusSpectator => 'Spectateur';

  @override
  String get sharedTodRuleObjective =>
      'À tour de rôle, choisissez Action ou Vérité. Répondez honnêtement ou accomplissez le gage — il n\'y a pas d\'option « sûre » une fois choisi.';

  @override
  String get sharedTodRuleScoring =>
      'Les vérités et gages complétés s\'ajoutent à votre score. Les passes sont aussi suivies — elles peuvent déclencher un gage (voir ci-dessous).';

  @override
  String get sharedTodRuleTurnFlow =>
      'Le joueur actuel choisit Action ou Vérité, reçoit une carte, puis y répond/l\'accomplit ou (si autorisé) passe. Le tour passe ensuite au joueur suivant dans l\'ordre.';

  @override
  String get sharedUnmute => 'Réactiver le son';

  @override
  String sharedWantsToJoinCurrentGame(String name) {
    return '$name souhaite rejoindre la partie en cours.';
  }

  @override
  String get friendsAccept => 'Accepter';

  @override
  String get friendsReject => 'Refuser';

  @override
  String get friendsDecline => 'Refuser';

  @override
  String get friendsPendingRequestsHeader => 'Demandes d\'amitié en attente';

  @override
  String get friendsYourFriendsHeader => 'Vos amis';

  @override
  String get friendsAdd => 'Ajouter';

  @override
  String get friendsAddFriend => 'Ajouter un ami';

  @override
  String get friendsBlock => 'Bloquer';

  @override
  String get friendsReport => 'Signaler';

  @override
  String get friendsReportAndBlock => 'Signaler et bloquer';

  @override
  String get friendsReportUserTitle => 'Signaler l\'utilisateur';

  @override
  String get friendsReportHint => 'Aidez-nous à garder la communauté sûre.';

  @override
  String get friendsReportReasonHarassment => 'Harcèlement';

  @override
  String get friendsReportReasonImpersonation => 'Usurpation d\'identité';

  @override
  String get friendsReportReasonUnderage => 'Utilisateur mineur';

  @override
  String get friendsBlocked => 'Bloqué';

  @override
  String get friendsCancelRequest => 'Annuler la demande';

  @override
  String get friendsCannotInteract =>
      'Vous ne pouvez pas interagir avec cet utilisateur.';

  @override
  String friendsCreatedBy(String name) {
    return 'Créé par $name';
  }

  @override
  String get friendsOfficialAccount => 'Compte officiel Jma3a';

  @override
  String friendsFollowersCount(int count) {
    return '$count abonnés';
  }

  @override
  String get friendsFollow => 'Suivre';

  @override
  String get friendsFollowersTitle => 'Abonnés';

  @override
  String get friendsNoFollowersYet => 'Pas encore d\'abonnés.';

  @override
  String friendsMostPlayedBy(String name) {
    return 'Les plus joués par $name';
  }

  @override
  String get friendsNoBlockedUsers => 'Aucun utilisateur bloqué';

  @override
  String get friendsNoBlockedUsersHint =>
      'Les personnes que vous bloquez apparaîtront ici.';

  @override
  String get friendsNoFriendsHint =>
      'Découvrez des personnes et connectez-vous avec des joueurs.';

  @override
  String get friendsNoFriendsYet => 'Aucun ami pour l\'instant';

  @override
  String get friendsNoPendingRequests => 'Aucune demande en attente';

  @override
  String get friendsNoPendingRequestsHint =>
      'Les demandes d\'ami que vous recevez apparaîtront ici.';

  @override
  String get friendsNoResults => 'Aucun résultat';

  @override
  String get friendsNoResultsHint =>
      'Essayez un autre nom ou nom d\'utilisateur.';

  @override
  String friendsOfflineCount(int count) {
    return 'Hors ligne — $count';
  }

  @override
  String friendsOnlineCount(int count) {
    return 'En ligne — $count';
  }

  @override
  String get creatorVerificationTitle => 'Devenir créateur vérifié';

  @override
  String get creatorVerificationSubtitle =>
      'Remplissez toutes ces conditions pour demander la vérification créateur.';

  @override
  String get creatorReqPremiumPlus => 'Abonné Premium Plus';

  @override
  String creatorReqGamesPlayed(int count) {
    return 'Jouer au moins $count parties';
  }

  @override
  String creatorReqPacksUsed(int count) {
    return 'Utiliser au moins $count packs';
  }

  @override
  String creatorReqFollowers(int count) {
    return 'Avoir au moins $count abonnés';
  }

  @override
  String creatorReqLoginStreak(int count) {
    return 'Ouvrir l\'application $count jours d\'affilée';
  }

  @override
  String creatorReqRoomStreak(int count) {
    return 'Créer une salle chaque jour pendant $count jours d\'affilée';
  }

  @override
  String creatorReqPackGamesStreak(int count, int days) {
    return 'Terminer au moins $count parties de packs chaque jour pendant $days jours d\'affilée';
  }

  @override
  String get creatorReqPlayedWithOthers =>
      'Jouer une partie avec d\'autres utilisateurs';

  @override
  String get creatorApplyNow => 'Postuler maintenant';

  @override
  String get creatorKeepGoing =>
      'Continuez — vous pourrez postuler une fois toutes les conditions remplies.';

  @override
  String get creatorRecoveryBannerTitle =>
      'Votre statut de créateur vérifié a été retiré';

  @override
  String get creatorRecoveryBannerBody =>
      'Votre abonnement Premium Plus a expiré et votre statut de créateur vérifié/vos privilèges ont été automatiquement retirés. Vous pouvez soumettre une demande de récupération pour examen par un administrateur.';

  @override
  String get creatorRecoveryBannerAction =>
      'Soumettre une demande de récupération';

  @override
  String get creatorRecoveryTitle => 'Demande de récupération';

  @override
  String get creatorRecoveryIntro =>
      'Expliquez-nous ce qui s\'est passé. Un administrateur examinera votre demande et, en cas d\'approbation, votre statut de créateur vérifié, vos privilèges et vos packs seront entièrement restaurés.';

  @override
  String get creatorRecoveryReasonLabel => 'Motif';

  @override
  String get creatorRecoveryReasonResubscribedLate =>
      'Je me suis réabonné mais après la période de grâce';

  @override
  String get creatorRecoveryReasonPaymentIssue =>
      'Un problème de paiement/facturation a causé l\'expiration';

  @override
  String get creatorRecoveryReasonUnawareOfExpiry =>
      'Je n\'ai pas été informé de l\'expiration de mon abonnement';

  @override
  String get creatorRecoveryReasonExtenuatingCircumstances =>
      'Des circonstances atténuantes ont empêché le renouvellement';

  @override
  String get creatorRecoveryReasonOther => 'Autre';

  @override
  String get creatorRecoveryExplanationLabel => 'Explication';

  @override
  String get creatorRecoveryExplanationHint =>
      'Expliquez ce qui s\'est passé en au moins 20 caractères';

  @override
  String get creatorRecoveryExplanationTooShort =>
      'Veuillez écrire au moins 20 caractères pour expliquer ce qui s\'est passé.';

  @override
  String get creatorRecoveryEvidenceLabel => 'Preuve (facultatif)';

  @override
  String get creatorRecoveryEvidenceUploadFailed =>
      'Impossible de téléverser cette image. Veuillez réessayer.';

  @override
  String get creatorRecoverySubmit => 'Envoyer la demande';

  @override
  String get creatorRecoverySubmitted =>
      'Votre demande de récupération a été soumise pour examen.';

  @override
  String get creatorRecoveryFailed =>
      'Impossible d\'envoyer votre demande de récupération. Veuillez réessayer.';

  @override
  String get creatorRecoveryPendingTitle =>
      'Demande de récupération en attente';

  @override
  String get creatorRecoveryPendingBody =>
      'Votre demande de récupération est en cours d\'examen par un administrateur. Vous serez averti dès qu\'une décision sera prise.';

  @override
  String get creatorRecoveryRejectedTitle =>
      'Votre demande de récupération précédente a été rejetée';

  @override
  String get creatorApplyDialogTitle => 'Demande de vérification';

  @override
  String get creatorApplyDialogRealName => 'Nom légal complet';

  @override
  String get creatorApplyDialogBio => 'Courte bio (facultatif)';

  @override
  String get creatorApplySubmitted =>
      'Demande envoyée ! Nous l\'examinerons bientôt.';

  @override
  String get creatorApplyFailed =>
      'Échec de l\'envoi de la demande. Réessayez.';

  @override
  String get profileBecomeCreator => 'Devenir créateur vérifié';

  @override
  String get profileBecomeCreatorHint =>
      'Débloquez les outils créateur et les revenus';

  @override
  String get friendsPlayingNow => 'Joue en ce moment';

  @override
  String get friendsProfileNotFound => 'Profil introuvable.';

  @override
  String get friendsReceived => 'Reçues';

  @override
  String get friendsRemoveFriend => 'Retirer l\'ami';

  @override
  String get friendsRequests => 'Demandes';

  @override
  String get friendsSearchForFriends => 'Rechercher des amis';

  @override
  String get friendsSearchHint => 'Rechercher par nom d\'utilisateur ou nom…';

  @override
  String get friendsSearchMinChars => 'Saisissez au moins 2 caractères.';

  @override
  String friendsSentCount(int count) {
    return 'Envoyées — $count';
  }

  @override
  String get friendsStatusInGame => 'En partie';

  @override
  String get friendsStatusOffline => 'Hors ligne';

  @override
  String get friendsStatusOnline => 'En ligne';

  @override
  String get presenceUserIsAway => 'Absent';

  @override
  String get presenceUserIsAwayFull => 'L\'utilisateur est absent';

  @override
  String presenceUserAwaySnackbar(String name) {
    return '$name est absent';
  }

  @override
  String get friendsStatusInRoomLobby => 'Dans le salon d\'attente';

  @override
  String friendsStatusPlayingGame(String game) {
    return 'Joue à $game';
  }

  @override
  String get friendsUnblock => 'Débloquer';

  @override
  String friendsUnblockedNotice(String name) {
    return '$name débloqué';
  }

  @override
  String get friendsUnfollow => 'Ne plus suivre';

  @override
  String get friendsUserFallback => 'Utilisateur';

  @override
  String get friendsYouHaveBlocked => 'Vous avez bloqué cet utilisateur.';

  @override
  String get notifJustNow => 'À l\'instant';

  @override
  String notifMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a ${count}m',
      one: 'il y a ${count}m',
    );
    return '$_temp0';
  }

  @override
  String get settingsAboutUs => 'À propos de nous';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTermsConditions => 'Conditions d\'utilisation';

  @override
  String get settingsRequestAccountDeletion =>
      'Demander la suppression du compte';

  @override
  String get settingsRequestAccountDeletionPending =>
      'Demande de suppression en cours d\'examen';

  @override
  String get deleteAccountDialogTitle => 'Supprimer votre compte ?';

  @override
  String get deleteAccountDialogMessage =>
      'Cette action soumet une demande que notre équipe examinera — votre compte n\'est pas supprimé immédiatement. Une fois approuvée, votre profil, vos packs, le solde de votre portefeuille et votre historique de jeu seront définitivement supprimés, et cette action est irréversible.';

  @override
  String get deleteAccountDialogConfirm => 'Envoyer la demande';

  @override
  String get deleteAccountSubmitted =>
      'Votre demande de suppression de compte a été soumise pour examen.';

  @override
  String get deleteAccountAlreadyPending =>
      'Vous avez déjà une demande de suppression en cours d\'examen.';

  @override
  String get settingsCancelAccountDeletion =>
      'Annuler la suppression du compte';

  @override
  String get settingsCancelAccountDeletionHint =>
      'Votre compte restera actif si vous annulez avant son traitement.';

  @override
  String get settingsCancelAccountDeletionDialogTitle =>
      'Annuler la demande de suppression ?';

  @override
  String get settingsCancelAccountDeletionDialogMessage =>
      'Votre compte restera actif et rien ne sera supprimé.';

  @override
  String get settingsCancelAccountDeletionConfirm => 'Annuler la demande';

  @override
  String get settingsAccountDeletionCancelled =>
      'Votre demande de suppression de compte a été annulée.';

  @override
  String get settingsCancelAccountDeletionFailed =>
      'Impossible d\'annuler votre demande. Elle a peut-être déjà été traitée — veuillez réessayer ou contacter le support.';

  @override
  String get aboutUsTitle => 'À propos de nous';

  @override
  String get aboutUsVersionLabel => 'Version';

  @override
  String get aboutUsDescription =>
      'Jma3a est une plateforme sociale de jeux de société multijoueurs développée et détenue par MOUJ TECH. Jouez à Action ou Vérité, Je n\'ai jamais et des jeux de mèmes avec vos amis et votre famille, créez et partagez vos propres packs, construisez votre profil et, en tant que Créateur Vérifié, gagnez de l\'argent grâce aux packs que vous publiez.';

  @override
  String get aboutUsCompanySectionTitle => 'Entreprise';

  @override
  String get aboutUsCompanyInfo =>
      'Jma3a est développé et détenu par MOUJ TECH. MOUJ TECH est responsable du développement, des fonctionnalités et de l\'exploitation continue de l\'application, y compris les packs créés par la communauté, les outils du Créateur Vérifié, Premium et Premium Plus, ainsi que le portefeuille de gains des créateurs.';

  @override
  String get moujTechDevelopedBy => 'Développé par MOUJ TECH';

  @override
  String get aboutUsContactTitle => 'Contact';

  @override
  String get aboutUsContactEmail => 'support@jma3a.app';

  @override
  String get aboutUsWebsiteTitle => 'Site web';

  @override
  String get aboutUsWebsite => 'www.jma3a.app';

  @override
  String get aboutUsFollowUsTitle => 'Suivez-nous';

  @override
  String get aboutUsSocialTiktok => 'TikTok';

  @override
  String get aboutUsSocialSnapchat => 'Snapchat';

  @override
  String get aboutUsSocialFacebook => 'Facebook';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get privacyPolicyIntro =>
      'Cette politique de confidentialité explique quelles informations l\'application Jma3a collecte, comment elles sont utilisées, et les choix qui s\'offrent à vous. Elle décrit les fonctionnalités réelles et actuelles de l\'application. Certains détails juridiques propres à la société MOUJ TECH (comme son adresse enregistrée et ses canaux de contact officiels) sont encore en cours de finalisation et seront ajoutés ici dès qu\'ils seront disponibles — cela ne change rien à ce qui est décrit ci-dessous sur la manière dont l\'application elle-même traite vos informations.';

  @override
  String get privacySectionInfoCollected => 'Informations que nous collectons';

  @override
  String get privacySectionInfoCollectedBody =>
      'Informations de compte : l\'adresse e-mail avec laquelle vous vous inscrivez, ainsi que votre nom d\'utilisateur, nom affiché, biographie et avatar (photo importée ou avatar généré). Authentification : votre mot de passe est géré par notre fournisseur d\'authentification et ne nous est jamais visible en texte clair ; la connexion utilise aussi des codes de vérification à usage unique envoyés à votre e-mail. Activité et données sociales : les salons et parties que vous rejoignez ou animez, vos actions en jeu, vos scores et séries, les messages de chat envoyés dans les salons, ainsi que vos amis, abonnés et tout compte que vous bloquez. Achats et activité de créateur : les packs que vous achetez ou publiez, votre statut de Créateur Vérifié, le solde de votre portefeuille et l\'historique des paiements, et — si vous commandez un pack physique — le nom, le numéro de téléphone et la zone de livraison que vous fournissez pour cette commande. Signalements : si vous signalez un pack, nous enregistrons le motif et les détails que vous ajoutez. Demandes de suppression de compte : si vous demandez la suppression de votre compte, nous enregistrons le motif choisi et le statut de la demande. Informations sur l\'appareil et l\'application : la version et le numéro de build de l\'application, ainsi que des informations de base sur la plateforme (Android ou iOS), utilisées pour assurer le bon fonctionnement de l\'application et vérifier les mises à jour requises.';

  @override
  String get privacySectionHowUsed => 'Comment nous utilisons vos informations';

  @override
  String get privacySectionHowUsedBody =>
      'Nous utilisons vos informations pour faire fonctionner les fonctionnalités essentielles de l\'application : créer et sécuriser votre compte, vous mettre en relation avec des salons et des parties, afficher votre profil et vos statistiques aux autres joueurs et amis comme prévu par chaque fonctionnalité, traiter les achats de packs et les paiements des créateurs, livrer les commandes de packs physiques que vous demandez, examiner les signalements et les demandes de suppression de compte, et envoyer les notifications décrites ci-dessous. Nous n\'utilisons aucun outil d\'analyse ou de suivi publicitaire tiers dans cette application. Nous ne vendons pas vos informations.';

  @override
  String get privacySectionNotifications => 'Notifications';

  @override
  String get privacySectionNotificationsBody =>
      'Jma3a envoie des notifications pour des événements tels que les invitations à jouer, l\'activité des salons, les demandes d\'amis et les messages. L\'envoi des notifications push est géré via OneSignal, un service de notification tiers ; certaines notifications sont également planifiées directement sur votre appareil. Vous pouvez gérer les autorisations de notification à tout moment depuis les paramètres système de votre appareil.';

  @override
  String get privacySectionPurchases => 'Achats';

  @override
  String get privacySectionPurchasesBody =>
      'Certains packs sont payants, et Premium/Premium Plus sont des abonnements payants. Les Créateurs Vérifiés peuvent publier des packs et en tirer des revenus via un portefeuille intégré à l\'application. Jma3a ne collecte ni ne stocke directement les détails complets de votre carte de paiement ; les paiements sont traités via les moyens de paiement proposés au moment du règlement. Les enregistrements d\'achats et de paiements (montants, identifiants de pack/abonnement et statut) sont conservés dans le cadre de votre compte et de votre historique de créateur.';

  @override
  String get privacySectionUserContent => 'Contenu généré par l\'utilisateur';

  @override
  String get privacySectionUserContentBody =>
      'Les packs, cartes et autres contenus que vous créez et publiez peuvent être visibles par d\'autres utilisateurs selon la fonctionnalité utilisée pour les créer (par exemple, un pack publié dans la marketplace). Les messages de chat que vous envoyez dans un salon sont visibles par les autres membres de ce salon. Vous êtes responsable du contenu que vous choisissez de créer et de partager.';

  @override
  String get privacySectionAccountDeletion => 'Suppression du compte';

  @override
  String get privacySectionAccountDeletionBody =>
      'Vous pouvez demander la suppression de votre compte depuis les Paramètres. Cela soumet une demande pour examen — votre compte n\'est pas supprimé immédiatement. Tant que la demande est en attente, vous pouvez l\'annuler depuis les Paramètres et votre compte reste actif. Une fois la demande acceptée et traitée, la suppression est irréversible, et votre profil, vos packs, le solde de votre portefeuille et votre historique de jeu sont définitivement supprimés.';

  @override
  String get privacySectionThirdParty => 'Services tiers';

  @override
  String get privacySectionThirdPartyBody =>
      'Jma3a s\'appuie sur un nombre restreint de services tiers pour fonctionner : notre base de données backend et notre fournisseur d\'authentification, un espace de stockage cloud pour les images que vous importez (comme les avatars et les couvertures de packs), et OneSignal pour les notifications push. Ces prestataires ne traitent les données que dans la mesure nécessaire pour fournir leur service à Jma3a.';

  @override
  String get privacySectionContact => 'Nous contacter';

  @override
  String privacySectionContactBody(String email) {
    return 'Pour toute question concernant cette politique de confidentialité ou vos informations, contactez-nous à $email.';
  }

  @override
  String get termsConditionsTitle => 'Conditions d\'utilisation';

  @override
  String get termsConditionsIntro =>
      'Ces Conditions d\'utilisation régissent votre utilisation de Jma3a, une application de jeux sociaux multijoueurs développée et exploitée par MOUJ TECH. En créant un compte ou en utilisant l\'application, vous acceptez ces Conditions.';

  @override
  String get termsSectionAccount => 'Comptes';

  @override
  String get termsSectionAccountBody =>
      'Vous devez avoir au moins 13 ans pour créer un compte Jma3a. Vous pouvez vous inscrire avec un numéro de téléphone ou une adresse e-mail, vérifiés par un code à usage unique. Vous êtes responsable de la sécurité de vos identifiants et de toute activité sur votre compte.';

  @override
  String get termsSectionAcceptableUse => 'Utilisation acceptable';

  @override
  String get termsSectionAcceptableUseBody =>
      'Vous acceptez d\'utiliser Jma3a de manière respectueuse et de ne pas harceler, menacer ou insulter d\'autres utilisateurs, usurper leur identité, ou utiliser l\'application à des fins illégales. Toute violation peut entraîner la suppression de contenu, des restrictions de fonctionnalités ou la suspension du compte.';

  @override
  String get termsSectionContent => 'Votre contenu';

  @override
  String get termsSectionContentBody =>
      'Vous conservez la propriété du contenu que vous créez, comme votre profil ou les packs et cartes que vous réalisez. En publiant du contenu sur Jma3a, vous nous accordez le droit de l\'afficher et de le diffuser dans l\'application afin que les autres utilisateurs puissent le voir et interagir avec lui. Vous êtes responsable du contenu que vous créez ou partagez.';

  @override
  String get termsSectionCreators => 'Créateurs et comptes officiels';

  @override
  String get termsSectionCreatorsBody =>
      'Jma3a propose un statut de Créateur vérifié aux créateurs de contenu éligibles, affiché sur leur profil. Ce statut peut être accordé ou retiré selon la conduite de votre compte et le respect de ces Conditions. Un compte officiel Jma3a peut également apparaître dans l\'application pour partager des annonces et des réponses.';

  @override
  String get termsSectionRoomsGames => 'Salons et jeux';

  @override
  String get termsSectionRoomsGamesBody =>
      'Jma3a vous permet de créer ou de rejoindre des salons pour jouer à des jeux multijoueurs avec des amis et d\'autres joueurs, en utilisant des packs de contenu fournis par Jma3a ou créés par les utilisateurs. Les hôtes et membres d\'un salon sont tenus de respecter ces Conditions pendant le jeu.';

  @override
  String get termsSectionPremium => 'Premium et Premium Plus';

  @override
  String get termsSectionPremiumBody =>
      'Jma3a propose des abonnements Premium et Premium Plus facultatifs qui débloquent des fonctionnalités et avantages supplémentaires dans l\'application. Le contenu de chaque formule peut évoluer ; ce qui est inclus vous sera indiqué avant l\'achat.';

  @override
  String get termsSectionWallet => 'Portefeuille et paiements';

  @override
  String get termsSectionWalletBody =>
      'Jma3a inclut un portefeuille intégré qui peut être rechargé via les moyens de paiement locaux pris en charge. Les créateurs peuvent gagner un solde grâce à leur contenu et demander des retraits, sous réserve de l\'examen de Jma3a. Les paiements sont également soumis aux conditions du fournisseur du moyen de paiement utilisé.';

  @override
  String get termsSectionModeration => 'Signalement et modération';

  @override
  String get termsSectionModerationBody =>
      'Vous pouvez signaler ou bloquer d\'autres utilisateurs et du contenu qui enfreint ces Conditions. Jma3a peut examiner les signalements et prendre des mesures, notamment la suppression de contenu, la restriction de fonctionnalités, ou la suspension ou résiliation de comptes qui enfreignent ces Conditions.';

  @override
  String get termsSectionTermination => 'Suspension et résiliation';

  @override
  String get termsSectionTerminationBody =>
      'Nous pouvons suspendre ou résilier votre compte si vous enfreignez ces Conditions, utilisez l\'application de manière abusive, ou adoptez un comportement frauduleux ou nuisible. Vous pouvez également demander la suppression de votre compte et de vos données à tout moment.';

  @override
  String get termsSectionAvailability => 'Disponibilité du service';

  @override
  String get termsSectionAvailabilityBody =>
      'Jma3a est fourni \"tel quel disponible\". Nous pouvons modifier, suspendre ou interrompre certaines parties de l\'application à tout moment, et nous ne garantissons pas un service ininterrompu ou sans erreur.';

  @override
  String get termsSectionChanges => 'Modifications de ces Conditions';

  @override
  String get termsSectionChangesBody =>
      'Nous pouvons mettre à jour ces Conditions de temps à autre. Continuer à utiliser Jma3a après la publication de modifications signifie que vous acceptez les Conditions mises à jour.';

  @override
  String get termsSectionContact => 'Nous contacter';

  @override
  String termsSectionContactBody(String email) {
    return 'Pour toute question concernant ces Conditions, contactez-nous à $email.';
  }

  @override
  String get accountSuspendedDialogTitle => 'Compte suspendu';

  @override
  String accountSuspendedUntil(String until) {
    return 'Votre compte a été suspendu jusqu\'au $until.';
  }

  @override
  String get accountBannedPermanently =>
      'Votre compte a été définitivement suspendu de Jma3a.';

  @override
  String get appUpdateAvailableTitle => 'Mise à jour disponible';

  @override
  String get appUpdateDefaultTitle => 'Une nouvelle version est disponible';

  @override
  String get appUpdateDefaultMessage =>
      'Veuillez mettre à jour l\'application pour continuer à profiter des dernières fonctionnalités.';

  @override
  String get appUpdateNowButton => 'Mettre à jour';

  @override
  String get appUpdateLaterButton => 'Plus tard';

  @override
  String get appUpdateBannerMessage =>
      'Une nouvelle version de Jma3a est disponible.';

  @override
  String get deleteAccountReasonPrompt => 'Pourquoi partez-vous ?';

  @override
  String get deleteAccountReasonNoLongerUse =>
      'Je n\'utilise plus l\'application';

  @override
  String get deleteAccountReasonPrivacy =>
      'Préoccupations liées à la confidentialité';

  @override
  String get deleteAccountReasonFoundAnother =>
      'J\'ai trouvé une autre application';

  @override
  String get deleteAccountReasonTooManyNotifications => 'Trop de notifications';

  @override
  String get deleteAccountReasonTechnicalProblems => 'Problèmes techniques';

  @override
  String get deleteAccountReasonTemporaryBreak => 'Pause temporaire';

  @override
  String get deleteAccountReasonOther => 'Autre';

  @override
  String get deleteAccountReasonOtherHint =>
      'Merci de nous en dire plus (requis)';

  @override
  String get deleteAccountReasonValidation => 'Veuillez sélectionner un motif';

  @override
  String get deleteAccountOtherDescriptionValidation =>
      'Veuillez décrire votre motif';

  @override
  String get deleteAccountContinueButton => 'Continuer';

  @override
  String get tutHomeNavTitle => 'Naviguer';

  @override
  String get tutHomeNavBody =>
      'Passez d\'ici entre Salons, Amis, la Boutique et votre Profil.';

  @override
  String get tutBrowserCreateTitle => 'Créer un salon';

  @override
  String get tutBrowserCreateBody =>
      'Créez votre salon, choisissez un jeu et invitez vos amis.';

  @override
  String get tutBrowserJoinCodeTitle => 'Rejoindre avec un code';

  @override
  String get tutBrowserJoinCodeBody =>
      'Vous avez un code d\'invitation ? Saisissez-le ici pour entrer dans un salon privé.';

  @override
  String get tutBrowserFilterTitle => 'Trouver une partie';

  @override
  String get tutBrowserFilterBody =>
      'Filtrez les salons publics par type de jeu pour en trouver un ouvert.';

  @override
  String get tutCreateNameTitle => 'Nommez votre salon';

  @override
  String get tutCreateNameBody =>
      'Donnez un nom à votre salon pour que vos amis le reconnaissent.';

  @override
  String get tutCreateVisibilityTitle => 'Public ou privé';

  @override
  String get tutCreateVisibilityBody =>
      'Les salons publics apparaissent dans Parcourir pour tous. Les salons privés sont sur invitation.';

  @override
  String get tutCreateSpectatorsTitle => 'Spectateurs';

  @override
  String get tutCreateSpectatorsBody =>
      'Laissez des personnes regarder sans jouer. Les spectateurs n\'affectent jamais la partie.';

  @override
  String get tutCreateButtonTitle => 'Créer et animer';

  @override
  String get tutCreateButtonBody =>
      'Vous devenez l\'hôte — vous contrôlez le salon et lancez la partie.';

  @override
  String get tutLobbyManageTitle => 'Gérer votre salon';

  @override
  String get tutLobbyManageBody =>
      'En tant qu\'hôte, fermez le salon aux nouveaux joueurs puis rouvrez-le plus tard — sans terminer la partie.';

  @override
  String get tutLobbyStartTitle => 'Lancer la partie';

  @override
  String get tutLobbyStartBody =>
      'Seul l\'hôte lance la partie. Assurez-vous que tout le monde est prêt.';

  @override
  String get tutLobbyReadyTitle => 'Se déclarer prêt';

  @override
  String get tutLobbyReadyBody =>
      'Touchez pour indiquer à l\'hôte que vous êtes prêt. La partie démarre quand tous le sont.';

  @override
  String get tutMembersTitle => 'Gérer les joueurs';

  @override
  String get tutMembersBody =>
      'En tant qu\'hôte, touchez un joueur pour le rendre muet, l\'exclure ou le bannir. Muet : il ne peut plus agir ; exclu : il est retiré ; banni : il ne peut plus revenir.';

  @override
  String get tutTodTitle => 'Action ou Vérité';

  @override
  String get tutTodBody =>
      'Le joueur en cours s\'affiche ici. Il choisit Vérité ou Action et l\'accomplit, puis c\'est au suivant.';

  @override
  String get tutNhieTitle => 'À vous de répondre';

  @override
  String get tutNhieBody =>
      'Lisez l\'affirmation, puis donnez votre réponse ci-dessous. Les résultats s\'affichent quand tout le monde a répondu.';

  @override
  String get tutNhieSpectatorBody =>
      'Suivez et observez les réponses — les spectateurs ne votent pas.';

  @override
  String get tutMemeTitle => 'Réagissez au mème';

  @override
  String get tutMemeBody =>
      'Choisissez une réaction ou un autocollant pour ce mème et validez. Les choix les plus drôles gagnent la manche.';

  @override
  String get tutReplayTitle => 'Revoir les tutoriels';

  @override
  String get tutReplaySubtitle => 'Afficher à nouveau les guides intégrés';

  @override
  String get tutReplayDone =>
      'Tutoriels réinitialisés — ils réapparaîtront au fil de votre progression.';

  @override
  String get lobbyAnonymousSpectator => 'Spectateur anonyme';

  @override
  String get packIssuesHeader => 'Corrigez ceci avant de soumettre :';

  @override
  String get packIssueTitle => 'Ajoutez un nom pour chaque langue sélectionnée';

  @override
  String get packIssueCards => 'Ajoutez au moins 20 cartes';

  @override
  String get packIssueLanguage =>
      'Chaque carte doit avoir du contenu dans toutes les langues sélectionnées';

  @override
  String packIssuePrice(int min) {
    return 'Fixez un prix d\'au moins $min MRU';
  }

  @override
  String get packIssueBalance =>
      'Les packs Action ou Vérité nécessitent autant de cartes Vérité que d\'Action';

  @override
  String get packIssuePunishments =>
      'Ajoutez au moins 10 gages, ou supprimez-les tous';

  @override
  String get packIssueTerms => 'Acceptez les conditions de création de pack';

  @override
  String get packIssuePlayerRange =>
      'Le nombre maximum de joueurs doit être au moins égal au minimum';

  @override
  String get packTermsAgreePrefix => 'J\'accepte les ';

  @override
  String get packTermsAgreeLink => 'conditions de création de pack';

  @override
  String get packTermsTitle => 'Conditions de création de pack';

  @override
  String get packTermsBody =>
      'En soumettant un pack, vous confirmez que : vous possédez ou avez le droit de partager tout le contenu ; le contenu ne porte atteinte aux droits de personne et ne contient rien d\'illégal, haineux ou harcelant ; vous acceptez la révision de contenu de Jma3a et le pack peut être rejeté ou retiré ; et les packs payants sont soumis aux politiques de revenus et de remboursement de la plateforme. Les packs doivent respecter le prix minimum et, pour Action ou Vérité, contenir autant de cartes Vérité que d\'Action.';

  @override
  String packMinPriceLabel(int min) {
    return 'Le prix minimum est de $min MRU';
  }

  @override
  String packTruthDareBalanceHint(int truth, int dare) {
    return 'Les packs Action ou Vérité nécessitent autant de cartes Vérité que d\'Action. Vous avez $truth Vérité et $dare Action.';
  }

  @override
  String get exploreAddFriend => 'Ajouter en ami';

  @override
  String get exploreEmptyHint =>
      'Revenez bientôt — de nouvelles personnes rejoignent le pool de découverte à mesure que la communauté grandit.';

  @override
  String get exploreEmptyTitle => 'Personne à découvrir pour l’instant';

  @override
  String get exploreLoadFailed =>
      'Impossible de charger les personnes à découvrir.';

  @override
  String get exploreRequestSent => 'Demande envoyée';

  @override
  String get exploreSearchHint => 'Rechercher par nom d\'utilisateur ou nom…';

  @override
  String get exploreSubtitle => 'Découvrez des joueurs classés par réputation';

  @override
  String get exploreTabLabel => 'Explorer';

  @override
  String get honestyReasonHint =>
      'Qu’est-ce qui a semblé malhonnête ? (3 caractères minimum)';

  @override
  String get honestyReasonSheetTitle => 'Pourquoi n\'était-ce pas honnête ?';

  @override
  String honestyReasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count joueurs ont signalé ceci comme malhonnête',
      one: '1 joueur a signalé ceci comme malhonnête',
    );
    return '$_temp0';
  }

  @override
  String get profileStreakActive => 'Série active';

  @override
  String get profileStreakInactive =>
      'Série inactive — jouez aujourd\'hui pour la maintenir';

  @override
  String get officialResponsesTitle => 'Réponses officielles';

  @override
  String get officialResponsesReviews => 'Avis';

  @override
  String get officialResponsesWarnings => 'Avertissements';

  @override
  String get officialResponsesBansAndSuspensions =>
      'Bannissements et suspensions';

  @override
  String get officialResponsesRequestsAndDecisions => 'Demandes et décisions';

  @override
  String get officialResponsesEmpty => 'Rien ici pour l\'instant';

  @override
  String officialResponseExpiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get walletDepositsUnavailable =>
      'Les dépôts sont temporairement indisponibles.';

  @override
  String get walletWithdrawalsUnavailable =>
      'Les retraits sont temporairement indisponibles.';

  @override
  String get walletFinanceServiceUnavailable =>
      'Service financier temporairement indisponible';

  @override
  String get authIdentifierLabel => 'E-mail ou numéro de téléphone';

  @override
  String get authIdentifierHint => 'vous@exemple.com ou 12345678';

  @override
  String get authIdentifierRequired =>
      'Entrez votre e-mail ou numéro de téléphone';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordHint => 'Entrez votre mot de passe';

  @override
  String get authPasswordRequired => 'Le mot de passe est requis';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get authPasswordTooLong =>
      'Le mot de passe doit contenir au plus 72 caractères';

  @override
  String get authPasswordNeedsLetterAndDigit =>
      'Le mot de passe doit contenir au moins une lettre et un chiffre';

  @override
  String get authPasswordConfirmationLabel => 'Confirmer le mot de passe';

  @override
  String get authPasswordConfirmationHint => 'Ressaisissez votre mot de passe';

  @override
  String get authPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authShowPassword => 'Afficher le mot de passe';

  @override
  String get authHidePassword => 'Masquer le mot de passe';

  @override
  String get authLogIn => 'Se connecter';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authInvalidCredentials =>
      'E-mail/téléphone ou mot de passe incorrect.';

  @override
  String get authSetPasswordTitle => 'Définir un mot de passe';

  @override
  String get authSetPasswordSubtitle =>
      'Créez un mot de passe pour vous connecter sans code la prochaine fois';

  @override
  String get authSetPasswordSubmit => 'Commencer à jouer';

  @override
  String get authResetPasswordTitle => 'Réinitialiser votre mot de passe';

  @override
  String get authResetPasswordSubtitle =>
      'Choisissez un nouveau mot de passe pour votre compte';

  @override
  String get authResetPasswordSubmit => 'Réinitialiser le mot de passe';

  @override
  String get authPasswordSetSuccess => 'Mot de passe défini avec succès';

  @override
  String get authPasswordResetSuccess =>
      'Mot de passe réinitialisé avec succès';

  @override
  String get authForgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get authForgotPasswordSubtitle =>
      'Entrez votre e-mail ou numéro de téléphone et nous vous enverrons un code';

  @override
  String get authForgotPasswordSendCode => 'Envoyer le code';

  @override
  String get authBackToLogin => 'Retour à la connexion';

  @override
  String get authMethodPhone => 'Téléphone';

  @override
  String get authMethodPhoneHint => '+222 ...';

  @override
  String get authMethodEmail => 'E-mail';

  @override
  String get authMethodEmailHint => 'nom@exemple.com';

  @override
  String get authSignupTitle => 'Rejoindre Jma3a 🎉';

  @override
  String get authSignupSubtitle => 'Comment souhaitez-vous vous inscrire ?';

  @override
  String get authContinue => 'Continuer';

  @override
  String get authAlreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get authPhoneInvalid => 'Entrez votre numéro mauritanien à 8 chiffres';

  @override
  String get authWelcomeBack => 'Content de vous revoir 👋';

  @override
  String get authReadyToPlay => 'Prêt à jouer ?';

  @override
  String get authLegacyNoPasswordTitle => 'Pas encore de mot de passe';

  @override
  String get authLegacyNoPasswordBody =>
      'Ce compte n\'a pas encore de mot de passe. Vérifiez-le avec un code à usage unique pour en créer un.';

  @override
  String get authVerifyWithOtp => 'Vérifier avec un code';

  @override
  String get authDontHaveAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get passwordSettingsTitle => 'Mot de passe et sécurité';

  @override
  String get passwordSettingsUpdateTitle => 'Mettre à jour le mot de passe';

  @override
  String get passwordSettingsUpdateSubtitle =>
      'Changez votre mot de passe en toute sécurité.';

  @override
  String get passwordSettingsVerifyButton => 'Vérifier le mot de passe actuel';

  @override
  String get passwordSettingsChangeButton => 'Changer le mot de passe';

  @override
  String get passwordSettingsOtpNotice =>
      'Nous vous enverrons un code de vérification pour confirmer votre identité avant d\'appliquer ce changement.';

  @override
  String get passwordSettingsCurrentLabel => 'Mot de passe actuel';

  @override
  String get passwordSettingsNewLabel => 'Nouveau mot de passe';

  @override
  String get passwordSettingsConfirmLabel =>
      'Confirmer le nouveau mot de passe';

  @override
  String get passwordSettingsNoPasswordTitle => 'Mot de passe';

  @override
  String get passwordSettingsNoPasswordBody =>
      'Vous n\'avez pas encore défini de mot de passe.';

  @override
  String get passwordSettingsHasPasswordBody =>
      'Votre mot de passe est défini.';

  @override
  String get passwordSettingsSetButton =>
      'Définir un mot de passe avec un code';

  @override
  String get passwordSettingsChangeSuccess => 'Mot de passe changé avec succès';

  @override
  String get settingsPassword => 'Mot de passe et sécurité';

  @override
  String get settingsPasswordSubtitleReady =>
      'Appuyez pour changer votre mot de passe';

  @override
  String get settingsPasswordSubtitleNotSet =>
      'Vous n\'avez pas encore défini de mot de passe';

  @override
  String get authAccountAlreadyExists =>
      'Un compte avec ce numéro/e-mail existe déjà. Veuillez vous connecter.';
}
