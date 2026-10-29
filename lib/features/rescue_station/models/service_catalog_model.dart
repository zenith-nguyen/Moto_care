import 'package:flutter/foundation.dart';

import '../../activity/models/rescue_order.dart';
import '../../partner/models/marketplace_catalog.dart';

enum ServiceFulfillment { onSite, toWorkshop, atStation }

/// Station-published information, independent of the shared booking price.
@immutable
class ServiceCatalogDetails {
  ServiceCatalogDetails({
    required this.description,
    required List<String> procedureSteps,
    required this.materialsCommitment,
    required this.warranty,
  }) : procedureSteps = List.unmodifiable(procedureSteps);

  final String description;
  final List<String> procedureSteps;
  final String materialsCommitment;
  final String warranty;
}

/// A read-only catalog entry: opening it never changes a cart or an order.
@immutable
class ServiceCatalogModel {
  const ServiceCatalogModel({
    required this.id,
    required this.name,
    required this.price,
    required this.serviceType,
    required this.fulfillment,
    this.details,
  });

  factory ServiceCatalogModel.fromPackage(
    ServicePackage package, {
    ServiceCatalogDetails? details,
  }) => ServiceCatalogModel(
    id: package.id,
    name: package.name,
    price: package.price,
    serviceType: package.serviceType,
    fulfillment: switch (package.serviceType) {
      RescueServiceType.towing => ServiceFulfillment.toWorkshop,
      RescueServiceType.charging ||
      RescueServiceType.maintenance => ServiceFulfillment.atStation,
      _ => ServiceFulfillment.onSite,
    },
    details: details,
  );

  final String id;
  final String name;
  final int price;
  final RescueServiceType serviceType;
  final ServiceFulfillment fulfillment;
  final ServiceCatalogDetails? details;
}
