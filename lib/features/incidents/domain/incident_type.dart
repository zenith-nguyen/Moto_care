import '../../../core/money/money_amount.dart';
import '../../../core/network/json_reader.dart';

class IncidentType {
  const IncidentType({
    required this.id,
    required this.code,
    required this.name,
    required this.basePrice,
  });

  final int id;
  final String code;
  final String name;
  final MoneyAmount basePrice;

  factory IncidentType.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return IncidentType(
      id: reader.positiveInt('id'),
      code: reader.string('code'),
      name: reader.string('name'),
      basePrice: MoneyAmount.parse(reader.value('basePrice')),
    );
  }
}
