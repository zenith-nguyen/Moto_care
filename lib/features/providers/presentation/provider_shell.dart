import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/money/money_amount.dart';
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
import '../application/provider_work_controller.dart';
import '../application/provider_work_state.dart';
import '../application/professional_profile_provider.dart';
import '../application/provider_stats_provider.dart';
import '../domain/provider_models.dart';
import '../domain/professional_profile.dart';
import 'provider_formatters.dart';
import 'provider_home_tab.dart';
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
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            ProviderHomeTab(),
            _ProviderOrdersPage(),
            _ProviderWalletPage(),
            _ProviderAccountPage(),
          ],
        ),
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

enum _OrderFilter { all, active, completed, cancelled }

const _ordersSecondary = RevoBrandColors.inactive;
const _ordersPale = RevoBrandColors.surfaceSoft;

/// Provider Orders tab rebuilt to match the final REVO mechanic reference:
/// pill tabs with live counts, search field, status chips and a sort popup.
/// Presentation only: the list is still the real [providerWorkControllerProvider]
/// orders and each card keeps the existing detail-route navigation.
class _ProviderOrdersPage extends ConsumerStatefulWidget {
  const _ProviderOrdersPage();

  @override
  ConsumerState<_ProviderOrdersPage> createState() =>
      _ProviderOrdersPageState();
}

class _ProviderOrdersPageState extends ConsumerState<_ProviderOrdersPage> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  _OrderFilter _filter = _OrderFilter.all;
  bool _sortNewest = true;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _inFilter(OrderSummary order, _OrderFilter filter) => switch (filter) {
    _OrderFilter.all => true,
    _OrderFilter.active => providerOrderIsActive(order.status),
    _OrderFilter.completed =>
      order.status == OrderStatus.completed || order.status == OrderStatus.paid,
    _OrderFilter.cancelled =>
      order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.refundPending ||
          order.status == OrderStatus.refunded,
  };

  bool _matchesSearch(OrderSummary order) {
    final key = _search.text.trim().toLowerCase();
    if (key.isEmpty) return true;
    final haystack = '${order.code} ${providerOrderStatusLabel(order.status)}'
        .toLowerCase();
    return haystack.contains(key);
  }

  bool get _filtering =>
      _filter != _OrderFilter.all || _search.text.trim().isNotEmpty;

  void _clear() => setState(() {
    _filter = _OrderFilter.all;
    _search.clear();
  });

  static const _chipLabels = [
    (_OrderFilter.all, 'Tất cả'),
    (_OrderFilter.active, 'Đang làm'),
    (_OrderFilter.completed, 'Hoàn thành'),
    (_OrderFilter.cancelled, 'Đã hủy'),
  ];

  // Pill tabs mirror the reference: "Đã hủy" lives only in the chip row.
  static const _tabLabels = [
    (_OrderFilter.all, 'Tất cả'),
    (_OrderFilter.active, 'Đang làm'),
    (_OrderFilter.completed, 'Hoàn thành'),
  ];

  @override
  Widget build(BuildContext context) {
    final work = ref.watch(providerWorkControllerProvider);
    return work.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FailureCard(
        message: 'Không tải được danh sách đơn: $error',
        onRetry: () => ref.invalidate(providerWorkControllerProvider),
      ),
      data: (state) {
        final all = state.orders;
        final shown =
            all
                .where((o) => _inFilter(o, _filter) && _matchesSearch(o))
                .toList()
              ..sort(
                (a, b) => _sortNewest
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt),
              );
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(providerWorkControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _pillTabs(all),
              const SizedBox(height: 12),
              _banner(),
              const SizedBox(height: 12),
              _searchBar(),
              const SizedBox(height: 10),
              _chipsRow(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${shown.length} đơn hàng',
                      style: RevoTypography.caption.copyWith(
                        fontSize: 12,
                        color: _ordersSecondary,
                      ),
                    ),
                  ),
                  _sortButton(),
                ],
              ),
              const SizedBox(height: 10),
              if (shown.isEmpty)
                _ordersEmpty(all.isNotEmpty)
              else
                for (final order in shown) ...[
                  _OrderCard(order: order),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _pillTabs(List<OrderSummary> all) {
    int count(_OrderFilter f) => all.where((o) => _inFilter(o, f)).length;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _ordersPale,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final (f, label) in _tabLabels)
            Expanded(
              child: Semantics(
                selected: _filter == f,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _filter == f
                          ? RevoBrandColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '$label (${count(f)})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _filter == f
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _filter == f ? Colors.white : _ordersSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _banner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _ordersPale,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý công việc của bạn',
          style: RevoTypography.label.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 3),
        Text(
          'Theo dõi các đơn đang xử lý và lịch sử công việc.',
          style: RevoTypography.caption.copyWith(
            fontSize: 11.5,
            color: _ordersSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _searchBar() => TextField(
    controller: _search,
    focusNode: _searchFocus,
    onChanged: (_) => setState(() {}),
    textInputAction: TextInputAction.search,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: 'Tìm kiếm theo mã đơn hoặc trạng thái...',
      hintMaxLines: 2,
      filled: true,
      fillColor: RevoBrandColors.light,
      prefixIcon: const Icon(
        Icons.search_rounded,
        size: 22,
        color: _ordersSecondary,
      ),
      suffixIcon: _search.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Xóa từ khóa',
              onPressed: () => setState(_search.clear),
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: _ordersSecondary,
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: RevoBrandColors.border, width: .8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: RevoBrandColors.primary),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _chipsRow() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (f, label) in _chipLabels) ...[
          ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _filter == f ? Colors.white : RevoBrandColors.ink,
              ),
            ),
            showCheckmark: false,
            selected: _filter == f,
            selectedColor: RevoBrandColors.primary,
            backgroundColor: _ordersPale,
            side: BorderSide.none,
            onSelected: (_) => setState(() => _filter = f),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );

  Widget _sortButton() => PopupMenuButton<bool>(
    tooltip: 'Sắp xếp',
    initialValue: _sortNewest,
    onSelected: (v) => setState(() => _sortNewest = v),
    itemBuilder: (_) => const [
      PopupMenuItem(value: true, child: Text('Mới nhất')),
      PopupMenuItem(value: false, child: Text('Cũ nhất')),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.swap_vert_rounded,
            size: 18,
            color: RevoBrandColors.ink,
          ),
          const SizedBox(width: 4),
          Text(
            _sortNewest ? 'Mới nhất' : 'Cũ nhất',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: RevoBrandColors.ink,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: RevoBrandColors.ink,
          ),
        ],
      ),
    ),
  );

  Widget _ordersEmpty(bool hasAny) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: RevoBrandColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: RevoBrandColors.border, width: .7),
    ),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 28, color: _ordersSecondary),
        const SizedBox(height: 8),
        Text(
          'Chưa có đơn hàng phù hợp',
          textAlign: TextAlign.center,
          style: RevoTypography.label.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          hasAny
              ? 'Thử thay đổi từ khóa hoặc bộ lọc.'
              : 'Các đơn bạn nhận sẽ hiển thị tại đây.',
          textAlign: TextAlign.center,
          style: RevoTypography.caption.copyWith(color: _ordersSecondary),
        ),
        if (_filtering) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: _clear, child: const Text('Xóa bộ lọc')),
        ],
      ],
    ),
  );
}

