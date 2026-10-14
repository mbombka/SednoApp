import 'package:sedno_app/features/shared/domain/json_values.dart';

enum IdentityProvider { guest, google, email }

class Account {
  Account({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
  }) {
    if (id.trim().isEmpty ||
        (email != null && email!.trim().isEmpty) ||
        (displayName != null && displayName!.trim().isEmpty)) {
      throw const FormatException('Nieprawidłowe konto.');
    }
  }

  final String id;
  final IdentityProvider provider;
  final String? email;
  final String? displayName;

  Map<String, Object?> toJson() => {
    'id': id,
    'provider': provider.name,
    'email': email,
    'displayName': displayName,
  };

  factory Account.fromJson(Map<String, dynamic> json) {
    final providerName = requiredString(json, 'provider');
    final provider = IdentityProvider.values.where(
      (value) => value.name == providerName,
    );
    if (provider.isEmpty) {
      throw const FormatException('Nieznany dostawca tożsamości.');
    }
    final email = json['email'];
    final displayName = json['displayName'];
    if (email != null && email is! String ||
        displayName != null && displayName is! String) {
      throw const FormatException('Nieprawidłowe konto.');
    }
    return Account(
      id: requiredString(json, 'id'),
      provider: provider.single,
      email: email as String?,
      displayName: displayName as String?,
    );
  }
}
