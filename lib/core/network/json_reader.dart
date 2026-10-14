class JsonReader {
  const JsonReader(this._json);

  final Map<String, dynamic> _json;

  Object? value(String key) => _json[key];

  int positiveInt(String key) {
    final value = _json[key];
    if (value is! int || value <= 0) {
      throw FormatException('Invalid positive integer field: $key');
    }
    return value;
  }

  int? nullablePositiveInt(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is! int || value <= 0) {
      throw FormatException('Invalid optional integer field: $key');
    }
    return value;
  }

  int? nullableInt(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is! int) throw FormatException('Invalid integer field: $key');
    return value;
  }

  String string(String key) {
    final value = _json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid string field: $key');
    }
    return value;
  }

  String? nullableString(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('Invalid string field: $key');
    return value;
  }

  bool boolean(String key) {
    final value = _json[key];
    if (value is! bool) throw FormatException('Invalid boolean field: $key');
    return value;
  }

  double number(String key) {
    final value = _json[key];
    if (value is! num || !value.isFinite) {
      throw FormatException('Invalid number field: $key');
    }
    return value.toDouble();
  }

  DateTime dateTime(String key) {
    final value = DateTime.tryParse(string(key));
    if (value == null) throw FormatException('Invalid timestamp field: $key');
    return value.toUtc();
  }

  DateTime? nullableDateTime(String key) {
    final raw = _json[key];
    if (raw == null) return null;
    if (raw is! String) throw FormatException('Invalid timestamp field: $key');
    final value = DateTime.tryParse(raw);
    if (value == null) throw FormatException('Invalid timestamp field: $key');
    return value.toUtc();
  }

  Map<String, dynamic> object(String key) {
    final value = _json[key];
    if (value is! Map) throw FormatException('Invalid object field: $key');
    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic>? nullableObject(String key) {
    final value = _json[key];
    if (value == null) return null;
    if (value is! Map) throw FormatException('Invalid object field: $key');
    return Map<String, dynamic>.from(value);
  }

  List<Object?> list(String key) {
    final value = _json[key];
    if (value is! List) throw FormatException('Invalid list field: $key');
    return List<Object?>.from(value);
  }
}
