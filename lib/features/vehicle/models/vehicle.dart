import 'package:flutter/foundation.dart';

enum TireType {
  tubeless('tubeless', 'Không ruột'),
  tubed('tubed', 'Có ruột');

  const TireType(this.value, this.label);
  final String value;
  final String label;

  static TireType fromValue(String value) => values.firstWhere(
    (type) => type.value == value,
    orElse: () => throw FormatException('Unknown tire type: $value'),
  );
}

enum EngineType {
  gas('gas', 'Xe xăng'),
  electric('electric', 'Xe điện');

  const EngineType(this.value, this.label);
  final String value;
  final String label;

  static EngineType fromValue(String value) => values.firstWhere(
    (type) => type.value == value,
    orElse: () => throw FormatException('Unknown engine type: $value'),
  );
}

@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.licensePlate,
    required this.tireType,
    required this.engineType,
    this.isDefault = false,
    this.color = '',
  });

  final String id;
  final String name;
  final String brand;
  final String licensePlate;
  final TireType tireType;
  final EngineType engineType;
  final bool isDefault;
  final String color;

  Vehicle copyWith({
    String? name,
    String? brand,
    String? licensePlate,
    TireType? tireType,
    EngineType? engineType,
    bool? isDefault,
    String? color,
  }) => Vehicle(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    licensePlate: licensePlate ?? this.licensePlate,
    tireType: tireType ?? this.tireType,
    engineType: engineType ?? this.engineType,
    isDefault: isDefault ?? this.isDefault,
    color: color ?? this.color,
  );

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String,
    licensePlate: json['licensePlate'] as String,
    tireType: TireType.fromValue(json['tireType'] as String),
    engineType: EngineType.fromValue(json['engineType'] as String),
    isDefault: json['isDefault'] as bool? ?? false,
    color: json['color'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'licensePlate': licensePlate,
    'tireType': tireType.value,
    'engineType': engineType.value,
    'isDefault': isDefault,
    'color': color,
  };
}
