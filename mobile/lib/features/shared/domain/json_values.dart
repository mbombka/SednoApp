String requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Nieprawidłowe pole: $key.');
  }
  return value;
}

int requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Nieprawidłowe pole: $key.');
  return value;
}

DateTime requiredUtcDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|\+00:00)$')
          .hasMatch(value)) {
    throw FormatException('Nieprawidłowa data UTC: $key.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null ||
      !parsed.isUtc ||
      parsed.year != int.parse(value.substring(0, 4)) ||
      parsed.month != int.parse(value.substring(5, 7)) ||
      parsed.day != int.parse(value.substring(8, 10)) ||
      parsed.hour != int.parse(value.substring(11, 13)) ||
      parsed.minute != int.parse(value.substring(14, 16)) ||
      parsed.second != int.parse(value.substring(17, 19))) {
    throw FormatException('Nieprawidłowa data UTC: $key.');
  }
  return parsed;
}
