import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../theme/admin_mechanic_theme.dart';
import 'admin_mechanic_gallery.dart';

class AdminMechanicProfileCard extends StatelessWidget {
  const AdminMechanicProfileCard({super.key, required this.application});
  final AdminProviderApplication application;

  @override
  Widget build(BuildContext context) => Container(
    decoration: AdminMechanicTheme.card,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Chân dung ${application.name}',
              child: ClipOval(
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: AdminMechanicImage(
                    photo: application.portraitPhoto,
                    emptyLabel: '',
                    emptyIcon: Icons.person_outline_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thợ cứu hộ xe máy',
                    style: AdminMechanicTheme.heading,
                  ),
                  const SizedBox(height: 5),
                  Text(application.phone, style: AdminMechanicTheme.value),
                  const SizedBox(height: 2),
                  Text(application.email, style: AdminMechanicTheme.label),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AdminTokens.primaryBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                application.workshopAddress ?? 'Chưa cập nhật địa chỉ xưởng',
                style: AdminMechanicTheme.value,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class AdminMechanicFeatures extends StatelessWidget {
  const AdminMechanicFeatures({super.key, required this.application});
  final AdminProviderApplication application;

  @override
  Widget build(BuildContext context) {
    final equipment = application.vehicle
        .split('•')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final features = [
      for (var i = 0; i < equipment.length; i++)
        (
          i == 0
              ? Icons.two_wheeler_outlined
              : Icons.home_repair_service_outlined,
          equipment[i],
        ),
      (
        application.identityVerified
            ? Icons.verified_user_outlined
            : Icons.badge_outlined,
        application.identityVerified
            ? 'Đã xác minh CCCD'
            : 'Chưa xác minh CCCD',
      ),
      (
        Icons.schedule_rounded,
        'Thời gian ĐK: ${DateFormat('dd/MM/yyyy').format(application.registeredAt)}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Trang bị & Kỹ năng', style: AdminMechanicTheme.heading),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final (icon, label) in features)
              Container(
                decoration: BoxDecoration(
                  color: AdminTokens.card,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17, color: AdminTokens.neutral),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        style: AdminMechanicTheme.label.copyWith(
                          color: AdminTokens.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class AdminMechanicDocuments extends StatelessWidget {
  const AdminMechanicDocuments({super.key, required this.application});
  final AdminProviderApplication application;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('admin-mechanic-documents'),
    decoration: AdminMechanicTheme.card,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Giấy tờ & CCCD', style: AdminMechanicTheme.heading),
        const SizedBox(height: 12),
        const Text('Thông tin CCCD', style: AdminMechanicTheme.label),
        const SizedBox(height: 3),
        Text(
          application.citizenIdMasked ?? 'Chưa cập nhật',
          style: AdminMechanicTheme.value,
        ),
        const SizedBox(height: 10),
        const Text('Biển số xe', style: AdminMechanicTheme.label),
        const SizedBox(height: 3),
        Text(application.plate, style: AdminMechanicTheme.value),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _document(
                context,
                'front',
                'Mặt trước CCCD',
                application.identityFrontPhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _document(
                context,
                'back',
                'Mặt sau CCCD',
                application.identityBackPhoto,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _document(
    BuildContext context,
    String slot,
    String label,
    AdminMechanicPhoto? photo,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        key: ValueKey('admin-mechanic-document-$slot'),
        onTap: photo == null
            ? null
            : () => showAdminMechanicGallery(context, application, photo),
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 92,
            child: AdminMechanicImage(
              photo: photo,
              emptyIcon: Icons.badge_outlined,
            ),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Text(label, textAlign: TextAlign.center, style: AdminMechanicTheme.label),
    ],
  );
}

class AdminMechanicActionBar extends StatelessWidget {
  const AdminMechanicActionBar({
    super.key,
    required this.application,
    required this.onApprove,
    required this.onReject,
  });
  final AdminProviderApplication application;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('admin-mechanic-action-bar'),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                application.id,
                style: AdminMechanicTheme.heading.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                application.status == AdminReviewStatus.pending
                    ? 'Hồ sơ đăng ký mới'
                    : application.status.label,
                style: AdminMechanicTheme.label,
              ),
            ],
          );
          final buttons = Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const ValueKey('admin-mechanic-reject'),
                  onPressed: onReject,
                  style: _button(
                    const Color(0xFFFFEBEE),
                    const Color(0xFFD32F2F),
                    FontWeight.w600,
                  ),
                  child: const Text('Từ chối', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const ValueKey('admin-mechanic-approve'),
                  onPressed: onApprove,
                  style: _button(
                    AdminTokens.primaryBlue,
                    Colors.white,
                    FontWeight.bold,
                  ),
                  child: const Text('Duyệt hồ sơ', textAlign: TextAlign.center),
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.2) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 12), buttons],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: identity),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: buttons),
            ],
          );
        },
      ),
    ),
  );

  ButtonStyle _button(Color background, Color foreground, FontWeight weight) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        textStyle: AdminMechanicTheme.value.copyWith(
          fontSize: 12,
          fontWeight: weight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
}
