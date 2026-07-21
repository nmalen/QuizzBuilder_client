// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get standardMode => 'Standard';

  @override
  String get survivalMode => 'Survival';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

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
  String get quizzBuilderContent => 'QuizzBuilder';

  @override
  String get quizzBuilderContentSubtitle => 'Total active content (including unpurchased)';

  @override
  String get userContent => 'User';

  @override
  String get userContentSubtitle => 'Unlocked content';

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
  String get account => 'Account';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get optOutButton => 'Delete account';

  @override
  String get optOutDescription => 'Request deletion of your account and all associated data.';

  @override
  String get optOutConfirmTitle => 'Confirm account deletion';

  @override
  String get optOutConfirmMessage => 'Are you sure you want to delete your account? All of your user data, including your purchases, will be deleted within 30 days. After confirmation, you will no longer be able to access the application.';

  @override
  String get optOutRecordedTitle => 'Request recorded';

  @override
  String get optOutConfirmAction => 'Confirm request';

  @override
  String get optOutSuccess => 'Your deletion request has been recorded. A confirmation email has been sent. You will now be logged out.';

  @override
  String get optOutAlreadyRequested => 'Your account is already scheduled for deletion. You will now be logged out.';

  @override
  String get optOutError => 'Unable to request account deletion right now. Please try again.';

  @override
  String get pendingDeletionTitle => 'Pending deletion request';

  @override
  String get pendingDeletionMessage => 'A pending account deletion request is active. If you want to revert this process, contact the admin at admin@ndsh-software.fr.';

  @override
  String get pendingDeletionLoginBlockedMessage => 'A pending account deletion request is active. Login is disabled. Contact the admin at admin@ndsh-software.fr to restore access.';

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
  String get version => 'QuizzBuilder v0.21.3';

  @override
  String get aboutText => 'An interactive quiz platform to test your knowledge.';

  @override
  String get storeFeatureComing => 'Store feature coming soon!';

  @override
  String get errorLoadingCategories => 'Error loading categories';

  @override
  String get errorLoadingThemes => 'Error loading themes';

  @override
  String get errorTooManyRequests => 'Too many requests. Please wait a moment and try again.';

  @override
  String get errorGenericTryAgain => 'Something went wrong. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get noCategories => 'No categories available';

  @override
  String get noThemes => 'No themes available';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

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
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordMessage => 'Enter the email address linked to your account. If it exists, you will receive a reset link by email.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get passwordResetEmailSent => 'If an account exists for this email, a password reset link has been sent.';

  @override
  String get passwordResetInvalidEmail => 'Please enter a valid email address.';

  @override
  String get passwordResetError => 'Unable to request a password reset right now. Please try again.';

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

  @override
  String get setupSoloGame => 'Setup solo game';

  @override
  String get setupMultiplayerGame => 'Setup multiplayer game';

  @override
  String get selectNumberOfQuestions => 'Select number of questions (5-20)';

  @override
  String get selectNumberOfPlayers => 'Select number of players (1-4)';

  @override
  String get selectQuestionsLevels => 'Select questions level(s)';

  @override
  String get dailyPathToFreeCredit => 'Path to the next free credit';

  @override
  String get players => 'Players';

  @override
  String get startGame => 'Start Game';

  @override
  String get continueText => 'Continue';

  @override
  String get noThemesSelected => 'No themes selected.';

  @override
  String get theme => 'Theme';

  @override
  String get quizSummary => 'Quiz Summary';

  @override
  String get question => 'Question';

  @override
  String get changeSelection => 'Change selection';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get yourScore => 'Your Score';

  @override
  String get correct => 'Correct';

  @override
  String get correctAnswers => 'Correct Answers';

  @override
  String get wrongAnswers => 'Wrong Answers';

  @override
  String get timeUsed => 'Time Used';

  @override
  String get home => 'Home';

  @override
  String get playAgain => 'Play Again';

  @override
  String get save => 'Save';

  @override
  String get gameOver => 'Game Over!';

  @override
  String get survivalComplete => 'Survival Complete!';

  @override
  String get survivalBestScores => 'Best survival scores';

  @override
  String get survivalNoBestScores => 'No saved survival scores yet.';

  @override
  String get survivalCurrentResult => 'Current result';

  @override
  String get survivalNewBestTitle => 'New best score!';

  @override
  String get survivalNewBestMessage => 'Save this score under a name.';

  @override
  String get survivalPlayerName => 'Player name';

  @override
  String survivalRankLabel(int rank) {
    return 'Rank #$rank';
  }

  @override
  String get timesUp => 'Time\'s Up!';

  @override
  String get quizComplete => 'Quiz Complete!';

  @override
  String get ok => 'OK';

  @override
  String get emailAlreadyExists => 'An account with this email already exists.';

  @override
  String get outstanding => 'Outstanding! 🌟';

  @override
  String get excellent => 'Excellent! ⭐';

  @override
  String get greatJob => 'Great Job! 👍';

  @override
  String get goodEffort => 'Good Effort! 💪';

  @override
  String get notBad => 'Not Bad! 📚';

  @override
  String get keepPracticing => 'Keep Practicing! 📖';

  @override
  String get free => 'Free';

  @override
  String get premium => 'Premium';

  @override
  String get feedbackInvitation => 'Feel free to contact me to request new themes or share your feedback';

  @override
  String get iapNotImplemented => 'In-app purchases are not yet implemented. This feature is coming soon!';

  @override
  String get storePacksTitle => 'Question Packs';

  @override
  String storeCurrentBalance(String packs) {
    return 'Available credit(s): $packs';
  }

  @override
  String get storeRestorePurchases => 'Restore purchases';

  @override
  String get storeRestoring => 'Restoring...';

  @override
  String get storeUnavailableOnDevice => 'Purchases are currently unavailable on this device.';

  @override
  String get storeUnlockExplanation => 'Each purchased pack can be used to unlock additional premium themes.';

  @override
  String storeCreditPackDescription(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Unlock up to $count premium themes',
      one: 'Unlock $count premium theme',
    );
    return '$_temp0';
  }

  @override
  String storeLockedPaidThemesCount(int count) {
    return 'Premium themes not yet unlocked: $count';
  }

  @override
  String storePurchaseSuccess(String granted, String balance) {
    return 'Pack added: +$granted (available $balance)';
  }

  @override
  String storeRestoreSuccess(String balance) {
    return 'Restore complete. Available packs: $balance.';
  }

  @override
  String storeVerificationFailed(String error) {
    return 'Verification failed: $error';
  }

  @override
  String storeRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get storeProductUnavailable => 'This pack is not available for purchase yet.';

  @override
  String get storePurchaseFlowFailed => 'Failed to start purchase flow.';

  @override
  String storeUnknownProductId(String productId) {
    return 'Unknown product ID: $productId';
  }

  @override
  String get storeBuy => 'Get pack';

  @override
  String get storeProcessing => 'Processing...';

  @override
  String storeQuestionPackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count question packs',
      one: '$count question pack',
    );
    return '$_temp0';
  }

  @override
  String storeCreditCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credits',
      one: '$count credit',
    );
    return '$_temp0';
  }

  @override
  String storePackTooLargeForRemaining(String remaining) {
    return 'This pack is too large for your remaining unlocks ($remaining).';
  }

  @override
  String get unlockPremiumThemesTitle => 'Unlock Premium Themes';

  @override
  String get unlockThemeAction => 'Unlock';

  @override
  String unlockThemePrompt(String theme) {
    return 'Unlock $theme for 1 credit?';
  }

  @override
  String get unlockThemeNoCredits => 'You need at least 1 credit to unlock this theme.';

  @override
  String get openStore => 'Open store';

  @override
  String unlockThemeSuccess(String theme, String balance) {
    return '$theme unlocked. Remaining credits: $balance';
  }

  @override
  String get noPremiumThemesToUnlock => 'All premium themes are already unlocked.';

  @override
  String get tapLockedThemeToUnlock => 'Tap a locked premium theme to unlock it with 1 credit.';

  @override
  String get errorLoadingCredits => 'Could not refresh credit balance.';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get reportError => 'Report error';

  @override
  String get questionFlagged => 'Question reported successfully';

  @override
  String failedToReportError(String error) {
    return 'Failed to report error: $error';
  }

  @override
  String get noQuestionsFound => 'No questions found';

  @override
  String get goBack => 'Go back';

  @override
  String get itsTie => 'It\'s a tie!';

  @override
  String playerWins(int player) {
    return 'Player $player wins!';
  }

  @override
  String get winningScore => 'Winning Score';

  @override
  String get finalLeaderboard => 'Final Leaderboard';

  @override
  String player(int number) {
    return 'Player $number';
  }

  @override
  String get dailyMode => 'Daily';

  @override
  String get dailyStatusLoadError => 'Unable to load daily status.';

  @override
  String get dailyChallenge => 'Daily challenge';

  @override
  String dailyProgress(int currentStreak, int target) {
    return 'Progress: $currentStreak/$target without error';
  }

  @override
  String dailyRewardsGranted(int count) {
    return 'Free credits unlocked: $count';
  }

  @override
  String get dailyAvailableToday => 'Available today';

  @override
  String get dailyAlreadyPlayedToday => 'Already played today';

  @override
  String get dailyTierReached => 'Milestone reached: +1 credit ready to unlock';

  @override
  String dailyTierTarget(int target) {
    return 'Credit milestone: reached at ${target}th success';
  }

  @override
  String get dailyTierHint => 'The credit milestone is highlighted in gold.';

  @override
  String get offlineBannerMessage => 'You\'re offline. You can still play quizzes you\'ve already downloaded, but new downloads and purchases are unavailable.';

  @override
  String get offlineDownloadUnavailable => 'This quiz isn\'t downloaded yet and you\'re offline. Connect to the internet to download it.';

  @override
  String get offlinePurchaseUnavailable => 'Purchases are unavailable offline. Connect to the internet to buy or unlock content.';

  @override
  String get dailyChallengeOfflineUnavailable => 'The daily challenge needs an internet connection and can\'t be played offline. Connect to the internet and try again.';
}
