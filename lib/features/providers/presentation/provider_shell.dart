import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/revo_brand.dart';
import '../../../core/theme/revo_theme.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../auth/domain/app_user.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_status.dart';
import '../../wallet/application/provider_wallet_controller.dart';
import '../../wallet/domain/wallet_models.dart';
import '../application/provider_location_tracking_controller.dart';
import '../application/provider_location_tracking_state.dart';
import '../application/provider_work_controller.dart';
import '../application/provider_work_state.dart';
import '../application/professional_profile_provider.dart';
import '../domain/provider_models.dart';
import '../domain/professional_profile.dart';
import 'provider_formatters.dart';
import 'provider_incoming_offer.dart';

class ProviderShell extends ConsumerStatefulWidget {
  const ProviderShell({super.key});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  var _index = 0;

  /// Offer ids already surfaced as a full-screen incoming request, so a silent
  /// realtime refresh does not re-pop the same request.
  final Set<int> _announcedOffers = <int>{};
  bool _offerDialogOpen = false;
  bool _offersInitialized = false;

  static const _titles = ['Tổng quan', 'Đơn cứu hộ', 'Ví sandbox', 'Tài khoản'];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (session is SessionSignedIn &&
        session.session.user.status == AppUserStatus.pendingApproval) {
      return _PendingProviderApprovalPage(user: session.session.user);
    }

    // Ride-hailing style dispatch: when a new offer arrives in realtime
    // (Socket.IO offer.created -> pendingOffers), surface it prominently.
    ref.listen<AsyncValue<ProviderWorkState>>(providerWorkControllerProvider, (
      _,
      next,
    ) {
      _maybeShowIncomingOffer(next.value);
    });

    return Scaffold(
      backgroundColor: _index == 0
          ? RevoBrandColors.surface
          : RevoBrandColors.bg,
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _index == 3
                ? () => ref.invalidate(professionalProfileProvider)
                : _refreshCurrent,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _ProviderDashboard(),
          _ProviderOrdersPage(),
          _ProviderWalletPage(),
          _ProviderAccountPage(),
        ],
      ),
      bottomNavigationBar: _RevoBottomNav(
        currentIndex: _index,
        onChanged: (value) {
          setState(() => _index = value);
          if (value == 2) {
            ref.invalidate(providerWalletControllerProvider);
          }
        },
      ),
    );
  }

  void _refreshCurrent() {
    if (_index == 2) {
      ref.read(providerWalletControllerProvider.notifier).refresh();
    } else {
      ref.read(providerWorkControllerProvider.notifier).refresh();
    }
  }

  void _maybeShowIncomingOffer(ProviderWorkState? state) {
    if (state == null || _offerDialogOpen) return;
    // First snapshot (e.g. offers already pending when the app opens): record
    // them as seen so only requests arriving afterwards pop up as dispatch.
    if (!_offersInitialized) {
      _offersInitialized = true;
      for (final offer in state.pendingOffers) {
        _announcedOffers.add(offer.id);
      }
      return;
    }
    PendingOffer? fresh;
    for (final offer in state.pendingOffers) {
      if (!_announcedOffers.contains(offer.id) && !offer.isExpired) {
        fresh = offer;
        break;
      }
    }
    if (fresh == null) return;
    final offer = fresh;
    _announcedOffers.add(offer.id);
    _offerDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _offerDialogOpen = false;
        return;
      }
      if (_index != 0) setState(() => _index = 0);
      final result = await showIncomingOfferDialog(context, offer);
      _offerDialogOpen = false;
      if (!mounted || result == null) return;
      if (result.outcome == IncomingOfferOutcome.accepted &&
          result.orderId != null) {
        await ref
            .read(providerLocationTrackingControllerProvider.notifier)
            .trackOrder(result.orderId!);
        if (mounted) context.push('/provider/orders/${result.orderId}');
      }
    });
  }
}

