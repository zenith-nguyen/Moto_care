import 'package:flutter/material.dart';

import '../data/home_catalog.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/order_identity.dart';
import '../widgets/ui.dart';
import 'order_history_detail_screen.dart';
import 'order_received_screen.dart';

/// One status filter shared by the pill tabs, the chips and the filter sheet.
enum OrderStatusFilter { all, active, completed, cancelled }

enum OrderSort { newest, oldest }

const _navy = Color(0xFF172638);
const _secondary = Color(0xFF71839E);
const _paleBlue = Color(0xFFEAF0F6);

class _Entry {
  _Entry(
      {required this.code,
      required this.issue,
      required this.vehicle,
      required this.address,
      required this.time,
      required this.status,
      required this.amount,
      required this.onOpen});
  final String code, issue, vehicle, address;
  final DateTime time;
  final OrderStatus status;

  /// Earning (completed) or current quote (active); null when nothing is recorded.
  final int? amount;
  final VoidCallback onOpen;
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  var _status = OrderStatusFilter.all;
  var _sort = OrderSort.newest;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_Entry> _entries() {
    final active = appState.activeOrder;
    return [
      if (active != null)
        _Entry(
            code: active.offer.code,
            issue: active.offer.issue,
            vehicle: active.offer.vehicle,
            address: active.offer.address,
            time: active.acceptedAt,
            status: OrderStatus.active,
            amount: active.finalPrice,
            onOpen: () => openActiveOrder(context, active)),
      for (final item in appState.showcaseOrdersEnabled
          ? appState.showcaseOrders
          : appState.history)
        _Entry(
            code: item.code,
            issue: item.issue,
            vehicle: item.vehicle,
            address: item.address,
            time: item.time,
            status: item.status,
            amount: item.status == OrderStatus.completed ? item.earning : null,
            onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderHistoryDetailScreen(item: item)))),
    ];
  }

  bool _inStatus(_Entry e, OrderStatusFilter f) => switch (f) {
        OrderStatusFilter.all => true,
        OrderStatusFilter.active => e.status == OrderStatus.active,
        OrderStatusFilter.completed => e.status == OrderStatus.completed,
        OrderStatusFilter.cancelled => e.status == OrderStatus.cancelled,
      };

  bool _matchesSearch(_Entry e) {
    final key = homeSearchKey(_search.text);
    if (key.isEmpty) return true;
    return homeSearchKey(
            '${e.code} ${e.issue} ${e.vehicle} ${vehicleLabel(e.vehicle)} ${e.address}')
        .contains(key);
  }

  bool get _filtering =>
      _status != OrderStatusFilter.all || _search.text.trim().isNotEmpty;

  void _clear() => setState(() {
        _status = OrderStatusFilter.all;
        _search.clear();
      });

  String _sortLabel(OrderSort s) =>
      s == OrderSort.newest ? 'Mới nhất' : 'Cũ nhất';

  Future<void> _openFilterSheet() async {
    var status = _status;
    var sort = _sort;
    final applied = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SheetHandle(),
                          const SizedBox(height: 16),
                          const Text('Bộ lọc đơn hàng',
                              style: AppTypography.title),
                          const SizedBox(height: 16),
                          const Text('Trạng thái', style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final (value, label) in _statusLabels)
                              ChoiceChip(
                                  label: Text(label, style: appText(12)),
                                  selected: status == value,
                                  onSelected: (_) =>
                                      update(() => status = value))
                          ]),
                          const SizedBox(height: 12),
                          const Text('Sắp xếp', style: AppTypography.label),
                          Wrap(spacing: 8, children: [
                            for (final s in OrderSort.values)
                              ChoiceChip(
                                  label:
                                      Text(_sortLabel(s), style: appText(12)),
                                  selected: sort == s,
                                  onSelected: (_) => update(() => sort = s))
                          ]),
                          const SizedBox(height: 16),
                          PrimaryButton(
                              label: 'Áp dụng bộ lọc',
                              onPressed: () => Navigator.pop(ctx, true)),
                        ])))));
    if (!mounted || applied != true) return;
    setState(() {
      _status = status;
      _sort = sort;
    });
  }

  static const _statusLabels = [
    (OrderStatusFilter.all, 'Tất cả'),
    (OrderStatusFilter.active, 'Đang làm'),
    (OrderStatusFilter.completed, 'Hoàn thành'),
    (OrderStatusFilter.cancelled, 'Đã hủy'),
  ];

  Widget _header() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
      child: Row(children: [
        Expanded(
            child: Text('Đơn hàng',
                style: appText(26, weight: FontWeight.w700, color: _navy))),
        IconButton(
            tooltip: 'Tìm đơn hàng',
            onPressed: _searchFocus.requestFocus,
            icon: const Icon(Icons.search_rounded,
                size: 26, color: AppColors.primary)),
        IconButton(
            tooltip: 'Bộ lọc đơn hàng',
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune_rounded,
                size: 26, color: AppColors.primary)),
      ]));

  /// Pill tabs; "Đã hủy" lives in the chips, so none is highlighted for it.
  Widget _tabs(List<_Entry> all) {
    int count(OrderStatusFilter f) => all.where((e) => _inStatus(e, f)).length;
    return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: _paleBlue, borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          for (final (f, label) in const [
            (OrderStatusFilter.all, 'Tất cả'),
            (OrderStatusFilter.active, 'Đang làm'),
            (OrderStatusFilter.completed, 'Hoàn thành'),
          ])
            Expanded(
                child: Semantics(
                    selected: _status == f,
                    button: true,
                    child: InkWell(
                        key: ValueKey('orders-tab-${f.name}'),
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => setState(() => _status = f),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                vertical: 11, horizontal: 4),
                            decoration: BoxDecoration(
                                color: _status == f
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22)),
                            child: Text('$label (${count(f)})',
                                textAlign: TextAlign.center,
                                style: appText(12,
                                    weight: _status == f
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: _status == f
                                        ? Colors.white
                                        : _secondary)))))),
        ]));
  }

  Widget _banner() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF4FC),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quản lý công việc của bạn',
            style: appText(14, weight: FontWeight.w700, color: _navy)),
        const SizedBox(height: 3),
        Text('Theo dõi các đơn đang xử lý và lịch sử công việc.',
            style: appText(11.5, color: _secondary, height: 1.4)),
      ]));

  Widget _searchBar() => TextField(
      key: const ValueKey('orders-search'),
      controller: _search,
      focusNode: _searchFocus,
      onChanged: (_) => setState(() {}),
      style: appText(13),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
          hintText: 'Tìm kiếm theo dịch vụ, xe, địa chỉ hoặc mã đơn...',
          hintMaxLines: 3,
          hintStyle: appText(12, color: _secondary),
          filled: true,
          fillColor: const Color(0xFFF1F5FA),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 22, color: _secondary),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa từ khóa',
                  onPressed: () => setState(_search.clear),
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: _secondary)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide:
                  const BorderSide(color: Color(0xFFE3EAF3), width: .8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary, width: 1)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none)));

  Widget _chipsRow() => SingleChildScrollView(
      key: const ValueKey('orders-chips'),
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final (f, label) in _statusLabels) ...[
          ChoiceChip(
              key: ValueKey('orders-chip-${f.name}'),
              label: Text(label,
                  style: appText(12,
                      weight: FontWeight.w600,
                      color: _status == f ? Colors.white : _navy)),
              showCheckmark: false,
              selected: _status == f,
              selectedColor: AppColors.primary,
              backgroundColor: _paleBlue,
              side: BorderSide.none,
              onSelected: (_) => setState(() => _status = f)),
          const SizedBox(width: 8),
        ],
      ]));

  Widget _sortButton() => PopupMenuButton<OrderSort>(
      key: const ValueKey('orders-sort'),
      tooltip: 'Sắp xếp',
      initialValue: _sort,
      onSelected: (v) => setState(() => _sort = v),
      itemBuilder: (_) => [
            for (final s in OrderSort.values)
              PopupMenuItem(
                  value: s, child: Text(_sortLabel(s), style: appText(13))),
          ],
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3EAF3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.swap_vert_rounded, size: 18, color: _navy),
            const SizedBox(width: 4),
            Text(_sortLabel(_sort),
                style: appText(12, weight: FontWeight.w500, color: _navy)),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _navy),
          ])));

  Widget _empty(bool hasAny) => Container(
      key: const ValueKey('orders-empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3EAF3), width: .7)),
      child: Column(children: [
        const Icon(Icons.search_off_rounded, size: 28, color: _secondary),
        const SizedBox(height: 8),
        Text('Chưa có đơn hàng phù hợp',
            textAlign: TextAlign.center,
            style: appText(14, weight: FontWeight.w700, color: _navy)),
        const SizedBox(height: 4),
        Text(
            hasAny
                ? 'Thử thay đổi từ khóa hoặc bộ lọc.'
                : 'Các đơn bạn nhận sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: appText(12, color: _secondary, height: 1.4)),
        if (_filtering) ...[
          const SizedBox(height: 8),
          TextButton(
              onPressed: _clear,
              child: Text('Xóa bộ lọc',
                  style: appText(12.5, weight: FontWeight.w600))),
        ],
      ]));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final all = _entries();
        final shown = all
            .where((e) => _inStatus(e, _status) && _matchesSearch(e))
            .toList()
          ..sort((a, b) => _sort == OrderSort.newest
              ? b.time.compareTo(a.time)
              : a.time.compareTo(b.time));
        return SafeArea(
            bottom: false,
            child: Column(children: [
              _header(),
              Expanded(
                  child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                    _tabs(all),
                    const SizedBox(height: 12),
                    _banner(),
                    const SizedBox(height: 12),
                    _searchBar(),
                    const SizedBox(height: 10),
                    _chipsRow(),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: Text(
                              appState.showcaseOrdersEnabled
                                  ? '${shown.length} đơn hàng · Dữ liệu trình diễn, không ghi vào Ví'
                                  : '${shown.length} đơn hàng',
                              key: const ValueKey('orders-count'),
                              style: appText(12, color: _secondary))),
                      _sortButton(),
                    ]),
                    const SizedBox(height: 8),
                    if (shown.isEmpty)
                      _empty(all.isNotEmpty)
                    else
                      for (final e in shown) ...[
                        _OrderCard(entry: e),
                        const SizedBox(height: 10),
                      ],
                  ])),
            ]));
      });
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.entry});
  final _Entry entry;

  String get _date {
    final t = entry.time;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} · ${two(t.hour)}:${two(t.minute)}';
  }

  Widget _badge() {
    final (label, color, bg) = switch (entry.status) {
      OrderStatus.active => (
          'Đang làm',
          AppColors.primary,
          AppColors.surfaceSoft
        ),
      OrderStatus.completed => (
          'Hoàn thành',
          AppColors.successDark,
          AppColors.successSoft
        ),
      OrderStatus.cancelled => (
          'Đã hủy',
          AppColors.dangerDark,
          AppColors.dangerSoft
        ),
    };
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: appText(11.5, color: color, weight: FontWeight.w600)));
  }

  /// Right-hand money block: earning, current quote or an explicit "none".
  Widget _money(CrossAxisAlignment align) {
    final label = switch (entry.status) {
      OrderStatus.completed => 'Thu nhập',
      OrderStatus.active => 'Báo giá',
      OrderStatus.cancelled => null,
    };
    return Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.status == OrderStatus.cancelled)
            Text('Không ghi nhận thu nhập',
                textAlign: align == CrossAxisAlignment.end
                    ? TextAlign.end
                    : TextAlign.start,
                style: appText(11, color: _secondary, height: 1.3))
          else ...[
            Text(label!, style: appText(11, color: _secondary)),
            Text(formatVnd(entry.amount ?? 0),
                key: ValueKey('orders-amount-${entry.code}'),
                style: appText(17, weight: FontWeight.w700, color: _navy)),
          ],
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final compact = MediaQuery.sizeOf(context).width < 360 || scale > 1.25;
    final photo = compact ? 84.0 : 98.0;
    final info =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(entry.issue,
          style:
              appText(16, weight: FontWeight.w700, color: _navy, height: 1.25)),
      const SizedBox(height: 3),
      Text('${entry.vehicle} · ${vehicleLabel(entry.vehicle)}',
          style: appText(12.5,
              weight: FontWeight.w500, color: _secondary, height: 1.35)),
      Text(entry.address, style: appText(12, color: _secondary, height: 1.35)),
      Text(_date, style: appText(12, color: _secondary, height: 1.35)),
    ]);
    return ShadowCard(
        key: ValueKey(entry.code),
        onTap: entry.onOpen,
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          OrderPhoto(
              issue: entry.issue,
              vehicle: entry.vehicle,
              width: photo,
              height: photo * .8),
          const SizedBox(width: 12),
          Expanded(
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          info,
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _badge(),
                                _money(CrossAxisAlignment.start),
                              ]),
                        ])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Expanded(child: info),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 104),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _badge(),
                                    const SizedBox(height: 8),
                                    _money(CrossAxisAlignment.end),
                                  ])),
                        ])),
          const Padding(
              padding: EdgeInsets.only(top: 22),
              child: Icon(Icons.chevron_right_rounded, size: 20, color: _navy)),
        ]));
  }
}
