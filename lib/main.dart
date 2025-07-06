import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/providers/theme_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final themeSettings = ref.watch(themeSettingsNotifierProvider);

    return MaterialApp(
      title: 'Last.fm Now Playing Dashboard',
      theme: themeData,
      themeMode: themeSettings.themeMode,
      home: const DashboardPage(),
    );
  }
}
