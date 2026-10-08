import 'package:flutter/material.dart';

import '../../../core/widgets/service_scaffold.dart';

const _priceGroups = [
  (
    'Cứu hộ cơ bản',
    Icons.build_circle_outlined,
    [('Vá xe', '30k - 50k'), ('Cứu hộ hết xăng', '40k'), ('Kích bình', '50k')],
  ),
  (
    'Săm & Lốp xe',
    Icons.tire_repair,
    [('Ruột xe số', '90k'), ('Lốp tay ga không ruột', '350k - 450k')],
  ),
  (
    'Bình Ắc quy & Điện',
    Icons.battery_charging_full,
    [('Thay bình ắc quy GS', '380k')],
  ),
];

class BangGiaScreen extends StatefulWidget {
  const BangGiaScreen({super.key});

  @override
  State<BangGiaScreen> createState() => _BangGiaScreenState();
}

class _BangGiaScreenState extends State<BangGiaScreen> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = [
      for (final (title, icon, items) in _priceGroups)
        (
          title,
          icon,
          items
              .where(
                (item) =>
                    normalizeServiceSearch('$title ${item.$1}')
                        .contains(_query),
              )
              .toList(),
        ),
    ].where((group) => group.$3.isNotEmpty).toList();
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
          for (final (title, icon, items) in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ExpansionTile(
                  key: ValueKey('$title-${_query.isNotEmpty}'),
                  initiallyExpanded: _query.isNotEmpty,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(icon, color: ServiceColors.orange),
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