/// Richer order card: status badge + money block. Vehicle plate and address are
/// intentionally omitted because the repo [OrderSummary] model does not expose
/// those fields (never invented). Keeps the real detail-route navigation.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  (String, Color, Color) get _badge {
    final label = providerOrderStatusLabel(order.status);
    return switch (order.status) {
      OrderStatus.completed || OrderStatus.paid => (
        label,
        RevoBrandColors.successDark,
        RevoBrandColors.successSoft,
      ),
      OrderStatus.cancelled ||
      OrderStatus.refundPending ||
      OrderStatus.refunded => (
        label,
        RevoBrandColors.dangerDark,
        RevoBrandColors.dangerSoft,
      ),
      _ => (label, RevoBrandColors.primary, RevoBrandColors.surfaceSoft),
    };
  }

  Widget _money() {
    // Money semantics by lifecycle: earning when settled, quote while active,
    // explicit "no income" for cancelled/refunded orders.
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.refundPending ||
        order.status == OrderStatus.refunded) {
      return Text(
        'Không ghi nhận thu nhập',
        textAlign: TextAlign.end,
        style: RevoTypography.caption.copyWith(
          fontSize: 11,
          color: _ordersSecondary,
        ),
      );
    }
    final earned =
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.paid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          earned ? 'Thu nhập' : 'Báo giá',
          style: RevoTypography.caption.copyWith(
            fontSize: 11,
            color: _ordersSecondary,
          ),
        ),
        Text(
          formatProviderMoney(order.finalPrice ?? order.estimatedPrice),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: RevoBrandColors.ink,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final (badgeLabel, badgeColor, badgeBg) = _badge;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/provider/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: badgeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: RevoBrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatProviderDateTime(order.createdAt),
                      style: RevoTypography.caption.copyWith(
                        fontSize: 12,
                        color: _ordersSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _money(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// REVO mechanic wallet palette (emerald balance card on a light surface).
const _walletEmerald1 = Color(0xFF1F9877);
const _walletEmerald2 = Color(0xFF0E6B56);
const _walletEmerald3 = Color(0xFF05433F);
const _walletNavy = Color(0xFF172638);
const _walletSecondary = Color(0xFF71839E);
const _walletBorder = Color(0xFFE3EAF3);
const _walletIvory = Color(0xFFF4FBF7);

class _ProviderWalletPage extends ConsumerStatefulWidget {
  const _ProviderWalletPage();

  @override
  ConsumerState<_ProviderWalletPage> createState() =>
      _ProviderWalletPageState();
}

class _ProviderWalletPageState extends ConsumerState<_ProviderWalletPage> {
  bool _sortNewest = true;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(providerWalletControllerProvider);
    return wallet.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FailureCard(
        message: 'Không tải được ví sandbox: $error',
        onRetry: () => ref.invalidate(providerWalletControllerProvider),
      ),
      data: (state) {
        final sortNewest = _sortNewest;
        final txs = [...state.wallet.transactions]
          ..sort(
            (a, b) => sortNewest
                ? b.createdAt.compareTo(a.createdAt)
                : a.createdAt.compareTo(b.createdAt),
          );
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(providerWalletControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_walletEmerald1, _walletEmerald2, _walletEmerald3],
                    stops: [0, 0.45, 1],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330E6B56),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.wallet.demoOnly
                          ? 'Số dư khả dụng • Sandbox'
                          : 'Số dư khả dụng',
                      style: const TextStyle(
                        color: _walletIvory,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatProviderMoney(
                          state.wallet.summary.availableBalance,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đang khóa: '
                      '${formatProviderMoney(state.wallet.summary.lockedBalance)}',
                      style: const TextStyle(
                        color: _walletIvory,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.wallet.demoOnly) ...[
                const SizedBox(height: 12),
                const Text(
                  'Đây là số dư mô phỏng phục vụ kiểm thử; không phải tiền '
                  'ngân hàng thật.',
                  style: TextStyle(color: RevoBrandColors.textSubtle),
                ),
              ],
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _actionTile(
                        Icons.account_balance_wallet_outlined,
                        'Nạp tiền',
                        'Qua ngân hàng',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nạp tiền chưa khả dụng. Ví chỉ ghi nhận thu '
                              'nhập từ đơn hoàn thành.',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _actionTile(
                        Icons.credit_card_outlined,
                        'Rút tiền',
                        'Về tài khoản',
                        state.isBusy
                            ? null
                            : () => _showWithdrawalDialog(
                                context,
                                ref,
                                demoOnly: state.wallet.demoOnly,
                                available:
                                    state.wallet.summary.availableBalance,
                              ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _actionTile(
                        Icons.bar_chart_rounded,
                        'Thống kê',
                        'Thu nhập',
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thống kê thu nhập sẽ sớm có.'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.lastFailure != null) ...[
                const SizedBox(height: 14),
                _FailureCard(
                  message: 'Thao tác ví thất bại: ${state.lastFailure}',
                ),
              ],
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _walletNavy,
                    ),
                  ),
                  _sortButton(sortNewest),
                ],
              ),
              const SizedBox(height: 12),
              if (txs.isEmpty)
                const _EmptyCard(
                  icon: Icons.payments_outlined,
                  text: 'Chưa có giao dịch ví.',
                )
              else
                ...txs.map(_WalletTransactionTile.new),
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
        );
      },
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) => Material(
    color: const Color(0xFFF1F7FD),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: _walletBorder),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: RevoBrandColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _walletNavy,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: _walletSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sortButton(bool newest) => PopupMenuButton<bool>(
    tooltip: 'Sắp xếp giao dịch',
    initialValue: newest,
    onSelected: (v) => setState(() => _sortNewest = v),
    itemBuilder: (_) => const [
      PopupMenuItem(value: true, child: Text('Mới nhất')),
      PopupMenuItem(value: false, child: Text('Cũ nhất')),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _walletBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swap_vert_rounded, size: 18, color: _walletNavy),
          const SizedBox(width: 6),
          Text(
            newest ? 'Mới nhất' : 'Cũ nhất',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _walletNavy,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: _walletNavy,
          ),
        ],
      ),
    ),
  );

  Future<void> _showWithdrawalDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool demoOnly,
    required MoneyAmount available,
  }) async {
    final controller = TextEditingController();
    final amount = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(demoOnly ? 'Rút tiền sandbox' : 'Yêu cầu rút tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số dư khả dụng: ${formatProviderMoney(available)}',
              style: const TextStyle(color: RevoBrandColors.textSubtle),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Số tiền (VND)',
                hintText: 'Ví dụ: 100000',
              ),
            ),
          ],
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

  String get _title => transaction.orderId == null
      ? 'Rút tiền'
      : 'Quyết toán đơn #${transaction.orderId}';

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == WalletTransactionType.credit;
    return Card(
      child: ListTile(
        onTap: () => _showDetail(context, isCredit),
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
        title: Text(_title),
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

  void _showDetail(BuildContext context, bool isCredit) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chi tiết giao dịch', style: RevoTypography.title),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${isCredit ? '+' : '-'}${formatProviderMoney(transaction.amount)}',
                  style: RevoTypography.amount.copyWith(
                    color: isCredit
                        ? RevoBrandColors.success
                        : RevoBrandColors.dangerDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DetailLine(label: 'Loại', value: _title),
              _DetailLine(
                label: 'Chiều',
                value: isCredit ? 'Tiền vào' : 'Tiền ra',
              ),
              _DetailLine(label: 'Mã giao dịch', value: '#${transaction.id}'),
              if (transaction.orderId != null)
                _DetailLine(label: 'Đơn', value: '#${transaction.orderId}'),
              if (transaction.withdrawalId != null)
                _DetailLine(
                  label: 'Yêu cầu rút',
                  value: '#${transaction.withdrawalId}',
                ),
              _DetailLine(
                label: 'Thời gian',
                value: formatProviderDateTime(transaction.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: RevoTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: RevoTypography.label,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletStatusChip extends StatelessWidget {
  const _WalletStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RevoRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
    final (label, color) = switch (withdrawal.status) {
      WithdrawalStatus.pending => ('Chờ duyệt', RevoBrandColors.warning),
      WithdrawalStatus.approved => ('Đã duyệt', RevoBrandColors.success),
      WithdrawalStatus.rejected => ('Bị từ chối', RevoBrandColors.dangerDark),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatProviderMoney(withdrawal.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _WalletStatusChip(label: label, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatProviderDateTime(withdrawal.createdAt),
              style: const TextStyle(
                color: RevoBrandColors.textSubtle,
                fontSize: 12,
              ),
            ),
            if (withdrawal.decisionReason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Lý do: ${withdrawal.decisionReason}'),
            ],
          ],
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

  Future<void> _manageSkills(
    BuildContext context,
    WidgetRef ref,
    ProfessionalProfile profile,
  ) async {
    final repo = ref.read(providersRepositoryProvider);
    List<ProviderSkillOption> catalog;
    try {
      catalog = await repo.listSkillCatalog();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được danh mục dịch vụ.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final selected = <int>{
      for (final option in catalog)
        if (profile.skills.contains(option.name)) option.id,
    };
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Quản lý dịch vụ', style: RevoTypography.title),
              const SizedBox(height: 4),
              const Text(
                'Chọn các dịch vụ bạn nhận. Dịch vụ mới cần quản trị viên '
                'duyệt trước khi áp dụng.',
                style: TextStyle(color: RevoBrandColors.textSubtle),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: catalog.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Chưa có dịch vụ nào trong danh mục.'),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final option in catalog)
                            CheckboxListTile(
                              value: selected.contains(option.id),
                              title: Text(option.name),
                              contentPadding: EdgeInsets.zero,
                              onChanged: saving
                                  ? null
                                  : (checked) => setSheetState(() {
                                      if (checked == true) {
                                        selected.add(option.id);
                                      } else {
                                        selected.remove(option.id);
                                      }
                                    }),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setSheetState(() => saving = true);
                        try {
                          await repo.replaceMySkills(selected.toList());
                          if (sheetContext.mounted) {
                            ref.invalidate(professionalProfileProvider);
                            Navigator.pop(sheetContext);
                          }
                        } catch (_) {
                          if (sheetContext.mounted) {
                            setSheetState(() => saving = false);
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chưa lưu được dịch vụ. Hãy thử lại.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Đang lưu...' : 'Lưu dịch vụ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, [String? message]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Tính năng sẽ sớm có.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is SessionSignedIn ? state.session.user : null;
    final profile = ref.watch(professionalProfileProvider);
    final weekly = ref.watch(providerWeeklyStatsProvider);
    final profileValue = profile.asData?.value;
    final tierName = _providerTierName(profileValue?.tier);
    final rating = weekly.asData?.value.averageRating;
    final reviewCount = weekly.asData?.value.reviewCount ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _profileCard(
          context,
          ref,
          user: user,
          profile: profileValue,
          rating: rating,
          reviewCount: reviewCount,
          tierName: tierName,
        ),
        const SizedBox(height: 12),
        _statsCard(weekly),
        const SizedBox(height: 14),
        _quickActions(context, ref, profileValue),
        _group('Hồ sơ & năng lực', [
          _row(
            context,
            Icons.person_outline,
            'Thông tin hồ sơ',
            profileValue == null
                ? () => _comingSoon(context, 'Đang tải hồ sơ Thợ...')
                : () => _editProfile(context, ref, profileValue),
            subtitle: 'Giới thiệu, kinh nghiệm & bán kính nhận đơn',
          ),
          _row(
            context,
            Icons.build_outlined,
            'Quản lý dịch vụ',
            profileValue == null
                ? () => _comingSoon(context, 'Đang tải hồ sơ Thợ...')
                : () => _manageSkills(context, ref, profileValue),
            subtitle: profileValue == null || profileValue.skills.isEmpty
                ? 'Chọn dịch vụ bạn nhận'
                : profileValue.skills.join(', '),
          ),
          _row(
            context,
            Icons.workspace_premium_outlined,
            'Hạng thợ & quyền lợi',
            () => context.push('/provider/stats'),
            subtitle: tierName == null ? 'Tiến độ lên hạng' : 'Hạng $tierName',
          ),
        ]),
        _group('Hoạt động công việc', [
          _row(
            context,
            Icons.insights_rounded,
            'Thống kê & đánh giá',
            () => context.push('/provider/stats'),
            subtitle: 'Thu nhập tuần, đánh giá và hạng thợ',
          ),
        ]),
        _group('Tài chính', [
          _row(
            context,
            Icons.account_balance_wallet_outlined,
            'Ví & lịch sử giao dịch',
            () => _comingSoon(context, 'Mở tab Ví để xem số dư và giao dịch.'),
          ),
          _row(
            context,
            Icons.payments_outlined,
            'Rút tiền',
            () => _comingSoon(context, 'Mở tab Ví để gửi yêu cầu rút tiền.'),
          ),
        ]),
        _group('Hệ thống', [
          _row(
            context,
            Icons.notifications_none_rounded,
            'Thông báo',
            () => context.push('/provider/notifications'),
          ),
          _row(
            context,
            Icons.support_agent_rounded,
            'Trợ giúp & hỗ trợ',
            () => context.push('/provider/support'),
          ),
          _row(
            context,
            Icons.info_outline_rounded,
            'Giới thiệu REVO',
            () => _comingSoon(context),
          ),
          _row(
            context,
            Icons.description_outlined,
            'Điều khoản & cam kết',
            () => _comingSoon(context),
          ),
        ]),
        const SizedBox(height: 12),
        _LogoutCard(
          onLogout: () =>
              ref.read(sessionControllerProvider.notifier).signOut(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Dữ liệu hồ sơ và thống kê lấy trực tiếp từ hệ thống REVO.',
          textAlign: TextAlign.center,
          style: RevoTypography.caption,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _profileCard(
    BuildContext context,
    WidgetRef ref, {
    required AppUser? user,
    required ProfessionalProfile? profile,
    required double? rating,
    required int reviewCount,
    required String? tierName,
  }) {
    final name = user?.name ?? 'Tài khoản thợ';
    final verified = user != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF1F7FC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E8F5)),
        boxShadow: RevoShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: RevoBrandColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: RevoBrandColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: RevoBrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Thợ cứu hộ REVO',
                      style: TextStyle(
                        fontSize: 13,
                        color: RevoBrandColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (verified)
                          const Icon(
                            Icons.verified_rounded,
                            color: RevoBrandColors.primary,
                            size: 16,
                          ),
                        Text(
                          verified ? 'Đã xác minh' : 'Chờ xác minh',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: RevoBrandColors.primary,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          color: RevoBrandColors.warning,
                          size: 16,
                        ),
                        Text(
                          rating == null
                              ? '— ($reviewCount)'
                              : '${rating.toStringAsFixed(1)} ($reviewCount)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: RevoBrandColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.handyman_outlined,
                size: 17,
                color: RevoBrandColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  profile == null
                      ? 'Đang tải hồ sơ nghề nghiệp...'
                      : '${profile.yearsOfExperience} năm kinh nghiệm • '
                            'Bán kính ${profile.serviceRadiusKm} km',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: RevoBrandColors.textSubtle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(RevoRadius.pill),
                onTap: profile == null
                    ? () => _comingSoon(context, 'Đang tải hồ sơ Thợ...')
                    : () => _editProfile(context, ref, profile),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(RevoRadius.pill),
                    border: Border.all(color: const Color(0xFFCFE2F3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sửa hồ sơ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: RevoBrandColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: RevoBrandColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsCard(AsyncValue<ProviderWeeklyStats> weekly) {
    final stats = weekly.asData?.value;
    final orders = stats == null ? '—' : '${stats.completedOrders}';
    final rating = stats?.averageRating == null
        ? '—'
        : stats!.averageRating!.toStringAsFixed(1);
    final income = stats == null
        ? '—'
        : formatProviderMoney(stats.creditedAmount);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(RevoRadius.md),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _stat(orders, 'Đơn hoàn thành')),
                const VerticalDivider(
                  width: 1,
                  thickness: .7,
                  color: RevoBrandColors.border,
                ),
                Expanded(child: _stat(rating, 'Điểm đánh giá')),
                const VerticalDivider(
                  width: 1,
                  thickness: .7,
                  color: RevoBrandColors.border,
                ),
                Expanded(child: _stat(income, 'Thu nhập tuần')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Số liệu tuần này theo giờ Việt Nam',
            textAlign: TextAlign.center,
            style: RevoTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    children: [
      FittedBox(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: RevoBrandColors.ink,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: RevoTypography.caption.copyWith(fontSize: 11),
      ),
    ],
  );

  Widget _quickActions(
    BuildContext context,
    WidgetRef ref,
    ProfessionalProfile? profile,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _quick(
        Icons.bar_chart_rounded,
        'Thống kê',
        () => context.push('/provider/stats'),
      ),
      _quick(
        Icons.notifications_none_rounded,
        'Thông báo',
        () => context.push('/provider/notifications'),
      ),
      _quick(
        Icons.build_outlined,
        'Dịch vụ',
        profile == null
            ? () => _comingSoon(context, 'Đang tải hồ sơ Thợ...')
            : () => _manageSkills(context, ref, profile),
      ),
      _quick(
        Icons.support_agent_rounded,
        'Hỗ trợ',
        () => context.push('/provider/support'),
      ),
    ],
  );

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: RevoBrandColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: RevoBrandColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _group(String title, List<Widget> rows) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: RevoBrandColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: RevoBrandColors.surface,
            borderRadius: BorderRadius.circular(RevoRadius.md),
            border: Border.all(color: RevoBrandColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: .7, indent: 48),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    String? subtitle,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    minLeadingWidth: 36,
    leading: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: RevoBrandColors.surfaceSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: RevoBrandColors.primary),
    ),
    title: Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: RevoBrandColors.ink,
      ),
    ),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: RevoTypography.caption.copyWith(fontSize: 11.5),
          ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: RevoBrandColors.textSubtle,
    ),
    onTap: onTap,
  );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: RevoBrandColors.surface,
      borderRadius: BorderRadius.circular(RevoRadius.md),
      border: Border.all(color: RevoBrandColors.border),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: RevoBrandColors.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.logout_rounded,
          size: 20,
          color: RevoBrandColors.dangerDark,
        ),
      ),
      title: const Text(
        'Đăng xuất',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RevoBrandColors.dangerDark,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: RevoBrandColors.dangerDark,
      ),
      onTap: onLogout,
    ),
  );
}

String? _providerTierName(String? tier) => switch (tier?.toUpperCase()) {
  'STANDARD' => 'Tiêu chuẩn',
  'SILVER' => 'Bạc',
  'GOLD' => 'Vàng',
  'PLATINUM' => 'Bạch Kim',
  _ => null,
};

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
