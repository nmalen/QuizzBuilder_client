import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/theme.dart' as theme_model;
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/quizz_builder_provider.dart';
import '../services/catalog_service.dart';
import '../widgets/offline_banner.dart';

class PremiumThemeUnlockScreen extends StatefulWidget {
  const PremiumThemeUnlockScreen({super.key});

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

  Future<void> _unlockTheme(theme_model.Theme theme) async {
    final builder = Provider.of<QuizzBuilderProvider>(context, listen: false);
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
      final remaining = await builder.unlockThemeWithCredit(theme);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.unlockThemeSuccess(
              theme.getName(Localizations.localeOf(context).languageCode),
              l10n.storeQuestionPackCount(remaining),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _unlockingThemeId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnline = context.select<ConnectivityProvider, bool>(
      (provider) => provider.isOnline,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.unlockPremiumThemesTitle),
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
              .where((theme) => !builder.isThemeEntitled(theme))
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
                    Text(l10n.tapLockedThemeToUnlock),
                    const SizedBox(height: 4),
                    Text(
                      l10n.storeLockedPaidThemesCount(lockedThemes.length),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                                              child: CircularProgressIndicator(
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
