import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_information.dart';
import 'package:sedno_app/features/shared/presentation/link_text.dart';

/// A labelled web address that opens in the browser when tapped.
class WebsiteInformation extends StatelessWidget {
  const WebsiteInformation({
    this.address = AppInformation.website,
    this.label,
    this.opener = openExternalUrl,
    super.key,
  });

  final String address;
  final String? label;
  final UrlOpener opener;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label ?? context.l10n.website),
      Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          link: true,
          child: TextButton(
            onPressed: () => openLink(context, Uri.parse(address), opener),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              address,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ),
    ],
  );
}
