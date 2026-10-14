import 'package:characters/characters.dart';

/// User text is counted in visible grapheme clusters, including emoji sequences.
class InputText {
  InputText(String value) : value = value {
    if (value.trim().isEmpty) {
      throw const FormatException('Tekst nie może być pusty.');
    }
    if (value.characters.length > maxCharacters) {
      throw const FormatException('Tekst może mieć maksymalnie 4000 znaków.');
    }
  }

  static const maxCharacters = 4000;

  final String value;

  int get characterCount => value.characters.length;

  Map<String, Object?> toJson() => {'text': value};

  factory InputText.fromJson(Map<String, dynamic> json) {
    final text = json['text'];
    if (text is! String) throw const FormatException('Nieprawidłowy tekst.');
    return InputText(text);
  }
}
