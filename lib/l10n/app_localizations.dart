import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @standardMode.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standardMode;

  /// No description provided for @survivalMode.
  ///
  /// In en, this message translates to:
  /// **'Survival'**
  String get survivalMode;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuizzBuilder'**
  String get appTitle;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}!'**
  String welcomeMessage(String userName);

  /// No description provided for @readyToTest.
  ///
  /// In en, this message translates to:
  /// **'Ready to test your knowledge?'**
  String get readyToTest;

  /// No description provided for @playQuiz.
  ///
  /// In en, this message translates to:
  /// **'Play Quiz'**
  String get playQuiz;

  /// No description provided for @playQuizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select categories, themes, and challenge yourself'**
  String get playQuizSubtitle;

  /// No description provided for @buildQuiz.
  ///
  /// In en, this message translates to:
  /// **'Build Quiz'**
  String get buildQuiz;

  /// No description provided for @buildQuizSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compose your own quiz from themes'**
  String get buildQuizSubtitle;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @storeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium themes and categories'**
  String get storeSubtitle;

  /// No description provided for @availableContent.
  ///
  /// In en, this message translates to:
  /// **'Available content'**
  String get availableContent;

  /// Display of selected content stats
  ///
  /// In en, this message translates to:
  /// **'Selected: {categories} categor{categoryPlural} • {themes} theme{themePlural} • {questions} question{questionPlural}'**
  String selectedContent(int categories, String categoryPlural, int themes, String themePlural, int questions, String questionPlural);

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No selection yet. Go to Build Quiz to create one.'**
  String get noSelection;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectThemes.
  ///
  /// In en, this message translates to:
  /// **'Select Themes'**
  String get selectThemes;

  /// No description provided for @selectGameMode.
  ///
  /// In en, this message translates to:
  /// **'Select Game Mode'**
  String get selectGameMode;

  /// No description provided for @chooseYourChallenge.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Challenge'**
  String get chooseYourChallenge;

  /// No description provided for @soloMode.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get soloMode;

  /// No description provided for @soloModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Challenge yourself alone'**
  String get soloModeDesc;

  /// No description provided for @multiplayerMode.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get multiplayerMode;

  /// No description provided for @multiplayerModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get multiplayerModeDesc;

  /// Theme count suffix
  ///
  /// In en, this message translates to:
  /// **'{count} theme'**
  String themes_count(int count);

  /// Question count suffix
  ///
  /// In en, this message translates to:
  /// **'{count} question'**
  String questions_count(int count);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'QuizzBuilder v1.0.0'**
  String get version;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'An interactive quiz platform to test your knowledge.'**
  String get aboutText;

  /// No description provided for @storeFeatureComing.
  ///
  /// In en, this message translates to:
  /// **'Store feature coming soon!'**
  String get storeFeatureComing;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// No description provided for @errorLoadingThemes.
  ///
  /// In en, this message translates to:
  /// **'Error loading themes'**
  String get errorLoadingThemes;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategories;

  /// No description provided for @noThemes.
  ///
  /// In en, this message translates to:
  /// **'No themes available'**
  String get noThemes;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Selected item message
  ///
  /// In en, this message translates to:
  /// **'Selected: {name}'**
  String selected(String name);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please check your email to verify your account.'**
  String get registrationSuccessful;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @switchToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get switchToLogin;

  /// No description provided for @switchToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get switchToRegister;

  /// No description provided for @setupSoloGame.
  ///
  /// In en, this message translates to:
  /// **'Setup solo game'**
  String get setupSoloGame;

  /// No description provided for @setupMultiplayerGame.
  ///
  /// In en, this message translates to:
  /// **'Setup multiplayer game'**
  String get setupMultiplayerGame;

  /// No description provided for @selectNumberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Select number of questions (5-20)'**
  String get selectNumberOfQuestions;

  /// No description provided for @selectNumberOfPlayers.
  ///
  /// In en, this message translates to:
  /// **'Select number of players (1-4)'**
  String get selectNumberOfPlayers;

  /// No description provided for @selectQuestionsLevels.
  ///
  /// In en, this message translates to:
  /// **'Select questions level(s)'**
  String get selectQuestionsLevels;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @noThemesSelected.
  ///
  /// In en, this message translates to:
  /// **'No themes selected.'**
  String get noThemesSelected;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @quizSummary.
  ///
  /// In en, this message translates to:
  /// **'Quiz Summary'**
  String get quizSummary;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @changeSelection.
  ///
  /// In en, this message translates to:
  /// **'Change selection'**
  String get changeSelection;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
