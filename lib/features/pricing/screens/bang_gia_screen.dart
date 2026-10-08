import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pricing_provider.dart';
import '../models/price_group.dart';

import '../../../core/widgets/service_scaffold.dart';

class BangGiaScreen extends ConsumerStatefulWidget {
  const BangGiaScreen({super.key});

  @override
  ConsumerState<BangGiaScreen> createState() => _BangGiaScreenState();
}

class _BangGiaScreenState extends ConsumerState<BangGiaScreen> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(filteredPriceGroupsProvider(_query));
    return ServiceScaffold(
      title: 'Bảng giá dịch vụ & Phụ tùng',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ServiceSearchBar(
            controller: _search,
            hint: 'Tìm phụ tùng hoặc dịch vụ',
            onChanged: (value) =>
                setState(() => _query = normalizeServiceSearch(value)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ServiceColors.goldBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.black,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cam kết minh bạch giá - Không chặt chém',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const ServiceSectionTitle('Giá tham khảo'),
          const Text(
            'Xác nhận giá và phụ tùng với thợ trước khi thực hiện dịch vụ.',
            style: TextStyle(color: ServiceColors.muted),
          ),
          const SizedBox(height: 16),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Không tìm thấy phụ tùng hoặc dịch vụ phù hợp.'),
            ),
          for (final (title, category, items) in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ExpansionTile(
                  key: ValueKey('$title-${_query.isNotEmpty}'),
                  initiallyExpanded: _query.isNotEmpty,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(switch (category) {
                    PriceCategory.rescue => Icons.build_circle_outlined,
                    PriceCategory.tire => Icons.tire_repair,
                    PriceCategory.battery => Icons.battery_charging_full,
                  }, color: ServiceColors.orange),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    for (final (name, price) in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(name),
                            Text(
                              price,
                              style: const TextStyle(
                                color: ServiceColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
