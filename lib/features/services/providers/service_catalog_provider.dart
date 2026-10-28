import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/search_service.dart';
import '../data/service_catalog_items.dart';
import '../models/service_catalog_item.dart';

final serviceCatalogProvider = Provider<List<ServiceCatalogItem>>(
  (ref) => serviceCatalogItems,
);
final filteredServiceCatalogProvider = Provider.autoDispose
    .family<List<ServiceCatalogItem>, (String, ServiceCatalogCategory)>((
      ref,
      filter,
    ) {
      final query = normalizeServiceSearch(filter.$1);
      return List.unmodifiable(
        ref.watch(serviceCatalogProvider).where((item) {
          final inCategory =
              filter.$2 == ServiceCatalogCategory.all ||
              item.categories.contains(filter.$2);
          return inCategory &&
              normalizeServiceSearch(
                '${item.title} ${item.description} ${item.service.title}',
              ).contains(query);
        }),
      );
    });
