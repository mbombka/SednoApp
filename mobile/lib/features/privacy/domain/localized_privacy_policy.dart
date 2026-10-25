import 'package:sedno_app/features/shared/domain/app_language.dart';

import 'privacy_policy.dart';
import 'privacy_policy_en.dart';
import 'privacy_policy_fr.dart';
import 'privacy_policy_de.dart';
import 'privacy_policy_it.dart';
import 'privacy_policy_es.dart';
import 'privacy_policy_pt.dart';
import 'privacy_policy_sk.dart';
import 'privacy_policy_cs.dart';
import 'privacy_policy_ro.dart';
import 'privacy_policy_nb.dart';
import 'privacy_policy_sv.dart';

abstract final class LocalizedPrivacyPolicy {
  static String aiNotice(AppLanguage language) => switch (language) {
    AppLanguage.polish => PrivacyPolicy.aiNotice,
    AppLanguage.english => PrivacyPolicyEn.aiNotice,
    AppLanguage.americanEnglish => PrivacyPolicyEn.aiNotice,
    AppLanguage.french => PrivacyPolicyFr.aiNotice,
    AppLanguage.german => PrivacyPolicyDe.aiNotice,
    AppLanguage.italian => PrivacyPolicyIt.aiNotice,
    AppLanguage.spanish => PrivacyPolicyEs.aiNotice,
    AppLanguage.portuguese => PrivacyPolicyPt.aiNotice,
    AppLanguage.slovak => PrivacyPolicySk.aiNotice,
    AppLanguage.czech => PrivacyPolicyCs.aiNotice,
    AppLanguage.romanian => PrivacyPolicyRo.aiNotice,
    AppLanguage.norwegian => PrivacyPolicyNb.aiNotice,
    AppLanguage.swedish => PrivacyPolicySv.aiNotice,
  };
  static String deletionNotice(AppLanguage language) => switch (language) {
    AppLanguage.polish => PrivacyPolicy.deletionNotice,
    AppLanguage.english => PrivacyPolicyEn.deletionNotice,
    AppLanguage.americanEnglish => PrivacyPolicyEn.deletionNotice,
    AppLanguage.french => PrivacyPolicyFr.deletionNotice,
    AppLanguage.german => PrivacyPolicyDe.deletionNotice,
    AppLanguage.italian => PrivacyPolicyIt.deletionNotice,
    AppLanguage.spanish => PrivacyPolicyEs.deletionNotice,
    AppLanguage.portuguese => PrivacyPolicyPt.deletionNotice,
    AppLanguage.slovak => PrivacyPolicySk.deletionNotice,
    AppLanguage.czech => PrivacyPolicyCs.deletionNotice,
    AppLanguage.romanian => PrivacyPolicyRo.deletionNotice,
    AppLanguage.norwegian => PrivacyPolicyNb.deletionNotice,
    AppLanguage.swedish => PrivacyPolicySv.deletionNotice,
  };
  static String versionLabel(AppLanguage language) => switch (language) {
    AppLanguage.polish => PrivacyPolicy.versionLabel,
    AppLanguage.english => PrivacyPolicyEn.versionLabel,
    AppLanguage.americanEnglish => PrivacyPolicyEn.versionLabel,
    AppLanguage.french => PrivacyPolicyFr.versionLabel,
    AppLanguage.german => PrivacyPolicyDe.versionLabel,
    AppLanguage.italian => PrivacyPolicyIt.versionLabel,
    AppLanguage.spanish => PrivacyPolicyEs.versionLabel,
    AppLanguage.portuguese => PrivacyPolicyPt.versionLabel,
    AppLanguage.slovak => PrivacyPolicySk.versionLabel,
    AppLanguage.czech => PrivacyPolicyCs.versionLabel,
    AppLanguage.romanian => PrivacyPolicyRo.versionLabel,
    AppLanguage.norwegian => PrivacyPolicyNb.versionLabel,
    AppLanguage.swedish => PrivacyPolicySv.versionLabel,
  };
  static List<PrivacySection> sections(AppLanguage language) =>
      switch (language) {
        AppLanguage.polish => PrivacyPolicy.sections,
        AppLanguage.english => PrivacyPolicyEn.sections,
        AppLanguage.americanEnglish => PrivacyPolicyEn.sections,
        AppLanguage.french => PrivacyPolicyFr.sections,
        AppLanguage.german => PrivacyPolicyDe.sections,
        AppLanguage.italian => PrivacyPolicyIt.sections,
        AppLanguage.spanish => PrivacyPolicyEs.sections,
        AppLanguage.portuguese => PrivacyPolicyPt.sections,
        AppLanguage.slovak => PrivacyPolicySk.sections,
        AppLanguage.czech => PrivacyPolicyCs.sections,
        AppLanguage.romanian => PrivacyPolicyRo.sections,
        AppLanguage.norwegian => PrivacyPolicyNb.sections,
        AppLanguage.swedish => PrivacyPolicySv.sections,
      };
}
