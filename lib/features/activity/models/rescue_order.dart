import 'package:flutter/foundation.dart';

import 'rescue_order_item.dart';
export 'rescue_order_item.dart';

enum RescueOrderStatus {
  pending('pending', 'Đã gửi yêu cầu'),
  enRoute('en_route', 'Đang đến'),
  repairing('repairing', 'Đang sửa'),
  completed('completed', 'Đã hoàn thành'),
  cancelled('cancelled', 'Đã hủy');

  const RescueOrderStatus(this.value, this.label);
  final String value;
  final String label;

  bool get isActive => this != completed && this != cancelled;

  static RescueOrderStatus fromValue(String value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw FormatException('Unknown order status: $value'),
  );
}

enum RescueServiceType {
  flatTire('Xẹp lốp'),
  outOfFuel('Hết xăng'),
  engineFailure('Chết máy'),
  batteryJump('Kích bình điện'),
  floodedEngine('Sửa ngập nước'),
  towing('Xe cẩu kéo'),
  maintenance('Đặt lịch bảo dưỡng'),
  nightRescue('Cứu hộ đêm 24/7'),
  charging('Trạm sạc');

  const RescueServiceType(this.label);
  final String label;

  static RescueServiceType fromValue(String value) => values.firstWhere(
    (service) => service.label == value,
    orElse: () => throw FormatException('Unknown service type: $value'),
  );
}

