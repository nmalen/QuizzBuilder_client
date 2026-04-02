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

  /// No description provided for @quizzBuilderContent.
  ///
  /// In en, this message translates to:
  /// **'QuizzBuilder'**
  String get quizzBuilderContent;

  /// No description provided for @quizzBuilderContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total active content (including unpurchased)'**
  String get quizzBuilderContentSubtitle;

  /// No description provided for @userContent.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userContent;

  /// No description provided for @userContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlocked content'**
  String get userContentSubtitle;

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
  /// **'QuizzBuilder v0.21.3'**
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

  /// No description provided for @dailyPathToFreeCredit.
  ///
  /// In en, this message translates to:
  /// **'Path to the next free credit'**
  String get dailyPathToFreeCredit;

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

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your Score'**
  String get yourScore;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @correctAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get correctAnswers;

  /// No description provided for @wrongAnswers.
  ///
  /// In en, this message translates to:
  /// **'Wrong Answers'**
  String get wrongAnswers;

  /// No description provided for @timeUsed.
  ///
  /// In en, this message translates to:
  /// **'Time Used'**
  String get timeUsed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over!'**
  String get gameOver;

  /// No description provided for @survivalComplete.
  ///
  /// In en, this message translates to:
  /// **'Survival Complete!'**
  String get survivalComplete;

  /// No description provided for @survivalBestScores.
  ///
  /// In en, this message translates to:
  /// **'Best survival scores'**
  String get survivalBestScores;

  /// No description provided for @survivalNoBestScores.
  ///
  /// In en, this message translates to:
  /// **'No saved survival scores yet.'**
  String get survivalNoBestScores;

  /// No description provided for @survivalCurrentResult.
  ///
  /// In en, this message translates to:
  /// **'Current result'**
  String get survivalCurrentResult;

  /// No description provided for @survivalNewBestTitle.
  ///
  /// In en, this message translates to:
  /// **'New best score!'**
  String get survivalNewBestTitle;

  /// No description provided for @survivalNewBestMessage.
  ///
  /// In en, this message translates to:
  /// **'Save this score under a name.'**
  String get survivalNewBestMessage;

  /// No description provided for @survivalPlayerName.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get survivalPlayerName;

  /// No description provided for @survivalRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank #{rank}'**
  String survivalRankLabel(int rank);

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get timesUp;

  /// No description provided for @quizComplete.
  ///
  /// In en, this message translates to:
  /// **'Quiz Complete!'**
  String get quizComplete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get emailAlreadyExists;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding! 🌟'**
  String get outstanding;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! ⭐'**
  String get excellent;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great Job! 👍'**
  String get greatJob;

  /// No description provided for @goodEffort.
  ///
  /// In en, this message translates to:
  /// **'Good Effort! 💪'**
  String get goodEffort;

  /// No description provided for @notBad.
  ///
  /// In en, this message translates to:
  /// **'Not Bad! 📚'**
  String get notBad;

  /// No description provided for @keepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep Practicing! 📖'**
  String get keepPracticing;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @feedbackInvitation.
  ///
  /// In en, this message translates to:
  /// **'Feel free to contact me to request new themes or share your feedback'**
  String get feedbackInvitation;

  /// No description provided for @iapNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases are not yet implemented. This feature is coming soon!'**
  String get iapNotImplemented;

  /// No description provided for @storePacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Question Packs'**
  String get storePacksTitle;

  /// No description provided for @storeCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Available packs: {packs}'**
  String storeCurrentBalance(String packs);

  /// No description provided for @storeRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get storeRestorePurchases;

  /// No description provided for @storeRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get storeRestoring;

  /// No description provided for @storeUnavailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Purchases are currently unavailable on this device.'**
  String get storeUnavailableOnDevice;

  /// No description provided for @storeUnlockExplanation.
  ///
  /// In en, this message translates to:
  /// **'Each purchased pack can be used to unlock additional premium themes.'**
  String get storeUnlockExplanation;

  /// No description provided for @storeCreditPackDescription.
  String storeCreditPackDescription(int count);

  /// No description provided for @storeLockedPaidThemesCount.
  ///
  /// In en, this message translates to:
  /// **'Premium themes not yet unlocked: {count}'**
  String storeLockedPaidThemesCount(int count);

  /// No description provided for @storePurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pack added: +{granted} (available {balance})'**
  String storePurchaseSuccess(String granted, String balance);

  /// No description provided for @storeRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore complete. Available packs: {balance}.'**
  String storeRestoreSuccess(String balance);

  /// No description provided for @storeVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String storeVerificationFailed(String error);

  /// No description provided for @storeRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String storeRestoreFailed(String error);

  /// No description provided for @storeProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This pack is not available for purchase yet.'**
  String get storeProductUnavailable;

  /// No description provided for @storePurchaseFlowFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start purchase flow.'**
  String get storePurchaseFlowFailed;

  /// No description provided for @storeUnknownProductId.
  ///
  /// In en, this message translates to:
  /// **'Unknown product ID: {productId}'**
  String storeUnknownProductId(String productId);

  /// No description provided for @storeBuy.
  ///
  /// In en, this message translates to:
  /// **'Get pack'**
  String get storeBuy;

  /// No description provided for @storeProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get storeProcessing;

  /// No description provided for @storeQuestionPackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} question pack} other{{count} question packs}}'**
  String storeQuestionPackCount(int count);

  /// No description provided for @storeCreditCount.
  String storeCreditCount(int count);

  /// No description provided for @storePackTooLargeForRemaining.
  ///
  /// In en, this message translates to:
  /// **'This pack is too large for your remaining unlocks ({remaining}).'**
  String storePackTooLargeForRemaining(String remaining);

  /// No description provided for @unlockPremiumThemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium Themes'**
  String get unlockPremiumThemesTitle;

  /// No description provided for @unlockThemeAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockThemeAction;

  /// No description provided for @unlockThemePrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock {theme} for 1 credit?'**
  String unlockThemePrompt(String theme);

  /// No description provided for @unlockThemeNoCredits.
  ///
  /// In en, this message translates to:
  /// **'You need at least 1 credit to unlock this theme.'**
  String get unlockThemeNoCredits;

  /// No description provided for @openStore.
  ///
  /// In en, this message translates to:
  /// **'Open store'**
  String get openStore;

  /// No description provided for @unlockThemeSuccess.
  ///
  /// In en, this message translates to:
  /// **'{theme} unlocked. Remaining credits: {balance}'**
  String unlockThemeSuccess(String theme, String balance);

  /// No description provided for @noPremiumThemesToUnlock.
  ///
  /// In en, this message translates to:
  /// **'All premium themes are already unlocked.'**
  String get noPremiumThemesToUnlock;

  /// No description provided for @tapLockedThemeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Tap a locked premium theme to unlock it with 1 credit.'**
  String get tapLockedThemeToUnlock;

  /// No description provided for @errorLoadingCredits.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh credit balance.'**
  String get errorLoadingCredits;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @reportError.
  ///
  /// In en, this message translates to:
  /// **'Report error'**
  String get reportError;

  /// No description provided for @questionFlagged.
  ///
  /// In en, this message translates to:
  /// **'Question reported successfully'**
  String get questionFlagged;

  /// No description provided for @failedToReportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to report error: {error}'**
  String failedToReportError(String error);

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No questions found'**
  String get noQuestionsFound;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @itsTie.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie!'**
  String get itsTie;

  /// No description provided for @playerWins.
  ///
  /// In en, this message translates to:
  /// **'Player {player} wins!'**
  String playerWins(int player);

  /// No description provided for @winningScore.
  ///
  /// In en, this message translates to:
  /// **'Winning Score'**
  String get winningScore;

  /// No description provided for @finalLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Final Leaderboard'**
  String get finalLeaderboard;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String player(int number);

  /// No description provided for @dailyMode.
  String get dailyMode;

  /// No description provided for @dailyStatusLoadError.
  String get dailyStatusLoadError;

  /// No description provided for @dailyChallenge.
  String get dailyChallenge;

  /// No description provided for @dailyProgress.
  String dailyProgress(int currentStreak, int target);

  /// No description provided for @dailyRewardsGranted.
  String dailyRewardsGranted(int count);

  /// No description provided for @dailyAvailableToday.
  String get dailyAvailableToday;

  /// No description provided for @dailyAlreadyPlayedToday.
  String get dailyAlreadyPlayedToday;

  /// No description provided for @dailyTierReached.
  String get dailyTierReached;

  /// No description provided for @dailyTierTarget.
  String dailyTierTarget(int target);

  /// No description provided for @dailyTierHint.
  String get dailyTierHint;
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
