import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'guide_provider.dart';
import 'settings_provider.dart';

class AppProvider extends StatelessWidget {
  final Widget child;
  final SettingsProvider settingsProvider;

  const AppProvider({
    super.key,
    required this.child,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => GuideProvider(settingsProvider)),
      ],
      child: child,
    );
  }
}
