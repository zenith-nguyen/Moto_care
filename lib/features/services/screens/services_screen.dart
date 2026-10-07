import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/theme/home_theme.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../../home/widgets/home_service_grid.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  void _openService(BuildContext context, HomeService service) =>
      context.push(service.partnerRoute);

  @override
  Widget build(BuildContext context) => Theme(
    data: HomeTheme.light,
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Dịch vụ'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionTitle(
                    title: 'Cứu hộ khẩn cấp SOS',
                    subtitle: 'Chọn dịch vụ phù hợp với sự cố của bạn',
                    icon: Icons.sos_rounded,
                  ),
                  const SizedBox(height: 16),
                  _ServiceGrid(
                    columns: 3,
                    children: [
                      for (final (service, label) in const [
                        (HomeService.tire, 'Vá xe / Săm'),
                        (HomeService.battery, 'Kích bình ắc quy'),
                        (HomeService.fuel, 'Cứu hộ hết xăng'),
                        (HomeService.flood, 'Sửa xe ngập nước'),
                        (HomeService.towing, 'Xe cẩu kéo'),
                        (HomeService.night, 'Cứu hộ đêm 24/7'),
                      ])
                        ServiceTile(
                          key: ValueKey('service-${service.name}'),
                          label: label,
                          icon: service.icon,
                          color: service.color,
                          onTap: () => _openService(context, service),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    title: 'Chăm sóc & Tiện ích xe',
                    subtitle: 'Chăm xe mỗi ngày, an tâm mỗi chuyến đi',
                    icon: Icons.two_wheeler_rounded,
                  ),
                  const SizedBox(height: 16),
                  _ServiceGrid(
                    columns: 4,
                    children: [
                      for (final service in const [
                        HomeService.maintenance,
                        HomeService.charging,
                      ])
                        ServiceTile(
                          key: ValueKey('service-${service.name}'),
                          label: service.label,
                          icon: service.icon,
                          color: service.color,
                          onTap: () => _openService(context, service),
                        ),
                      for (final (id, label, icon, color, route) in const [
                        (
                          'prices',
                          'Bảng giá\nphụ tùng',
                          Icons.receipt_long_rounded,
                          Color(0xFF2563EB),
                          '/bang-gia',
                        ),
                        (
                          'tips',
                          'Mẹo tự xử lý\nsự cố',
                          Icons.lightbulb_outline_rounded,
                          Color(0xFFF9A825),
                          '/meo-xu-ly',
                        ),
                      ])
                        ServiceTile(
                          key: ValueKey('service-$id'),
                          label: label,
                          icon: icon,
                          color: color,
                          onTap: () => context.push(route),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Material(
                    color: HomeColors.selected,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(
                        Icons.location_on_rounded,
                        color: HomeColors.red,
                      ),
                      title: const Text(
                        'Tìm trạm cứu hộ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Xem danh sách trạm và thông tin liên hệ',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/tram-cuu-ho'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: HomeBottomNavigation(
          light: true,
          selectedDestination: HomeDestination.services,
          onSelected: (destination) => navigateMainTab(context, destination),
        ),
      ),
    ),
  );
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return GridView.count(
      crossAxisCount: columns,
      mainAxisExtent: (columns == 4 ? 142 : 122) + (scale - 1) * 120,
      crossAxisSpacing: 8,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: HomeColors.selected,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: HomeColors.red),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                color: HomeColors.secondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
