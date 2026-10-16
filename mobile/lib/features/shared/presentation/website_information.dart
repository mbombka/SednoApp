import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sedno_app/app/app_information.dart';

class WebsiteInformation extends StatelessWidget {
  const WebsiteInformation({
    this.address = AppInformation.website,
    this.label = 'Strona internetowa Sedno',
    this.copyLabel = 'Kopiuj adres strony',
    super.key,
  });

  final String address;
  final String label;
  final String copyLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label),
      const SizedBox(height: 8),
      Text(address),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: address));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skopiowano adres strony.')),
          );
        },
        icon: const Icon(Icons.copy),
        label: Text(copyLabel),
      ),
    ],
  );
}
