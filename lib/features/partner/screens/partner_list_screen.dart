import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/widgets/order_summary.dart';
import '../providers/partner_search_provider.dart';
import '../../home/theme/home_theme.dart';
import '../providers/partner_provider.dart';
import '../widgets/marketplace_widgets.dart';

class PartnerListScreen extends ConsumerStatefulWidget {
  const PartnerListScreen({super.key, required this.serviceType});
  final String serviceType;
  @override
  ConsumerState<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends ConsumerState<PartnerListScreen> {
  String _query = '';
  PartnerVehicleType? _filter;
  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(
      partnerSearchProvider((widget.serviceType, _query, _filter)),
    );
    return MarketplaceScaffold(
      title: widget.serviceType,
      onBack: () => context.canPop() ? context.pop() : context.go('/trang-chu'),
      body: ListView.builder(
        key: const ValueKey('partner-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: listings.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tiệm cứu hộ gần bạn',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('partner-search'),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Tìm tiệm sửa xe, cứu hộ...',
                    prefixIcon: Icon(Icons.search, color: HomeColors.text),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in PartnerVehicleType.values)
                      FilterChip(
                        label: Text(type.label),
                        selected: _filter == type,
                        onSelected: (selected) =>
                            setState(() => _filter = selected ? type : null),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Danh sách và giá tham khảo trong phiên dùng thử.',
                  style: TextStyle(color: HomeColors.secondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (listings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Không tìm thấy tiệm phù hợp. Thử tên khác hoặc bỏ bộ lọc.',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          }
          final listing = listings[index - 1];
          final shop = listing.shop;
          final distance = listing.distance;
          final price = listing.price;
          void select() => context.push(
            '/partners/${Uri.encodeComponent(shop.id)}?service=${Uri.encodeComponent(widget.serviceType)}',
          );
          return _PartnerCard(
            key: ValueKey('partner-${shop.id}'),
            shop: shop,
            distance: distance,
            minutes: listing.minutes,
            price: price,
            onSelected: select,
          );
        },
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    super.key,
    required this.shop,
    required this.distance,
    required this.minutes,
    required this.price,
    required this.onSelected,
  });
  final PartnerShop shop;
  final double distance;
  final int minutes;
  final int price;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      border: Border.all(color: HomeColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 60,
                decoration: BoxDecoration(
                  color: HomeColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: HomeColors.red,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.station.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (shop.station.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: VerifiedPartnerBadge(),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: HomeColors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${shop.station.rating.toStringAsFixed(1)} (${shop.station.completedRescues}+)  |  ≈ ${distance.toStringAsFixed(1)} km  |  ≈ $minutes phút',
                            style: const TextStyle(
                              color: HomeColors.secondary,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sửa được: ${shop.supportedVehicles}',
                      style: const TextStyle(
                        color: HomeColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Từ ${formatOrderPrice(price)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: HomeColors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      key: ValueKey('choose-${shop.id}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 40),
                      ),
                      onPressed: onSelected,
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
