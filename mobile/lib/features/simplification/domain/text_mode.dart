enum TextMode {
  simplify,
  correct;

  String get action => this == simplify ? 'Uprość' : 'Popraw';
  String get heading => this == simplify ? 'uprość tekst' : 'popraw tekst';
  String get resultHeading =>
      this == simplify ? 'Uproszczony tekst' : 'Poprawiony tekst';

  static TextMode fromJson(Object? value) => switch (value) {
    null || 'simplify' => simplify,
    'correct' => correct,
    _ => throw const FormatException('Nieprawidłowy tryb tekstu.'),
  };
}
