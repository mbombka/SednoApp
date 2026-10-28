import 'package:sedno_app/l10n/localization.dart';

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/account/domain/account_repository.dart';

abstract interface class IntegrityTokenSource {
  Future<String?> tokenFor(String requestHash);
}

abstract interface class GuestSessionAdmission {
  Future<http.Response> create(String installationId);
}

abstract interface class SessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage(this.storage);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}

class AndroidIntegrityTokenSource implements IntegrityTokenSource {
  const AndroidIntegrityTokenSource(this.cloudProjectNumber);

  final int cloudProjectNumber;
  static const _channel = MethodChannel('sedno/play_integrity');

  @override
  Future<String?> tokenFor(String requestHash) async {
    if (cloudProjectNumber == 0 && !kReleaseMode) return null;
    if (cloudProjectNumber == 0) {
      throw StateError('Brak konfiguracji zabezpieczenia aplikacji.');
    }
    return _channel.invokeMethod<String>('requestToken', {
      'cloudProjectNumber': cloudProjectNumber,
      'requestHash': requestHash,
    });
  }
}

class BackendSessionGateway {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

  BackendSessionGateway({
    required this.baseUrl,
    required this.client,
    required this.storage,
    required this.integrity,
    this.guestAdmission,
  }) {
    if (baseUrl.scheme != 'https' &&
        (kReleaseMode ||
            baseUrl.scheme != 'http' ||
            !{'localhost', '127.0.0.1', '10.0.2.2'}.contains(baseUrl.host))) {
      throw ArgumentError('Wymagany jest adres HTTPS.');
    }
  }

  final Uri baseUrl;
  final http.Client client;
  final SessionStorage storage;
  final IntegrityTokenSource integrity;
  final GuestSessionAdmission? guestAdmission;
  Future<String>? _creatingGuest;
  Future<void> Function()? onSessionRejected;
  bool sessionRejected = false;
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);
  final ValueNotifier<int> quotaRevision = ValueNotifier(0);

  static const _installationKey = 'installation_id';
  static const _guestKey = 'guest_token';
  static const _accountKey = 'account_token';
  static const _accountJsonKey = 'account_json';

  /// Returns the current revocable backend bearer, creating a guest session
  /// only when no account or guest session has been stored.
  Future<String> accessToken() async {
    if (await storage.read('deletion_confirmed') == 'true') {
      throw StateError(strings.finishLocalDeletion);
    }
    final account = await storage.read(_accountKey);
    if (account != null) return account;
    return _guestToken();
  }

  Future<Account?> savedAccount() async {
    final token = await storage.read(_accountKey);
    final json = await storage.read(_accountJsonKey);
    if (token == null || json == null) return null;
    try {
      return Account.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<String> _installationId() async {
    final stored = await storage.read(_installationKey);
    if (stored != null) return stored;
    final random = Random.secure();
    final id = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
    await storage.write(_installationKey, id);
    return id;
  }

  Future<String> _guestToken() => _creatingGuest ??= _createGuestToken()
      .whenComplete(() => _creatingGuest = null);

  Future<String> _createGuestToken() async {
    final stored = await storage.read(_guestKey);
    if (stored != null) return stored;
    final installationId = await _installationId();
    final response = guestAdmission != null
        ? await guestAdmission!.create(installationId)
        : await _androidGuestSession(installationId);
    if (response.statusCode == 403) {
      throw AccountActionException(
        guestAdmission == null
            ? strings.installationRejected
            : strings.appleInstallationRejected,
      );
    }
    if (response.statusCode != 200) {
      throw StateError(strings.sessionStartFailed);
    }
    final token =
        (jsonDecode(response.body) as Map<String, dynamic>)['accessToken']
            as String;
    await storage.write(_guestKey, token);
    return token;
  }

  Future<http.Response> _androidGuestSession(String installationId) async {
    final hash = base64UrlEncode(
      sha256.convert(utf8.encode('guest-session:$installationId')).bytes,
    ).replaceAll('=', '');
    final integrityToken = await integrity.tokenFor(hash);
    return client.post(
      baseUrl.resolve('/v1/guest-sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'installationId': installationId,
        'integrityToken': integrityToken,
      }),
    );
  }

  Future<Account> link(String firebaseIdToken) async {
    final guest = await _guestToken();
    final response = await client.post(
      baseUrl.resolve('/v1/auth/sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $guest',
      },
      body: jsonEncode({'idToken': firebaseIdToken}),
    );
    if (response.statusCode == 401) {
      await rejectSession(guest);
      throw AccountActionException(
        strings.signInToLink,
        account: Account(id: 'guest', provider: IdentityProvider.guest),
      );
    }
    if (response.statusCode != 200) {
      throw StateError(strings.cannotLinkAccount);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final account = Account.fromJson(data['account'] as Map<String, dynamic>);
    await storage.write(_accountKey, data['accessToken'] as String);
    await storage.write(_accountJsonKey, jsonEncode(account.toJson()));
    await storage.delete(_guestKey);
    sessionRejected = false;
    sessionRevision.value++;
    return account;
  }

  Future<bool> get deletionPending async =>
      await storage.read('deletion_confirmed') == 'true';

  Future<void> deleteAccount({String? firebaseIdToken}) async {
    if (await storage.read('deletion_confirmed') == 'true') return;
    final token = await storage.read(_accountKey);
    if (token == null) throw StateError(strings.signInAgain);
    final response = await client.delete(
      baseUrl.resolve('/v1/account'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'idToken': firebaseIdToken}),
    );
    if (response.statusCode == 401) {
      await rejectSession(token);
      throw AccountActionException(
        strings.sessionExpiredSignIn,
        account: Account(id: 'guest', provider: IdentityProvider.guest),
      );
    }
    if (response.statusCode == 403) {
      throw AccountActionException(strings.signInToDelete);
    }
    if (response.statusCode != 204) {
      throw StateError(strings.cannotDeleteAccount);
    }
    await storage.write('deletion_confirmed', 'true');
    sessionRevision.value++;
  }

  Future<void> clearDeletedSession() async {
    await storage.delete(_accountKey);
    await storage.delete(_accountJsonKey);
    await storage.delete(_guestKey);
    await storage.delete('deletion_confirmed');
    // The installation identifier is device configuration, separate from the account.
    sessionRevision.value++;
  }

  Future<void> rejectCurrentAccount() async {
    final token = await storage.read(_accountKey);
    if (token != null) await rejectSession(token);
  }

  Future<void> rejectSession(String bearer) async {
    final account = await storage.read(_accountKey);
    final guest = await storage.read(_guestKey);
    if (bearer != account && bearer != guest) return;
    if (bearer == account) {
      await storage.delete(_accountKey);
      await storage.delete(_accountJsonKey);
    }
    await storage.delete(_guestKey);
    sessionRejected = true;
    try {
      if (bearer == account) await onSessionRejected?.call();
    } finally {
      sessionRevision.value++;
    }
  }

  Future<void> signOut() async {
    final token = await storage.read(_accountKey);
    if (token != null) {
      final response = await client.post(
        baseUrl.resolve('/v1/auth/sign-out'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 204 && response.statusCode != 401) {
        throw StateError(strings.cannotSignOut);
      }
    }
    await storage.delete(_accountKey);
    await storage.delete(_accountJsonKey);
    sessionRejected = false;
    sessionRevision.value++;
  }
}
