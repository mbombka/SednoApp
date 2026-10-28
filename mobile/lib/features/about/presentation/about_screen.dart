import 'dart:io';

import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_information.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/shared/presentation/link_text.dart';
import 'package:sedno_app/features/shared/presentation/website_information.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({this.openUrl = openExternalUrl, super.key});

  final UrlOpener openUrl;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.about),
      leading: Navigator.of(context).canPop()
          ? IconButton(
              tooltip: context.l10n.back,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Sedno',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          // Plain Polish: short sections, one sentence per line.
          _Heading(context.l10n.appPurpose),
          Text(context.l10n.appDescription),
          Text(context.l10n.appAudience),
          Text(context.l10n.appAge),
          _Heading(context.l10n.howItWorks),
          Text(context.l10n.typingInstructions),
          Text(context.l10n.captureInstructions),
          Text(context.l10n.captureSubmitInstructions),
          Text(context.l10n.localMediaNotice),
          Text(
            (Platform.isIOS
                ? context.l10n.localSpeechUnavailable
                : context.l10n.speechModelRequirements),
          ),
          Text(context.l10n.playbackRequirements),
          Text(context.l10n.restoreInstructions),
          Text(context.l10n.inputLimitNotice),
          Text(context.l10n.guestNotice),
          _Heading(context.l10n.dailyLimit),
          Text(context.l10n.freeAllowance),
          Text(context.l10n.paidAllowance),
          Text(context.l10n.sharedAllowance),
          Text(
            (Platform.isIOS
                ? context.l10n.appleSubscriptionPriceNotice
                : context.l10n.subscriptionPriceNotice),
          ),
          // Local clock time first; UTC for users comparing with other sources.
          Text(context.l10n.resetAbout(QuotaReset.localTime())),
          _Heading(context.l10n.important),
          Text(context.l10n.aiErrorNotice),
          Text(context.l10n.checkResult),
          _Heading(context.l10n.contact),
          Text(context.l10n.author),
          const SizedBox(height: 8),
          Text(context.l10n.contactAddress(AppInformation.contact)),
          const SizedBox(height: 16),
          WebsiteInformation(opener: openUrl),
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
            child: Text(context.l10n.privacy),
          ),
        ],
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
