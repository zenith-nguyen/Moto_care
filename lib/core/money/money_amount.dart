class MoneyAmount {
  MoneyAmount._(this.value);

  static final _pattern = RegExp(r'^(0|[1-9][0-9]*)\.[0-9]{2}$');

  final String value;

  factory MoneyAmount.parse(Object? raw) {
    if (raw is! String || !_pattern.hasMatch(raw)) {
      throw const FormatException(
        'Money amount must be a non-negative decimal string with two digits.',
      );
    }
    return MoneyAmount._(raw);
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) {
    return other is MoneyAmount && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
