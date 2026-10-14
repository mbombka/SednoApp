import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historia', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Tutaj pojawi się historia uproszczonych tekstów.'),
        ],
      ),
    );
  }
}
