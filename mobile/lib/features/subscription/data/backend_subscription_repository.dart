import 'dart:convert';

import 'package:sedno_app/features/account/data/backend_session_gateway.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class BackendSubscriptionRepository implements SubscriptionRepository {
  BackendSubscriptionRepository(this.sessions);
  final BackendSessionGateway sessions;

  Future<SubscriptionStatus> _request(String? token) async {
    final bearer = await sessions.accessToken();
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
    if (response.statusCode != 200) {
      throw StateError(
        'Nie można sprawdzić subskrypcji. Zaloguj się i spróbuj ponownie.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return SubscriptionStatus(
      active: data['active'] as bool,
      state: data['state'] as String,
      accountBinding: data['accountBinding'] as String,
    );
  }

  @override
  Future<SubscriptionStatus> current() => _request(null);
  @override
  Future<SubscriptionStatus> verify(String token) async {
    final status = await _request(token);
    sessions.sessionRevision.value++;
    return status;
  }
}
