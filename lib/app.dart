import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/drinks_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/stats_screen.dart';

class WaterTrackerApp extends ConsumerWidget {
  const WaterTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Трекер воды',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      routes: {
        '/': (_) => const HomeScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        DrinksScreen.routeName: (_) => const DrinksScreen(),
        HistoryScreen.routeName: (_) => const HistoryScreen(),
        StatsScreen.routeName: (_) => const StatsScreen(),
      },
      initialRoute: '/',
    );
  }
}
