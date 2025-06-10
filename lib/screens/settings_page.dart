import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learn_progress_tracker/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/persistence_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final persistenceService = PersistenceService();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Appearance Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearance,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                // Dark Mode Switch
                SwitchListTile(
                  title: Text(l10n.darkMode),
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme();
                  },
                ),
                const Divider(),
                // Language Selection
                ListTile(
                  title: Text(l10n.language),
                  trailing: DropdownButton<Locale>(
                    value: localeProvider.locale,
                    items: [
                      DropdownMenuItem(
                        value: const Locale('en'),
                        child: Text(l10n.english),
                      ),
                      DropdownMenuItem(
                        value: const Locale('de'),
                        child: Text(l10n.german),
                      ),
                    ],
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        localeProvider.setLocale(newLocale);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Data Management Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dataManagement,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.upload_rounded),
                  title: Text(l10n.exportData),
                  onTap: () async {
                    try {
                      final backupPath = await persistenceService.exportData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.dataExported}\nPath: $backupPath'),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.exportError)),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(l10n.importData),
                  onTap: () async {
                    try {
                      await persistenceService.importData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.dataImported)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.importError)),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // About Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.about,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(l10n.version),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  title: Text(l10n.help),
                  onTap: () {
                    // TODO: Implement help functionality
                  },
                ),
                ListTile(
                  title: Text(l10n.feedback),
                  onTap: () {
                    // TODO: Implement feedback functionality
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 