import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.newPassword = false,
    this.confirmation = false,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final bool newPassword;
  final bool confirmation;
  final String? Function(String?)? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: !_visible,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    validator: widget.validator,
    decoration: InputDecoration(
      labelText: widget.label,
      errorMaxLines: 3,
      suffixIcon: IconButton(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        tooltip: widget.confirmation
            ? (_visible ? 'Ukryj powtórzone hasło' : 'Pokaż powtórzone hasło')
            : (_visible ? 'Ukryj hasło' : 'Pokaż hasło'),
        onPressed: widget.enabled
            ? () => setState(() => _visible = !_visible)
            : null,
        icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
      ),
    ),
  );
}
