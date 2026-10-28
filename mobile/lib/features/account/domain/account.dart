import 'package:sedno_app/features/shared/domain/json_values.dart';

enum IdentityProvider { guest, google, email, apple }

class Account {
  Account({
    required this.id,
    required this.provider,
    this.email,
    this.displayName,
    this.emailVerificationRequired = false,
    this.sessionLinkRequired = false,
  }) {
    if ((emailVerificationRequired && sessionLinkRequired) ||
        id.trim().isEmpty ||
        (email != null && email!.trim().isEmpty) ||
        (displayName != null && displayName!.trim().isEmpty)) {
      throw const FormatException('Nieprawidłowe konto.');
    }
  }

  final String id;
  final IdentityProvider provider;
  final String? email;
  final String? displayName;
  final bool emailVerificationRequired;
  final bool sessionLinkRequired;

  bool get signInPending => emailVerificationRequired || sessionLinkRequired;

  Map<String, Object?> toJson() => {
    'id': id,
    'provider': provider.name,
    'email': email,
    'displayName': displayName,
    'emailVerificationRequired': emailVerificationRequired,
    'sessionLinkRequired': sessionLinkRequired,
  };

  factory Account.fromJson(Map<String, dynamic> json) {
    final providerName = requiredString(json, 'provider');
    final provider = IdentityProvider.values.where(
      (value) => value.name == providerName,
    );
    if (provider.isEmpty) {
      throw const FormatException('Nieznany dostawca tożsamości.');
    }
    final linking = json['sessionLinkRequired'];
    if (linking != null && linking is! bool) {
      throw const FormatException('Nieprawidłowe konto.');
    }
    final pending = json['emailVerificationRequired'];
    if (pending != null && pending is! bool) {
      throw const FormatException('Nieprawidłowe konto.');
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
      emailVerificationRequired: pending as bool? ?? false,
      sessionLinkRequired: linking as bool? ?? false,
    );
  }
}
