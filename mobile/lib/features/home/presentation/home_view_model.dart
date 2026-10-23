import 'package:sedno_app/l10n/localization.dart';

class HomeViewModel {
  const HomeViewModel({required this.appName});

  final String appName;

  String get welcomeMessage => polishStrings().welcomeName(appName);
}
