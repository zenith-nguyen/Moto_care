import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/widgets/order_summary.dart';
import '../../home/providers/home_provider.dart';
import '../../home/theme/home_theme.dart';
import '../../rescue/models/marketplace_booking.dart';
import '../providers/partner_provider.dart';
import '../widgets/marketplace_widgets.dart';

class PartnerDetailScreen extends ConsumerStatefulWidget {
  const PartnerDetailScreen({
    super.key,
    required this.partnerId,
    required this.serviceType,
  });
  final String partnerId;
  final String serviceType;
  @override
  ConsumerState<PartnerDetailScreen> createState() =>
      _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends ConsumerState<PartnerDetailScreen> {
  final _quantities = <String, int>{};
  @override
  Widget build(BuildContext context) {
    final matches = ref
        .watch(partnerShopsProvider)
        .where((shop) => shop.id == widget.partnerId);
    final shop = matches.isEmpty ? null : matches.first;
    if (shop == null) {
      return const MarketplaceScaffold(
        title: 'Thông tin tiệm',
        body: Center(child: Text('Tiệm không còn trong danh sách.')),
      );
    }
    final distance = stationDistanceKm(
      shop.station,
      ref.watch(rescueLocationProvider),
    );
    final menu = shop.menu(widget.serviceType);
    final selected = [
      for (final package in menu)
        if ((_quantities[package.id] ?? 0) > 0)
          package.item(_quantities[package.id]!),
    ];
    final booking = MarketplaceBooking(
      partnerId: shop.id,
      serviceType: widget.serviceType,
      items: selected,
    );
    return MarketplaceScaffold(
      title: 'Chi tiết tiệm',
      body: ListView(
        children: [
          MarketplaceSection(
            title: shop.station.name,
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 64,
                color: HomeColors.red,
              ),
              const SizedBox(height: 16),
              if (shop.station.isVerified) const VerifiedPartnerBadge(),
              const SizedBox(height: 12),
              Text(
                shop.station.address,
                style: const TextStyle(
                  color: HomeColors.secondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: HomeColors.red,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${shop.station.rating.toStringAsFixed(1)} (${shop.station.completedRescues}+)  •  Cách bạn ≈ ${distance.toStringAsFixed(1)} km',
                      style: const TextStyle(color: HomeColors.secondary),
                    ),
                  ),
                ],
              ),
              if (!shop.station.isOpen)
                const Text(
                  'Tiệm đang đóng cửa',
                  style: TextStyle(color: HomeColors.red),
                ),
            ],
          ),
          MarketplaceSection(
            title: widget.serviceType,
            children: [
              if (menu.isEmpty) const Text('Tiệm chưa có gói dịch vụ phù hợp.'),
              for (final package in menu)
                Container(
                  key: ValueKey('package-${package.id}'),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: HomeColors.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            formatOrderPrice(package.price),
                            style: const TextStyle(
                              color: HomeColors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          QuantityControl(
                            quantity: _quantities[package.id] ?? 0,
                            onChanged: (quantity) => setState(
                              () => _quantities[package.id] = quantity,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            children: [
              Text('${booking.quantity} dịch vụ đã chọn'),
              Text(
                formatOrderPrice(booking.subtotal),
                style: const TextStyle(
                  color: HomeColors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('marketplace-continue'),
            onPressed: booking.isValidFor(shop)
                ? () => context.push('/checkout', extra: booking)
                : null,
            child: const Text(
              'TIẾP TỤC THANH TOÁN',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
