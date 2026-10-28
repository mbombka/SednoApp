import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:sedno_app/features/account/data/backend_session_gateway.dart';

/// App Attest has its own admission protocol; it never falls back to Play
/// Integrity or admits a device based on an unverified platform declaration.
class AppleAppAttestAdmission implements GuestSessionAdmission {
  AppleAppAttestAdmission({
    required this.baseUrl,
    required this.client,
    required this.storage,
    this.channel = const MethodChannel('sedno/app_attest'),
  });

  final Uri baseUrl;
  final http.Client client;
  final SessionStorage storage;
  final MethodChannel channel;
  static const _key = 'app_attest_key_id';
  static const _registered = 'app_attest_registered';
  static const _pending = 'app_attest_pending_registration';

  Future<http.Response> _post(String path, Map<String, Object?> body) => client
      .post(
        baseUrl.resolve(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));

  static String clientDataHash({
    required String purpose,
    required String installationId,
    required String keyId,
    required String challengeId,
    required String challenge,
  }) => base64UrlEncode(
    sha256
        .convert(
          utf8.encode(
            'sedno:app-attest:v1:$purpose:$installationId:$keyId:$challengeId:$challenge',
          ),
        )
        .bytes,
  );

  Future<Map<String, dynamic>> _challenge(
    String installationId,
    String keyId,
    String purpose,
  ) async {
    final response = await _post('/v1/ios/attestation/challenges', {
      'installationId': installationId,
      'keyId': keyId,
      'purpose': purpose,
    });
    if (response.statusCode != 200) {
      throw StateError('App Attest challenge rejected.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<http.Response> create(String installationId) async {
    // One automatic recovery handles expired/deleted keys without forcing a
    // second tap. A second rejection is surfaced; installation/quota never reset.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _create(installationId);
        if (attempt == 0 &&
            response.statusCode == 403 &&
            await storage.read(_key) == null) {
          continue;
        }
        return response;
      } on PlatformException catch (error) {
        if (error.code != 'invalid_key') rethrow;
        await storage.delete(_key);
        await storage.delete(_registered);
        await storage.delete(_pending);
        if (attempt != 0) rethrow;
      }
    }
    throw StateError('App Attest recovery exhausted.');
  }

  Future<http.Response> _create(String installationId) async {
    if (await channel.invokeMethod<bool>('isSupported') != true) {
      throw StateError('App Attest is unavailable.');
    }
    var keyId = await storage.read(_key);
    if (keyId == null) {
      keyId = await channel.invokeMethod<String>('generateKey');
      if (keyId == null || keyId.isEmpty) {
        throw StateError('App Attest key unavailable.');
      }
      await storage.write(_key, keyId);
      await storage.delete(_registered);
      await storage.delete(_pending);
    }
    if (await storage.read(_registered) != keyId) {
      final saved = await storage.read(_pending);
      Map<String, Object?> registration;
      if (saved != null) {
        registration = jsonDecode(saved) as Map<String, dynamic>;
      } else {
        final challenge = await _challenge(installationId, keyId, 'register');
        final attestation = await channel.invokeMethod<String>('attestKey', {
          'keyId': keyId,
          'clientDataHash': clientDataHash(
            purpose: 'register',
            installationId: installationId,
            keyId: keyId,
            challengeId: challenge['challengeId'] as String,
            challenge: challenge['challenge'] as String,
          ),
        });
        if (attestation == null) {
          throw StateError('App Attest attestation unavailable.');
        }
        registration = {
          'installationId': installationId,
          'keyId': keyId,
          'challengeId': challenge['challengeId'],
          'attestation': attestation,
        };
        // Persist the exact proof for a retry if the server's response is lost.
        await storage.write(_pending, jsonEncode(registration));
      }
      final response = await _post('/v1/ios/attestation/keys', registration);
      if (response.statusCode != 204) {
        if (response.statusCode == 403) {
          // A fresh key on retry retains the same installation and quota.
          await storage.delete(_key);
          await storage.delete(_pending);
        }
        return response;
      }
      await storage.write(_registered, keyId);
      await storage.delete(_pending);
    }
    final challenge = await _challenge(installationId, keyId, 'session');
    final assertion = await channel.invokeMethod<String>('generateAssertion', {
      'keyId': keyId,
      'clientDataHash': clientDataHash(
        purpose: 'session',
        installationId: installationId,
        keyId: keyId,
        challengeId: challenge['challengeId'] as String,
        challenge: challenge['challenge'] as String,
      ),
    });
    if (assertion == null) {
      throw StateError('App Attest assertion unavailable.');
    }
    final response = await _post('/v1/ios/guest-sessions', {
      'installationId': installationId,
      'keyId': keyId,
      'challengeId': challenge['challengeId'],
      'assertion': assertion,
    });
    if (response.statusCode == 403 &&
        (jsonDecode(response.body) as Map<String, dynamic>)['code'] ==
            'app_attest_key_unknown') {
      await storage.delete(_registered);
      await storage.delete(_key);
    }
    return response;
  }
}
