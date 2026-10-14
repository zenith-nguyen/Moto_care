import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';

enum WeatherCategory {
  disabled('DISABLED'),
  unavailable('UNAVAILABLE'),
  normal('NORMAL'),
  moderate('MODERATE'),
  severe('SEVERE');

  const WeatherCategory(this.wireValue);

  final String wireValue;

  static WeatherCategory fromWire(Object? raw) {
    return values.firstWhere(
      (category) => category.wireValue == raw,
      orElse: () => throw FormatException('Unsupported weather category: $raw'),
    );
  }
}

enum WeatherSource {
  openMeteo('OPEN_METEO'),
  fallback('FALLBACK');

  const WeatherSource(this.wireValue);

  final String wireValue;

  static WeatherSource fromWire(Object? raw) {
    return values.firstWhere(
      (source) => source.wireValue == raw,
      orElse: () => throw FormatException('Unsupported weather source: $raw'),
    );
  }
}

class OrderPricing {
  const OrderPricing({
    required this.basePrice,
    required this.weatherSurcharge,
    required this.weatherMultiplier,
    required this.weatherCategory,
    required this.weatherSource,
    required this.weatherObservedAt,
    required this.weatherCode,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.windGustKmh,
    required this.attribution,
  });

  final MoneyAmount basePrice;
  final MoneyAmount weatherSurcharge;
  final String weatherMultiplier;
  final WeatherCategory weatherCategory;
  final WeatherSource weatherSource;
  final DateTime? weatherObservedAt;
  final int? weatherCode;
  final String? precipitationMm;
  final String? windSpeedKmh;
  final String? windGustKmh;
  final String? attribution;

  factory OrderPricing.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final multiplier = reader.string('weatherMultiplier');
    if (!RegExp(r'^[0-9]+\.[0-9]{4}$').hasMatch(multiplier)) {
      throw const FormatException('Invalid weather multiplier.');
    }
    return OrderPricing(
      basePrice: MoneyAmount.parse(reader.value('basePrice')),
      weatherSurcharge: MoneyAmount.parse(reader.value('weatherSurcharge')),
      weatherMultiplier: multiplier,
      weatherCategory: WeatherCategory.fromWire(
        reader.value('weatherCategory'),
      ),
      weatherSource: WeatherSource.fromWire(reader.value('weatherSource')),
      weatherObservedAt: reader.nullableDateTime('weatherObservedAt'),
      weatherCode: reader.nullableInt('weatherCode'),
      precipitationMm: _nullableDecimal(reader, 'precipitationMm'),
      windSpeedKmh: _nullableDecimal(reader, 'windSpeedKmh'),
      windGustKmh: _nullableDecimal(reader, 'windGustKmh'),
      attribution: reader.nullableString('attribution'),
    );
  }
}

String? _nullableDecimal(JsonReader reader, String key) {
  final value = reader.nullableString(key);
  if (value != null && !RegExp(r'^[0-9]+\.[0-9]{2}$').hasMatch(value)) {
    throw FormatException('Invalid decimal field: $key');
  }
  return value;
}
