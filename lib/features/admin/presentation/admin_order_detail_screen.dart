import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm_map;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as osm;

import '../../../app/app_dependencies.dart';
import '../../../core/theme/revo_brand.dart';
import '../domain/admin_operation_models.dart';
import 'admin_formatters.dart';

final adminOrderDetailProvider = FutureProvider.autoDispose
    .family<AdminOrderDetail, int>((ref, orderId) async {
      return ref.read(adminRepositoryProvider).getOrderDetail(orderId);
    });

/// Read-only admin view of a single order: customer, provider, location and
/// pricing. No money actions here (those live in the finance/reconciliation
/// screens with the manual-transfer guardrail).
class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminOrderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: RevoBrandColors.bg,
      appBar: AppBar(
        backgroundColor: RevoBrandColors.bg,
        foregroundColor: RevoBrandColors.ink,
        title: const Text(
          'Chi tiết đơn',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không tải được chi tiết đơn.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(adminOrderDetailProvider(orderId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (order) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: RevoBrandColors.ink,
                          ),
                        ),
                      ),
                      _StatusChip(label: adminOrderStatusLabel(order.status)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tạo lúc ${formatAdminDateTime(order.createdAt)}',
                    style: const TextStyle(
                      color: RevoBrandColors.textSubtle,
                      fontSize: 12,
                    ),
                  ),
                  if (order.incidentType != null) ...[
                    const SizedBox(height: 4),
                    Text('Sự cố: ${order.incidentType}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: _PartySection(
                icon: Icons.person_outline_rounded,
                title: 'Khách hàng',
                name: order.customer?.name ?? 'Chưa có thông tin',
                phone: order.customer?.phone,
                extra: order.customer?.address,
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: _PartySection(
                icon: Icons.handyman_outlined,
                title: 'Thợ cứu hộ',
                name: order.provider?.name ?? 'Chưa có thợ nhận đơn',
                phone: order.provider?.phone,
              ),
            ),
            if (order.customerLatitude != null &&
                order.customerLongitude != null) ...[
              const SizedBox(height: 12),
              _MapCard(order: order),
            ],
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chi phí',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  _PriceRow(
                    'Giá tạm tính',
                    formatAdminMoney(order.estimatedPrice),
                  ),
                  _PriceRow('Phát sinh', formatAdminMoney(order.extraCost)),
                  _PriceRow(
                    'Giảm giá',
                    '- ${formatAdminMoney(order.discountAmount)}',
                  ),
                  const Divider(height: 20),
                  _PriceRow(
                    'Giá cuối',
                    order.finalPrice == null
                        ? 'Chưa chốt'
                        : formatAdminMoney(order.finalPrice!),
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.order});

  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final customer = osm.LatLng(
      order.customerLatitude!,
      order.customerLongitude!,
    );
    final hasProvider =
        order.provider?.latitude != null && order.provider?.longitude != null;
    final provider = hasProvider
        ? osm.LatLng(order.provider!.latitude!, order.provider!.longitude!)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: osm_map.FlutterMap(
          options: osm_map.MapOptions(initialCenter: customer, initialZoom: 14),
          children: [
            osm_map.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.motocare.app',
              maxNativeZoom: 19,
            ),
            osm_map.MarkerLayer(
              markers: [
                osm_map.Marker(
                  point: customer,
                  width: 40,
                  height: 40,
                  child: const _Pin(
                    color: RevoBrandColors.danger,
                    icon: Icons.person_pin_circle_rounded,
                  ),
                ),
                if (provider != null)
                  osm_map.Marker(
                    point: provider,
                    width: 40,
                    height: 40,
                    child: const _Pin(
                      color: RevoBrandColors.primary,
                      icon: Icons.two_wheeler_rounded,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}

class _PartySection extends StatelessWidget {
  const _PartySection({
    required this.icon,
    required this.title,
    required this.name,
    this.phone,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String name;
  final String? phone;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: RevoBrandColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: RevoBrandColors.textSubtle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (phone != null && phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(phone!, style: const TextStyle(color: RevoBrandColors.ink)),
        ],
        if (extra != null && extra!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            extra!,
            style: const TextStyle(color: RevoBrandColors.textSubtle),
          ),
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasize ? 17 : 14,
            color: RevoBrandColors.ink,
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: RevoBrandColors.border),
    ),
    child: child,
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: RevoBrandColors.surfaceSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: RevoBrandColors.primaryDeep,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
