import 'package:flutter/material.dart';

import '../models/home_discovery.dart';
import '../theme/revo_home_theme.dart';
import 'home_sheets.dart';

class HomeDiscoveryFilterSheet extends StatefulWidget {
  const HomeDiscoveryFilterSheet({super.key, required this.filters});
  final HomeDiscoveryFilters filters;

  @override
  State<HomeDiscoveryFilterSheet> createState() =>
      _HomeDiscoveryFilterSheetState();
}

class _HomeDiscoveryFilterSheetState extends State<HomeDiscoveryFilterSheet> {
  late bool _open24h = widget.filters.open24h;
  late bool _verified = widget.filters.verified;
  late int? _distance = widget.filters.maxDistanceKm;

  @override
  Widget build(BuildContext context) => HomeSheetContent(
    title: 'Bộ lọc trạm cứu hộ',
    children: [
      const Text(
        'Khoảng cách',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final distance in <int?>[null, 3, 5, 10])
            ChoiceChip(
              label: Text(distance == null ? 'Tất cả' : 'Dưới $distance km'),
              selected: _distance == distance,
              showCheckmark: false,
              selectedColor: RevoHomeColors.primary,
              backgroundColor: RevoHomeColors.surface,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: _distance == distance
                    ? Colors.white
                    : RevoHomeColors.ink,
              ),
              onSelected: (_) => setState(() => _distance = distance),
            ),
        ],
      ),
      const SizedBox(height: 18),
      SwitchListTile.adaptive(
        key: const ValueKey('home-filter-open24h'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Phục vụ 24/7'),
        value: _open24h,
        activeTrackColor: RevoHomeColors.primary,
        onChanged: (value) => setState(() => _open24h = value),
      ),
      SwitchListTile.adaptive(
        key: const ValueKey('home-filter-verified'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Trạm đã xác minh'),
        value: _verified,
        activeTrackColor: RevoHomeColors.primary,
        onChanged: (value) => setState(() => _verified = value),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          HomeDiscoveryFilters(
            open24h: _open24h,
            verified: _verified,
            maxDistanceKm: _distance,
          ),
        ),
        child: const Text('Áp dụng bộ lọc'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() {
          _open24h = false;
          _verified = false;
          _distance = null;
        }),
        child: const Text('Đặt lại'),
      ),
    ],
  );
}
