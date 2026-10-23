import 'package:sedno_app/features/privacy/domain/localized_privacy_policy.dart';
import 'package:sedno_app/l10n/localization.dart';

import 'dart:async';

import 'package:sedno_app/features/account/presentation/tester_access_panel.dart';

import 'package:sedno_app/features/account/presentation/password_field.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_panel.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

enum _AccountForm { signIn, register, resetPassword }

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    this.repository,
    this.subscriptionModel,
    this.quota,
    this.onDataCleared,
    super.key,
  });

  final AccountRepository? repository;
  final VoidCallback? onDataCleared;
  final SubscriptionViewModel? subscriptionModel;
  final ValueListenable<QuotaState?>? quota;

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

  String? _localeName;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeName = context.l10n.localeName;
    if (_localeName != null && _localeName != localeName) _message = null;
    _localeName = localeName;
  }

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
    if (email.isEmpty) return context.l10n.enterEmail;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return context.l10n.enterValidEmail;
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
        setState(() => _message = context.l10n.passwordResetSent);
      }
    } on AccountActionException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.emailSendFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  ValueListenable<int>? _accountChanges;
  void _accountChanged() {
    if (!_busy) _load();
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
    final repository = widget.repository;
    if (repository is AccountStateSource) {
      _accountChanges = (repository as AccountStateSource).accountRevision;
      _accountChanges!.addListener(_accountChanged);
    }
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
        setState(() => _message = context.l10n.accountLoadFailed);
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
      setState(() => _message = context.l10n.verificationEmailSent);
    } on AccountActionException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.emailSendFailed);
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
              _message = context.l10n.verificationEmailSent;
            }
            if (checkingVerification) {
              _message = context.l10n.emailNotVerified;
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
        setState(() => _message = context.l10n.signInFailed);
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
        setState(() => _message = context.l10n.signOutFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _revealMessage();
      }
    }
  }

  Future<void> _deleteAccount() async {
    var password = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteAccountTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LocalizedPrivacyPolicy.deletionNotice(context.language)),
              Text(context.l10n.deleteAccountIdentity),
              if (_account?.provider == IdentityProvider.email)
                TextField(
                  onChanged: (value) => password = value,
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.l10n.password),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.keepAccount),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deleteAccountAndData),
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
      await widget.repository!.deleteAccount(password: password);
      _email.clear();
      _clearPasswords();
      _form = _AccountForm.signIn;
      if (mounted) {
        setState(() {
          _account = Account(id: 'guest', provider: IdentityProvider.guest);
          _message = context.l10n.accountDeleted;
        });
      }
    } on AccountActionException catch (error) {
      if (mounted) {
        setState(() {
          _account = error.account ?? _account;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = context.l10n.accountDeleteIncomplete);
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
    _accountChanges?.removeListener(_accountChanged);
    _resendTimer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // Subscriptions belong to the Sedno account, so show which one is active.
  String _signedInLabel(Account account) {
    final email = account.email;
    if (email == null) return context.l10n.signedIn;
    final method = switch (account.provider) {
      IdentityProvider.google => context.l10n.googleAccountMethod,
      IdentityProvider.email => context.l10n.emailAccountMethod,
      IdentityProvider.guest => '',
    };
    return context.l10n.signedInAs(email, method);
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
          Text(
            context.l10n.account,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
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
                child: Text(context.l10n.finishDataCleanup),
              ),
            const SizedBox(height: 12),
          ],
          if (repository == null) Text(context.l10n.accountNotConfigured),
          if (repository != null && signedIn) ...[
            Text(_signedInLabel(_account!)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _busy ? null : _signOut,
              child: Text(context.l10n.signOut),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _deleteAccount,
              child: Text(context.l10n.deleteAccount),
            ),
          ],
          if (repository != null && pending) ...[
            Text(
              awaitingSession
                  ? context.l10n.emailVerified
                  : context.l10n.checkInbox,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_account?.email case final email?)
              Text(
                awaitingSession
                    ? context.l10n.accountEmail(email)
                    : context.l10n.emailToVerify(email),
              ),
            const SizedBox(height: 12),
            Text(
              awaitingSession
                  ? context.l10n.finishAccountLinkNotice
                  : context.l10n.verifyEmailInstructions,
            ),
            const SizedBox(height: 12),
            Text(context.l10n.guestWhileVerifying),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(
                      repository.checkEmailVerification,
                      checkingVerification: true,
                    ),
              child: Text(
                awaitingSession
                    ? context.l10n.finishSignIn
                    : context.l10n.checkVerification,
              ),
            ),
            if (!awaitingSession)
              OutlinedButton(
                onPressed: _busy || _resendSeconds > 0
                    ? null
                    : _resendVerification,
                child: Text(
                  _resendSeconds > 0
                      ? context.l10n.resendAfter('$_resendSeconds')
                      : context.l10n.resendEmail,
                ),
              ),
            TextButton(
              onPressed: _busy ? null : _signOut,
              child: Text(context.l10n.signOutUseGuest),
            ),
          ],
          if (repository != null && !signedIn && !pending) ...[
            Text(switch (_form) {
              _AccountForm.signIn => context.l10n.signIn,
              _AccountForm.register => context.l10n.newAccount,
              _AccountForm.resetPassword => context.l10n.recoverAccess,
            }, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(context.l10n.guestSignInNotice),
            const SizedBox(height: 16),
            if (_form == _AccountForm.signIn) ...[
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(repository.signInWithGoogle),
                child: Text(context.l10n.signInGoogle),
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
                    decoration: InputDecoration(
                      labelText: context.l10n.emailAddress,
                      errorMaxLines: 3,
                    ),
                  ),
                  if (_form != _AccountForm.resetPassword) ...[
                    const SizedBox(height: 12),
                    PasswordField(
                      key: ValueKey('password-$_form'),
                      controller: _password,
                      label: context.l10n.password,
                      enabled: !_busy,
                      newPassword: _form == _AccountForm.register,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.enterPassword;
                        }
                        if (_form == _AccountForm.register &&
                            value.length < 6) {
                          return context.l10n.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_form == _AccountForm.register) ...[
                    const SizedBox(height: 12),
                    PasswordField(
                      controller: _confirmPassword,
                      label: context.l10n.repeatPassword,
                      enabled: !_busy,
                      newPassword: true,
                      confirmation: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.enterRepeatedPassword;
                        }
                        if (value != _password.text) {
                          return context.l10n.passwordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(context.l10n.verificationEmailNotice),
                  ],
                  if (_form == _AccountForm.resetPassword) ...[
                    const SizedBox(height: 12),
                    Text(context.l10n.passwordResetInstructions),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : _form == _AccountForm.resetPassword
                        ? _resetPassword
                        : _submitEmail,
                    child: Text(switch (_form) {
                      _AccountForm.signIn => context.l10n.signInEmail,
                      _AccountForm.register => context.l10n.createAccount,
                      _AccountForm.resetPassword => context.l10n.sendResetLink,
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
                child: Text(context.l10n.forgotPassword),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _changeForm(_AccountForm.register),
                child: Text(context.l10n.createAccountLink),
              ),
            ] else
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _changeForm(_AccountForm.signIn),
                child: Text(context.l10n.backToSignIn),
              ),
          ],
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (signedIn && widget.quota != null)
            TesterAccessPanel(quota: widget.quota!),
          if (widget.subscriptionModel case final model?)
            SubscriptionPanel(
              model: model,
              signedIn: signedIn,
              quota: widget.quota,
            ),
        ],
      ),
    );
  }
}
