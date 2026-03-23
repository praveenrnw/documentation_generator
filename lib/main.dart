import 'package:flutter/material.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  runApp(
    AppProvider(settingsProvider: settingsProvider, child: const DocGenApp()),
  );
}
