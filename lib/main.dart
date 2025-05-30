import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:learn_progress_tracker/l10n/app_localizations.dart';
import 'models/module.dart'; // Added import
import 'screens/module_creation_page.dart'; // Added import
import 'screens/modules_list_page.dart'; // Added import
import 'screens/calendar_page.dart';
import 'screens/settings_page.dart';
import 'screens/statistics_page.dart';
import 'services/persistence_service.dart'; // Import PersistenceService
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'Learn Progress Tracker',
          theme: themeProvider.theme,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('de'),
          ],
          home: const HomePage(),
        );
      },
    );
  }
}