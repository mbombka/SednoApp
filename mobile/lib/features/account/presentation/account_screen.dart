import 'package:flutter/material.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({this.repository, super.key});

  final AccountRepository? repository;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  Account? _account;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account = await widget.repository?.current();
    if (mounted) setState(() => _account = account);
  }

  Future<void> _run(Future<Account> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final account = await action();
      if (mounted) setState(() => _account = account);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Nie udało się zalogować. Sprawdź dane i spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository!.signOut();
      if (mounted) {
        setState(
          () =>
              _account = Account(id: 'guest', provider: IdentityProvider.guest),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Nie udało się wylogować. Spróbuj ponownie.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final signedIn =
        _account != null && _account!.provider != IdentityProvider.guest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Konto', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (repository == null) const Text('Tutaj pojawią się opcje konta.'),
          if (repository != null && signedIn) ...[
            const Text('Zalogowano.'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Wyloguj się'),
            ),
          ],
          if (repository != null && !signedIn) ...[
            const Text('Możesz korzystać z aplikacji bez logowania.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : () => _run(repository.signInWithGoogle),
              child: const Text('Zaloguj przez Google'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Adres e-mail'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Hasło'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => repository.signInWithEmail(
                        _email.text,
                        _password.text,
                      ),
                    ),
              child: const Text('Zaloguj przez e-mail'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      () => repository.registerWithEmail(
                        _email.text,
                        _password.text,
                      ),
                    ),
              child: const Text('Utwórz konto'),
            ),
          ],
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
