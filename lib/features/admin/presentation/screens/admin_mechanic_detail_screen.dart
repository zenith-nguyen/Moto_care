import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/admin_tokens.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/admin_mechanic_theme.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_action_dialog.dart';
import '../../widgets/admin_common.dart';
import '../../widgets/admin_mechanic_detail_cards.dart';
import '../../widgets/admin_mechanic_gallery.dart';

void _backToApplications(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/admin/providers');
  }
}

/// Resolves direct links through the authenticated repository.
class AdminMechanicDetailRoute extends ConsumerWidget {
  const AdminMechanicDetailRoute({super.key, required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adminSessionProvider)?.isAdmin != true) {
      return const _MechanicStatePage(child: AdminStateView.forbidden());
    }
    final value = ref.watch(adminProviderDetailProvider(providerId));
    Widget state() => _MechanicStatePage(
      child: AdminAsyncSection(
        value: value,
        onRetry: () {
          ref.invalidate(adminProvidersProvider);
          ref.invalidate(adminProviderDetailProvider(providerId));
        },
        isEmpty: (application) => application == null,
        builder: (_) => const SizedBox.shrink(),
      ),
    );
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: state,
      error: (_, stack) => state(),
      data: (application) => application == null
          ? state()
          : AdminMechanicDetailScreen(
              key: ValueKey(application.id),
              application: application,
            ),
    );
  }
}

/// Can also be embedded with a supplied application; no sample identity is
/// stored in this view. Decisions use the existing confirmation/retry flow.
class AdminMechanicDetailScreen extends ConsumerStatefulWidget {
  const AdminMechanicDetailScreen({super.key, required this.application});
  final AdminProviderApplication application;

  @override
  ConsumerState<AdminMechanicDetailScreen> createState() =>
      _AdminMechanicDetailScreenState();
}

class _AdminMechanicDetailScreenState
    extends ConsumerState<AdminMechanicDetailScreen> {
  bool _bookmarked = false;

  Future<void> _resolve(bool approve) async {
    final session = ref.read(adminSessionProvider);
    final application = widget.application;
    final success = await showAdminAction(
      context,
      kind: AdminActionKind.provider,
      id: application.id,
      approve: approve,
      title: approve ? 'Duyệt hồ sơ thợ' : 'Từ chối hồ sơ thợ',
      description: approve
          ? 'Cấp quyền hoạt động cho ${application.name} (${application.id})?'
          : '${application.name} • ${application.id}',
      noteRequired: !approve,
    );
    if (mounted && success && ref.read(adminSessionProvider) == session) {
      _backToApplications(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(adminSessionProvider)?.isAdmin != true) {
      return const _MechanicStatePage(child: AdminStateView.forbidden());
    }
    final busy = ref.watch(adminActionProvider).isLoading;
    final application = widget.application;
    final canResolve = !busy && application.status == AdminReviewStatus.pending;
    return Theme(
      data: AdminTheme.light,
      child: PopScope(
        canPop: !busy,
        child: Scaffold(
          backgroundColor: AdminMechanicTheme.backdrop,
          body: CustomScrollView(
            key: const PageStorageKey('admin-mechanic-detail-scroll'),
            slivers: [
              SliverToBoxAdapter(child: _cover(context, application, busy)),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  application.name,
                                  style: AdminMechanicTheme.title,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                flex: 2,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AdminStatusChip(
                                    application.status ==
                                            AdminReviewStatus.pending
                                        ? 'Chờ duyệt'
                                        : application.status.label,
                                    color: adminReviewColor(application.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AdminMechanicProfileCard(application: application),
                          const SizedBox(height: 24),
                          AdminMechanicFeatures(application: application),
                          const SizedBox(height: 24),
                          AdminMechanicDocuments(application: application),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AdminMechanicActionBar(
            application: application,
            onApprove: canResolve ? () => _resolve(true) : null,
            onReject: canResolve ? () => _resolve(false) : null,
          ),
        ),
      ),
    );
  }

  Widget _cover(
    BuildContext context,
    AdminProviderApplication application,
    bool busy,
  ) => SizedBox(
    height: 310 + MediaQuery.paddingOf(context).top,
    child: Stack(
      fit: StackFit.expand,
      children: [
        AdminMechanicImage(
          photo: application.workshopPhoto,
          emptyLabel: 'Chưa có ảnh tiệm sửa xe',
          emptyIcon: Icons.storefront_outlined,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66000000),
                Color(0x00000000),
                AdminMechanicTheme.backdrop,
              ],
              stops: [0, 0.4, 1],
            ),
          ),
        ),
        Positioned(
          top: 12 + MediaQuery.paddingOf(context).top,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filled(
                tooltip: 'Quay lại hồ sơ thợ',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AdminMechanicTheme.backdrop,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: busy ? null : () => _backToApplications(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              IconButton.filled(
                tooltip: _bookmarked ? 'Bỏ đánh dấu hồ sơ' : 'Đánh dấu hồ sơ',
                isSelected: _bookmarked,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AdminTokens.primaryBlue,
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () => setState(() => _bookmarked = !_bookmarked),
                icon: const Icon(Icons.bookmark_border_rounded),
                selectedIcon: const Icon(Icons.bookmark_rounded),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AdminMechanicGallery(application: application),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MechanicStatePage extends StatelessWidget {
  const _MechanicStatePage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: AdminTheme.light,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ thợ'),
        leading: BackButton(onPressed: () => _backToApplications(context)),
      ),
      body: SafeArea(child: SingleChildScrollView(child: child)),
    ),
  );
}
