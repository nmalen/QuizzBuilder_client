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
  String get multiplayerModeDesc => 'Challenge each other with 1 to 4 players or in teams';

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
  String get storePurchaseIncidentTitle => 'Purchase needs attention';

  @override
  String get storePurchaseIncidentBody => 'We couldn\'t confirm this purchase with our server after several attempts. It may not have been credited yet. Please contact support with the reference below so we can check it manually.';

  @override
  String get storePurchaseIncidentReferenceLabel => 'Reference';

  @override
  String get storePurchaseIncidentCopyReference => 'Copy reference';

  @override
  String get storePurchaseIncidentReferenceCopied => 'Reference copied';

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

  @override
  String multiplayerNotEnoughQuestions(int required, int players, int perPlayer, int available) {
    return 'Not enough questions for this game. You need $required ($players players × $perPlayer questions each) but your themes and levels only provide $available. Reduce the number of players or questions, or select more themes or levels.';
  }

  @override
  String multiplayerQuestionsAvailability(int available, int required, int players, int perPlayer) {
    return '$available questions available · $required needed ($players × $perPlayer)';
  }

  @override
  String multiplayerAdviceReduceQuestions(int max) {
    return 'Reduce to $max questions per player, or select more themes or levels.';
  }

  @override
  String get multiplayerAdviceReducePlayers => 'Reduce the number of players, or select more themes or levels.';

  @override
  String multiplayerThemesBanner(int max, int maxPlayers, int maxQuestions) {
    return 'Multiplayer: each player gets their own questions. Plan for players × questions per player, up to $max questions ($maxPlayers players × $maxQuestions). The question counter shows what you have.';
  }

  @override
  String get selectAllThemes => 'Select all';

  @override
  String get deselectAllThemes => 'Deselect all';

  @override
  String difficultyLevelWithCount(String level, int count) {
    return '$level ($count)';
  }

  @override
  String get duelCardTitle => 'Duel';

  @override
  String get duelCardSubtitle => 'Challenge a friend';

  @override
  String get duelHubTitle => 'Duel';

  @override
  String get duelInviteTitle => 'Invite a friend';

  @override
  String get duelInviteSubtitle => 'Share a code or a link';

  @override
  String get duelJoinTitle => 'Join with a code';

  @override
  String get duelJoinSubtitle => 'Got a code?';

  @override
  String duelOpponentsSection(int count) {
    return 'My opponents ($count)';
  }

  @override
  String duelOpponentSince(String date) {
    return 'Opponent since $date';
  }

  @override
  String get duelMenuRemove => 'Remove';

  @override
  String get duelMenuBlock => 'Block';

  @override
  String get duelMyInvitations => 'My invitations';

  @override
  String get duelBlockedPlayers => 'Blocked players';

  @override
  String get duelNoOpponents => 'No opponents yet. Invite a friend with a code or a link.';

  @override
  String get duelOfflineMessage => 'Duel needs an internet connection. Reconnect to see your opponents.';

  @override
  String get duelInviteOfflineMessage => 'Creating an invitation needs an internet connection.';

  @override
  String get duelOfflineListMessage => 'This list needs an internet connection.';

  @override
  String duelRemoveTitle(String username) {
    return 'Remove $username?';
  }

  @override
  String duelRemoveBody(String username) {
    return '$username will no longer be one of your opponents. To connect again, you will need a new invitation.';
  }

  @override
  String get duelRemoveAction => 'Remove';

  @override
  String duelBlockTitle(String username) {
    return 'Block $username?';
  }

  @override
  String duelBlockBody(String username) {
    return '$username will be removed from your opponents and will not be able to join you with an invitation. You can unblock them from “Blocked players”.';
  }

  @override
  String get duelBlockAction => 'Block';

  @override
  String duelRemoved(String username) {
    return '$username was removed.';
  }

  @override
  String duelBlocked(String username) {
    return '$username was blocked.';
  }

  @override
  String get duelInviteCodeLabel => 'Your invitation code';

  @override
  String duelInviteValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get duelInviteSingleUse => 'Single use';

  @override
  String get duelShare => 'Share';

  @override
  String get duelCopy => 'Copy';

  @override
  String get duelInviteHelp => 'Your friend taps the link or enters the code under Duel › Join with a code. If they don\'t have the app, they can install it, then sign up with this code.';

  @override
  String get duelCopied => 'Copied to the clipboard';

  @override
  String get duelSeeMyInvitations => 'See my invitations';

  @override
  String duelShareMessage(String link, String code, String expiry) {
    return 'Challenge me on QuizzBuilder! Tap this link to become my opponent: $link\nIf you already have the app, you can also enter the code $code under Duel › Join with a code. Valid until $expiry.';
  }

  @override
  String get duelJoinCodeLabel => 'Invitation code';

  @override
  String get duelJoinCodeHelp => '6 characters, with or without a dash';

  @override
  String get duelContinue => 'Continue';

  @override
  String get duelConfirmTitle => 'Invitation';

  @override
  String duelChallengesYou(String username) {
    return '$username challenges you';
  }

  @override
  String duelAcceptBody(String username) {
    return 'Accept to become opponents with $username.';
  }

  @override
  String duelInvitationValidUntil(String date) {
    return 'Invitation valid until $date';
  }

  @override
  String get duelAccept => 'Accept';

  @override
  String get duelNotNow => 'Not now';

  @override
  String duelNowOpponent(String username) {
    return 'You are now opponents with $username';
  }

  @override
  String duelNewOpponents(int count) {
    return 'You have $count new opponents';
  }

  @override
  String get duelMyInvitationsTitle => 'My invitations';

  @override
  String duelInvitationExpires(String date) {
    return 'Expires on $date';
  }

  @override
  String get duelNoInvitations => 'No active invitations.';

  @override
  String get duelCancelInvitationTitle => 'Cancel the invitation?';

  @override
  String duelCancelInvitationBody(String code) {
    return 'The code $code will no longer work.';
  }

  @override
  String get duelBack => 'Back';

  @override
  String get duelCancelInvitationAction => 'Cancel invitation';

  @override
  String get duelInvitationCancelled => 'Invitation cancelled';

  @override
  String get duelBlockedTitle => 'Blocked players';

  @override
  String duelBlockedSince(String date) {
    return 'Blocked on $date';
  }

  @override
  String get duelUnblock => 'Unblock';

  @override
  String get duelNoBlocked => 'No blocked players.';

  @override
  String duelUnblockTitle(String username) {
    return 'Unblock $username?';
  }

  @override
  String duelUnblockBody(String username) {
    return '$username will not become your opponent again automatically: you will need a new invitation.';
  }

  @override
  String duelUnblocked(String username) {
    return '$username was unblocked.';
  }

  @override
  String get duelErrInvitationNotFound => 'This code doesn\'t exist or is no longer valid. Check it with your friend.';

  @override
  String get duelErrInvitationExpired => 'This invitation has expired. Ask your friend to send you a new one.';

  @override
  String get duelErrInvitationAlreadyUsed => 'This invitation has already been used. Ask your friend to send you a new one.';

  @override
  String get duelErrOwnInvitation => 'This is your own invitation: share it with a friend.';

  @override
  String get duelErrAlreadyOpponents => 'You are already opponents.';

  @override
  String get duelErrOpponentLimit => 'You have reached the limit of 100 opponents. Remove one to add another.';

  @override
  String get duelErrInviterOpponentLimit => 'This person has reached their opponent limit. Try again later.';

  @override
  String get duelErrThrottled => 'Too many attempts. Try again in an hour.';

  @override
  String get duelErrActiveInvitationLimit => 'You already have 5 active invitations. Cancel one or wait for it to expire.';

  @override
  String get duelErrOpponentNotFound => 'This opponent no longer exists. The list has been refreshed.';

  @override
  String get duelErrBlockNotFound => 'This block no longer exists. The list has been refreshed.';

  @override
  String get duelErrNetwork => 'Unable to connect. Check your internet connection and try again.';

  @override
  String get invitationCodeOptional => 'Invitation code (optional)';

  @override
  String get invitationCodeHelp => 'If a friend invited you, enter their code.';

  @override
  String get invitationCodeBanner => 'A friend invited you. Sign up: the code is already filled in.';

  @override
  String get invitationCodeLength => 'The code has 6 characters';

  @override
  String duelBannerPlaying(String username) {
    return 'Duel in progress against $username';
  }

  @override
  String get duelBannerPlayingSub => 'Tap to resume the game';

  @override
  String duelBannerWaiting(String username) {
    return '$username is waiting for you';
  }

  @override
  String get duelBannerWaitingSub => 'Tap to join the room';

  @override
  String duelBannerMany(int count) {
    return '$count duels are waiting for you';
  }

  @override
  String get duelBannerManySub => 'Tap to see them';

  @override
  String duelOpenSection(int count) {
    return 'Open duels ($count)';
  }

  @override
  String duelOpenWaitingForMe(String username) {
    return '$username is waiting for you';
  }

  @override
  String get duelOpenWaitingForMeSub => 'Join the waiting room';

  @override
  String duelOpenMyChallenge(String username) {
    return 'Your challenge to $username';
  }

  @override
  String duelOpenMyChallengeSub(String time) {
    return 'Waiting · room open until $time';
  }

  @override
  String duelOpenPlaying(String username) {
    return 'Game in progress against $username';
  }

  @override
  String get duelOpenPlayingSub => 'Resume the game';

  @override
  String duelOpenAwaitingResult(String username) {
    return 'Result pending · $username';
  }

  @override
  String get duelOpenAwaitingResultSub => 'Tap to see the result';

  @override
  String get duelChallengeAction => 'Challenge';

  @override
  String get duelOpenAction => 'Open';

  @override
  String get duelHistoryTitle => 'Duel history';

  @override
  String duelChallengeTitle(String username) {
    return 'Challenge $username';
  }

  @override
  String get duelThemesSection => 'Themes';

  @override
  String duelThemesChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count themes chosen',
      one: '1 theme chosen',
      zero: 'No theme chosen',
    );
    return '$_temp0';
  }

  @override
  String get duelDifficultiesSection => 'Difficulties';

  @override
  String get duelQuestionCountSection => 'Number of questions';

  @override
  String get duelCountsGreyedHint => 'Some numbers are greyed out: there are not enough questions with this choice.';

  @override
  String duelSecondsPerQuestion(int seconds) {
    return '$seconds seconds per question, for both of you.';
  }

  @override
  String get duelStartChallenge => 'Start the challenge';

  @override
  String get duelNoPlayableThemes => 'No theme can be played for this duel right now.';

  @override
  String duelAlreadyOpenOpened(String username) {
    return 'A duel is already open with $username: here it is.';
  }

  @override
  String get duelRoomTitle => 'Waiting room';

  @override
  String get duelRoomOpening => 'Opening the room…';

  @override
  String duelRoomWaitingFor(String username) {
    return 'Waiting for $username…';
  }

  @override
  String duelRoomHintChallenger(String username) {
    return 'The game starts as soon as $username joins you.';
  }

  @override
  String duelRoomHintChallenged(String username) {
    return '$username challenged you. The game starts as soon as you are both here.';
  }

  @override
  String duelRoomTimeLeft(String time) {
    return 'Room open for another $time';
  }

  @override
  String get duelRoomUnstable => 'Unstable connection… trying again';

  @override
  String get duelRoomOffline => 'You are offline. The room will resume as soon as you are back online.';

  @override
  String get duelCallLinkTitle => 'Call link';

  @override
  String duelCallLinkHelp(String username) {
    return 'Send this link to $username: tapping it opens the room directly.';
  }

  @override
  String duelCallShareMessage(String link, String time) {
    return 'I challenge you to a duel on QuizzBuilder! Tap this link to join me: $link\nThe waiting room is open until $time.';
  }

  @override
  String duelRoomSummary(int count, int seconds, String difficulties) {
    return '$count questions · $seconds s per question · $difficulties';
  }

  @override
  String get duelCancelDuel => 'Cancel the duel';

  @override
  String get duelCancelDuelTitle => 'Cancel the duel?';

  @override
  String get duelCancelDuelBody => 'The waiting room will be closed for both of you.';

  @override
  String get duelDuelCancelled => 'Duel cancelled';

  @override
  String get duelRoomExpired => 'This waiting room has expired. You can start a new challenge.';

  @override
  String get duelRoomCancelled => 'This duel was cancelled.';

  @override
  String get duelBackToDuels => 'Back to duels';

  @override
  String duelCountdownIntro(String username) {
    return 'Your duel against $username starts in';
  }

  @override
  String get duelCountdownGo => 'Go!';

  @override
  String get duelNoCorrectionHint => 'Answers will only be revealed at the end.';

  @override
  String get duelLoadingQuestions => 'Loading questions…';

  @override
  String duelQuestionsAndSeconds(int count, int seconds) {
    return '$count questions · $seconds s per question';
  }

  @override
  String duelGameTitle(String username) {
    return 'Duel against $username';
  }

  @override
  String duelQuestionOf(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String duelAnswerSaved(String time) {
    return 'Answer saved. Next question in $time';
  }

  @override
  String duelAnswerSavedLast(String time) {
    return 'Answer saved. The game ends in $time';
  }

  @override
  String get duelTimeUp => 'Time\'s up';

  @override
  String get duelQuitTitle => 'Leave the duel?';

  @override
  String get duelQuitBody => 'Your answers so far are sent now. The remaining questions will count as unanswered.';

  @override
  String get duelKeepPlaying => 'Keep playing';

  @override
  String get duelQuitAction => 'Leave';

  @override
  String get duelSendingAnswers => 'Sending your answers…';

  @override
  String get duelSendRetry => 'Connection failed. Trying again…';

  @override
  String get duelAnswersSent => 'Answers sent';

  @override
  String duelWaitingOpponentFinish(String username) {
    return 'Waiting for $username to finish…';
  }

  @override
  String get duelComputingResult => 'Working out the result…';

  @override
  String duelResultAtLatest(String time) {
    return 'Result in $time at the latest';
  }

  @override
  String get duelResultTitle => 'Duel result';

  @override
  String get duelResultWin => 'Victory!';

  @override
  String duelResultWinSub(String username) {
    return 'You beat $username';
  }

  @override
  String get duelResultLoss => 'Defeat';

  @override
  String duelResultLossSub(String username) {
    return '$username wins this time';
  }

  @override
  String get duelResultDraw => 'Draw';

  @override
  String get duelResultDrawSub => 'You are tied';

  @override
  String get duelResultWinForfeit => 'Win by forfeit';

  @override
  String duelResultWinForfeitSub(String username) {
    return '$username did not finish in time.';
  }

  @override
  String get duelResultLossForfeit => 'Loss by forfeit';

  @override
  String get duelResultLossForfeitSub => 'Your answers did not arrive in time.';

  @override
  String get duelResultNone => 'No result';

  @override
  String get duelResultNoneSub => 'Nobody sent any answers.';

  @override
  String get duelScoreYou => 'You';

  @override
  String duelScoreOutOf(int score, int total) {
    return '$score/$total';
  }

  @override
  String get duelReviewTitle => 'Question review';

  @override
  String duelReviewQuestionHeader(int number, String theme) {
    return 'Question $number · $theme';
  }

  @override
  String get duelReviewCorrect => 'Correct answer';

  @override
  String get duelReviewNoAnswerYou => 'You: no answer';

  @override
  String duelReviewNoAnswerOpponent(String username) {
    return '$username: no answer';
  }

  @override
  String get duelReviewUnavailable => 'The question review is not available.';

  @override
  String get duelHistoryEmpty => 'No duels played yet.';

  @override
  String duelHistoryLine(String outcome, int count) {
    return '$outcome · $count questions';
  }

  @override
  String get duelOutcomeWin => 'Win';

  @override
  String get duelOutcomeLoss => 'Loss';

  @override
  String get duelOutcomeDraw => 'Draw';

  @override
  String get duelOutcomeWinForfeit => 'Win by forfeit';

  @override
  String get duelOutcomeLossForfeit => 'Loss by forfeit';

  @override
  String get duelOutcomeNone => 'No result';

  @override
  String get duelErrNoThemeSelected => 'Pick at least one theme.';

  @override
  String get duelErrThemeNotPlayable => 'One of the themes you picked is no longer available for this duel. The list has been refreshed.';

  @override
  String get duelErrInvalidQuestionCount => 'That number of questions is not possible. Pick 5, 10, 15 or 20.';

  @override
  String get duelErrInvalidDifficulty => 'Pick at least one difficulty.';

  @override
  String get duelErrNotEnoughQuestions => 'There are not enough questions for this choice. Add a theme or a difficulty, or reduce the number of questions.';

  @override
  String get duelErrLentThemeLimit => 'You have reached today\'s duel limit for these themes. Pick other themes, or try again tomorrow.';

  @override
  String get duelErrDuelNotFound => 'This duel no longer exists, or this link is not for you.';

  @override
  String get duelErrDuelClosed => 'This duel is over or was cancelled.';

  @override
  String get duelErrCannotCancel => 'The game is about to start: it can no longer be cancelled.';

  @override
  String get duelErrNotStarted => 'The duel has not started yet. Please wait a moment.';

  @override
  String get duelErrDeadlinePassed => 'The time to send your answers has run out.';
}
