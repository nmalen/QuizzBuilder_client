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

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @optOutButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get optOutButton;

  /// No description provided for @optOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Request deletion of your account and all associated data.'**
  String get optOutDescription;

  /// No description provided for @optOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm account deletion'**
  String get optOutConfirmTitle;

  /// No description provided for @optOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? All of your user data, including your purchases, will be deleted within 30 days. After confirmation, you will no longer be able to access the application.'**
  String get optOutConfirmMessage;

  /// No description provided for @optOutRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request recorded'**
  String get optOutRecordedTitle;

  /// No description provided for @optOutConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm request'**
  String get optOutConfirmAction;

  /// No description provided for @optOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request has been recorded. A confirmation email has been sent. You will now be logged out.'**
  String get optOutSuccess;

  /// No description provided for @optOutAlreadyRequested.
  ///
  /// In en, this message translates to:
  /// **'Your account is already scheduled for deletion. You will now be logged out.'**
  String get optOutAlreadyRequested;

  /// No description provided for @optOutError.
  ///
  /// In en, this message translates to:
  /// **'Unable to request account deletion right now. Please try again.'**
  String get optOutError;

  /// No description provided for @pendingDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending deletion request'**
  String get pendingDeletionTitle;

  /// No description provided for @pendingDeletionMessage.
  ///
  /// In en, this message translates to:
  /// **'A pending account deletion request is active. If you want to revert this process, contact the admin at admin@ndsh-software.fr.'**
  String get pendingDeletionMessage;

  /// No description provided for @pendingDeletionLoginBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'A pending account deletion request is active. Login is disabled. Contact the admin at admin@ndsh-software.fr to restore access.'**
  String get pendingDeletionLoginBlockedMessage;

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
  /// **'Challenge each other with 1 to 4 players or in teams'**
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

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorGenericTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGenericTryAgain;

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

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address linked to your account. If it exists, you will receive a reset link by email.'**
  String get forgotPasswordMessage;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a password reset link has been sent.'**
  String get passwordResetEmailSent;

  /// No description provided for @passwordResetInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get passwordResetInvalidEmail;

  /// No description provided for @passwordResetError.
  ///
  /// In en, this message translates to:
  /// **'Unable to request a password reset right now. Please try again.'**
  String get passwordResetError;

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
  /// **'Available credit(s): {packs}'**
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
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Unlock {count} premium theme} other{Unlock up to {count} premium themes}}'**
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

  /// No description provided for @storePurchaseIncidentTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase needs attention'**
  String get storePurchaseIncidentTitle;

  /// No description provided for @storePurchaseIncidentBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm this purchase with our server after several attempts. It may not have been credited yet. Please contact support with the reference below so we can check it manually.'**
  String get storePurchaseIncidentBody;

  /// No description provided for @storePurchaseIncidentReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get storePurchaseIncidentReferenceLabel;

  /// No description provided for @storePurchaseIncidentCopyReference.
  ///
  /// In en, this message translates to:
  /// **'Copy reference'**
  String get storePurchaseIncidentCopyReference;

  /// No description provided for @storePurchaseIncidentReferenceCopied.
  ///
  /// In en, this message translates to:
  /// **'Reference copied'**
  String get storePurchaseIncidentReferenceCopied;

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
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} credit} other{{count} credits}}'**
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
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyMode;

  /// No description provided for @dailyStatusLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load daily status.'**
  String get dailyStatusLoadError;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {currentStreak}/{target} without error'**
  String dailyProgress(int currentStreak, int target);

  /// No description provided for @dailyRewardsGranted.
  ///
  /// In en, this message translates to:
  /// **'Free credits unlocked: {count}'**
  String dailyRewardsGranted(int count);

  /// No description provided for @dailyAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'Available today'**
  String get dailyAvailableToday;

  /// No description provided for @dailyAlreadyPlayedToday.
  ///
  /// In en, this message translates to:
  /// **'Already played today'**
  String get dailyAlreadyPlayedToday;

  /// No description provided for @dailyTierReached.
  ///
  /// In en, this message translates to:
  /// **'Milestone reached: +1 credit ready to unlock'**
  String get dailyTierReached;

  /// No description provided for @dailyTierTarget.
  ///
  /// In en, this message translates to:
  /// **'Credit milestone: reached at {target}th success'**
  String dailyTierTarget(int target);

  /// No description provided for @dailyTierHint.
  ///
  /// In en, this message translates to:
  /// **'The credit milestone is highlighted in gold.'**
  String get dailyTierHint;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. You can still play quizzes you\'ve already downloaded, but new downloads and purchases are unavailable.'**
  String get offlineBannerMessage;

  /// No description provided for @offlineDownloadUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This quiz isn\'t downloaded yet and you\'re offline. Connect to the internet to download it.'**
  String get offlineDownloadUnavailable;

  /// No description provided for @offlinePurchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are unavailable offline. Connect to the internet to buy or unlock content.'**
  String get offlinePurchaseUnavailable;

  /// No description provided for @dailyChallengeOfflineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The daily challenge needs an internet connection and can\'t be played offline. Connect to the internet and try again.'**
  String get dailyChallengeOfflineUnavailable;

  /// No description provided for @multiplayerNotEnoughQuestions.
  ///
  /// In en, this message translates to:
  /// **'Not enough questions for this game. You need {required} ({players} players × {perPlayer} questions each) but your themes and levels only provide {available}. Reduce the number of players or questions, or select more themes or levels.'**
  String multiplayerNotEnoughQuestions(int required, int players, int perPlayer, int available);

  /// No description provided for @multiplayerQuestionsAvailability.
  ///
  /// In en, this message translates to:
  /// **'{available} questions available · {required} needed ({players} × {perPlayer})'**
  String multiplayerQuestionsAvailability(int available, int required, int players, int perPlayer);

  /// No description provided for @multiplayerAdviceReduceQuestions.
  ///
  /// In en, this message translates to:
  /// **'Reduce to {max} questions per player, or select more themes or levels.'**
  String multiplayerAdviceReduceQuestions(int max);

  /// No description provided for @multiplayerAdviceReducePlayers.
  ///
  /// In en, this message translates to:
  /// **'Reduce the number of players, or select more themes or levels.'**
  String get multiplayerAdviceReducePlayers;

  /// No description provided for @multiplayerThemesBanner.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer: each player gets their own questions. Plan for players × questions per player, up to {max} questions ({maxPlayers} players × {maxQuestions}). The question counter shows what you have.'**
  String multiplayerThemesBanner(int max, int maxPlayers, int maxQuestions);

  /// No description provided for @selectAllThemes.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAllThemes;

  /// No description provided for @deselectAllThemes.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAllThemes;

  /// No description provided for @difficultyLevelWithCount.
  ///
  /// In en, this message translates to:
  /// **'{level} ({count})'**
  String difficultyLevelWithCount(String level, int count);

  /// No description provided for @duelCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get duelCardTitle;

  /// No description provided for @duelCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get duelCardSubtitle;

  /// No description provided for @duelHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get duelHubTitle;

  /// No description provided for @duelInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend'**
  String get duelInviteTitle;

  /// No description provided for @duelInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a code or a link'**
  String get duelInviteSubtitle;

  /// No description provided for @duelJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get duelJoinTitle;

  /// No description provided for @duelJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Got a code?'**
  String get duelJoinSubtitle;

  /// No description provided for @duelOpponentsSection.
  ///
  /// In en, this message translates to:
  /// **'My opponents ({count})'**
  String duelOpponentsSection(int count);

  /// No description provided for @duelOpponentSince.
  ///
  /// In en, this message translates to:
  /// **'Opponent since {date}'**
  String duelOpponentSince(String date);

  /// No description provided for @duelMenuRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get duelMenuRemove;

  /// No description provided for @duelMenuBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get duelMenuBlock;

  /// No description provided for @duelMyInvitations.
  ///
  /// In en, this message translates to:
  /// **'My invitations'**
  String get duelMyInvitations;

  /// No description provided for @duelBlockedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Blocked players'**
  String get duelBlockedPlayers;

  /// No description provided for @duelNoOpponents.
  ///
  /// In en, this message translates to:
  /// **'No opponents yet. Invite a friend with a code or a link.'**
  String get duelNoOpponents;

  /// No description provided for @duelOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Duel needs an internet connection. Reconnect to see your opponents.'**
  String get duelOfflineMessage;

  /// No description provided for @duelInviteOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Creating an invitation needs an internet connection.'**
  String get duelInviteOfflineMessage;

  /// No description provided for @duelOfflineListMessage.
  ///
  /// In en, this message translates to:
  /// **'This list needs an internet connection.'**
  String get duelOfflineListMessage;

  /// No description provided for @duelRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {username}?'**
  String duelRemoveTitle(String username);

  /// No description provided for @duelRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{username} will no longer be one of your opponents. To connect again, you will need a new invitation.'**
  String duelRemoveBody(String username);

  /// No description provided for @duelRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get duelRemoveAction;

  /// No description provided for @duelBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {username}?'**
  String duelBlockTitle(String username);

  /// No description provided for @duelBlockBody.
  ///
  /// In en, this message translates to:
  /// **'{username} will be removed from your opponents and will not be able to join you with an invitation. You can unblock them from “Blocked players”.'**
  String duelBlockBody(String username);

  /// No description provided for @duelBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get duelBlockAction;

  /// No description provided for @duelRemoved.
  ///
  /// In en, this message translates to:
  /// **'{username} was removed.'**
  String duelRemoved(String username);

  /// No description provided for @duelBlocked.
  ///
  /// In en, this message translates to:
  /// **'{username} was blocked.'**
  String duelBlocked(String username);

  /// No description provided for @duelInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your invitation code'**
  String get duelInviteCodeLabel;

  /// No description provided for @duelInviteValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String duelInviteValidUntil(String date);

  /// No description provided for @duelInviteSingleUse.
  ///
  /// In en, this message translates to:
  /// **'Single use'**
  String get duelInviteSingleUse;

  /// No description provided for @duelShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get duelShare;

  /// No description provided for @duelCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get duelCopy;

  /// No description provided for @duelInviteHelp.
  ///
  /// In en, this message translates to:
  /// **'Your friend taps the link or enters the code under Duel › Join with a code. If they don\'t have the app, they can install it, then sign up with this code.'**
  String get duelInviteHelp;

  /// No description provided for @duelCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard'**
  String get duelCopied;

  /// No description provided for @duelSeeMyInvitations.
  ///
  /// In en, this message translates to:
  /// **'See my invitations'**
  String get duelSeeMyInvitations;

  /// No description provided for @duelShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Challenge me on QuizzBuilder! Tap this link to become my opponent: {link}\nIf you already have the app, you can also enter the code {code} under Duel › Join with a code. Valid until {expiry}.'**
  String duelShareMessage(String link, String code, String expiry);

  /// No description provided for @duelJoinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get duelJoinCodeLabel;

  /// No description provided for @duelJoinCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'6 characters, with or without a dash'**
  String get duelJoinCodeHelp;

  /// No description provided for @duelContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get duelContinue;

  /// No description provided for @duelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get duelConfirmTitle;

  /// No description provided for @duelChallengesYou.
  ///
  /// In en, this message translates to:
  /// **'{username} challenges you'**
  String duelChallengesYou(String username);

  /// No description provided for @duelAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Accept to become opponents with {username}.'**
  String duelAcceptBody(String username);

  /// No description provided for @duelInvitationValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Invitation valid until {date}'**
  String duelInvitationValidUntil(String date);

  /// No description provided for @duelAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get duelAccept;

  /// No description provided for @duelNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get duelNotNow;

  /// No description provided for @duelNowOpponent.
  ///
  /// In en, this message translates to:
  /// **'You are now opponents with {username}'**
  String duelNowOpponent(String username);

  /// No description provided for @duelNewOpponents.
  ///
  /// In en, this message translates to:
  /// **'You have {count} new opponents'**
  String duelNewOpponents(int count);

  /// No description provided for @duelMyInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'My invitations'**
  String get duelMyInvitationsTitle;

  /// No description provided for @duelInvitationExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String duelInvitationExpires(String date);

  /// No description provided for @duelNoInvitations.
  ///
  /// In en, this message translates to:
  /// **'No active invitations.'**
  String get duelNoInvitations;

  /// No description provided for @duelCancelInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the invitation?'**
  String get duelCancelInvitationTitle;

  /// No description provided for @duelCancelInvitationBody.
  ///
  /// In en, this message translates to:
  /// **'The code {code} will no longer work.'**
  String duelCancelInvitationBody(String code);

  /// No description provided for @duelBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get duelBack;

  /// No description provided for @duelCancelInvitationAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation'**
  String get duelCancelInvitationAction;

  /// No description provided for @duelInvitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled'**
  String get duelInvitationCancelled;

  /// No description provided for @duelBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked players'**
  String get duelBlockedTitle;

  /// No description provided for @duelBlockedSince.
  ///
  /// In en, this message translates to:
  /// **'Blocked on {date}'**
  String duelBlockedSince(String date);

  /// No description provided for @duelUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get duelUnblock;

  /// No description provided for @duelNoBlocked.
  ///
  /// In en, this message translates to:
  /// **'No blocked players.'**
  String get duelNoBlocked;

  /// No description provided for @duelUnblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {username}?'**
  String duelUnblockTitle(String username);

  /// No description provided for @duelUnblockBody.
  ///
  /// In en, this message translates to:
  /// **'{username} will not become your opponent again automatically: you will need a new invitation.'**
  String duelUnblockBody(String username);

  /// No description provided for @duelUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{username} was unblocked.'**
  String duelUnblocked(String username);

  /// No description provided for @duelErrInvitationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This code doesn\'t exist or is no longer valid. Check it with your friend.'**
  String get duelErrInvitationNotFound;

  /// No description provided for @duelErrInvitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired. Ask your friend to send you a new one.'**
  String get duelErrInvitationExpired;

  /// No description provided for @duelErrInvitationAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been used. Ask your friend to send you a new one.'**
  String get duelErrInvitationAlreadyUsed;

  /// No description provided for @duelErrOwnInvitation.
  ///
  /// In en, this message translates to:
  /// **'This is your own invitation: share it with a friend.'**
  String get duelErrOwnInvitation;

  /// No description provided for @duelErrAlreadyOpponents.
  ///
  /// In en, this message translates to:
  /// **'You are already opponents.'**
  String get duelErrAlreadyOpponents;

  /// No description provided for @duelErrOpponentLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit of 100 opponents. Remove one to add another.'**
  String get duelErrOpponentLimit;

  /// No description provided for @duelErrInviterOpponentLimit.
  ///
  /// In en, this message translates to:
  /// **'This person has reached their opponent limit. Try again later.'**
  String get duelErrInviterOpponentLimit;

  /// No description provided for @duelErrThrottled.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in an hour.'**
  String get duelErrThrottled;

  /// No description provided for @duelErrActiveInvitationLimit.
  ///
  /// In en, this message translates to:
  /// **'You already have 5 active invitations. Cancel one or wait for it to expire.'**
  String get duelErrActiveInvitationLimit;

  /// No description provided for @duelErrOpponentNotFound.
  ///
  /// In en, this message translates to:
  /// **'This opponent no longer exists. The list has been refreshed.'**
  String get duelErrOpponentNotFound;

  /// No description provided for @duelErrBlockNotFound.
  ///
  /// In en, this message translates to:
  /// **'This block no longer exists. The list has been refreshed.'**
  String get duelErrBlockNotFound;

  /// No description provided for @duelErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet connection and try again.'**
  String get duelErrNetwork;

  /// No description provided for @invitationCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Invitation code (optional)'**
  String get invitationCodeOptional;

  /// No description provided for @invitationCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'If a friend invited you, enter their code.'**
  String get invitationCodeHelp;

  /// No description provided for @invitationCodeBanner.
  ///
  /// In en, this message translates to:
  /// **'A friend invited you. Sign up: the code is already filled in.'**
  String get invitationCodeBanner;

  /// No description provided for @invitationCodeLength.
  ///
  /// In en, this message translates to:
  /// **'The code has 6 characters'**
  String get invitationCodeLength;

  /// No description provided for @duelBannerPlaying.
  ///
  /// In en, this message translates to:
  /// **'Duel in progress against {username}'**
  String duelBannerPlaying(String username);

  /// No description provided for @duelBannerPlayingSub.
  ///
  /// In en, this message translates to:
  /// **'Tap to resume the game'**
  String get duelBannerPlayingSub;

  /// No description provided for @duelBannerWaiting.
  ///
  /// In en, this message translates to:
  /// **'{username} is waiting for you'**
  String duelBannerWaiting(String username);

  /// No description provided for @duelBannerWaitingSub.
  ///
  /// In en, this message translates to:
  /// **'Tap to join the room'**
  String get duelBannerWaitingSub;

  /// No description provided for @duelBannerMany.
  ///
  /// In en, this message translates to:
  /// **'{count} duels are waiting for you'**
  String duelBannerMany(int count);

  /// No description provided for @duelBannerManySub.
  ///
  /// In en, this message translates to:
  /// **'Tap to see them'**
  String get duelBannerManySub;

  /// No description provided for @duelOpenSection.
  ///
  /// In en, this message translates to:
  /// **'Open duels ({count})'**
  String duelOpenSection(int count);

  /// No description provided for @duelOpenWaitingForMe.
  ///
  /// In en, this message translates to:
  /// **'{username} is waiting for you'**
  String duelOpenWaitingForMe(String username);

  /// No description provided for @duelOpenWaitingForMeSub.
  ///
  /// In en, this message translates to:
  /// **'Join the waiting room'**
  String get duelOpenWaitingForMeSub;

  /// No description provided for @duelOpenMyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Your challenge to {username}'**
  String duelOpenMyChallenge(String username);

  /// No description provided for @duelOpenMyChallengeSub.
  ///
  /// In en, this message translates to:
  /// **'Waiting · room open until {time}'**
  String duelOpenMyChallengeSub(String time);

  /// No description provided for @duelOpenPlaying.
  ///
  /// In en, this message translates to:
  /// **'Game in progress against {username}'**
  String duelOpenPlaying(String username);

  /// No description provided for @duelOpenPlayingSub.
  ///
  /// In en, this message translates to:
  /// **'Resume the game'**
  String get duelOpenPlayingSub;

  /// No description provided for @duelOpenAwaitingResult.
  ///
  /// In en, this message translates to:
  /// **'Result pending · {username}'**
  String duelOpenAwaitingResult(String username);

  /// No description provided for @duelOpenAwaitingResultSub.
  ///
  /// In en, this message translates to:
  /// **'Tap to see the result'**
  String get duelOpenAwaitingResultSub;

  /// No description provided for @duelChallengeAction.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get duelChallengeAction;

  /// No description provided for @duelOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get duelOpenAction;

  /// No description provided for @duelHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel history'**
  String get duelHistoryTitle;

  /// No description provided for @duelChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge {username}'**
  String duelChallengeTitle(String username);

  /// No description provided for @duelThemesSection.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get duelThemesSection;

  /// No description provided for @duelThemesChosen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No theme chosen} =1{1 theme chosen} other{{count} themes chosen}}'**
  String duelThemesChosen(int count);

  /// No description provided for @duelDifficultiesSection.
  ///
  /// In en, this message translates to:
  /// **'Difficulties'**
  String get duelDifficultiesSection;

  /// No description provided for @duelQuestionCountSection.
  ///
  /// In en, this message translates to:
  /// **'Number of questions'**
  String get duelQuestionCountSection;

  /// No description provided for @duelCountsGreyedHint.
  ///
  /// In en, this message translates to:
  /// **'Some numbers are greyed out: there are not enough questions with this choice.'**
  String get duelCountsGreyedHint;

  /// No description provided for @duelSecondsSection.
  ///
  /// In en, this message translates to:
  /// **'Time per question'**
  String get duelSecondsSection;

  /// No description provided for @duelSecondsChoice.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String duelSecondsChoice(int seconds);

  /// No description provided for @duelSecondsHelp.
  ///
  /// In en, this message translates to:
  /// **'The same time for both of you.'**
  String get duelSecondsHelp;

  /// No description provided for @duelStartChallenge.
  ///
  /// In en, this message translates to:
  /// **'Start the challenge'**
  String get duelStartChallenge;

  /// No description provided for @duelNoPlayableThemes.
  ///
  /// In en, this message translates to:
  /// **'No theme can be played for this duel right now.'**
  String get duelNoPlayableThemes;

  /// No description provided for @duelAlreadyOpenOpened.
  ///
  /// In en, this message translates to:
  /// **'A duel is already open with {username}: here it is.'**
  String duelAlreadyOpenOpened(String username);

  /// No description provided for @duelRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting room'**
  String get duelRoomTitle;

  /// No description provided for @duelRoomOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the room…'**
  String get duelRoomOpening;

  /// No description provided for @duelRoomWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {username}…'**
  String duelRoomWaitingFor(String username);

  /// No description provided for @duelRoomHintChallenger.
  ///
  /// In en, this message translates to:
  /// **'The game starts as soon as {username} joins you.'**
  String duelRoomHintChallenger(String username);

  /// No description provided for @duelRoomHintChallenged.
  ///
  /// In en, this message translates to:
  /// **'{username} challenged you. The game starts as soon as you are both here.'**
  String duelRoomHintChallenged(String username);

  /// No description provided for @duelRoomTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Room open for another {time}'**
  String duelRoomTimeLeft(String time);

  /// No description provided for @duelRoomUnstable.
  ///
  /// In en, this message translates to:
  /// **'Unstable connection… trying again'**
  String get duelRoomUnstable;

  /// No description provided for @duelRoomOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. The room will resume as soon as you are back online.'**
  String get duelRoomOffline;

  /// No description provided for @duelCallLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Call link'**
  String get duelCallLinkTitle;

  /// No description provided for @duelCallLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'Send this link to {username}: tapping it opens the room directly.'**
  String duelCallLinkHelp(String username);

  /// No description provided for @duelCallShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I challenge you to a duel on QuizzBuilder! Tap this link to join me: {link}\nThe waiting room is open until {time}.'**
  String duelCallShareMessage(String link, String time);

  /// No description provided for @duelRoomSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} questions · {seconds} s per question · {difficulties}'**
  String duelRoomSummary(int count, int seconds, String difficulties);

  /// No description provided for @duelCancelDuel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the duel'**
  String get duelCancelDuel;

  /// No description provided for @duelCancelDuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel the duel?'**
  String get duelCancelDuelTitle;

  /// No description provided for @duelCancelDuelBody.
  ///
  /// In en, this message translates to:
  /// **'The waiting room will be closed for both of you.'**
  String get duelCancelDuelBody;

  /// No description provided for @duelDuelCancelled.
  ///
  /// In en, this message translates to:
  /// **'Duel cancelled'**
  String get duelDuelCancelled;

  /// No description provided for @duelRoomExpired.
  ///
  /// In en, this message translates to:
  /// **'This waiting room has expired. You can start a new challenge.'**
  String get duelRoomExpired;

  /// No description provided for @duelRoomCancelled.
  ///
  /// In en, this message translates to:
  /// **'This duel was cancelled.'**
  String get duelRoomCancelled;

  /// No description provided for @duelBackToDuels.
  ///
  /// In en, this message translates to:
  /// **'Back to duels'**
  String get duelBackToDuels;

  /// No description provided for @duelCountdownIntro.
  ///
  /// In en, this message translates to:
  /// **'Your duel against {username} starts in'**
  String duelCountdownIntro(String username);

  /// No description provided for @duelCountdownGo.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get duelCountdownGo;

  /// No description provided for @duelNoCorrectionHint.
  ///
  /// In en, this message translates to:
  /// **'Answers will only be revealed at the end.'**
  String get duelNoCorrectionHint;

  /// No description provided for @duelLoadingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Loading questions…'**
  String get duelLoadingQuestions;

  /// No description provided for @duelQuestionsAndSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count} questions · {seconds} s per question'**
  String duelQuestionsAndSeconds(int count, int seconds);

  /// No description provided for @duelGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel against {username}'**
  String duelGameTitle(String username);

  /// No description provided for @duelQuestionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current}/{total}'**
  String duelQuestionOf(int current, int total);

  /// No description provided for @duelAnswerSaved.
  ///
  /// In en, this message translates to:
  /// **'Answer saved. Next question in {time}'**
  String duelAnswerSaved(String time);

  /// No description provided for @duelAnswerSavedLast.
  ///
  /// In en, this message translates to:
  /// **'Answer saved. The game ends in {time}'**
  String duelAnswerSavedLast(String time);

  /// No description provided for @duelTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get duelTimeUp;

  /// No description provided for @duelQuitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the duel?'**
  String get duelQuitTitle;

  /// No description provided for @duelQuitBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers so far are sent now. The remaining questions will count as unanswered.'**
  String get duelQuitBody;

  /// No description provided for @duelKeepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get duelKeepPlaying;

  /// No description provided for @duelQuitAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get duelQuitAction;

  /// No description provided for @duelSendingAnswers.
  ///
  /// In en, this message translates to:
  /// **'Sending your answers…'**
  String get duelSendingAnswers;

  /// No description provided for @duelSendRetry.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Trying again…'**
  String get duelSendRetry;

  /// No description provided for @duelAnswersSent.
  ///
  /// In en, this message translates to:
  /// **'Answers sent'**
  String get duelAnswersSent;

  /// No description provided for @duelWaitingOpponentFinish.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {username} to finish…'**
  String duelWaitingOpponentFinish(String username);

  /// No description provided for @duelComputingResult.
  ///
  /// In en, this message translates to:
  /// **'Working out the result…'**
  String get duelComputingResult;

  /// No description provided for @duelResultAtLatest.
  ///
  /// In en, this message translates to:
  /// **'Result in {time} at the latest'**
  String duelResultAtLatest(String time);

  /// No description provided for @duelResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Duel result'**
  String get duelResultTitle;

  /// No description provided for @duelResultWin.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get duelResultWin;

  /// No description provided for @duelResultWinSub.
  ///
  /// In en, this message translates to:
  /// **'You beat {username}'**
  String duelResultWinSub(String username);

  /// No description provided for @duelResultLoss.
  ///
  /// In en, this message translates to:
  /// **'Defeat'**
  String get duelResultLoss;

  /// No description provided for @duelResultLossSub.
  ///
  /// In en, this message translates to:
  /// **'{username} wins this time'**
  String duelResultLossSub(String username);

  /// No description provided for @duelResultDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get duelResultDraw;

  /// No description provided for @duelResultDrawSub.
  ///
  /// In en, this message translates to:
  /// **'You are tied'**
  String get duelResultDrawSub;

  /// No description provided for @duelResultWinForfeit.
  ///
  /// In en, this message translates to:
  /// **'Win by forfeit'**
  String get duelResultWinForfeit;

  /// No description provided for @duelResultWinForfeitSub.
  ///
  /// In en, this message translates to:
  /// **'{username} did not finish in time.'**
  String duelResultWinForfeitSub(String username);

  /// No description provided for @duelResultLossForfeit.
  ///
  /// In en, this message translates to:
  /// **'Loss by forfeit'**
  String get duelResultLossForfeit;

  /// No description provided for @duelResultLossForfeitSub.
  ///
  /// In en, this message translates to:
  /// **'Your answers did not arrive in time.'**
  String get duelResultLossForfeitSub;

  /// No description provided for @duelResultNone.
  ///
  /// In en, this message translates to:
  /// **'No result'**
  String get duelResultNone;

  /// No description provided for @duelResultNoneSub.
  ///
  /// In en, this message translates to:
  /// **'Nobody sent any answers.'**
  String get duelResultNoneSub;

  /// No description provided for @duelScoreYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get duelScoreYou;

  /// No description provided for @duelScoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{score}/{total}'**
  String duelScoreOutOf(int score, int total);

  /// No description provided for @duelReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Question review'**
  String get duelReviewTitle;

  /// No description provided for @duelReviewQuestionHeader.
  ///
  /// In en, this message translates to:
  /// **'Question {number} · {theme}'**
  String duelReviewQuestionHeader(int number, String theme);

  /// No description provided for @duelReviewCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get duelReviewCorrect;

  /// No description provided for @duelReviewNoAnswerYou.
  ///
  /// In en, this message translates to:
  /// **'You: no answer'**
  String get duelReviewNoAnswerYou;

  /// No description provided for @duelReviewNoAnswerOpponent.
  ///
  /// In en, this message translates to:
  /// **'{username}: no answer'**
  String duelReviewNoAnswerOpponent(String username);

  /// No description provided for @duelReviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The question review is not available.'**
  String get duelReviewUnavailable;

  /// No description provided for @duelHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No duels played yet.'**
  String get duelHistoryEmpty;

  /// No description provided for @duelHistoryLine.
  ///
  /// In en, this message translates to:
  /// **'{outcome} · {count} questions'**
  String duelHistoryLine(String outcome, int count);

  /// No description provided for @duelOutcomeWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get duelOutcomeWin;

  /// No description provided for @duelOutcomeLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get duelOutcomeLoss;

  /// No description provided for @duelOutcomeDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get duelOutcomeDraw;

  /// No description provided for @duelOutcomeWinForfeit.
  ///
  /// In en, this message translates to:
  /// **'Win by forfeit'**
  String get duelOutcomeWinForfeit;

  /// No description provided for @duelOutcomeLossForfeit.
  ///
  /// In en, this message translates to:
  /// **'Loss by forfeit'**
  String get duelOutcomeLossForfeit;

  /// No description provided for @duelOutcomeNone.
  ///
  /// In en, this message translates to:
  /// **'No result'**
  String get duelOutcomeNone;

  /// No description provided for @duelErrNoThemeSelected.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one theme.'**
  String get duelErrNoThemeSelected;

  /// No description provided for @duelErrThemeNotPlayable.
  ///
  /// In en, this message translates to:
  /// **'One of the themes you picked is no longer available for this duel. The list has been refreshed.'**
  String get duelErrThemeNotPlayable;

  /// No description provided for @duelErrInvalidQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'That number of questions is not possible. Pick 5, 10, 15 or 20.'**
  String get duelErrInvalidQuestionCount;

  /// No description provided for @duelErrInvalidDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one difficulty.'**
  String get duelErrInvalidDifficulty;

  /// No description provided for @duelErrNotEnoughQuestions.
  ///
  /// In en, this message translates to:
  /// **'There are not enough questions for this choice. Add a theme or a difficulty, or reduce the number of questions.'**
  String get duelErrNotEnoughQuestions;

  /// No description provided for @duelErrLentThemeLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached today\'s duel limit for these themes. Pick other themes, or try again tomorrow.'**
  String get duelErrLentThemeLimit;

  /// No description provided for @duelErrDuelNotFound.
  ///
  /// In en, this message translates to:
  /// **'This duel no longer exists, or this link is not for you.'**
  String get duelErrDuelNotFound;

  /// No description provided for @duelErrDuelClosed.
  ///
  /// In en, this message translates to:
  /// **'This duel is over or was cancelled.'**
  String get duelErrDuelClosed;

  /// No description provided for @duelErrCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'The game is about to start: it can no longer be cancelled.'**
  String get duelErrCannotCancel;

  /// No description provided for @duelErrNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The duel has not started yet. Please wait a moment.'**
  String get duelErrNotStarted;

  /// No description provided for @duelErrDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'The time to send your answers has run out.'**
  String get duelErrDeadlinePassed;

  /// No description provided for @duelInviteQrCaption.
  ///
  /// In en, this message translates to:
  /// **'Your friend can also scan this QR code with their phone\'s camera.'**
  String get duelInviteQrCaption;

  /// No description provided for @duelCallQrCaption.
  ///
  /// In en, this message translates to:
  /// **'{username} can also scan this QR code with their phone\'s camera.'**
  String duelCallQrCaption(String username);

  /// No description provided for @duelQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'Link QR code'**
  String get duelQrSemantics;

  /// No description provided for @duelGameOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get duelGameOfflineTitle;

  /// No description provided for @duelDeadlineWarning.
  ///
  /// In en, this message translates to:
  /// **'Your answers must be sent before {time}, or you forfeit.'**
  String duelDeadlineWarning(String time);

  /// No description provided for @duelSendTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String duelSendTimeLeft(String time);

  /// No description provided for @registerThrottledMessage.
  ///
  /// In en, this message translates to:
  /// **'Many sign-ups are coming from this connection right now. {wait}'**
  String registerThrottledMessage(String wait);

  /// No description provided for @registerThrottledWaitShort.
  ///
  /// In en, this message translates to:
  /// **'Try again in less than a minute.'**
  String get registerThrottledWaitShort;

  /// No description provided for @registerThrottledWait.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Try again in about 1 minute.} other{Try again in about {minutes} minutes.}}'**
  String registerThrottledWait(int minutes);

  /// No description provided for @registerThrottledWaitUnknown.
  ///
  /// In en, this message translates to:
  /// **'Try again in a little while.'**
  String get registerThrottledWaitUnknown;
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
