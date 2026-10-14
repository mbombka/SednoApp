import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Konto', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text('Tutaj pojawią się opcje konta.'),
        ],
      ),
    );
  }
}
