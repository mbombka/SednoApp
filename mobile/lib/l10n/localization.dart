import 'package:sedno_app/features/simplification/domain/text_mode.dart';
import 'package:sedno_app/app/app_language.dart';
import 'package:flutter/widgets.dart';
import 'package:sedno_app/l10n/app_localizations.dart';
import 'package:sedno_app/l10n/app_localizations_pl.dart';

export 'app_localizations.dart';

// Polish remains the fallback for legacy standalone widget tests and adapters.
AppLocalizations polishStrings() => AppLocalizationsPl();

extension LocalizedContext on BuildContext {
  AppLanguage get language =>
      LanguageScope.maybeOf(this)?.language ??
      AppLanguage.fromCode(
        AppLocalizations.of(this)?.localeName.split('_').first,
      );
  AppLocalizations get l10n => AppLocalizations.of(this) ?? polishStrings();
}

extension LocalizedTextMode on TextMode {
  String localizedAction(AppLocalizations strings) =>
      this == TextMode.simplify ? strings.simplify : strings.correct;
  String localizedHeading(AppLocalizations strings) => this == TextMode.simplify
      ? strings.simplifyHeading
      : strings.correctHeading;
  String localizedResultHeading(AppLocalizations strings) =>
      this == TextMode.simplify
      ? strings.simplifiedText
      : strings.correctedText;
}
