import 'dart:async';

import 'package:sedno_app/features/account/presentation/password_field.dart';

import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_panel.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

enum _AccountForm { signIn, register, resetPassword }

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    this.repository,
    this.subscriptionModel,
    this.onDataCleared,
    super.key,
  });

  final AccountRepository? repository;
  final VoidCallback? onDataCleared;
  final SubscriptionViewModel? subscriptionModel;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with WidgetsBindingObserver {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  _AccountForm _form = _AccountForm.signIn;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _clearPasswords() {
    _password.clear();
    _confirmPassword.clear();
  }

  void _changeForm(_AccountForm form) {
    FocusScope.of(context).unfocus();
    setState(() {
      _form = form;
      _formKey = GlobalKey<FormState>();
      _clearPasswords();
      _message = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Wpisz adres e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Wpisz poprawny adres e-mail.';
    }
    return null;
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = widget.repository!;
    await _run(
      () => _form == _AccountForm.register
          ? repository.registerWithEmail(_email.text, _password.text)
          : repository.signInWithEmail(_email.text, _password.text),
      verificationEmailSent: _form == _AccountForm.register,
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository!.sendPasswordResetEmail(_email.text);
      if (mounted) {
        setState(
          () => _message = 'Jeśli konto z tym adresem istnieje, otrzymasz wiadomość z linkiem do zmiany hasła. Sprawdź też folder Spam.',
        );
      }
    } on AccountActionException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Nie udało się wysłać wiadomości. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  Account? _account;
  bool _busy = false;
  String? _message;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  final _messageKey = GlobalKey();

  void _revealMessage() {
    if (_message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _messageKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final account = await widget.repository?.current();
      if (mounted) {
        setState(() {
          _account = account;
          _message = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Nie udało się odczytać konta lub dokończyć usuwania danych. Spróbuj ponownie.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_busy &&
        _account?.emailVerificationRequired == true) {
      _run(
        widget.repository!.checkEmailVerification,
        checkingVerification: true,
      );
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendSeconds--);
      if (_resendSeconds == 0) timer.cancel();
    });
  }

  Future<void> _resendVerification() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository!.resendVerificationEmail();
      if (!mounted) return;
      _startResendCooldown();
      setState(
        () => _message =
            'Wysłaliśmy wiadomość z linkiem. Sprawdź pocztę i folder Spam.',
      );
    } on AccountActionException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Nie udało się wysłać wiadomości. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  Future<void> _run(
    Future<Account> Function() action, {
    bool verificationEmailSent = false,
    bool checkingVerification = false,
  }) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final account = await action();
      if (mounted) {
        _clearPasswords();
        if (verificationEmailSent && account.emailVerificationRequired) {
          _startResendCooldown();
        }
        setState(() {
          _account = account;
          if (account.emailVerificationRequired) {
            if (verificationEmailSent) {
              _message = 'Wysłaliśmy wiadomość z linkiem. Sprawdź pocztę i folder Spam.';
            }
            if (checkingVerification) {
              _message = 'Adres nie jest jeszcze potwierdzony. Kliknij link w wiadomości i spróbuj ponownie.';
            }
          }
        });
      }
    } on AccountActionException catch (error) {
      if (mounted) {
        if (error.account != null) _clearPasswords();
        setState(() {
          _account = error.account ?? _account;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Nie udało się zalogować. Sprawdź dane i spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      widget.onDataCleared?.call();
      await widget.repository!.signOut();
      _email.clear();
      _clearPasswords();
      _form = _AccountForm.signIn;
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
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć konto?'),
        content: const SingleChildScrollView(
          child: Text(PrivacyScreen.deletionNotice),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zachowaj konto'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń konto i dane'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      widget.onDataCleared?.call();
      await widget.repository!.deleteAccount();
      _email.clear();
      _clearPasswords();
      _form = _AccountForm.signIn;
      if (mounted) {
        setState(() {
          _account = Account(id: 'guest', provider: IdentityProvider.guest);
          _message = 'Konto i dane zostały usunięte. Subskrypcję anuluj osobno w Google Play.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _message = 'Nie udało się zakończyć usuwania. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resendTimer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final pending = _account?.signInPending == true;
    final awaitingSession = _account?.sessionLinkRequired == true;
    final signedIn =
        _account != null &&
        _account!.provider != IdentityProvider.guest &&
        !pending;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Konto', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (_message case final message?) ...[
            Semantics(
              key: _messageKey,
              liveRegion: true,
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            if (!pending)
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Odśwież konto i dokończ czyszczenie'),
              ),
            const SizedBox(height: 12),
          ],
          if (repository == null) const Text('Tutaj pojawią się opcje konta.'),
          if (repository != null && signedIn) ...[
            const Text('Zalogowano.'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Wyloguj się'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _deleteAccount,
              child: const Text('Usuń konto'),
            ),
          ],
          if (repository != null && pending) ...[
            Text(
              awaitingSession ? 'Adres e-mail potwierdzony' : 'Sprawdź pocztę',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_account?.email case final email?)
              Text(
                awaitingSession
                    ? 'Adres e-mail: $email'
                    : 'Adres do potwierdzenia: $email',
              ),
            const SizedBox(height: 12),
            Text(
              awaitingSession
                  ? 'Adres został potwierdzony. Pozostało połączenie z kontem Sedna. Nie musisz ponownie klikać linku w wiadomości.'
                  : 'Aby dokończyć tworzenie konta, kliknij link w wiadomości od Sedna. Sprawdź też folder Spam. Potem wróć tutaj i wybierz „Sprawdź potwierdzenie”.',
            ),
            const SizedBox(height: 12),
            const Text('Do tego czasu możesz korzystać z aplikacji bez konta.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      repository.checkEmailVerification,
                      checkingVerification: true,
                    ),
              child: Text(
                awaitingSession ? 'Dokończ logowanie' : 'Sprawdź potwierdzenie',
              ),
            ),
            if (!awaitingSession)
              OutlinedButton(
                onPressed: _busy || _resendSeconds > 0
                    ? null
                    : _resendVerification,
                child: Text(
                  _resendSeconds > 0
                      ? 'Wyślij ponownie za $_resendSeconds s'
                      : 'Wyślij wiadomość ponownie',
                ),
              ),
            TextButton(
              onPressed: _busy ? null : _signOut,
              child: const Text('Wyloguj się i korzystaj bez konta'),
            ),
          ],
          if (repository != null && !signedIn && !pending) ...[
            Text(switch (_form) {
              _AccountForm.signIn => 'Zaloguj się',
              _AccountForm.register => 'Nowe konto',
              _AccountForm.resetPassword => 'Odzyskaj dostęp',
            }, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Możesz korzystać z aplikacji bez logowania.'),
            const SizedBox(height: 16),
            if (_form == _AccountForm.signIn) ...[
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(repository.signInWithGoogle),
                child: const Text('Zaloguj przez Google'),
              ),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      labelText: 'Adres e-mail',
                      errorMaxLines: 3,
                    ),
                  ),
                  if (_form != _AccountForm.resetPassword) ...[
                    const SizedBox(height: 12),
                    PasswordField(
                      key: ValueKey('password-$_form'),
                      controller: _password,
                      label: 'Hasło',
                      enabled: !_busy,
                      newPassword: _form == _AccountForm.register,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wpisz hasło.';
                        }
                        if (_form == _AccountForm.register &&
                            value.length < 6) {
                          return 'Użyj co najmniej 6 znaków.';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_form == _AccountForm.register) ...[
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _confirmPassword,
                      label: 'Powtórz hasło',
                      enabled: !_busy,
                      newPassword: true,
                      confirmation: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Powtórz hasło.';
                        }
                        if (value != _password.text) {
                          return 'Hasła muszą być takie same.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Wyślemy wiadomość z linkiem do potwierdzenia adresu e-mail.',
                    ),
                  ],
                  if (_form == _AccountForm.resetPassword) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Wpisz adres e-mail swojego konta. Wyślemy link do zmiany hasła.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : _form == _AccountForm.resetPassword
                        ? _resetPassword
                        : _submitEmail,
                    child: Text(switch (_form) {
                      _AccountForm.signIn => 'Zaloguj przez e-mail',
                      _AccountForm.register => 'Utwórz konto',
                      _AccountForm.resetPassword =>
                        'Wyślij link do zmiany hasła',
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_form == _AccountForm.signIn) ...[
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _changeForm(_AccountForm.resetPassword),
                child: const Text('Nie pamiętam hasła'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _changeForm(_AccountForm.register),
                child: const Text('Nie masz konta? Utwórz konto'),
              ),
            ] else
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _changeForm(_AccountForm.signIn),
                child: const Text('Wróć do logowania'),
              ),
          ],
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (widget.subscriptionModel case final model?)
            SubscriptionPanel(model: model),
        ],
      ),
    );
  }
}