/// Floating capsule bottom navigation matching the REVO provider UI reference.
class _RevoBottomNav extends StatelessWidget {
  const _RevoBottomNav({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <(String, IconData, IconData)>[
    ('Trang chủ', Icons.home_outlined, Icons.home_rounded),
    ('Đơn hàng', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    (
      'Ví',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
    ),
    ('Tài khoản', Icons.person_outline_rounded, Icons.person_rounded),
  ];
  static const _radius = 36.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      14,
      6,
      14,
      MediaQuery.viewPaddingOf(context).bottom + 10,
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: RevoBrandColors.border, width: .8),
        boxShadow: RevoShadows.navigation,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _RevoNavItem(
                    label: _items[i].$1,
                    icon: i == currentIndex ? _items[i].$3 : _items[i].$2,
                    active: i == currentIndex,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RevoNavItem extends StatelessWidget {
  const _RevoNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? RevoBrandColors.primary : RevoBrandColors.inactive;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 46,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? RevoBrandColors.surfaceSoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: RevoTypography.caption.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingProviderApprovalPage extends ConsumerWidget {
  const _PendingProviderApprovalPage({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = user.email ?? user.phone ?? 'Tài khoản Thợ';
    return Scaffold(
      appBar: AppBar(title: const Text('Xét duyệt tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: RevoBrandColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                size: 44,
                color: RevoBrandColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hồ sơ Thợ đang chờ duyệt',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thông tin đăng ký đã được lưu vào hệ thống. Quản trị viên cần duyệt hồ sơ trước khi bạn có thể bật trạng thái sẵn sàng và nhận đơn cứu hộ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: RevoBrandColors.textSubtle,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(user.name),
                subtitle: Text(contact),
                trailing: const Chip(label: Text('Chờ duyệt')),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).bootstrap(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kiểm tra trạng thái'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderDashboard extends ConsumerWidget {
  const _ProviderDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final work = ref.watch(providerWorkControllerProvider);
    final location = ref.watch(providerLocationTrackingControllerProvider);
    final name = session is SessionSignedIn ? session.session.user.name : 'Thợ';

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(providerWorkControllerProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _ProviderHomeHeader(name: name),
          const SizedBox(height: 20),
          _AvailabilityCard(location: location),
          const SizedBox(height: 22),
          const _ProviderServicesSection(),
          const SizedBox(height: 22),
          work.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _FailureCard(
              message: 'Không tải được công việc: $error',
              onRetry: () => ref.invalidate(providerWorkControllerProvider),
            ),
            data: (state) => _DashboardWork(state: state),
          ),
        ],
      ),
    );
  }
}

/// REVO-style home header: gradient avatar with initials + greeting.
class _ProviderHomeHeader extends StatelessWidget {
  const _ProviderHomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            gradient: RevoGradients.balance,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào,', style: RevoTypography.caption),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// "Dịch vụ của bạn": the provider's own skills from the real profile API.
class _ProviderServicesSection extends ConsumerWidget {
  const _ProviderServicesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(professionalProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Dịch vụ của bạn',
          count: profile.asData?.value.skills.length ?? 0,
        ),
        const SizedBox(height: 10),
        profile.when(
          loading: () => const _EmptyCard(
            icon: Icons.handyman_outlined,
            text: 'Đang tải danh sách dịch vụ...',
          ),
          error: (error, _) => const _EmptyCard(
            icon: Icons.error_outline_rounded,
            text: 'Không tải được dịch vụ. Kéo xuống để thử lại.',
          ),
          data: (p) => p.skills.isEmpty
              ? const _EmptyCard(
                  icon: Icons.handyman_outlined,
                  text: 'Chưa có dịch vụ nào. Thêm trong mục Tài khoản.',
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final skill in p.skills) _ServiceTile(label: skill),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(RevoRadius.md),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: RevoBrandColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.build_rounded,
              size: 18,
              color: RevoBrandColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends ConsumerWidget {
  const _AvailabilityCard({required this.location});

  final AsyncValue<ProviderLocationTrackingState> location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return location.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => _FailureCard(
        message: 'Không khởi tạo được GPS: $error',
        onRetry: () =>
            ref.invalidate(providerLocationTrackingControllerProvider),
      ),
      data: (state) {
        final online = state.isTracking;
        return Card(
          color: online
              ? RevoBrandColors.surfaceSoft
              : Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: online
                            ? RevoBrandColors.success
                            : RevoBrandColors.textSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        online ? Icons.location_on_rounded : Icons.location_off,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            online ? 'Đang sẵn sàng' : 'Đang ngoại tuyến',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(switch (state.mode) {
                            ProviderLocationMode.offline =>
                              'GPS chưa được gửi tới hệ thống.',
                            ProviderLocationMode.waiting =>
                              'Đang cập nhật GPS khi chờ đơn.',
                            ProviderLocationMode.activeOrder =>
                              'Đang chia sẻ GPS cho đơn #${state.orderId}.',
                          }),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: online,
                      onChanged: state.isBusy
                          ? null
                          : (value) {
                              final controller = ref.read(
                                providerLocationTrackingControllerProvider
                                    .notifier,
                              );
                              if (value) {
                                controller.goOnline();
                              } else {
                                controller.goOffline();
                              }
                            },
                    ),
                  ],
                ),
                if (state.lastSentAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'GPS gần nhất: ${formatProviderDateTime(state.lastSentAt!)}',
                    style: const TextStyle(color: RevoBrandColors.textSubtle),
                  ),
                ],
                if (state.lastFailure != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Không thể cập nhật GPS: ${state.lastFailure}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: state.isBusy
                            ? null
                            : () => ref
                                  .read(
                                    providerLocationTrackingControllerProvider
                                        .notifier,
                                  )
                                  .sendNow(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(
                              providerLocationTrackingControllerProvider
                                  .notifier,
                            )
                            .openRecoverySettings(),
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Mở cài đặt'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardWork extends StatelessWidget {
  const _DashboardWork({required this.state});

  final ProviderWorkState state;

  @override
  Widget build(BuildContext context) {
    final activeOrders = state.orders
        .where((order) => providerOrderIsActive(order.status))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.lastFailure != null) ...[
          _FailureCard(
            message: 'Thao tác chưa thành công: ${state.lastFailure}',
          ),
          const SizedBox(height: 16),
        ],
        _SectionTitle(title: 'Yêu cầu mới', count: state.pendingOffers.length),
        const SizedBox(height: 10),
        if (state.pendingOffers.isEmpty)
          const _EmptyCard(
            icon: Icons.notifications_none_rounded,
            text: 'Chưa có yêu cầu cứu hộ mới.',
          )
        else
          ...state.pendingOffers.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OfferCard(offer: offer, busy: state.isBusy),
            ),
          ),
        const SizedBox(height: 18),
        _SectionTitle(title: 'Đơn đang thực hiện', count: activeOrders.length),
        const SizedBox(height: 10),
        if (activeOrders.isEmpty)
          const _EmptyCard(
            icon: Icons.handyman_outlined,
            text: 'Bạn chưa có đơn đang thực hiện.',
          )
        else
          ...activeOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderCard(order: order),
            ),
          ),
      ],
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer, required this.busy});

  final PendingOffer offer;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.order.incidentType.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  formatProviderMoney(offer.order.estimatedPrice),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: RevoBrandColors.primaryDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Mã đơn: ${offer.order.code}'),
            const SizedBox(height: 4),
            Text(
              'Vị trí: ${offer.order.customerLocation.latitude.toStringAsFixed(5)}, '
              '${offer.order.customerLocation.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 4),
            Text('Hết hạn: ${formatProviderDateTime(offer.expiresAt)}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy || offer.isExpired
                        ? null
                        : () => ref
                              .read(providerWorkControllerProvider.notifier)
                              .rejectOffer(offer),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: busy || offer.isExpired
                        ? null
                        : () => _accept(context, ref),
                    child: const Text('Nhận đơn'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    await ref.read(providerWorkControllerProvider.notifier).acceptOffer(offer);
    final state = ref.read(providerWorkControllerProvider).value;
    if (!context.mounted || state?.selectedOrder?.id != offer.orderId) return;
    await ref
        .read(providerLocationTrackingControllerProvider.notifier)
        .trackOrder(offer.orderId);
    if (context.mounted) context.push('/provider/orders/${offer.orderId}');
  }
}

class _ProviderOrdersPage extends ConsumerWidget {
  const _ProviderOrdersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = ref.watch(providerWorkControllerProvider);
    return work.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FailureCard(
        message: 'Không tải được danh sách đơn: $error',
        onRetry: () => ref.invalidate(providerWorkControllerProvider),
      ),
      data: (state) => RefreshIndicator(
        onRefresh: () =>
            ref.read(providerWorkControllerProvider.notifier).refresh(),
        child: state.orders.isEmpty
            ? const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: _EmptyCard(
                      icon: Icons.receipt_long_outlined,
                      text: 'Chưa có đơn cứu hộ nào.',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: state.orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _OrderCard(order: state.orders[index]),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/provider/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.code,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 8),
              _StatusChip(status: order.status),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatProviderDateTime(order.createdAt)),
                  Text(
                    formatProviderMoney(
                      order.finalPrice ?? order.estimatedPrice,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderWalletPage extends ConsumerWidget {
  const _ProviderWalletPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(providerWalletControllerProvider);
    return wallet.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FailureCard(
        message: 'Không tải được ví sandbox: $error',
        onRetry: () => ref.invalidate(providerWalletControllerProvider),
      ),
      data: (state) => RefreshIndicator(
        onRefresh: () =>
            ref.read(providerWalletControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    RevoBrandColors.primaryDeep,
                    RevoBrandColors.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SỐ DƯ KHẢ DỤNG • SANDBOX',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatProviderMoney(state.wallet.summary.availableBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đang khóa: ${formatProviderMoney(state.wallet.summary.lockedBalance)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: state.isBusy
                        ? null
                        : () => _showWithdrawalDialog(context, ref),
                    icon: const Icon(Icons.account_balance_outlined),
                    label: const Text('Tạo yêu cầu rút thử nghiệm'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đây là số dư mô phỏng phục vụ kiểm thử; không phải tiền ngân hàng thật.',
              style: TextStyle(color: RevoBrandColors.textSubtle),
            ),
            if (state.lastFailure != null) ...[
              const SizedBox(height: 14),
              _FailureCard(
                message: 'Thao tác ví thất bại: ${state.lastFailure}',
              ),
            ],
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Giao dịch gần đây',
              count: state.wallet.transactions.length,
            ),
            const SizedBox(height: 10),
            if (state.wallet.transactions.isEmpty)
              const _EmptyCard(
                icon: Icons.payments_outlined,
                text: 'Chưa có giao dịch ví.',
              )
            else
              ...state.wallet.transactions.map(_WalletTransactionTile.new),
            const SizedBox(height: 22),
            _SectionTitle(
              title: 'Yêu cầu rút',
              count: state.withdrawals.items.length,
            ),
            const SizedBox(height: 10),
            if (state.withdrawals.items.isEmpty)
              const _EmptyCard(
                icon: Icons.history_rounded,
                text: 'Chưa có yêu cầu rút thử nghiệm.',
              )
            else
              ...state.withdrawals.items.map(_WithdrawalTile.new),
          ],
        ),
      ),
    );
  }

  Future<void> _showWithdrawalDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final amount = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rút tiền sandbox'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Số tiền (VND)',
            hintText: 'Ví dụ: 100000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || amount.isEmpty) return;
    final normalized = amount.contains('.') ? amount : '$amount.00';
    await ref
        .read(providerWalletControllerProvider.notifier)
        .createWithdrawal(normalized);
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile(this.transaction);

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == WalletTransactionType.credit;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? RevoBrandColors.success.withValues(alpha: 0.12)
              : RevoBrandColors.dangerSoft,
          child: Icon(
            isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: isCredit
                ? RevoBrandColors.success
                : RevoBrandColors.dangerDark,
          ),
        ),
        title: Text(
          transaction.orderId == null
              ? 'Rút tiền sandbox'
              : 'Quyết toán đơn #${transaction.orderId}',
        ),
        subtitle: Text(formatProviderDateTime(transaction.createdAt)),
        trailing: Text(
          '${isCredit ? '+' : '-'}${formatProviderMoney(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isCredit
                ? RevoBrandColors.success
                : RevoBrandColors.dangerDark,
          ),
        ),
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile(this.withdrawal);

  final WithdrawalRequest withdrawal;

  @override
  Widget build(BuildContext context) {
    final label = switch (withdrawal.status) {
      WithdrawalStatus.pending => 'Chờ duyệt',
      WithdrawalStatus.approved => 'Đã duyệt',
      WithdrawalStatus.rejected => 'Bị từ chối',
    };
    return Card(
      child: ListTile(
        title: Text(formatProviderMoney(withdrawal.amount)),
        subtitle: Text(formatProviderDateTime(withdrawal.createdAt)),
        trailing: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ProviderAccountPage extends ConsumerWidget {
  const _ProviderAccountPage();

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    ProfessionalProfile profile,
  ) async {
    final bio = TextEditingController(text: profile.bio);
    final years = TextEditingController(text: '${profile.yearsOfExperience}');
    final radius = TextEditingController(text: '${profile.serviceRadiusKm}');
    final form = GlobalKey<FormState>();
    var saving = false;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Hồ sơ nghề nghiệp',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bio,
                        maxLength: 1000,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Giới thiệu bản thân',
                        ),
                      ),
                      TextFormField(
                        controller: years,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số năm kinh nghiệm',
                        ),
                        validator: (value) {
                          final number = int.tryParse(value?.trim() ?? '');
                          return number == null || number < 0 || number > 70
                              ? 'Nhập số từ 0 đến 70.'
                              : null;
                        },
                      ),
                      TextFormField(
                        controller: radius,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bán kính nhận đơn (km)',
                        ),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          return number == null || number < 1 || number > 100
                              ? 'Nhập số từ 1 đến 100 km.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!form.currentState!.validate()) return;
                                setSheetState(() => saving = true);
                                try {
                                  await updateProfessionalProfile(
                                    ref,
                                    bio: bio.text,
                                    yearsOfExperience: int.parse(
                                      years.text.trim(),
                                    ),
                                    serviceRadiusKm: double.parse(
                                      radius.text.trim(),
                                    ),
                                  );
                                  if (sheetContext.mounted) {
                                    ref.invalidate(professionalProfileProvider);
                                    Navigator.pop(sheetContext);
                                  }
                                } on Exception {
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Chưa lưu được hồ sơ Thợ. Hãy thử lại.',
                                            ),
                                          ),
                                        );
                                  }
                                } finally {
                                  if (sheetContext.mounted) {
                                    setSheetState(() => saving = false);
                                  }
                                }
                              },
                        child: Text(saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } finally {
      bio.dispose();
      years.dispose();
      radius.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is SessionSignedIn ? state.session.user : null;
    final profile = ref.watch(professionalProfileProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: RevoBrandColors.surfaceSoft,
                  child: Icon(
                    Icons.handyman_rounded,
                    size: 34,
                    color: RevoBrandColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Tài khoản thợ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user?.phone != null) Text(user!.phone!),
                      if (user?.email != null) Text(user!.email!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        profile.when(
          loading: () =>
              const Card(child: ListTile(title: Text('Đang tải hồ sơ Thợ...'))),
          error: (_, _) => Card(
            child: ListTile(
              title: const Text('Chưa tải được hồ sơ Thợ'),
              subtitle: const Text('Kiểm tra kết nối rồi tải lại.'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(professionalProfileProvider),
              ),
            ),
          ),
          data: (value) => Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Hồ sơ nghề nghiệp'),
                  subtitle: Text(
                    value.bio.isEmpty ? 'Chưa có giới thiệu' : value.bio,
                  ),
                  trailing: IconButton(
                    tooltip: 'Chỉnh sửa hồ sơ Thợ',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editProfile(context, ref, value),
                  ),
                ),
                ListTile(
                  title: const Text('Kinh nghiệm'),
                  trailing: Text('${value.yearsOfExperience} năm'),
                ),
                ListTile(
                  title: const Text('Bán kính nhận đơn'),
                  trailing: Text('${value.serviceRadiusKm} km'),
                ),
                ListTile(
                  title: const Text('Kỹ năng'),
                  subtitle: Text(
                    value.skills.isEmpty
                        ? 'Chưa có kỹ năng được đăng ký'
                        : value.skills.join(', '),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(sessionControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: RevoBrandColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: RevoBrandColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.completed || OrderStatus.paid => RevoBrandColors.success,
      OrderStatus.cancelled ||
      OrderStatus.refundPending ||
      OrderStatus.refunded => RevoBrandColors.dangerDark,
      _ => RevoBrandColors.warning,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          providerOrderStatusLabel(status),
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: RevoBrandColors.textSubtle),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: RevoBrandColors.dangerSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: RevoBrandColors.dangerDark),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            if (onRetry != null)
              IconButton(
                tooltip: 'Thử lại',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
