import 'dart:convert';

import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class BackendSubscriptionRepository implements SubscriptionRepository {
  BackendSubscriptionRepository(this.sessions);
  final BackendSessionGateway sessions;

  Future<SubscriptionStatus> _request(String? token) async {
    final revision = sessions.sessionRevision.value;
    if (await sessions.savedAccount() == null) {
      if (token != null) throw StateError('Zaloguj się, aby przywrócić zakup.');
      return const SubscriptionStatus(
        active: false,
        state: 'none',
        accountBinding: '',
      );
    }
    final bearer = await sessions.accessToken();
    if (revision != sessions.sessionRevision.value) {
      throw StateError('Sesja uległa zmianie.');
    }
    final url = sessions.baseUrl.resolve('/v1/subscription');
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
    return SubscriptionStatus(
      active: data['active'] as bool,
      state: data['state'] as String,
      accountBinding: data['accountBinding'] as String,
    );
  }

  @override
  Future<SubscriptionStatus> current() => _request(null);
  @override
  Future<SubscriptionStatus> verify(String token) => _request(token);
}
