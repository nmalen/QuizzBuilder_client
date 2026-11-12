// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get standardMode => 'Standard';

  @override
  String get survivalMode => 'Survie';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Moyen';

  @override
  String get hard => 'Difficile';

  @override
  String get appTitle => 'QuizzBuilder';

  @override
  String welcomeMessage(String userName) {
    return 'Bienvenue, $userName!';
  }

  @override
  String get readyToTest => 'Prêt à tester vos connaissances?';

  @override
  String get playQuiz => 'Jouer au Quiz';

  @override
  String get playQuizSubtitle => 'Sélectionnez des catégories, des thèmes et défiez-vous';

  @override
  String get buildQuiz => 'Construire un Quiz';

  @override
  String get buildQuizSubtitle => 'Composez votre propre quiz à partir de thèmes';

  @override
  String get store => 'Boutique';

  @override
  String get storeSubtitle => 'Déverrouiller les thèmes et catégories premium';

  @override
  String get availableContent => 'Contenu disponible';

  @override
  String get quizzBuilderContent => 'QuizzBuilder';

  @override
  String get quizzBuilderContentSubtitle => 'Contenu actif total (y compris non acheté)';

  @override
  String get userContent => 'Utilisateur';

  @override
  String get userContentSubtitle => 'Contenu déverrouillé';

  @override
  String selectedContent(int categories, String categoryPlural, int themes, String themePlural, int questions, String questionPlural) {
    return 'Sélectionné: $categories catégor$categoryPlural • $themes thème$themePlural • $questions question$questionPlural';
  }

  @override
  String get noSelection => 'Aucune sélection pour l\'instant. Allez à Construire un Quiz pour en créer une.';

  @override
  String get categories => 'Catégories';

  @override
  String get themes => 'Thèmes';

  @override
  String get questions => 'Questions';

  @override
  String get score => 'Score';

  @override
  String get logout => 'Déconnexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get account => 'Compte';

  @override
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get optOutButton => 'Suppression du compte';

  @override
  String get optOutDescription => 'Demander la suppression de votre compte et de toutes les données associées.';

  @override
  String get optOutConfirmTitle => 'Confirmer la suppression du compte';

  @override
  String get optOutConfirmMessage => 'Êtes-vous sûr de vouloir supprimer votre compte ? Toutes vos données utilisateur, y compris vos achats, seront supprimées dans un délai de 30 jours. Après confirmation, vous ne pourrez plus accéder à l\'application.';

  @override
  String get optOutRecordedTitle => 'Demande enregistrée';

  @override
  String get optOutConfirmAction => 'Confirmer';

  @override
  String get optOutSuccess => 'Votre demande de suppression a été enregistrée. Un email de confirmation a été envoyé. Vous allez maintenant être déconnecté.';

  @override
  String get optOutAlreadyRequested => 'Votre compte est déjà programmé pour suppression. Vous allez maintenant être déconnecté.';

  @override
  String get optOutError => 'Impossible de demander la suppression du compte pour le moment. Veuillez réessayer.';

  @override
  String get pendingDeletionTitle => 'Demande de suppression en attente';

  @override
  String get pendingDeletionMessage => 'Une demande de suppression de compte est active. Si vous souhaitez annuler ce processus, contactez l\'administrateur a admin@ndsh-software.fr.';

  @override
  String get pendingDeletionLoginBlockedMessage => 'Une demande de suppression de compte est active. La connexion est désactivée. Contactez l\'administrateur à admin@ndsh-software.fr pour rétablir l\'accès.';

  @override
  String get cancel => 'Annuler';

  @override
  String get selectCategory => 'Sélectionner une catégorie';

  @override
  String get selectThemes => 'Sélectionner les thèmes';

  @override
  String get selectGameMode => 'Sélectionner le mode de jeu';

  @override
  String get chooseYourChallenge => 'Choisissez votre défi';

  @override
  String get soloMode => 'Solo';

  @override
  String get soloModeDesc => 'Défiez-vous seul';

  @override
  String get multiplayerMode => 'Multijoueur';

  @override
  String get multiplayerModeDesc => 'Défiez vous de 1 à 4 joueurs ou par équipes';

  @override
  String themes_count(int count) {
    return '$count thème';
  }

  @override
  String questions_count(int count) {
    return '$count question';
  }

  @override
  String get language => 'Langue';

  @override
  String get about => 'À propos';

  @override
  String get version => 'QuizzBuilder v0.21.3';

  @override
  String get aboutText => 'Une plateforme de quizz interactive pour tester vos connaissances.';

  @override
  String get storeFeatureComing => 'La fonctionnalité de boutique arrive bientôt!';

  @override
  String get errorLoadingCategories => 'Erreur lors du chargement des catégories';

  @override
  String get errorLoadingThemes => 'Erreur lors du chargement des thèmes';

  @override
  String get errorTooManyRequests => 'Trop de requêtes. Merci de patienter un instant puis réessayer.';

  @override
  String get errorGenericTryAgain => 'Une erreur est survenue. Merci de réessayer.';

  @override
  String get retry => 'Réessayer';

  @override
  String get noCategories => 'Aucune catégorie disponible';

  @override
  String get noThemes => 'Aucun thème disponible';

  @override
  String get done => 'Terminé';

  @override
  String get next => 'Suivant';

  @override
  String selected(String name) {
    return 'Sélectionné: $name';
  }

  @override
  String get welcomeBack => 'Bienvenue';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get registrationSuccessful => 'Inscription réussie! Veuillez vérifier votre email pour confirmer votre compte.';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordMessage => 'Saisissez l\'adresse email liée à votre compte. Si elle existe, vous recevrez un lien de réinitialisation par email.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get passwordResetEmailSent => 'Si un compte existe pour cet email, un lien de réinitialisation a été envoyé.';

  @override
  String get passwordResetInvalidEmail => 'Veuillez saisir une adresse email valide.';

  @override
  String get passwordResetError => 'Impossible de demander la réinitialisation du mot de passe pour le moment. Veuillez réessayer.';

  @override
  String get email => 'Email';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get switchToLogin => 'Vous avez déjà un compte? Connectez-vous';

  @override
  String get switchToRegister => 'Vous n\'avez pas de compte? S\'inscrire';

  @override
  String get setupSoloGame => 'Configurer une partie solo';

  @override
  String get setupMultiplayerGame => 'Configurer une partie multijoueur';

  @override
  String get selectNumberOfQuestions => 'Sélectionnez le nombre de questions (5-20)';

  @override
  String get selectNumberOfPlayers => 'Sélectionnez le nombre de joueurs (1-4)';

  @override
  String get selectQuestionsLevels => 'Sélectionnez le(s) niveau(x) de question(s)';

  @override
  String get dailyPathToFreeCredit => 'Parcours jusqu\'au prochain crédit gratuit';

  @override
  String get players => 'Joueurs';

  @override
  String get startGame => 'Démarrer la partie';

  @override
  String get continueText => 'Continuer';

  @override
  String get noThemesSelected => 'Aucun thème sélectionné.';

  @override
  String get theme => 'Thème';

  @override
  String get quizSummary => 'Résumé du quiz';

  @override
  String get question => 'Question';

  @override
  String get changeSelection => 'Changer la sélection';

  @override
  String get startQuiz => 'Démarrer le quiz';

  @override
  String get yourScore => 'Votre score';

  @override
  String get correct => 'Correct';

  @override
  String get correctAnswers => 'Réponses correctes';

  @override
  String get wrongAnswers => 'Mauvaises réponses';

  @override
  String get timeUsed => 'Temps utilisé';

  @override
  String get home => 'Accueil';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get save => 'Enregistrer';

  @override
  String get gameOver => 'Fin du jeu!';

  @override
  String get survivalComplete => 'Survie réussie!';

  @override
  String get survivalBestScores => 'Meilleurs scores survie';

  @override
  String get survivalNoBestScores => 'Aucun score de survie enregistre pour le moment.';

  @override
  String get survivalCurrentResult => 'Resultat actuel';

  @override
  String get survivalNewBestTitle => 'Nouveau meilleur score !';

  @override
  String get survivalNewBestMessage => 'Enregistre ce score sous un nom.';

  @override
  String get survivalPlayerName => 'Nom du joueur';

  @override
  String survivalRankLabel(int rank) {
    return 'Rang n°$rank';
  }

  @override
  String get timesUp => 'Temps écoulé!';

  @override
  String get quizComplete => 'Quiz terminé!';

  @override
  String get ok => 'OK';

  @override
  String get emailAlreadyExists => 'Un compte avec cet email existe déjà.';

  @override
  String get outstanding => 'Exceptionnel! 🌟';

  @override
  String get excellent => 'Excellent! ⭐';

  @override
  String get greatJob => 'Excellent travail! 👍';

  @override
  String get goodEffort => 'Bon effort! 💪';

  @override
  String get notBad => 'Pas mal! 📚';

  @override
  String get keepPracticing => 'Continue à pratiquer! 📖';

  @override
  String get free => 'Gratuit';

  @override
  String get premium => 'Premium';

  @override
  String get feedbackInvitation => 'N\'hésitez pas à me contacter pour demander de nouveaux thèmes ou me faire part de vos commentaires';

  @override
  String get iapNotImplemented => 'Les achats intégrés ne sont pas encore implémentés. Cette fonctionnalité arrive bientôt!';

  @override
  String get storePacksTitle => 'Packs de questions';

  @override
  String storeCurrentBalance(String packs) {
    return 'Crédit(s) disponible(s) : $packs';
  }

  @override
  String get storeRestorePurchases => 'Restaurer les achats';

  @override
  String get storeRestoring => 'Restauration...';

  @override
  String get storeUnavailableOnDevice => 'Les achats ne sont actuellement pas disponibles sur cet appareil.';

  @override
  String get storeUnlockExplanation => 'Chaque pack acheté peut être utilisé pour débloquer des thèmes premium supplémentaires.';

  @override
  String storeCreditPackDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Débloquer jusqu\'à $count thèmes premium',
      one: 'Débloquer $count thème premium',
    );
    return '$_temp0';
  }

  @override
  String storeLockedPaidThemesCount(int count) {
    return 'Thèmes premium non encore débloqués : $count';
  }

  @override
  String storePurchaseSuccess(String granted, String balance) {
    return 'Pack ajouté : +$granted (disponibles : $balance)';
  }

  @override
  String storeRestoreSuccess(String balance) {
    return 'Restauration terminée. Packs disponibles : $balance.';
  }

  @override
  String storeVerificationFailed(String error) {
    return 'Vérification échouée : $error';
  }

  @override
  String get storePurchaseIncidentTitle => 'Achat à vérifier';

  @override
  String get storePurchaseIncidentBody => 'Nous n\'avons pas pu confirmer cet achat auprès de notre serveur après plusieurs tentatives. Il se peut qu\'il n\'ait pas encore été crédité. Contactez le support avec la référence ci-dessous afin que nous puissions vérifier manuellement.';

  @override
  String get storePurchaseIncidentReferenceLabel => 'Référence';

  @override
  String get storePurchaseIncidentCopyReference => 'Copier la référence';

  @override
  String get storePurchaseIncidentReferenceCopied => 'Référence copiée';

  @override
  String storeRestoreFailed(String error) {
    return 'Restauration échouée : $error';
  }

  @override
  String get storeProductUnavailable => 'Ce pack n\'est pas encore disponible à l\'achat.';

  @override
  String get storePurchaseFlowFailed => 'Impossible de démarrer l\'achat.';

  @override
  String storeUnknownProductId(String productId) {
    return 'Identifiant produit inconnu : $productId';
  }

  @override
  String get storeBuy => 'Obtenir le pack';

  @override
  String get storeProcessing => 'Traitement...';

  @override
  String storeQuestionPackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packs de questions',
      one: '$count pack de questions',
    );
    return '$_temp0';
  }

  @override
  String storeCreditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crédits',
      one: '$count crédit',
    );
    return '$_temp0';
  }

  @override
  String storePackTooLargeForRemaining(String remaining) {
    return 'Ce pack est trop grand pour vos déblocages restants ($remaining).';
  }

  @override
  String get unlockPremiumThemesTitle => 'Débloquer les thèmes premium';

  @override
  String get unlockThemeAction => 'Débloquer';

  @override
  String unlockThemePrompt(String theme) {
    return 'Débloquer $theme pour 1 crédit ?';
  }

  @override
  String get unlockThemeNoCredits => 'Il faut au moins 1 crédit pour débloquer ce thème.';

  @override
  String get openStore => 'Ouvrir la boutique';

  @override
  String unlockThemeSuccess(String theme, String balance) {
    return '$theme débloqué. Crédits restants : $balance';
  }

  @override
  String get noPremiumThemesToUnlock => 'Tous les thèmes premium sont déjà débloqués.';

  @override
  String get tapLockedThemeToUnlock => 'Touchez un thème premium verrouillé pour le débloquer avec 1 crédit.';

  @override
  String get errorLoadingCredits => 'Impossible d\'actualiser le solde de crédits.';

  @override
  String get emailOrUsername => 'Email ou nom d\'utilisateur';

  @override
  String get reportError => 'Signaler une erreur';

  @override
  String get questionFlagged => 'Question signalée avec succès';

  @override
  String failedToReportError(String error) {
    return 'Échec du signalement : $error';
  }

  @override
  String get noQuestionsFound => 'Aucune question trouvée';

  @override
  String get goBack => 'Retour';

  @override
  String get itsTie => 'Égalité !';

  @override
  String playerWins(int player) {
    return 'Le joueur $player gagne !';
  }

  @override
  String get winningScore => 'Score gagnant';

  @override
  String get finalLeaderboard => 'Classement final';

  @override
  String player(int number) {
    return 'Joueur $number';
  }

  @override
  String get dailyMode => 'Quotidien';

  @override
  String get dailyStatusLoadError => 'Impossible de charger le statut quotidien.';

  @override
  String get dailyChallenge => 'Défi quotidien';

  @override
  String dailyProgress(int currentStreak, int target) {
    return 'Progression : $currentStreak/$target sans erreur';
  }

  @override
  String dailyRewardsGranted(int count) {
    return 'Crédits gratuits débloqués : $count';
  }

  @override
  String get dailyAvailableToday => 'Disponible aujourd\'hui';

  @override
  String get dailyAlreadyPlayedToday => 'Déjà joué aujourd\'hui';

  @override
  String get dailyTierReached => 'Palier atteint : +1 crédit prêt à être débloqué';

  @override
  String dailyTierTarget(int target) {
    return 'Palier crédit : atteint au ${target}e succès';
  }

  @override
  String get dailyTierHint => 'Le palier crédit est mis en évidence en doré.';

  @override
  String get offlineBannerMessage => 'Vous êtes hors ligne. Vous pouvez toujours jouer aux quiz déjà téléchargés, mais les nouveaux téléchargements et les achats sont indisponibles.';

  @override
  String get offlineDownloadUnavailable => 'Ce quiz n\'est pas encore téléchargé et vous êtes hors ligne. Connectez-vous à internet pour le télécharger.';

  @override
  String get offlinePurchaseUnavailable => 'Les achats sont indisponibles hors ligne. Connectez-vous à internet pour acheter ou débloquer du contenu.';

  @override
  String get dailyChallengeOfflineUnavailable => 'Le défi quotidien nécessite une connexion internet et ne peut pas être joué hors ligne. Connectez-vous à internet puis réessayez.';

  @override
  String multiplayerNotEnoughQuestions(int required, int players, int perPlayer, int available) {
    return 'Pas assez de questions pour cette partie. Il en faut $required ($players joueurs × $perPlayer questions) et vos thèmes et niveaux n\'en offrent que $available. Réduisez le nombre de joueurs ou de questions, ou sélectionnez davantage de thèmes ou de niveaux.';
  }

  @override
  String multiplayerQuestionsAvailability(int available, int required, int players, int perPlayer) {
    return '$available questions disponibles · $required nécessaires ($players × $perPlayer)';
  }

  @override
  String multiplayerAdviceReduceQuestions(int max) {
    return 'Réduisez à $max questions par joueur, ou sélectionnez davantage de thèmes ou de niveaux.';
  }

  @override
  String get multiplayerAdviceReducePlayers => 'Réduisez le nombre de joueurs, ou sélectionnez davantage de thèmes ou de niveaux.';

  @override
  String multiplayerThemesBanner(int max, int maxPlayers, int maxQuestions) {
    return 'Multijoueur : chaque joueur reçoit ses propres questions. Prévoyez joueurs × questions par joueur, soit jusqu\'à $max questions ($maxPlayers joueurs × $maxQuestions). Le compteur de questions affiche ce dont vous disposez.';
  }

  @override
  String get selectAllThemes => 'Tout sélectionner';

  @override
  String get deselectAllThemes => 'Tout désélectionner';

  @override
  String difficultyLevelWithCount(String level, int count) {
    return '$level ($count)';
  }

  @override
  String get duelCardTitle => 'Duel';

  @override
  String get duelCardSubtitle => 'Défie un proche';

  @override
  String get duelHubTitle => 'Duel';

  @override
  String get duelInviteTitle => 'Inviter un proche';

  @override
  String get duelInviteSubtitle => 'Partage un code ou un lien';

  @override
  String get duelJoinTitle => 'Rejoindre avec un code';

  @override
  String get duelJoinSubtitle => 'Tu as reçu un code ?';

  @override
  String duelOpponentsSection(int count) {
    return 'Mes adversaires ($count)';
  }

  @override
  String duelOpponentSince(String date) {
    return 'Adversaire depuis le $date';
  }

  @override
  String get duelMenuRemove => 'Retirer';

  @override
  String get duelMenuBlock => 'Bloquer';

  @override
  String get duelMyInvitations => 'Mes invitations';

  @override
  String get duelBlockedPlayers => 'Joueurs bloqués';

  @override
  String get duelNoOpponents => 'Pas encore d\'adversaire. Invite un proche avec un code ou un lien.';

  @override
  String get duelOfflineMessage => 'Le duel nécessite une connexion internet. Reconnecte-toi pour retrouver tes adversaires.';

  @override
  String get duelInviteOfflineMessage => 'Créer une invitation nécessite une connexion internet.';

  @override
  String get duelOfflineListMessage => 'Cette liste nécessite une connexion internet.';

  @override
  String duelRemoveTitle(String username) {
    return 'Retirer $username ?';
  }

  @override
  String duelRemoveBody(String username) {
    return '$username ne sera plus dans tes adversaires. Pour vous retrouver, il faudra une nouvelle invitation.';
  }

  @override
  String get duelRemoveAction => 'Retirer';

  @override
  String duelBlockTitle(String username) {
    return 'Bloquer $username ?';
  }

  @override
  String duelBlockBody(String username) {
    return '$username sera retiré de tes adversaires et ne pourra plus te rejoindre avec une invitation. Tu pourras le débloquer depuis « Joueurs bloqués ».';
  }

  @override
  String get duelBlockAction => 'Bloquer';

  @override
  String duelRemoved(String username) {
    return '$username a été retiré.';
  }

  @override
  String duelBlocked(String username) {
    return '$username a été bloqué.';
  }

  @override
  String get duelInviteCodeLabel => 'Ton code d\'invitation';

  @override
  String duelInviteValidUntil(String date) {
    return 'Valable jusqu\'au $date';
  }

  @override
  String get duelInviteSingleUse => 'Usage unique';

  @override
  String get duelShare => 'Partager';

  @override
  String get duelCopy => 'Copier';

  @override
  String get duelInviteHelp => 'Ton proche touche le lien ou saisit le code dans Duel › Rejoindre avec un code. S\'il n\'a pas l\'app, il pourra l\'installer puis s\'inscrire avec ce code.';

  @override
  String get duelCopied => 'Copié dans le presse-papiers';

  @override
  String get duelSeeMyInvitations => 'Voir mes invitations';

  @override
  String duelShareMessage(String link, String code, String expiry) {
    return 'Défie-moi sur QuizzBuilder ! Touche ce lien pour devenir mon adversaire : $link\nSi tu as déjà l\'app, tu peux aussi saisir le code $code dans Duel › Rejoindre avec un code. Valable jusqu\'au $expiry.';
  }

  @override
  String get duelJoinCodeLabel => 'Code d\'invitation';

  @override
  String get duelJoinCodeHelp => '6 caractères, avec ou sans tiret';

  @override
  String get duelContinue => 'Continuer';

  @override
  String get duelConfirmTitle => 'Invitation';

  @override
  String duelChallengesYou(String username) {
    return '$username te défie';
  }

  @override
  String duelAcceptBody(String username) {
    return 'Accepte pour devenir adversaires de $username.';
  }

  @override
  String duelInvitationValidUntil(String date) {
    return 'Invitation valable jusqu\'au $date';
  }

  @override
  String get duelAccept => 'Accepter';

  @override
  String get duelNotNow => 'Pas maintenant';

  @override
  String duelNowOpponent(String username) {
    return 'Tu es maintenant adversaire de $username';
  }

  @override
  String duelNewOpponents(int count) {
    return 'Tu as $count nouveaux adversaires';
  }

  @override
  String get duelMyInvitationsTitle => 'Mes invitations';

  @override
  String duelInvitationExpires(String date) {
    return 'Expire le $date';
  }

  @override
  String get duelNoInvitations => 'Aucune invitation en cours.';

  @override
  String get duelCancelInvitationTitle => 'Annuler l\'invitation ?';

  @override
  String duelCancelInvitationBody(String code) {
    return 'Le code $code ne fonctionnera plus.';
  }

  @override
  String get duelBack => 'Retour';

  @override
  String get duelCancelInvitationAction => 'Annuler l\'invitation';

  @override
  String get duelInvitationCancelled => 'Invitation annulée';

  @override
  String get duelBlockedTitle => 'Joueurs bloqués';

  @override
  String duelBlockedSince(String date) {
    return 'Bloqué le $date';
  }

  @override
  String get duelUnblock => 'Débloquer';

  @override
  String get duelNoBlocked => 'Aucun joueur bloqué.';

  @override
  String duelUnblockTitle(String username) {
    return 'Débloquer $username ?';
  }

  @override
  String duelUnblockBody(String username) {
    return '$username ne redevient pas ton adversaire automatiquement : il faudra une nouvelle invitation.';
  }

  @override
  String duelUnblocked(String username) {
    return '$username a été débloqué.';
  }

  @override
  String get duelErrInvitationNotFound => 'Ce code n\'existe pas ou n\'est plus valable. Vérifie-le auprès de ton proche.';

  @override
  String get duelErrInvitationExpired => 'Cette invitation a expiré. Demande à ton proche de t\'en envoyer une nouvelle.';

  @override
  String get duelErrInvitationAlreadyUsed => 'Cette invitation a déjà été utilisée. Demande à ton proche de t\'en envoyer une nouvelle.';

  @override
  String get duelErrOwnInvitation => 'C\'est ta propre invitation : partage-la avec un proche.';

  @override
  String get duelErrAlreadyOpponents => 'Vous êtes déjà adversaires.';

  @override
  String get duelErrOpponentLimit => 'Tu as atteint la limite de 100 adversaires. Retires-en un pour en ajouter.';

  @override
  String get duelErrInviterOpponentLimit => 'Cette personne a atteint sa limite d\'adversaires. Réessaie plus tard.';

  @override
  String get duelErrThrottled => 'Trop de tentatives. Réessaie dans une heure.';

  @override
  String get duelErrActiveInvitationLimit => 'Tu as déjà 5 invitations en cours. Annule-en une ou attends qu\'elle expire.';

  @override
  String get duelErrOpponentNotFound => 'Cet adversaire n\'existe plus. La liste a été actualisée.';

  @override
  String get duelErrBlockNotFound => 'Ce blocage n\'existe plus. La liste a été actualisée.';

  @override
  String get duelErrNetwork => 'Connexion impossible. Vérifie ta connexion internet puis réessaie.';

  @override
  String get invitationCodeOptional => 'Code d\'invitation (facultatif)';

  @override
  String get invitationCodeHelp => 'Si un proche t\'a invité, saisis son code.';

  @override
  String get invitationCodeBanner => 'Un proche t\'invite à jouer. Inscris-toi : le code est déjà rempli.';

  @override
  String get invitationCodeLength => 'Le code comporte 6 caractères';

  @override
  String duelBannerPlaying(String username) {
    return 'Duel en cours contre $username';
  }

  @override
  String get duelBannerPlayingSub => 'Touche pour reprendre la partie';

  @override
  String duelBannerWaiting(String username) {
    return '$username t\'attend';
  }

  @override
  String get duelBannerWaitingSub => 'Touche pour rejoindre la salle';

  @override
  String duelBannerMany(int count) {
    return '$count duels t\'attendent';
  }

  @override
  String get duelBannerManySub => 'Touche pour les voir';

  @override
  String duelOpenSection(int count) {
    return 'Duels en cours ($count)';
  }

  @override
  String duelOpenWaitingForMe(String username) {
    return '$username t\'attend';
  }

  @override
  String get duelOpenWaitingForMeSub => 'Rejoins la salle d\'attente';

  @override
  String duelOpenMyChallenge(String username) {
    return 'Ton défi contre $username';
  }

  @override
  String duelOpenMyChallengeSub(String time) {
    return 'En attente · salle ouverte jusqu\'à $time';
  }

  @override
  String duelOpenPlaying(String username) {
    return 'Partie en cours contre $username';
  }

  @override
  String get duelOpenPlayingSub => 'Reprendre la partie';

  @override
  String duelOpenAwaitingResult(String username) {
    return 'Résultat en attente · $username';
  }

  @override
  String get duelOpenAwaitingResultSub => 'Touche pour voir le résultat';

  @override
  String get duelChallengeAction => 'Défier';

  @override
  String get duelOpenAction => 'Ouvrir';

  @override
  String get duelHistoryTitle => 'Historique des duels';

  @override
  String duelChallengeTitle(String username) {
    return 'Défier $username';
  }

  @override
  String get duelThemesSection => 'Thèmes';

  @override
  String duelThemesChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thèmes choisis',
      one: '1 thème choisi',
      zero: 'Aucun thème choisi',
    );
    return '$_temp0';
  }

  @override
  String get duelDifficultiesSection => 'Difficultés';

  @override
  String get duelQuestionCountSection => 'Nombre de questions';

  @override
  String get duelCountsGreyedHint => 'Certains nombres sont grisés : il n\'y a pas assez de questions avec ce choix.';

  @override
  String duelSecondsPerQuestion(int seconds) {
    return '$seconds secondes par question, pour vous deux.';
  }

  @override
  String get duelStartChallenge => 'Lancer le défi';

  @override
  String get duelNoPlayableThemes => 'Aucun thème n\'est jouable pour ce duel pour le moment.';

  @override
  String duelAlreadyOpenOpened(String username) {
    return 'Un duel est déjà ouvert avec $username : le voici.';
  }

  @override
  String get duelRoomTitle => 'Salle d\'attente';

  @override
  String get duelRoomOpening => 'Ouverture de la salle…';

  @override
  String duelRoomWaitingFor(String username) {
    return 'En attente de $username…';
  }

  @override
  String duelRoomHintChallenger(String username) {
    return 'La partie démarre dès que $username te rejoint.';
  }

  @override
  String duelRoomHintChallenged(String username) {
    return '$username t\'a défié. La partie démarre dès que vous êtes tous les deux là.';
  }

  @override
  String duelRoomTimeLeft(String time) {
    return 'Salle ouverte encore $time';
  }

  @override
  String get duelRoomUnstable => 'Connexion instable… nouvelle tentative';

  @override
  String get duelRoomOffline => 'Tu es hors ligne. La salle reprendra dès le retour de la connexion.';

  @override
  String get duelCallLinkTitle => 'Lien d\'appel';

  @override
  String duelCallLinkHelp(String username) {
    return 'Envoie ce lien à $username : le toucher ouvre directement la salle.';
  }

  @override
  String duelCallShareMessage(String link, String time) {
    return 'Je te défie en duel sur QuizzBuilder ! Touche ce lien pour me rejoindre : $link\nLa salle d\'attente est ouverte jusqu\'à $time.';
  }

  @override
  String duelRoomSummary(int count, int seconds, String difficulties) {
    return '$count questions · $seconds s par question · $difficulties';
  }

  @override
  String get duelCancelDuel => 'Annuler le duel';

  @override
  String get duelCancelDuelTitle => 'Annuler le duel ?';

  @override
  String get duelCancelDuelBody => 'La salle d\'attente sera fermée pour vous deux.';

  @override
  String get duelDuelCancelled => 'Duel annulé';

  @override
  String get duelRoomExpired => 'Cette salle d\'attente a expiré. Tu peux lancer un nouveau défi.';

  @override
  String get duelRoomCancelled => 'Ce duel a été annulé.';

  @override
  String get duelBackToDuels => 'Retour aux duels';

  @override
  String duelCountdownIntro(String username) {
    return 'Ton duel contre $username commence dans';
  }

  @override
  String get duelCountdownGo => 'C\'est parti !';

  @override
  String get duelNoCorrectionHint => 'Les réponses ne seront corrigées qu\'à la fin.';

  @override
  String get duelLoadingQuestions => 'Chargement des questions…';

  @override
  String duelQuestionsAndSeconds(int count, int seconds) {
    return '$count questions · $seconds s par question';
  }

  @override
  String duelGameTitle(String username) {
    return 'Duel contre $username';
  }

  @override
  String duelQuestionOf(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String duelAnswerSaved(String time) {
    return 'Réponse enregistrée. Question suivante dans $time';
  }

  @override
  String duelAnswerSavedLast(String time) {
    return 'Réponse enregistrée. Fin de la partie dans $time';
  }

  @override
  String get duelTimeUp => 'Temps écoulé';

  @override
  String get duelQuitTitle => 'Quitter le duel ?';

  @override
  String get duelQuitBody => 'Tes réponses déjà données sont envoyées maintenant. Les questions restantes compteront comme sans réponse.';

  @override
  String get duelKeepPlaying => 'Continuer à jouer';

  @override
  String get duelQuitAction => 'Quitter';

  @override
  String get duelSendingAnswers => 'Envoi de tes réponses…';

  @override
  String get duelSendRetry => 'Connexion impossible. Nouvelle tentative…';

  @override
  String get duelAnswersSent => 'Réponses envoyées';

  @override
  String duelWaitingOpponentFinish(String username) {
    return 'En attendant que $username termine…';
  }

  @override
  String get duelComputingResult => 'Calcul du résultat…';

  @override
  String duelResultAtLatest(String time) {
    return 'Résultat au plus tard dans $time';
  }

  @override
  String get duelResultTitle => 'Résultat du duel';

  @override
  String get duelResultWin => 'Victoire !';

  @override
  String duelResultWinSub(String username) {
    return 'Tu as battu $username';
  }

  @override
  String get duelResultLoss => 'Défaite';

  @override
  String duelResultLossSub(String username) {
    return '$username l\'emporte cette fois';
  }

  @override
  String get duelResultDraw => 'Match nul';

  @override
  String get duelResultDrawSub => 'Vous êtes à égalité';

  @override
  String get duelResultWinForfeit => 'Victoire par forfait';

  @override
  String duelResultWinForfeitSub(String username) {
    return '$username n\'a pas terminé à temps.';
  }

  @override
  String get duelResultLossForfeit => 'Défaite par forfait';

  @override
  String get duelResultLossForfeitSub => 'Tes réponses ne sont pas arrivées à temps.';

  @override
  String get duelResultNone => 'Pas de résultat';

  @override
  String get duelResultNoneSub => 'Personne n\'a envoyé de réponses.';

  @override
  String get duelScoreYou => 'Toi';

  @override
  String duelScoreOutOf(int score, int total) {
    return '$score/$total';
  }

  @override
  String get duelReviewTitle => 'Revue des questions';

  @override
  String duelReviewQuestionHeader(int number, String theme) {
    return 'Question $number · $theme';
  }

  @override
  String get duelReviewCorrect => 'Bonne réponse';

  @override
  String get duelReviewNoAnswerYou => 'Toi : pas de réponse';

  @override
  String duelReviewNoAnswerOpponent(String username) {
    return '$username : pas de réponse';
  }

  @override
  String get duelReviewUnavailable => 'La revue des questions n\'est pas disponible.';

  @override
  String get duelHistoryEmpty => 'Aucun duel joué pour l\'instant.';

  @override
  String duelHistoryLine(String outcome, int count) {
    return '$outcome · $count questions';
  }

  @override
  String get duelOutcomeWin => 'Victoire';

  @override
  String get duelOutcomeLoss => 'Défaite';

  @override
  String get duelOutcomeDraw => 'Match nul';

  @override
  String get duelOutcomeWinForfeit => 'Victoire par forfait';

  @override
  String get duelOutcomeLossForfeit => 'Défaite par forfait';

  @override
  String get duelOutcomeNone => 'Sans résultat';

  @override
  String get duelErrNoThemeSelected => 'Choisis au moins un thème.';

  @override
  String get duelErrThemeNotPlayable => 'Un des thèmes choisis n\'est plus disponible pour ce duel. La liste a été actualisée.';

  @override
  String get duelErrInvalidQuestionCount => 'Ce nombre de questions n\'est pas possible. Choisis 5, 10, 15 ou 20.';

  @override
  String get duelErrInvalidDifficulty => 'Choisis au moins une difficulté.';

  @override
  String get duelErrNotEnoughQuestions => 'Il n\'y a pas assez de questions pour ce choix. Ajoute un thème ou une difficulté, ou réduis le nombre de questions.';

  @override
  String get duelErrLentThemeLimit => 'Tu as atteint la limite de duels avec ces thèmes pour aujourd\'hui. Choisis d\'autres thèmes, ou réessaie demain.';

  @override
  String get duelErrDuelNotFound => 'Ce duel n\'existe plus, ou ce lien n\'est pas pour toi.';

  @override
  String get duelErrDuelClosed => 'Ce duel est terminé ou a été annulé.';

  @override
  String get duelErrCannotCancel => 'La partie est sur le point de commencer : il n\'est plus possible d\'annuler.';

  @override
  String get duelErrNotStarted => 'Le duel n\'a pas encore commencé. Patiente un instant.';

  @override
  String get duelErrDeadlinePassed => 'Le temps pour envoyer tes réponses est écoulé.';
}
