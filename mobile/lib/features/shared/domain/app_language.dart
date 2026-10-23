/// Language of text processing. Wire codes are independent of regional locales.
enum AppLanguage {
  polish('pl', 'pl-PL'),
  english('en', 'en-GB');

  const AppLanguage(this.code, this.speechTag);
  final String code;
  final String speechTag;

  static AppLanguage fromCode(String? code) => values.firstWhere(
    (language) => language.code == code,
    orElse: () => polish,
  );

  static AppLanguage resolve(Iterable<String> codes) {
    for (final code in codes) {
      for (final language in values) {
        if (code == language.code) return language;
      }
    }
    return polish;
  }
}

AppLanguage polishLanguage() => AppLanguage.polish;
