import 'package:sedno_app/features/shared/domain/app_language.dart';
import 'package:flutter/widgets.dart';
import 'package:sedno_app/l10n/app_localizations.dart';

export 'package:sedno_app/features/shared/domain/app_language.dart';

extension AppLanguageLocale on AppLanguage {
  Locale get locale => switch (this) {
    AppLanguage.polish => const Locale('pl', 'PL'),
    AppLanguage.english => const Locale('en', 'GB'),
  };
}

class LanguageController extends ChangeNotifier with WidgetsBindingObserver {
  LanguageController({this.read, this.write, List<Locale>? deviceLocales})
    : _deviceLocales =
          deviceLocales ?? WidgetsBinding.instance.platformDispatcher.locales {
    WidgetsBinding.instance.addObserver(this);
  }

  final Future<String?> Function()? read;
  final Future<void> Function(String?)? write;
  List<Locale> _deviceLocales;
  AppLanguage? _selected;
  AppLanguage? get selected => _selected;
  AppLanguage get language =>
      _selected ??
      AppLanguage.resolve(_deviceLocales.map((locale) => locale.languageCode));
  AppLocalizations get strings => lookupAppLocalizations(language.locale);

  Future<void> load() async {
    try {
      final saved = await read?.call();
      _selected = AppLanguage.values
          .where((value) => value.code == saved)
          .firstOrNull;
      notifyListeners();
    } catch (_) {
      // Device language remains available when local storage cannot be read.
    }
  }

  Future<void> select(AppLanguage? value) async {
    await write?.call(value?.code);
    _selected = value;
    notifyListeners();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    _deviceLocales =
        locales ?? WidgetsBinding.instance.platformDispatcher.locales;
    if (_selected == null) notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    required LanguageController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);
  static LanguageController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}