/// Prices are whole VND amounts. basePrice includes travel and repair labor.
@immutable
class RescueOrder {
  RescueOrder({
    required this.id,
    required this.orderCode,
    required this.status,
    required this.serviceType,
    required this.userVehicle,
    required this.locationAddress,
    required this.basePrice,
    required this.extraPartPrice,
    required this.discount,
    required this.createdAt,
    this.providerName,
    this.providerPhone,
    this.providerPlate,
    this.travelFee = 0,
    this.providerDistanceKm,
    this.etaMinutes,
    this.rating,
    this.locationLatitude,
    this.locationLongitude,
    this.locationLandmark = '',
    this.incidentDescription = '',
    this.serviceOption = '',
    this.vehicleType = '',
    this.incidentPhotoBytes,
    this.partnerId,
    this.partnerName,
    this.paymentMethod = RescuePaymentMethod.cash,
    this.voucherCode = '',
    List<RescueOrderItem> items = const [],
  }) : items = List.unmodifiable(items) {
    if (basePrice < 0 ||
        extraPartPrice < 0 ||
        discount < 0 ||
        discount > basePrice + extraPartPrice ||
        travelFee < 0 ||
        travelFee > basePrice) {
      throw ArgumentError('Invalid order prices');
    }
    if (items.isNotEmpty &&
        basePrice !=
            items.fold<int>(0, (sum, item) => sum + item.total) + travelFee) {
      throw ArgumentError('Order items do not match the subtotal');
    }
    if (rating != null && (!rating!.isFinite || rating! < 0 || rating! > 5)) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 0 and 5');
    }
    if ((etaMinutes != null && etaMinutes! < 0) ||
        (providerDistanceKm != null &&
            (!providerDistanceKm!.isFinite || providerDistanceKm! < 0))) {
      throw ArgumentError('Invalid provider distance or ETA');
    }
    if ((locationLatitude == null) != (locationLongitude == null) ||
        (locationLatitude != null &&
            (!locationLatitude!.isFinite || locationLatitude!.abs() > 90)) ||
        (locationLongitude != null &&
            (!locationLongitude!.isFinite || locationLongitude!.abs() > 180))) {
      throw ArgumentError('Invalid rescue location coordinates');
    }
  }

  final String id;
  final String orderCode;
  final RescueOrderStatus status;
  final RescueServiceType serviceType;
  final String userVehicle;
  final String locationAddress;
  final String locationLandmark;
  final String incidentDescription;
  final String serviceOption;
  final String vehicleType;
  final String? partnerId;
  final String? partnerName;
  final RescuePaymentMethod paymentMethod;
  final String voucherCode;
  final List<RescueOrderItem> items;
  // Incident photos stay in memory for the current session.
  final Uint8List? incidentPhotoBytes;
  final String? providerName;
  final String? providerPhone;
  final String? providerPlate;
  final int basePrice;
  final int extraPartPrice;
  final int discount;
  final int travelFee;
  final DateTime createdAt;
  final double? rating;
  final double? providerDistanceKm;
  final double? locationLatitude;
  final double? locationLongitude;
  final int? etaMinutes;

  int get laborFee => basePrice - travelFee;
  int get totalPrice => basePrice + extraPartPrice - discount;
  bool get hasProvider => providerName?.trim().isNotEmpty ?? false;

  int get progressStep => switch (status) {
    RescueOrderStatus.pending => hasProvider ? 1 : 0,
    RescueOrderStatus.enRoute => 2,
    RescueOrderStatus.repairing || RescueOrderStatus.completed => 3,
    RescueOrderStatus.cancelled => 0,
  };

  RescueOrder copyWith({RescueOrderStatus? status, double? rating}) =>
      RescueOrder(
        id: id,
        orderCode: orderCode,
        status: status ?? this.status,
        serviceType: serviceType,
        userVehicle: userVehicle,
        locationAddress: locationAddress,
        locationLandmark: locationLandmark,
        incidentDescription: incidentDescription,
        serviceOption: serviceOption,
        vehicleType: vehicleType,
        partnerId: partnerId,
        partnerName: partnerName,
        paymentMethod: paymentMethod,
        voucherCode: voucherCode,
        items: items,
        incidentPhotoBytes: incidentPhotoBytes,
        providerName: providerName,
        providerPhone: providerPhone,
        providerPlate: providerPlate,
        basePrice: basePrice,
        extraPartPrice: extraPartPrice,
        discount: discount,
        travelFee: travelFee,
        providerDistanceKm: providerDistanceKm,
        etaMinutes: etaMinutes,
        createdAt: createdAt,
        rating: rating ?? this.rating,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
      );

  factory RescueOrder.fromJson(Map<String, dynamic> json) => RescueOrder(
    id: json['id'] as String,
    orderCode: json['orderCode'] as String,
    status: RescueOrderStatus.fromValue(json['status'] as String),
    serviceType: RescueServiceType.fromValue(json['serviceType'] as String),
    userVehicle: json['userVehicle'] as String,
    locationAddress: json['locationAddress'] as String,
    locationLandmark: json['locationLandmark'] as String? ?? '',
    incidentDescription: json['incidentDescription'] as String? ?? '',
    serviceOption: json['serviceOption'] as String? ?? '',
    vehicleType: json['vehicleType'] as String? ?? '',
    partnerId: json['partnerId'] as String?,
    partnerName: json['partnerName'] as String?,
    paymentMethod: RescuePaymentMethod.fromValue(
      json['paymentMethod'] as String? ?? 'cash',
    ),
    voucherCode: json['voucherCode'] as String? ?? '',
    items: (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              RescueOrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    providerName: json['providerName'] as String?,
    providerPhone: json['providerPhone'] as String?,
    providerPlate: json['providerPlate'] as String?,
    basePrice: (json['basePrice'] as num).toInt(),
    extraPartPrice: (json['extraPartPrice'] as num).toInt(),
    discount: (json['discount'] as num).toInt(),
    travelFee: (json['travelFee'] as num?)?.toInt() ?? 0,
    providerDistanceKm: (json['providerDistanceKm'] as num?)?.toDouble(),
    etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    rating: (json['rating'] as num?)?.toDouble(),
    locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
    locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderCode': orderCode,
    'status': status.value,
    'serviceType': serviceType.label,
    'userVehicle': userVehicle,
    'locationAddress': locationAddress,
    'locationLandmark': locationLandmark,
    'incidentDescription': incidentDescription,
    'serviceOption': serviceOption,
    'vehicleType': vehicleType,
    'partnerId': partnerId,
    'partnerName': partnerName,
    'paymentMethod': paymentMethod.value,
    'voucherCode': voucherCode,
    'items': items.map((item) => item.toJson()).toList(),
    'providerName': providerName,
    'providerPhone': providerPhone,
    'providerPlate': providerPlate,
    'basePrice': basePrice,
    'extraPartPrice': extraPartPrice,
    'discount': discount,
    'totalPrice': totalPrice,
    'travelFee': travelFee,
    'providerDistanceKm': providerDistanceKm,
    'etaMinutes': etaMinutes,
    'createdAt': createdAt.toIso8601String(),
    'rating': rating,
    'locationLatitude': locationLatitude,
    'locationLongitude': locationLongitude,
  };
}
