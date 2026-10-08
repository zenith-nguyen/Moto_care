import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/search_service.dart';
import '../models/price_group.dart';
import '../data/demo_price_groups.dart';

final priceGroupsProvider = Provider<List<PriceGroup>>(
  (ref) => demoPriceGroups,
);
final filteredPriceGroupsProvider = Provider.autoDispose
    .family<List<PriceGroup>, String>(
      (ref, query) => List.unmodifiable(
        [
          for (final (title, category, items) in ref.watch(priceGroupsProvider))
            (
              title,
              category,
              List<PriceItem>.unmodifiable(
                items.where(
                  (item) =>
                      normalizeServiceSearch('$title ${item.$1}')
                          .contains(normalizeServiceSearch(query)),
                ),
              ),
            ),
        ].where((group) => group.$3.isNotEmpty),
      ),
    );
