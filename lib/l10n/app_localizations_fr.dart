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
}
