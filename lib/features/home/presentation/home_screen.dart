import 'package:flutter/material.dart';
import 'package:simplifier_app/features/home/presentation/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.appName, super.key});

  final String appName;

  @override
  Widget build(BuildContext context) {
    final viewModel = HomeViewModel(appName: appName);

    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: Center(
        child: Text(
          viewModel.welcomeMessage,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
