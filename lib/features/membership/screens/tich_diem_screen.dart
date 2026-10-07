import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/service_scaffold.dart';
import '../../home/models/home_destination.dart';
import '../../home/models/home_user.dart';
import '../../home/theme/home_theme.dart';
import '../../profile/providers/profile_provider.dart';

class TichDiemScreen extends ConsumerWidget {
  const TichDiemScreen({super.key, this.user});
  final HomeUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).profile;
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName
        : (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName
        : 'Thành viên MotoCare';
    final id = profile.id.isNotEmpty ? profile.id : user?.memberId ?? '—';
    return ServiceScaffold(
      title: 'Tích điểm & Hạng thành viên',
      selectedDestination: HomeDestination.account,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HomeColors.tintStrong,
                  HomeColors.selected,
                  HomeColors.tint,
                ],
              ),
              border: Border.all(color: HomeColors.accentBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      color: ServiceColors.gold,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MOTOCARE',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: ServiceColors.gold,
                      size: 34,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: $id',
                  style: const TextStyle(color: ServiceColors.muted),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HẠNG HIỆN TẠI',
                          style: TextStyle(
                            fontSize: 12,
                            color: ServiceColors.muted,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Vàng',
                          style: TextStyle(
                            color: ServiceColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG ĐIỂM',
                          style: TextStyle(
                            fontSize: 12,
                            color: ServiceColors.muted,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '350 điểm',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const ServiceSectionTitle('Hành trình lên hạng'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hạng tiếp theo: Bạch Kim',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(
                    value: 350 / 500,
                    minHeight: 10,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: ServiceColors.gold,
                    backgroundColor: ServiceColors.border,
                    semanticsLabel:
                        'Tiến độ lên hạng Bạch Kim: 350 trên 500 điểm',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '350 / 500 điểm',
                    style: TextStyle(color: ServiceColors.gold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tích thêm 150 điểm để lên hạng Bạch Kim.',
                    style: TextStyle(color: ServiceColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const ServiceSectionTitle('Đặc quyền thành viên'),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 74 + MediaQuery.textScalerOf(context).scale(62),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (icon, label) in const [
                (Icons.fact_check_outlined, 'Miễn phí kiểm tra'),
                (Icons.engineering_outlined, 'Ưu tiên thợ'),
                (Icons.nightlight_round, 'Giảm giá đêm'),
                (Icons.cake_outlined, 'Quà sinh nhật'),
              ])
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: ServiceColors.gold, size: 30),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const ServiceSectionTitle('Lịch sử tích điểm'),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final (points, title, date) = const [
                ('+50 điểm', 'Đơn SOS #MC8821', '02/10/2026'),
                ('-100 điểm', 'Đổi Voucher 20k', '30/09/2026'),
                ('+40 điểm', 'Đơn SOS #MC8750', '28/09/2026'),
              ][index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    points.startsWith('+')
                        ? Icons.add_circle_outline
                        : Icons.redeem,
                    color: ServiceColors.orange,
                  ),
                  title: Text(
                    '$points - $title',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(date),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
