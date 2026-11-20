import 'dart:convert';

import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class BackendSubscriptionRepository implements SubscriptionRepository {
  BackendSubscriptionRepository(this.sessions);
  final BackendSessionGateway sessions;

  Future<Map<String, dynamic>?> _request(String path, String? token) async {
    final revision = sessions.sessionRevision.value;
    if (await sessions.savedAccount() == null) {
      if (token != null) throw StateError('Zaloguj się, aby przywrócić zakup.');
      return null;
    }
    final bearer = await sessions.accessToken();
    if (revision != sessions.sessionRevision.value) {
      throw StateError('Sesja uległa zmianie.');
    }
    final url = sessions.baseUrl.resolve(path);
    final headers = {
      'Authorization': 'Bearer $bearer',
      'Content-Type': 'application/json',
    };
    final response =
        await (token == null
                ? sessions.client.get(url, headers: headers)
                : sessions.client.post(
                    url,
                    headers: headers,
                    body: jsonEncode({'purchaseToken': token}),
                  ))
            .timeout(const Duration(seconds: 30));
    if (revision != sessions.sessionRevision.value) {
      throw StateError('Sesja uległa zmianie.');
    }
    if (response.statusCode == 401) await sessions.rejectSession(bearer);
    if (response.statusCode != 200) {
      throw StateError(
        'Nie można sprawdzić subskrypcji. Zaloguj się i spróbuj ponownie.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    sessions.quotaRevision.value++;
    return data;
  }

  Future<SubscriptionStatus> _subscription(String? token) async {
    final data = await _request('/v1/subscription', token);
    return SubscriptionStatus(
      active: data?['active'] as bool? ?? false,
      state: data?['state'] as String? ?? 'none',
      accountBinding: data?['accountBinding'] as String? ?? '',
      packPurchasesEnabled: data?['packPurchasesEnabled'] == true,
    );
  }

  @override
  Future<SubscriptionStatus> current() => _subscription(null);
  @override
  Future<SubscriptionStatus> verify(String token) => _subscription(token);
  @override
  Future<String> verifyPack(String token) async =>
      (await _request('/v1/purchases/simplifications', token))!['state']
          as String;
}
