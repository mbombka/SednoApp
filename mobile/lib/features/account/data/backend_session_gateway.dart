import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sedno_app/features/account/domain/account.dart';

abstract interface class IntegrityTokenSource {
  Future<String?> tokenFor(String requestHash);
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
  BackendSessionGateway({
    required this.baseUrl,
    required this.client,
    required this.storage,
    required this.integrity,
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
  final ValueNotifier<int> sessionRevision = ValueNotifier(0);

  static const _installationKey = 'installation_id';
  static const _guestKey = 'guest_token';
  static const _accountKey = 'account_token';
  static const _accountJsonKey = 'account_json';

  /// Returns the current revocable backend bearer, creating a guest session
  /// only when no account or guest session has been stored.
  Future<String> accessToken() async {
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
    );
    await storage.write(_installationKey, id);
    return id;
  }

  Future<String> _guestToken() async {
    final stored = await storage.read(_guestKey);
    if (stored != null) return stored;
    final installationId = await _installationId();
    final hash = base64UrlEncode(
      sha256.convert(utf8.encode('guest-session:$installationId')).bytes,
    ).replaceAll('=', '');
    final integrityToken = await integrity.tokenFor(hash);
    final response = await client.post(
      baseUrl.resolve('/v1/guest-sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'installationId': installationId,
        'integrityToken': integrityToken,
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Nie można rozpocząć sesji. Spróbuj ponownie.');
    }
    final token =
        (jsonDecode(response.body) as Map<String, dynamic>)['accessToken']
            as String;
    await storage.write(_guestKey, token);
    return token;
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
    if (response.statusCode != 200) {
      throw StateError('Nie można połączyć konta. Spróbuj ponownie.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final account = Account.fromJson(data['account'] as Map<String, dynamic>);
    await storage.write(_accountKey, data['accessToken'] as String);
    await storage.write(_accountJsonKey, jsonEncode(account.toJson()));
    await storage.delete(_guestKey);
    sessionRevision.value++;
    return account;
  }

  Future<void> signOut() async {
    final token = await storage.read(_accountKey);
    if (token != null) {
      final response = await client.post(
        baseUrl.resolve('/v1/auth/sign-out'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 204 && response.statusCode != 401) {
        throw StateError('Nie można wylogować. Spróbuj ponownie.');
      }
    }
    await storage.delete(_accountKey);
    await storage.delete(_accountJsonKey);
    sessionRevision.value++;
  }
}
