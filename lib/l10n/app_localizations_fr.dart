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
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter?';

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
  String get multiplayerModeDesc => 'Bientôt disponible';

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
  String get version => 'QuizzBuilder v1.0.0';

  @override
  String get aboutText => 'Une plateforme de quiz interactive pour tester vos connaissances.';

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
}
