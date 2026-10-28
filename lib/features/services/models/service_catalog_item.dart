import 'package:flutter/foundation.dart';

import '../../home/models/home_service.dart';

enum ServiceCatalogCategory {
  all('Tất cả'),
  rescue('Cứu hộ 24/7'),
  onSite('Sửa chữa tận nơi'),
  maintenance('Bảo dưỡng định kỳ');

  const ServiceCatalogCategory(this.label);
  final String label;
}

@immutable
class ServiceCatalogItem {
  const ServiceCatalogItem({
    required this.service,
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.badge,
    required this.responseLabel,
    required this.categories,
  });
  final HomeService service;
  final String title;
  final String description;
  final String imageAsset;
  final String badge;
  final String responseLabel;
  final Set<ServiceCatalogCategory> categories;
}
