import 'package:sedno_app/features/shared/domain/app_language.dart';

import 'privacy_policy.dart';
import 'privacy_policy_en.dart';

abstract final class LocalizedPrivacyPolicy {
  static String aiNotice(AppLanguage language) => switch (language) {
    AppLanguage.polish => PrivacyPolicy.aiNotice,
    AppLanguage.english => PrivacyPolicyEn.aiNotice,
  };
  static String deletionNotice(AppLanguage language) => switch (language) {
    AppLanguage.polish => PrivacyPolicy.deletionNotice,
    AppLanguage.english => PrivacyPolicyEn.deletionNotice,
  };
  static String versionLabel(AppLanguage language) => switch (language) {
    AppLanguage.polish => PrivacyPolicy.versionLabel,
    AppLanguage.english => PrivacyPolicyEn.versionLabel,
  };
  static List<PrivacySection> sections(AppLanguage language) =>
      switch (language) {
        AppLanguage.polish => PrivacyPolicy.sections,
        AppLanguage.english => PrivacyPolicyEn.sections,
      };
}
