// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuizzBuilder';

  @override
  String welcomeMessage(String userName) {
    return 'Welcome, $userName!';
  }

  @override
  String get readyToTest => 'Ready to test your knowledge?';

  @override
  String get playQuiz => 'Play Quiz';

  @override
  String get playQuizSubtitle => 'Select categories, themes, and challenge yourself';

  @override
  String get buildQuiz => 'Build Quiz';

  @override
  String get buildQuizSubtitle => 'Compose your own quiz from themes';

  @override
  String get store => 'Store';

  @override
  String get storeSubtitle => 'Unlock premium themes and categories';

  @override
  String get availableContent => 'Available content';

  @override
  String selectedContent(int categories, String categoryPlural, int themes, String themePlural, int questions, String questionPlural) {
    return 'Selected: $categories categor$categoryPlural • $themes theme$themePlural • $questions question$questionPlural';
  }

  @override
  String get noSelection => 'No selection yet. Go to Build Quiz to create one.';

  @override
  String get categories => 'Categories';

  @override
  String get themes => 'Themes';

  @override
  String get questions => 'Questions';

  @override
  String get score => 'Score';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get selectThemes => 'Select Themes';

  @override
  String get selectGameMode => 'Select Game Mode';

  @override
  String get chooseYourChallenge => 'Choose Your Challenge';

  @override
  String get soloMode => 'Solo';

  @override
  String get soloModeDesc => 'Challenge yourself alone';

  @override
  String get multiplayerMode => 'Multiplayer';

  @override
  String get multiplayerModeDesc => 'Coming soon';

  @override
  String get selectedCategory => 'Selected Category';

  @override
  String get noThemesSelected => 'No themes selected';

  @override
  String get quizSummary => 'Quiz Summary';

  @override
  String get changeSelection => 'Change Selection';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get question => 'Question';

  @override
  String get theme => 'Theme';

  @override
  String themes_count(int count) {
    return '$count theme';
  }

  @override
  String questions_count(int count) {
    return '$count question';
  }

  @override
  String get language => 'Language';

  @override
  String get about => 'About';

  @override
  String get version => 'QuizzBuilder v1.0.0';

  @override
  String get aboutText => 'An interactive quiz platform to test your knowledge.';

  @override
  String get storeFeatureComing => 'Store feature coming soon!';

  @override
  String get errorLoadingCategories => 'Error loading categories';

  @override
  String get errorLoadingThemes => 'Error loading themes';

  @override
  String get retry => 'Retry';

  @override
  String get noCategories => 'No categories available';

  @override
  String get noThemes => 'No themes available';

  @override
  String get done => 'Done';

  @override
  String selected(String name) {
    return 'Selected: $name';
  }

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registrationSuccessful => 'Registration successful! Please check your email to verify your account.';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get switchToLogin => 'Already have an account? Login';

  @override
  String get switchToRegister => 'Don\'t have an account? Register';
}
