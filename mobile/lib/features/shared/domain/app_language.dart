/// Processing languages. Keep existing wire codes stable for saved history.
enum AppLanguage {
  polish('pl', 'pl-PL', 'Polski'),
  english('en', 'en-GB', 'English (UK)'),
  americanEnglish('en-US', 'en-US', 'English (US)'),
  french('fr', 'fr-FR', 'Français'),
  german('de', 'de-DE', 'Deutsch'),
  italian('it', 'it-IT', 'Italiano'),
  spanish('es', 'es-ES', 'Español'),
  portuguese('pt', 'pt-PT', 'Português (Portugal)'),
  slovak('sk', 'sk-SK', 'Slovenčina'),
  czech('cs', 'cs-CZ', 'Čeština'),
  romanian('ro', 'ro-RO', 'Română'),
  norwegian('nb', 'nb-NO', 'Norsk bokmål'),
  swedish('sv', 'sv-SE', 'Svenska');

  const AppLanguage(this.code, this.speechTag, this.nativeName);
  final String code;
  final String speechTag;
  final String nativeName;

  String get firebaseLanguage => switch (this) {
    english => 'en-GB',
    americanEnglish => 'en',
    portuguese => 'pt-PT',
    norwegian => 'no',
    _ => code,
  };

  static AppLanguage fromCode(String? code) => values.firstWhere(
    (language) => language.code == code,
    orElse: () => polish,
  );

  /// Exact regional matches precede language matches within each preference.
  /// Bare English retains the British default. Norwegian `no` maps to Bokmål;
  /// Nynorsk (`nn`) is not silently advertised as supported.
  static AppLanguage resolve(Iterable<String> tags) {
    for (final raw in tags) {
      final tag = raw.replaceAll('_', '-').toLowerCase();
      for (final language in values) {
        if (language.speechTag.toLowerCase() == tag) return language;
      }
      final code = tag.split('-').first;
      if (code == 'no' || code == 'nb') return norwegian;
      for (final language in values) {
        if (language.code.toLowerCase() == code) return language;
      }
    }
    return polish;
  }
}

AppLanguage polishLanguage() => AppLanguage.polish;
