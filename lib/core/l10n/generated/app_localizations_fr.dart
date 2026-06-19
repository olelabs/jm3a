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
  String get next => 'Suivant';

  @override
  String get back => 'Retour';

  @override
  String get skip => 'Passer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get remove => 'Retirer';

  @override
  String get close => 'Fermer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get or => 'ou';

  @override
  String get optional => 'Optionnel';

  @override
  String characters(int count, int max) {
    return '$count / $max';
  }

  @override
  String get error => 'Une erreur s\'est produite';

  @override
  String get errorNetwork => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get errorUnexpected =>
      'Une erreur inattendue s\'est produite. Réessayez.';

  @override
  String get errorNotFound => 'Introuvable';

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
  String get authSendingOtp => 'Envoi en cours…';

  @override
  String authOtpSent(String email) {
    return 'Code envoyé à $email';
  }

  @override
  String get authOtpLabel => 'Code de vérification';

  @override
  String get authOtpHint => 'Entrez le code à 6 chiffres';

  @override
  String get authOtpVerify => 'Vérifier';

  @override
  String get authOtpVerifying => 'Vérification…';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get authOtpExpired => 'Code expiré. Veuillez en demander un nouveau.';

  @override
  String get authOtpInvalid => 'Code invalide. Réessayez.';

  @override
  String get authOtpMaxAttempts =>
      'Trop de tentatives. Demandez un nouveau code.';

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
  String get profileTitle => 'Profil';

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
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutConfirm =>
      'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get roomsTitle => 'Salles';

  @override
  String get roomsBrowse => 'Parcourir les salles';

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
  String get roomsJoining => 'Connexion…';

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
  String get roomsBanned => 'Vous êtes banni de cette salle';

  @override
  String get lobbyTitle => 'Salle d\'attente';

  @override
  String get lobbyWaiting => 'En attente de joueurs…';

  @override
  String get lobbyReady => 'Prêt';

  @override
  String get lobbyNotReady => 'Pas prêt';

  @override
  String get lobbyStartGame => 'Démarrer la partie';

  @override
  String get lobbySelectGame => 'Choisir le jeu';

  @override
  String get lobbySelectPack => 'Choisir le pack';

  @override
  String get lobbyCopied => 'Code copié !';

  @override
  String get lobbyLeave => 'Quitter la salle';

  @override
  String get lobbyLeaveConfirm => 'Voulez-vous vraiment quitter ?';

  @override
  String lobbyOwnerLeft(String name) {
    return '$name est maintenant propriétaire de la salle';
  }

  @override
  String lobbyPlayerJoined(String name) {
    return '$name a rejoint';
  }

  @override
  String lobbyPlayerLeft(String name) {
    return '$name est parti';
  }

  @override
  String get chatPlaceholder => 'Dites quelque chose…';

  @override
  String get chatMuted => 'Vous êtes en sourdine';

  @override
  String get chatSend => 'Envoyer';

  @override
  String get gameSettings => 'Paramètres du jeu';

  @override
  String get gameSettingsTurnTimer => 'Minuteur de tour';

  @override
  String get gameSettingsAllowSkip => 'Autoriser le passage';

  @override
  String get gameSettingsMaxRounds => 'Nombre max de tours';

  @override
  String get gameSettingsAllowSpicy => 'Autoriser le contenu épicé';

  @override
  String gameSettingsSeconds(int n) {
    return '${n}s';
  }

  @override
  String get gameReconnecting => 'Reconnexion…';

  @override
  String get gameRecovering => 'Synchronisation…';

  @override
  String get gameConnectionLost => 'Connexion perdue';

  @override
  String get gameConnectionLostBody =>
      'Impossible de se reconnecter après plusieurs tentatives.';

  @override
  String get gameLeaveRoom => 'Quitter la salle';

  @override
  String get gameTryAgain => 'Réessayer';

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
  String get moderationYouWereMuted => 'Vous avez été mis en sourdine';

  @override
  String get moderationGamePaused => 'Jeu en pause';

  @override
  String get moderationGameResumed => 'Jeu repris';

  @override
  String get roomsJoinRequestSent =>
      'Demande envoyée ! En attente de l\'approbation de l\'hôte.';

  @override
  String get roomsRequiresApproval =>
      'Cette salle nécessite une approbation pour rejoindre';

  @override
  String get roomsJoinApproved => 'Votre demande a été approuvée !';

  @override
  String get roomsJoinRejected => 'Votre demande a été refusée.';

  @override
  String get roomsSpectators => 'Spectateurs';

  @override
  String roomsSpectatorCount(int count) {
    return '$count regardent';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifFriendRequests => 'Demandes d\'amis';

  @override
  String get settingsNotifRoomInvites => 'Invitations de salle';

  @override
  String get settingsNotifGameActions => 'Actions de jeu';

  @override
  String get settingsNotifWallet => 'Mises à jour du portefeuille';

  @override
  String get settingsNotifPackSales => 'Ventes de packs';

  @override
  String get walletEarnings => 'Gains';

  @override
  String get walletEarningsTotal => 'Total gagné';

  @override
  String get walletEarningsThisMonth => 'Ce mois-ci';

  @override
  String get walletEarningsTotalSales => 'Ventes totales';

  @override
  String get walletEarningsAvailable => 'Disponible';

  @override
  String get walletEarningsCommissionRate => 'Votre taux';

  @override
  String get walletTransactionHistory => 'Historique des transactions';

  @override
  String get profileGames => 'Jeux';

  @override
  String get profileFriends => 'Amis';

  @override
  String get profilePacks => 'Packs';

  @override
  String get profileFollowers => 'Abonnés';

  @override
  String get profileFollowing => 'Abonnements';

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String profileGamesPlayed(int count) {
    return '$count parties';
  }

  @override
  String get gameSettingsSpicy => 'Cartes épicées';

  @override
  String get gameSettingsRequireApproval =>
      'Approbation requise pour rejoindre';

  @override
  String get gameSettingsAllowSpectators => 'Autoriser les spectateurs';

  @override
  String get lobbyJoinRequests => 'Demandes de participation';

  @override
  String get lobbyApprove => 'Approuver';

  @override
  String get lobbyReject => 'Refuser';

  @override
  String get packCategory => 'Catégorie';

  @override
  String get packCategoryHint => 'Choisir une catégorie';

  @override
  String get packCategoryNone => 'Aucune catégorie';
}
