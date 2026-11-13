import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/theme.dart' as theme_model;
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/quizz_builder_provider.dart';
import '../services/catalog_service.dart';
import '../widgets/offline_banner.dart';
import 'credit_store_screen.dart';

/// The origin the server records for an unlock that starts from a padlock row
/// of the duel challenge screen (the only value it accepts).
const String duelChallengeUnlockOrigin = 'duel_challenge';

/// Unlocks premium themes with credits.
///
/// Without [duelChallengeThemeId] it lists every locked premium theme and
/// stays open after an unlock, exactly as it always did (and sends no origin).
/// With it, the screen is opened from a padlock row of the duel challenge
/// screen: it shows that one theme, sends [duelChallengeUnlockOrigin], and
/// closes itself with `true` (the theme is now the player's) or `false`
/// (nothing was unlocked).
class PremiumThemeUnlockScreen extends StatefulWidget {
  final int? duelChallengeThemeId;

  /// Replaces the credit store screen (tests: the real one needs the store
  /// plugins).
  final WidgetBuilder? storeBuilder;

  const PremiumThemeUnlockScreen({
    super.key,
    this.duelChallengeThemeId,
    this.storeBuilder,
  });

  @override
  State<PremiumThemeUnlockScreen> createState() =>
      _PremiumThemeUnlockScreenState();
}

class _PremiumThemeUnlockScreenState extends State<PremiumThemeUnlockScreen> {
  late final CatalogService _catalogService;

  bool _loading = true;
  String? _error;
  int? _unlockingThemeId;
  List<theme_model.Theme> _premiumThemes = const [];

  bool get _singleTheme => widget.duelChallengeThemeId != null;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _catalogService = CatalogService(authService: authProvider.authService);
    _load();
  }

  Future<void> _load() async {
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await builder.refreshThemeAccess();
      final themes = await _catalogService.getAllThemes();
      if (!mounted) return;
      if (_singleTheme && _leaveIfSettled(themes)) return;

      setState(() {
        _premiumThemes =
            themes
                .where((theme) => theme.isActive && !theme.isFree)
                .toList(growable: false)
              ..sort(
                (a, b) => a
                    .getName(Localizations.localeOf(context).languageCode)
                    .compareTo(
                      b.getName(Localizations.localeOf(context).languageCode),
                    ),
              );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Single-theme mode: closes the screen when the theme can no longer be
  /// unlocked from here. Returns whether it did.
  bool _leaveIfSettled(List<theme_model.Theme> all) {
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    theme_model.Theme? theme;
    for (final t in all) {
      if (t.id == widget.duelChallengeThemeId) theme = t;
    }
    if (theme == null || !theme.isActive || theme.isFree) {
      _leave(l10n.unlockThemeUnavailable, unlocked: false);
      return true;
    }
    if (builder.isThemeEntitled(theme)) {
      final name = theme.getName(Localizations.localeOf(context).languageCode);
      _leave(l10n.unlockThemeAlreadyUnlocked(name), unlocked: true);
      return true;
    }
    return false;
  }

  /// The message is shown by the screen underneath (snack bars outlive the
  /// route that raised them).
  void _leave(String message, {required bool unlocked, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : null,
      ),
    );
    Navigator.of(context).pop(unlocked);
  }

  /// Single-theme mode, after the server refused an unlock. The refusals
  /// carry no code (three identical 400s, English text), so the text is never
  /// read: the state is fetched again and decides.
  Future<void> _resyncAfterRefusal() async {
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    var resynced = false;
    try {
      await builder.refreshThemeAccess();
      if (builder.themeAccessError == null) {
        final all = await _catalogService.getAllThemes();
        if (!mounted) return;
        if (_leaveIfSettled(all)) return;
        resynced = true;
      }
    } catch (_) {
      // Handled below: the state could not be fetched again.
    }
    if (!mounted) return;
    // No credit left: the screen now shows that state, nothing more to say.
    if (resynced && builder.creditBalance < 1) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.errorGenericTryAgain),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _openStore() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: widget.storeBuilder ?? (_) => const CreditStoreScreen(),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _unlockTheme(theme_model.Theme theme) async {
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
    final catalogProvider = Provider.of<CatalogProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    if (!context.read<ConnectivityProvider>().isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offlinePurchaseUnavailable),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _unlockingThemeId = theme.id;
    });

    try {
      final remaining = await builder.unlockThemeWithCredit(
        theme,
        origin: _singleTheme ? duelChallengeUnlockOrigin : null,
      );
      // Download the newly-unlocked theme's questions right away so it's
      // playable offline without waiting for the next background sync.
      unawaited(catalogProvider.syncThemeQuestions(theme));
      if (!mounted) return;

      final message = l10n.unlockThemeSuccess(
        theme.getName(Localizations.localeOf(context).languageCode),
        l10n.storeQuestionPackCount(remaining),
      );
      if (_singleTheme) {
        _leave(message, unlocked: true, success: true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      if (_singleTheme) {
        await _resyncAfterRefusal();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _unlockingThemeId = null;
        });
      }
    }
  }

  /// Single-theme mode without credit: the reason, and the way to the store.
  List<Widget> _noCreditActions(AppLocalizations l10n) => [
    Text(l10n.unlockThemeNoCredits, key: const ValueKey('unlock-no-credits')),
    const SizedBox(height: 12),
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('unlock-open-store'),
        onPressed: _openStore,
        icon: const Icon(Icons.storefront),
        label: Text(l10n.openStore),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = context.select<ConnectivityProvider, bool>(
      (provider) => provider.isOnline,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _singleTheme
              ? l10n.unlockThemeFocusTitle
              : l10n.unlockPremiumThemesTitle,
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<QuizzBuilderProvider>(
        builder: (context, builder, _) {
          final lockedThemes = _premiumThemes
              .where(
                (theme) =>
                    !builder.isThemeEntitled(theme) &&
                    (!_singleTheme || theme.id == widget.duelChallengeThemeId),
              )
              .toList(growable: false);

          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: Text(l10n.retry)),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (!isOnline) const OfflineBanner(),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storeCurrentBalance(
                        l10n.storeQuestionPackCount(builder.creditBalance),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_singleTheme)
                      Text(l10n.unlockThemeFocusHelp)
                    else ...[
                      Text(l10n.tapLockedThemeToUnlock),
                      const SizedBox(height: 4),
                      Text(
                        l10n.storeLockedPaidThemesCount(lockedThemes.length),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: lockedThemes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.noPremiumThemesToUnlock,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: lockedThemes.length,
                        itemBuilder: (context, index) {
                          final theme = lockedThemes[index];
                          final isUnlocking = _unlockingThemeId == theme.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.getName(
                                      Localizations.localeOf(
                                        context,
                                      ).languageCode,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if ((theme.getDescription(
                                            Localizations.localeOf(
                                              context,
                                            ).languageCode,
                                          ) ??
                                          '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      theme.getDescription(
                                        Localizations.localeOf(
                                          context,
                                        ).languageCode,
                                      )!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Text(
                                    '${theme.questionsCount} ${theme.questionsCount == 1 ? l10n.question : l10n.questions}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 14),
                                  if (_singleTheme && builder.creditBalance < 1)
                                    ..._noCreditActions(l10n)
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed:
                                            builder.creditBalance < 1 ||
                                                isUnlocking ||
                                                !isOnline
                                            ? null
                                            : () => _unlockTheme(theme),
                                        icon: isUnlocking
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.lock_open),
                                        label: Text(l10n.unlockThemeAction),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
