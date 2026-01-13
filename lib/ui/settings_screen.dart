import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.language,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LanguageOption(
                    language: 'English',
                    code: 'en',
                    isSelected: languageProvider.languageCode == 'en',
                    onTap: () {
                      languageProvider.setLanguage('en');
                    },
                  ),
                  const SizedBox(height: 12),
                  _LanguageOption(
                    language: 'Français',
                    code: 'fr',
                    isSelected: languageProvider.languageCode == 'fr',
                    onTap: () {
                      languageProvider.setLanguage('fr');
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.about,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.version,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.aboutText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'admin@ndsh-software.fr',
                          );
                          if (await canLaunchUrl(emailLaunchUri)) {
                            await launchUrl(emailLaunchUri);
                          }
                        },
                        child: Text(
                          'admin@ndsh-software.fr',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© ndsh-software',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String language;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
