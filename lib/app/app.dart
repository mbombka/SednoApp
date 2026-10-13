import 'package:flutter/material.dart';
import 'package:simplifier_app/app/app_theme.dart';
import 'package:simplifier_app/features/home/presentation/home_screen.dart';

class SimplifierApp extends StatelessWidget {
  const SimplifierApp({super.key});

  static const name = 'SimplifierApp';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: name,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeScreen(appName: name),
    );
  }
}
