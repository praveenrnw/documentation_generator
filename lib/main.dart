import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/guide_provider.dart';
import 'providers/settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => GuideProvider(settingsProvider)),
      ],
      child: const DocGenApp(),
    ),
  );
}
