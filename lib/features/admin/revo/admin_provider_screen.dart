import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_operation_models.dart';
import 'revo_admin_style.dart';
import 'revo_provider_view.dart';

/// Provider approval in the REVO prototype look. The queue + the Duyệt/Từ chối
/// actions are wired to the real backend (adminOperationsController); the richer
/// KYC fields shown on the detail screen are demo placeholders (see
/// [ProviderProfileView]). Rendered inside AdminShell.
class RevoAdminProviderApprovalScreen extends ConsumerWidget {
  const RevoAdminProviderApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOperationsControllerProvider);

    ref.listen(adminOperationsControllerProvider, (previous, next) {
      final failure = next.value?.lastFailure;
      if (failure != null && previous?.value?.lastFailure != failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Thao tác không thành công: $failure')),
          );
      }
    });

    return ColoredBox(
      color: AdminTokens.background,
      child: Column(
        children: [
          _AdminScreenHeader(title: 'Duyệt hồ sơ thợ'),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Retry(
                message: 'Không tải được hàng chờ duyệt.',
                onRetry: () =>
                    ref.invalidate(adminOperationsControllerProvider),
              ),
              data: (data) {
                final items = data.pendingProviders;
                if (items.isEmpty) {
                  return const _EmptyState(
                    message: 'Không có hồ sơ thợ nào chờ duyệt.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminOperationsControllerProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final view = ProviderProfileView.fromApplication(
                        items[index],
                      );
                      return _ReviewCard(
                        view: view,
                        onDetail: () => context.push(
                          '/admin/providers/${view.id}',
                          extra: items[index],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen provider detail (pushed outside the shell), matching the
/// prototype mechanic profile. Duyệt/Từ chối are real; KYC visuals are demo.
class RevoAdminProviderDetailScreen extends ConsumerWidget {
  const RevoAdminProviderDetailScreen({
    super.key,
    required this.providerId,
    this.application,
  });

  final int providerId;
  final PendingProviderApplication? application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOperationsControllerProvider);
    PendingProviderApplication? found;
    for (final p in state.value?.pendingProviders ?? const []) {
      if (p.id == providerId) {
        found = p;
        break;
      }
    }
    final app = application ?? found;

    if (app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết hồ sơ thợ')),
        body: const _EmptyState(
          message: 'Hồ sơ không còn trong hàng chờ (đã được xử lý).',
        ),
      );
    }

    final view = ProviderProfileView.fromApplication(app);
    final busy = state.value?.isBusy ?? false;

    return Scaffold(
      backgroundColor: AdminTokens.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DetailHero(view: view)),
          SliverToBoxAdapter(child: _DetailBody(view: view)),
        ],
      ),
      bottomNavigationBar: _DetailActionBar(
        view: view,
        busy: busy,
        onDecision: (status) => _review(context, ref, view, status),
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    ProviderProfileView view,
    ProviderApprovalStatus status,
  ) async {
    final approve = status == ProviderApprovalStatus.approved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Duyệt hồ sơ thợ' : 'Từ chối hồ sơ thợ'),
        content: Text(
          approve
              ? 'Duyệt hồ sơ "${view.name}"? Thợ sẽ được kích hoạt và có thể '
                    'nhận đơn.'
              : 'Từ chối hồ sơ "${view.name}"? Thao tác này không thể hoàn tác.',
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
                    backgroundColor: AdminTokens.primaryRed,
                  ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(approve ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .reviewProvider(providerId: view.id, status: status);
    if (!context.mounted) return;
    final failure = ref
        .read(adminOperationsControllerProvider)
        .value
        ?.lastFailure;
    if (failure == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Đã duyệt hồ sơ thợ.' : 'Đã từ chối hồ sơ thợ.',
            ),
          ),
        );
      if (context.canPop()) context.pop();
    }
  }
}

// ---------------------------------------------------------------------------
// List card (replicates the prototype AdminReviewCard)
// ---------------------------------------------------------------------------

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.view, required this.onDetail});

  final ProviderProfileView view;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: revoCardDecoration(color: AdminTokens.card),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã hồ sơ:', style: _label),
                  const SizedBox(height: 4),
                  Text(
                    '${view.code} • ${view.name}',
                    style: revoFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AdminTokens.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusBadge(status: view.status),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Field(
                label: 'Email / SĐT',
                value: '${view.email}\n${view.phone}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Field(label: 'Thông tin xe', value: view.vehicle),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Field(label: 'Biển số', value: view.plate),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Field(
                label: 'Thời gian đăng ký',
                value: DateFormat('dd/MM/yyyy HH:mm').format(view.registeredAt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ReviewProgress(status: view.status),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onDetail,
            style: TextButton.styleFrom(
              backgroundColor: AdminTokens.activePill,
              foregroundColor: AdminTokens.primaryBlue,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              textStyle: revoFont(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Chi tiết'),
          ),
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _label),
      const SizedBox(height: 4),
      Text(
        value,
        style: revoFont(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AdminTokens.text,
          height: 1.4,
          letterSpacing: -0.2,
        ),
      ),
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProviderApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      ProviderApprovalStatus.pending => (
        const Color(0xFFFFF4DE),
        AdminTokens.warning,
        'Chờ xử lý',
      ),
      ProviderApprovalStatus.approved => (
        AdminTokens.activePill,
        AdminTokens.primaryBlue,
        'Đã duyệt',
      ),
      ProviderApprovalStatus.rejected => (
        const Color(0xFFFFEBEE),
        AdminTokens.primaryRed,
        'Đã từ chối',
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: revoFont(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }
}

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.status});

  final ProviderApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final completed = status == ProviderApprovalStatus.pending ? 1 : 3;
    const labels = ['Đã nhận hồ sơ', 'Đang xét duyệt', 'Đã xong'];
    const pending = Color(0xFFD1D1D6);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: 24,
            child: Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth / 6,
                  right: constraints.maxWidth / 6,
                  top: 11,
                  child: Row(
                    children: [
                      for (var i = 1; i < 3; i++)
                        Expanded(
                          child: ColoredBox(
                            color: i < completed ? AdminTokens.text : pending,
                            child: const SizedBox(height: 2),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Center(
                          child: i < completed
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 24,
                                  color: AdminTokens.text,
                                )
                              : const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: pending,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SizedBox(width: 24, height: 24),
                                ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: revoFont(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AdminTokens.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detail screen pieces
// ---------------------------------------------------------------------------

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.view});

  final ProviderProfileView view;

  @override
  Widget build(BuildContext context) => Container(
    height: 280 + MediaQuery.paddingOf(context).top,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2A4A5A), Color(0xFF3E6274)],
      ),
    ),
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.paddingOf(context).top + 8,
      16,
      16,
    ),
    child: Column(
      children: [
        Row(
          children: [
            _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go('/admin/providers'),
            ),
            const Spacer(),
            _CircleButton(icon: Icons.bookmark_border_rounded, onTap: () {}),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            _GalleryThumb(icon: Icons.storefront_rounded, label: 'Cơ sở'),
            const SizedBox(width: 10),
            _GalleryThumb(icon: Icons.badge_outlined, label: 'CCCD trước'),
            const SizedBox(width: 10),
            _GalleryThumb(icon: Icons.badge_outlined, label: 'CCCD sau'),
            const SizedBox(width: 10),
            _GalleryThumb(icon: Icons.person_rounded, label: 'Chân dung'),
          ],
        ),
      ],
    ),
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: AdminTokens.text, size: 22),
      ),
    ),
  );
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: revoFont(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.view});

  final ProviderProfileView view;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -20),
    child: Container(
      decoration: const BoxDecoration(
        color: AdminTokens.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  view.name,
                  style: revoFont(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              _StatusBadge(status: view.status),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: revoCardDecoration(color: AdminTokens.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AdminTokens.activePill,
                      child: Icon(
                        Icons.engineering_rounded,
                        color: AdminTokens.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thợ cứu hộ xe máy',
                            style: revoFont(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AdminTokens.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            view.phone,
                            style: revoFont(
                              fontSize: 13,
                              color: AdminTokens.muted,
                            ),
                          ),
                          Text(
                            view.email,
                            style: revoFont(
                              fontSize: 12,
                              color: AdminTokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AdminTokens.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        view.address,
                        style: revoFont(fontSize: 13, color: AdminTokens.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Trang bị & Kỹ năng',
            style: revoFont(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AdminTokens.text,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final chip in [
                view.vehicle.split(' • ').first,
                view.vehicle.contains(' • ')
                    ? view.vehicle.split(' • ').last
                    : 'Bộ dụng cụ cứu hộ',
                'Chưa xác minh CCCD',
                'Thời gian ĐK: ${DateFormat('dd/MM/yyyy').format(view.registeredAt)}',
              ])
                _SkillChip(label: chip),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: revoCardDecoration(color: AdminTokens.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giấy tờ & CCCD',
                  style: revoFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                  ),
                ),
                const SizedBox(height: 12),
                _KvRow(label: 'Số CCCD', value: view.citizenIdMasked),
                const SizedBox(height: 8),
                _KvRow(label: 'Biển số xe', value: view.plate),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: AdminTokens.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AdminTokens.border),
    ),
    child: Text(
      label,
      style: revoFont(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AdminTokens.text,
        letterSpacing: -0.2,
      ),
    ),
  );
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: revoFont(fontSize: 13, color: AdminTokens.muted),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: revoFont(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AdminTokens.text,
          ),
        ),
      ),
    ],
  );
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.view,
    required this.busy,
    required this.onDecision,
  });

  final ProviderProfileView view;
  final bool busy;
  final ValueChanged<ProviderApprovalStatus> onDecision;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  view.code,
                  style: revoFont(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                  ),
                ),
                Text(
                  'Hồ sơ đăng ký mới',
                  style: revoFont(fontSize: 11, color: AdminTokens.muted),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => onDecision(ProviderApprovalStatus.rejected),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTokens.primaryRed,
              side: const BorderSide(color: Color(0xFFF3C0C0)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('Từ chối'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: busy
                ? null
                : () => onDecision(ProviderApprovalStatus.approved),
            style: FilledButton.styleFrom(
              backgroundColor: AdminTokens.primaryBlue,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: const Text('Duyệt hồ sơ'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _AdminScreenHeader extends StatelessWidget {
  const _AdminScreenHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      MediaQuery.paddingOf(context).top + 14,
      16,
      12,
    ),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: revoFont(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AdminTokens.text,
        letterSpacing: -0.3,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 44,
            color: AdminTokens.success,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: revoFont(fontSize: 13, color: AdminTokens.muted),
          ),
        ],
      ),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AdminTokens.muted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: revoFont(fontSize: 13, color: AdminTokens.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

final _label = revoFont(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  color: AdminTokens.muted,
  letterSpacing: -0.2,
);
