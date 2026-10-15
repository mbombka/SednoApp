import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_theme.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

enum UserMenuDestination { start, history, account }

class UserMenuScreen extends StatelessWidget {
  const UserMenuScreen({super.key});

  static const _background = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      automaticallyImplyLeading: false,
      title: const Text('Sedno'),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Zamknij menu',
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: ExcludeSemantics(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Color(0xFFC2E7FF),
                        child: Icon(
                          Icons.person_outline,
                          size: 52,
                          color: AppTheme.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Witaj w Sedno',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 52),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        side: const BorderSide(color: AppTheme.blue),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () =>
                          Navigator.of(context)
                              .pop(UserMenuDestination.account),
                      child: const Text('Konto'),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: Text(
                      'W aplikacji',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _MenuRow(
                          label: 'Start',
                          icon: Icons.home_outlined,
                          onTap: () =>
                              Navigator.of(context)
                                  .pop(UserMenuDestination.start),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: _background,
                        ),
                        _MenuRow(
                          label: 'Historia',
                          icon: Icons.history,
                          onTap: () =>
                              Navigator.of(context)
                                  .pop(UserMenuDestination.history),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                  child: const Text('Prywatność i dane'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 72,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    leading: Icon(icon, color: AppTheme.navy, size: 28),
    title: Text(label, style: Theme.of(context).textTheme.titleMedium),
    trailing: const Icon(Icons.chevron_right, color: AppTheme.navy),
    onTap: onTap,
  );
}
