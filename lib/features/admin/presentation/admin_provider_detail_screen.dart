import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/revo_brand.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_operation_models.dart';
import 'admin_formatters.dart';

/// Full-screen review detail for a pending provider application.
///
/// Mirrors the final "Chi tiết hồ sơ thợ" layout (cover, profile card, skill
/// chips, documents, bottom approve/reject bar) and is wired to the real
/// AdminOperationsController, so every field shown is live data from
/// GET /admin/providers/pending. Fields the backend does not store yet
/// (workshop photo, CCCD images) show an honest placeholder instead of a
/// fabricated value.
class AdminProviderDetailScreen extends ConsumerWidget {
  const AdminProviderDetailScreen({super.key, required this.providerId});

  final int providerId;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/admin/providers');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOperationsControllerProvider);

    ref.listen(adminOperationsControllerProvider, (previous, next) {
      final failure = next.value?.lastFailure;
      if (failure != null && previous?.value?.lastFailure != failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: RevoBrandColors.dangerDark,
              content: Text('Thao tác không thành công: $failure'),
            ),
          );
      }
    });

    return state.when(
      loading: () => const _DetailScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _DetailScaffold(
        body: _Message(
          icon: Icons.error_outline_rounded,
          text: 'Không tải được hồ sơ: $error',
        ),
      ),
      data: (data) {
        PendingProviderApplication? application;
        for (final item in data.pendingProviders) {
          if (item.id == providerId) {
            application = item;
            break;
          }
        }
        if (application == null) {
          return const _DetailScaffold(
            body: _Message(
              icon: Icons.inbox_outlined,
              text: 'Hồ sơ này đã được xử lý hoặc không còn trong hàng chờ.',
            ),
          );
        }
        return _DetailBody(
          application: application,
          busy: data.isBusy,
          acting: data.isBusy && data.actionTargetId == application.id,
          onBack: () => _back(context),
          onReview: (status) => _review(context, ref, application!, status),
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    PendingProviderApplication application,
    ProviderApprovalStatus status,
  ) async {
    final approve = status == ProviderApprovalStatus.approved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Duyệt hồ sơ thợ' : 'Từ chối hồ sơ thợ'),
        content: Text(
          approve
              ? 'Duyệt hồ sơ "${application.name}"? Thợ sẽ được kích hoạt và '
                    'có thể nhận đơn.'
              : 'Từ chối hồ sơ "${application.name}"? Thao tác này không thể '
                    'hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: approve
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: RevoBrandColors.dangerDark,
                  ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(approve ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .reviewProvider(providerId: application.id, status: status);
    if (context.mounted) _back(context);
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.application,
    required this.busy,
    required this.acting,
    required this.onBack,
    required this.onReview,
  });

  final PendingProviderApplication application;
  final bool busy;
  final bool acting;
  final VoidCallback onBack;
  final void Function(ProviderApprovalStatus status) onReview;

  @override
  Widget build(BuildContext context) {
    final canResolve =
        !busy && application.approvalStatus == ProviderApprovalStatus.pending;
    return Scaffold(
      backgroundColor: RevoBrandColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _cover(context)),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: RevoBrandColors.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileCard(application: application),
                  const SizedBox(height: 16),
                  _StatsCard(application: application),
                  const SizedBox(height: 16),
                  _SkillsCard(application: application),
                  if ((application.bio ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _BioCard(bio: application.bio!.trim()),
                  ],
                  const SizedBox(height: 16),
                  _DocumentsCard(application: application),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        application: application,
        acting: acting,
        onApprove: canResolve
            ? () => onReview(ProviderApprovalStatus.approved)
            : null,
        onReject: canResolve
            ? () => onReview(ProviderApprovalStatus.rejected)
            : null,
      ),
    );
  }

  Widget _cover(BuildContext context) => SizedBox(
    height: 220 + MediaQuery.paddingOf(context).top,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [RevoBrandColors.primary, RevoBrandColors.primaryDeep],
            ),
          ),
        ),
        const Positioned(
          right: -20,
          top: 30,
          child: Icon(
            Icons.engineering_rounded,
            size: 180,
            color: Color(0x1AFFFFFF),
          ),
        ),
        Positioned(
          top: 12 + MediaQuery.paddingOf(context).top,
          left: 12,
          child: IconButton.filled(
            tooltip: 'Quay lại',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RevoBrandColors.ink,
              minimumSize: const Size(44, 44),
            ),
            onPressed: busy ? null : onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                application.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _StatusChip(status: application.approvalStatus),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.application});
  final PendingProviderApplication application;

  @override
  Widget build(BuildContext context) {
    final contact = application.phone ?? application.email ?? 'Chưa có liên hệ';
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: RevoBrandColors.surfaceSoft,
            child: Icon(
              Icons.engineering_rounded,
              color: RevoBrandColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thợ cứu hộ xe máy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RevoBrandColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_rounded,
                      size: 15,
                      color: RevoBrandColors.textSubtle,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      contact,
                      style: const TextStyle(
                        color: RevoBrandColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (application.email != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    application.email!,
                    style: const TextStyle(
                      color: RevoBrandColors.textSubtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.application});
  final PendingProviderApplication application;

  @override
  Widget build(BuildContext context) {
    final chips = <(IconData, String)>[
      (
        Icons.workspace_premium_outlined,
        'Kinh nghiệm: ${application.yearsOfExperience ?? 0} năm',
      ),
      if (application.serviceRadiusKm != null)
        (
          Icons.my_location_rounded,
          'Bán kính: ${application.serviceRadiusKm!.toStringAsFixed(0)} km',
        ),
      if ((application.tier ?? '').isNotEmpty)
        (Icons.military_tech_outlined, 'Hạng: ${application.tier!}'),
      if (application.createdAt != null)
        (
          Icons.schedule_rounded,
          'Đăng ký: ${formatAdminDate(application.createdAt!)}',
        ),
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Thông tin hành nghề'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final (icon, label) in chips)
                Container(
                  decoration: BoxDecoration(
                    color: RevoBrandColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: RevoBrandColors.primary),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: RevoBrandColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.application});
  final PendingProviderApplication application;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Kỹ năng đăng ký'),
        const SizedBox(height: 12),
        if (application.skills.isEmpty)
          const Text(
            'Thợ chưa khai báo kỹ năng.',
            style: TextStyle(color: RevoBrandColors.textSubtle),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final skill in application.skills)
                Container(
                  decoration: BoxDecoration(
                    color: RevoBrandColors.successSoft,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: RevoBrandColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.build_rounded,
                        size: 15,
                        color: RevoBrandColors.successDark,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: RevoBrandColors.successDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.bio});
  final String bio;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Giới thiệu'),
        const SizedBox(height: 10),
        Text(
          bio,
          style: const TextStyle(
            color: RevoBrandColors.navy,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.application});
  final PendingProviderApplication application;

  @override
  Widget build(BuildContext context) {
    final hasDoc = (application.documentUrl ?? '').trim().isNotEmpty;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Giấy tờ & xác minh'),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                hasDoc
                    ? Icons.description_rounded
                    : Icons.description_outlined,
                size: 18,
                color: hasDoc
                    ? RevoBrandColors.primary
                    : RevoBrandColors.textSubtle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasDoc
                      ? application.documentUrl!
                      : 'Thợ chưa tải lên giấy tờ hành nghề.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: hasDoc
                        ? RevoBrandColors.primaryDeep
                        : RevoBrandColors.textSubtle,
                    fontWeight: hasDoc ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RevoBrandColors.warningSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: RevoBrandColors.warningDark,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ảnh CCCD mặt trước/sau sẽ hiển thị khi thợ bổ sung trong '
                    'hồ sơ. Vui lòng đối chiếu giấy tờ trước khi duyệt.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: RevoBrandColors.warningDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.application,
    required this.acting,
    required this.onApprove,
    required this.onReject,
  });

  final PendingProviderApplication application;
  final bool acting;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Container(
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
      minimum: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mã hồ sơ #${application.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: RevoBrandColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Hồ sơ đăng ký mới',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: RevoBrandColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: RevoBrandColors.dangerDark,
                side: const BorderSide(color: RevoBrandColors.danger),
                minimumSize: const Size(0, 46),
                padding: EdgeInsets.zero,
              ),
              child: const Text('Từ chối'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: FilledButton(
              onPressed: onApprove,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              child: acting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Duyệt hồ sơ'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ProviderApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ProviderApprovalStatus.pending => 'Chờ duyệt',
      ProviderApprovalStatus.approved => 'Đã duyệt',
      ProviderApprovalStatus.rejected => 'Từ chối',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: RevoBrandColors.primaryDeep,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: RevoBrandColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: RevoBrandColors.border),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: RevoBrandColors.ink,
    ),
  );
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RevoBrandColors.bg,
    appBar: AppBar(
      backgroundColor: RevoBrandColors.bg,
      foregroundColor: RevoBrandColors.ink,
      title: const Text('Chi tiết hồ sơ thợ'),
    ),
    body: SafeArea(child: body),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: RevoBrandColors.textSubtle),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
