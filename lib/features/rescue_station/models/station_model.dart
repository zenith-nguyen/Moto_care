import 'package:flutter/foundation.dart';

import '../../partner/models/marketplace_catalog.dart';
import 'rescue_station.dart';
import 'service_catalog_model.dart';

@immutable
class StationProfile {
  StationProfile({
    required this.description,
    List<String> imageAssets = const [],
    this.mechanicCount,
    this.warrantyLabel,
    Map<String, ServiceCatalogDetails> serviceDetails = const {},
  }) : imageAssets = List.unmodifiable(imageAssets),
       serviceDetails = Map.unmodifiable(serviceDetails);

  final String description;
  final List<String> imageAssets;
  final int? mechanicCount;
  final String? warrantyLabel;
  final Map<String, ServiceCatalogDetails> serviceDetails;
}

/// The station directory, Home metadata and booking menu share one identity.
@immutable
class StationModel {
  StationModel({
    required this.station,
    required this.description,
    required List<String> imageAssets,
    required List<ServicePackage> services,
    List<ServiceCatalogModel>? serviceCatalog,
    required this.distanceKm,
    this.reviewCount,
    this.responseMinutes,
    this.mechanicCount,
    this.warrantyLabel,
  }) : imageAssets = List.unmodifiable(imageAssets),
       services = List.unmodifiable(services),
       serviceCatalog = List.unmodifiable(
         serviceCatalog ??
             services.map(
               (package) => ServiceCatalogModel.fromPackage(package),
             ),
       );

  final RescueStation station;
  final String description;
  final List<String> imageAssets;
  final List<ServicePackage> services;
  // Catalog metadata stays separate from package selection and cart state.
  final List<ServiceCatalogModel> serviceCatalog;
  final double distanceKm;
  final int? reviewCount;
  final int? responseMinutes;
  final int? mechanicCount;
  final String? warrantyLabel;

  String get id => station.id;
  String get name => station.name;
  String get address => station.address;
  double get rating => station.rating;
  bool get isVerified => station.isVerified;
  bool get isOpen => station.isOpen;

  String get openingLabel => !isOpen
      ? 'Đang đóng cửa'
      : station.isOpen24h
      ? 'Đang mở cửa 24/7'
      : 'Đang mở cửa';

  String get responseLabel => !isOpen
      ? 'Đóng cửa'
      : responseMinutes != null
      ? '$responseMinutes–${responseMinutes! + 5} phút'
      : 'Liên hệ trạm';

  Uri get mapUri => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '${station.latitude},${station.longitude}',
  });
}

@immutable
class StationReview {
  const StationReview({
    required this.id,
    required this.author,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String author;
  final int stars;
  final String comment;
  final DateTime createdAt;
}
