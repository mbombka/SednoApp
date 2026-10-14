import 'package:flutter/material.dart';
import 'package:simplifier_app/app/app_theme.dart';
import 'package:simplifier_app/features/account/presentation/account_screen.dart';
import 'package:simplifier_app/features/history/presentation/history_screen.dart';
import 'package:simplifier_app/features/home/presentation/home_screen.dart';

class SimplifierApp extends StatelessWidget {
  const SimplifierApp({super.key});

  static const name = 'SimplifierApp';
  static const displayName = 'Simplyfi_it';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: displayName,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const _AppNavigation(),
    );
  }
}

class _AppNavigation extends StatefulWidget {
  const _AppNavigation();

  @override
  State<_AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<_AppNavigation> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(SimplifierApp.displayName),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(height: 56, text: 'Start'),
              Tab(height: 56, text: 'Historia'),
              Tab(height: 56, text: 'Konto'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HomeScreen(
              appName: SimplifierApp.displayName,
              textController: _inputController,
            ),
            const HistoryScreen(),
            const AccountScreen(),
          ],
        ),
      ),
    );
  }
}
